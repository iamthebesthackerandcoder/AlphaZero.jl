# Move generation and validation for Checkers

# Get adjacent diagonal positions for a given position
function get_diagonal_neighbors(pos::Int)
    row, col = pos_to_coords(pos)
    neighbors = Int[]
    
    # Check all four diagonal directions
    for (dr, dc) in [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        new_row, new_col = row + dr, col + dc
        if is_valid_square(new_row, new_col)
            push!(neighbors, coords_to_pos(new_row, new_col))
        end
    end
    
    return neighbors
end

# Get positions that are two squares away diagonally (for jumps)
function get_jump_positions(pos::Int)
    row, col = pos_to_coords(pos)
    jumps = Tuple{Int, Int}[]  # (destination, captured_position)
    
    # Check all four diagonal directions
    for (dr, dc) in [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        mid_row, mid_col = row + dr, col + dc
        dest_row, dest_col = row + 2*dr, col + 2*dc
        
        if is_valid_square(mid_row, mid_col) && is_valid_square(dest_row, dest_col)
            mid_pos = coords_to_pos(mid_row, mid_col)
            dest_pos = coords_to_pos(dest_row, dest_col)
            push!(jumps, (dest_pos, mid_pos))
        end
    end
    
    return jumps
end

# Check if a piece can move in a given direction (for men vs kings)
function can_move_direction(piece::PieceType, from_pos::Int, to_pos::Int)
    if is_king(piece)
        return true  # Kings can move in any direction
    end
    
    from_row, _ = pos_to_coords(from_pos)
    to_row, _ = pos_to_coords(to_pos)
    
    # Men can only move forward
    if piece == WHITE_MAN
        return to_row < from_row  # White moves toward row 1
    elseif piece == BLACK_MAN
        return to_row > from_row  # Black moves toward row 8
    end
    
    return false
end

# Generate simple moves (non-capturing) for a piece
function generate_simple_moves(board::Board, pos::Int)
    piece = board[pos]
    if is_empty(piece)
        return Move[]
    end
    
    moves = Move[]
    
    for neighbor in get_diagonal_neighbors(pos)
        if is_empty(board[neighbor]) && can_move_direction(piece, pos, neighbor)
            push!(moves, Move(pos, neighbor))
        end
    end
    
    return moves
end

# Generate capture moves for a piece (recursive for multiple jumps)
function generate_capture_moves(board::Board, pos::Int, captured_so_far::Vector{Int}=Int[])
    piece = board[pos]
    if is_empty(piece)
        return Move[]
    end
    
    moves = Move[]
    player = piece_owner(piece)
    
    # Create a temporary board with captured pieces removed
    temp_board = board
    for cap_pos in captured_so_far
        temp_board = setindex(temp_board, EMPTY, cap_pos)
    end
    
    found_capture = false
    
    for (dest_pos, mid_pos) in get_jump_positions(pos)
        mid_piece = temp_board[mid_pos]
        
        # Check if we can capture this piece
        if !is_empty(mid_piece) && 
           piece_owner(mid_piece) != player && 
           is_empty(temp_board[dest_pos]) &&
           can_move_direction(piece, pos, dest_pos) &&
           mid_pos ∉ captured_so_far  # Don't capture the same piece twice
            
            found_capture = true
            new_captured = [captured_so_far; mid_pos]
            
            # Check for additional captures from the destination
            additional_moves = generate_capture_moves(temp_board, dest_pos, new_captured)
            
            if isempty(additional_moves)
                # No more captures possible, this is a complete move
                push!(moves, Move(pos, dest_pos, new_captured))
            else
                # Add all the extended capture sequences
                for add_move in additional_moves
                    push!(moves, Move(pos, add_move.to, add_move.captures))
                end
            end
        end
    end
    
    return moves
end

# Generate all legal moves for a player
function generate_all_moves(board::Board, player::Player)
    capture_moves = Move[]
    simple_moves = Move[]
    
    # Find all pieces belonging to the current player
    for pos in 1:NUM_POSITIONS
        piece = board[pos]
        if !is_empty(piece) && piece_owner(piece) == player
            # Generate capture moves first (captures are mandatory)
            captures = generate_capture_moves(board, pos)
            append!(capture_moves, captures)
            
            # Generate simple moves
            if isempty(captures)  # Only consider simple moves if no captures available
                simples = generate_simple_moves(board, pos)
                append!(simple_moves, simples)
            end
        end
    end
    
    # In checkers, captures are mandatory
    return isempty(capture_moves) ? simple_moves : capture_moves
end

# Check if a move is legal
function is_legal_move(board::Board, player::Player, move::Move)
    legal_moves = generate_all_moves(board, player)
    return move in legal_moves
end

# Apply a move to the board
function apply_move(board::Board, move::Move)
    new_board = board
    
    # Move the piece
    piece = board[move.from]
    new_board = setindex(new_board, EMPTY, move.from)
    
    # Check for promotion to king
    dest_row, _ = pos_to_coords(move.to)
    if piece == WHITE_MAN && dest_row == 1
        piece = WHITE_KING
    elseif piece == BLACK_MAN && dest_row == BOARD_SIZE
        piece = BLACK_KING
    end
    
    new_board = setindex(new_board, piece, move.to)
    
    # Remove captured pieces
    for cap_pos in move.captures
        new_board = setindex(new_board, EMPTY, cap_pos)
    end
    
    return new_board
end
