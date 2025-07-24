# Move generation and validation for Checkers

# Enhanced move structure with capture flag
struct CheckersMove
    from::Int  # Source position (1-32)
    to::Int    # Destination position (1-32)
    captures::Vector{Int}  # Positions of captured pieces
    is_capture::Bool  # Flag to mark capture moves
end

# Constructor for simple moves
CheckersMove(from::Int, to::Int) = CheckersMove(from, to, Int[], false)

# Constructor for capture moves
CheckersMove(from::Int, to::Int, captures::Vector{Int}) = CheckersMove(from, to, captures, !isempty(captures))

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
function can_move_direction(piece::Int8, from_pos::Int, to_pos::Int)
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

# Revert a move (for undo functionality)
# This requires storing additional information about the move
struct ReversibleMove
    from::Int  # Source position (1-32)
    to::Int    # Destination position (1-32)
    captures::Vector{Int}  # Positions of captured pieces
    captured_pieces::Vector{Int8}  # The actual captured pieces
    was_promoted::Bool  # Whether this move resulted in a promotion
    original_piece::Int8  # The original piece before promotion
    previous_halfmove_clock::Int  # Previous halfmove clock value for undo
end

# Create a reversible move from a regular move and board state
function create_reversible_move(board::Board, move::Move, halfmove_clock::Int)
    piece = board[move.from]
    captured_pieces = Int8[]

    # Store the captured pieces
    for cap_pos in move.captures
        push!(captured_pieces, board[cap_pos])
    end

    # Check if this move would result in a promotion
    dest_row, _ = pos_to_coords(move.to)
    was_promoted = false
    if piece == WHITE_MAN && dest_row == 1
        was_promoted = true
    elseif piece == BLACK_MAN && dest_row == BOARD_SIZE
        was_promoted = true
    end

    return ReversibleMove(move.from, move.to, move.captures, captured_pieces, was_promoted, piece, halfmove_clock)
end

# Revert a move using stored information
function revert_move(board::Board, rmove::ReversibleMove)
    new_board = board
    
    # Move the piece back
    # If it was promoted, restore the original piece type
    piece_to_restore = rmove.was_promoted ? rmove.original_piece : board[rmove.to]
    new_board = setindex(new_board, piece_to_restore, rmove.from)
    new_board = setindex(new_board, EMPTY, rmove.to)
    
    # Restore captured pieces
    for (i, cap_pos) in enumerate(rmove.captures)
        new_board = setindex(new_board, rmove.captured_pieces[i], cap_pos)
    end
    
    return new_board
end

# Simplified revert_move that works with regular Move struct
# This version reconstructs the original state by analyzing the current board
function revert_move(board::Board, move::Move)
    new_board = board
    
    # Get the piece that's currently at the destination
    moved_piece = board[move.to]
    
    # Determine what the original piece was before any promotion
    original_piece = moved_piece
    dest_row, _ = pos_to_coords(move.to)
    from_row, _ = pos_to_coords(move.from)
    
    # If this is a king on the back rank and it came from a non-back rank, it was promoted
    if moved_piece == WHITE_KING && dest_row == 1 && from_row != 1
        original_piece = WHITE_MAN
    elseif moved_piece == BLACK_KING && dest_row == BOARD_SIZE && from_row != BOARD_SIZE
        original_piece = BLACK_MAN
    end
    
    # Move the piece back
    new_board = setindex(new_board, original_piece, move.from)
    new_board = setindex(new_board, EMPTY, move.to)
    
    # For captured pieces, we need to determine what they were
    # This is a limitation - we'll need to reconstruct or store this information
    # For now, we'll assume captured pieces were of the opposite color as the moving piece
    player = piece_owner(original_piece)
    opponent = !player
    
    for cap_pos in move.captures
        # We need to guess what piece was captured
        # This is imperfect - ideally we'd store this information
        cap_row, _ = pos_to_coords(cap_pos)
        
        # Heuristic: if on back rank, it was likely a king, otherwise a man
        if (opponent == WHITE && cap_row == 1) || (opponent == BLACK && cap_row == BOARD_SIZE)
            captured_piece = opponent == WHITE ? WHITE_KING : BLACK_KING
        else
            captured_piece = opponent == WHITE ? WHITE_MAN : BLACK_MAN
        end
        
        new_board = setindex(new_board, captured_piece, cap_pos)
    end
    
    return new_board
end

# Convert Move to CheckersMove
function move_to_checkers_move(move::Move)
    return CheckersMove(move.from, move.to, move.captures)
end

# Generate CheckersMove simple moves for a piece
function generate_checkers_simple_moves(board::Board, pos::Int)
    piece = board[pos]
    if is_empty(piece)
        return CheckersMove[]
    end
    
    moves = CheckersMove[]
    
    for neighbor in get_diagonal_neighbors(pos)
        if is_empty(board[neighbor]) && can_move_direction(piece, pos, neighbor)
            push!(moves, CheckersMove(pos, neighbor))
        end
    end
    
    return moves
end

# Generate CheckersMove capture moves for a piece (recursive for multiple jumps)
function generate_checkers_capture_moves(board::Board, pos::Int, captured_so_far::Vector{Int}=Int[])
    piece = board[pos]
    if is_empty(piece)
        return CheckersMove[]
    end
    
    moves = CheckersMove[]
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
            additional_moves = generate_checkers_capture_moves(temp_board, dest_pos, new_captured)
            
            if isempty(additional_moves)
                # No more captures possible, this is a complete move
                push!(moves, CheckersMove(pos, dest_pos, new_captured))
            else
                # Add all the extended capture sequences
                for add_move in additional_moves
                    push!(moves, CheckersMove(pos, add_move.to, add_move.captures))
                end
            end
        end
    end
    
    return moves
end

# Main function: Generate all legal moves for the current player
# Returns Vector{CheckersMove} with captures marked and simple moves included even when captures exist
function legal_moves(env)
    board = env.board
    player = env.side_to_move
    
    capture_moves = CheckersMove[]
    simple_moves = CheckersMove[]
    
    # Find all pieces belonging to the current player
    for pos in 1:NUM_POSITIONS
        piece = board[pos]
        if !is_empty(piece) && piece_owner(piece) == player
            # Generate capture moves
            captures = generate_checkers_capture_moves(board, pos)
            append!(capture_moves, captures)
            
            # Generate simple moves - always include them (captures are NOT mandatory)
            simples = generate_checkers_simple_moves(board, pos)
            append!(simple_moves, simples)
        end
    end
    
    # Include both capture and simple moves (captures are NOT mandatory in this implementation)
    all_moves = CheckersMove[]
    append!(all_moves, capture_moves)
    append!(all_moves, simple_moves)
    
    return all_moves
end
