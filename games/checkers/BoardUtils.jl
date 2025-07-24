# Board representation & helper utilities for Checkers
# Using 8×8 matrix with values: 0 empty, 1 man white, 2 king white, -1 man black, -2 king black

# Board dimensions
const BOARD_DIM = 8

# Piece values for 8×8 matrix representation
const EMPTY_SQUARE = Int8(0)
const WHITE_MAN = Int8(1)
const WHITE_KING = Int8(2)
const BLACK_MAN = Int8(-1)
const BLACK_KING = Int8(-2)

# Board type - 8×8 matrix of Int8 values
const CheckersBoard = Matrix{Int8}

# Player types
const WHITE_PLAYER = 1
const BLACK_PLAYER = -1

"""
    square_color(row::Int, col::Int) -> Symbol

Returns the color of the square at given coordinates.
In checkers, only dark squares are used for play.
"""
function square_color(row::Int, col::Int)
    return (row + col) % 2 == 1 ? :dark : :light
end

"""
    is_dark_square(row::Int, col::Int) -> Bool

Check if the square at given coordinates is a dark square.
Only dark squares are used in checkers.
"""
function is_dark_square(row::Int, col::Int)
    return (row + col) % 2 == 1
end

"""
    inside_board(row::Int, col::Int) -> Bool

Check if the given coordinates are within the board boundaries.
"""
function inside_board(row::Int, col::Int)
    return 1 <= row <= BOARD_DIM && 1 <= col <= BOARD_DIM
end

"""
    is_valid_position(row::Int, col::Int) -> Bool

Check if the position is valid for checkers (inside board and on dark square).
"""
function is_valid_position(row::Int, col::Int)
    return inside_board(row, col) && is_dark_square(row, col)
end

"""
    diag_steps(from_row::Int, from_col::Int, to_row::Int, to_col::Int) -> Vector{Tuple{Int,Int}}

Get all diagonal steps between two positions (exclusive of endpoints).
Returns empty vector if positions are not on the same diagonal.
"""
function diag_steps(from_row::Int, from_col::Int, to_row::Int, to_col::Int)
    steps = Tuple{Int,Int}[]
    
    # Check if positions are on the same diagonal
    row_diff = to_row - from_row
    col_diff = to_col - from_col
    
    if abs(row_diff) != abs(col_diff) || row_diff == 0
        return steps  # Not on same diagonal
    end
    
    # Determine step direction
    row_step = sign(row_diff)
    col_step = sign(col_diff)
    
    # Generate intermediate steps
    current_row = from_row + row_step
    current_col = from_col + col_step
    
    while current_row != to_row && current_col != to_col
        push!(steps, (current_row, current_col))
        current_row += row_step
        current_col += col_step
    end
    
    return steps
end

"""
    is_diagonal_move(from_row::Int, from_col::Int, to_row::Int, to_col::Int) -> Bool

Check if the move is diagonal.
"""
function is_diagonal_move(from_row::Int, from_col::Int, to_row::Int, to_col::Int)
    row_diff = abs(to_row - from_row)
    col_diff = abs(to_col - from_col)
    return row_diff == col_diff && row_diff > 0
end

"""
    manhattan_distance(from_row::Int, from_col::Int, to_row::Int, to_col::Int) -> Int

Calculate Manhattan distance between two positions.
"""
function manhattan_distance(from_row::Int, from_col::Int, to_row::Int, to_col::Int)
    return abs(to_row - from_row) + abs(to_col - from_col)
end

"""
    diagonal_distance(from_row::Int, from_col::Int, to_row::Int, to_col::Int) -> Int

Calculate diagonal distance between two positions.
Returns -1 if positions are not on the same diagonal.
"""
function diagonal_distance(from_row::Int, from_col::Int, to_row::Int, to_col::Int)
    row_diff = abs(to_row - from_row)
    col_diff = abs(to_col - from_col)
    return row_diff == col_diff ? row_diff : -1
end

"""
    get_piece_at(board::CheckersBoard, row::Int, col::Int) -> Int8

Get the piece at the specified position.
"""
function get_piece_at(board::CheckersBoard, row::Int, col::Int)
    return board[row, col]
end

"""
    set_piece_at(board::CheckersBoard, row::Int, col::Int, piece::Int8) -> CheckersBoard

Set a piece at the specified position, returning a new board.
"""
function set_piece_at(board::CheckersBoard, row::Int, col::Int, piece::Int8)
    new_board = copy(board)
    new_board[row, col] = piece
    return new_board
end

"""
    is_empty_square(board::CheckersBoard, row::Int, col::Int) -> Bool

Check if the square is empty.
"""
function is_empty_square(board::CheckersBoard, row::Int, col::Int)
    return board[row, col] == EMPTY_SQUARE
end

"""
    is_white_piece(piece::Int8) -> Bool

Check if the piece belongs to white player.
"""
function is_white_piece(piece::Int8)
    return piece == WHITE_MAN || piece == WHITE_KING
end

"""
    is_black_piece(piece::Int8) -> Bool

Check if the piece belongs to black player.
"""
function is_black_piece(piece::Int8)
    return piece == BLACK_MAN || piece == BLACK_KING
end

"""
    is_man_piece(piece::Int8) -> Bool

Check if the piece is a man (not a king).
"""
function is_man_piece(piece::Int8)
    return piece == WHITE_MAN || piece == BLACK_MAN
end

"""
    is_king_piece(piece::Int8) -> Bool

Check if the piece is a king.
"""
function is_king_piece(piece::Int8)
    return piece == WHITE_KING || piece == BLACK_KING
end

"""
    get_piece_owner(piece::Int8) -> Int

Get the owner of the piece (WHITE_PLAYER, BLACK_PLAYER, or 0 for empty).
"""
function get_piece_owner(piece::Int8)
    if is_white_piece(piece)
        return WHITE_PLAYER
    elseif is_black_piece(piece)
        return BLACK_PLAYER
    else
        return 0  # Empty square
    end
end

"""
    promote_to_king(piece::Int8) -> Int8

Promote a man to king.
"""
function promote_to_king(piece::Int8)
    if piece == WHITE_MAN
        return WHITE_KING
    elseif piece == BLACK_MAN
        return BLACK_KING
    else
        return piece  # Already a king or empty
    end
end

"""
    should_promote(piece::Int8, row::Int) -> Bool

Check if a piece should be promoted to king when reaching the given row.
"""
function should_promote(piece::Int8, row::Int)
    if piece == WHITE_MAN && row == 1
        return true
    elseif piece == BLACK_MAN && row == BOARD_DIM
        return true
    else
        return false
    end
end

"""
    get_forward_direction(player::Int) -> Int

Get the forward direction for a player (row increment).
White moves up (decreasing row), Black moves down (increasing row).
"""
function get_forward_direction(player::Int)
    return player == WHITE_PLAYER ? -1 : 1
end

"""
    create_empty_board() -> CheckersBoard

Create an empty 8×8 checkers board.
"""
function create_empty_board()
    return CheckersBoard(zeros(Int8, BOARD_DIM, BOARD_DIM))
end

"""
    create_initial_board() -> CheckersBoard

Create the initial checkers board setup.
"""
function create_initial_board()
    board = create_empty_board()
    
    # Place black pieces (top 3 rows, only on dark squares)
    for row in 1:3
        for col in 1:BOARD_DIM
            if is_dark_square(row, col)
                board = set_piece_at(board, row, col, BLACK_MAN)
            end
        end
    end
    
    # Place white pieces (bottom 3 rows, only on dark squares)
    for row in (BOARD_DIM-2):BOARD_DIM
        for col in 1:BOARD_DIM
            if is_dark_square(row, col)
                board = set_piece_at(board, row, col, WHITE_MAN)
            end
        end
    end
    
    return board
end

"""
    count_pieces(board::CheckersBoard, player::Int) -> Int

Count the number of pieces for a given player.
"""
function count_pieces(board::CheckersBoard, player::Int)
    count = 0
    for row in 1:BOARD_DIM
        for col in 1:BOARD_DIM
            piece = board[row, col]
            if get_piece_owner(piece) == player
                count += 1
            end
        end
    end
    return count
end

"""
    count_kings(board::CheckersBoard, player::Int) -> Int

Count the number of kings for a given player.
"""
function count_kings(board::CheckersBoard, player::Int)
    count = 0
    target_king = player == WHITE_PLAYER ? WHITE_KING : BLACK_KING
    for row in 1:BOARD_DIM
        for col in 1:BOARD_DIM
            if board[row, col] == target_king
                count += 1
            end
        end
    end
    return count
end

"""
    get_all_pieces(board::CheckersBoard, player::Int) -> Vector{Tuple{Int,Int}}

Get positions of all pieces for a given player.
"""
function get_all_pieces(board::CheckersBoard, player::Int)
    pieces = Tuple{Int,Int}[]
    for row in 1:BOARD_DIM
        for col in 1:BOARD_DIM
            if get_piece_owner(board[row, col]) == player
                push!(pieces, (row, col))
            end
        end
    end
    return pieces
end

"""
    board_to_string(board::CheckersBoard) -> String

Convert board to a readable string representation.
"""
function board_to_string(board::CheckersBoard)
    result = "  " * join(1:BOARD_DIM, " ") * "\n"
    for row in 1:BOARD_DIM
        result *= "$row "
        for col in 1:BOARD_DIM
            if is_dark_square(row, col)
                piece = board[row, col]
                symbol = if piece == EMPTY_SQUARE
                    "."
                elseif piece == WHITE_MAN
                    "w"
                elseif piece == WHITE_KING
                    "W"
                elseif piece == BLACK_MAN
                    "b"
                elseif piece == BLACK_KING
                    "B"
                else
                    "?"
                end
                result *= "$symbol "
            else
                result *= "  "  # Light squares are not displayed
            end
        end
        result *= "\n"
    end
    return result
end

"""
    get_adjacent_squares(row::Int, col::Int) -> Vector{Tuple{Int,Int}}

Get all adjacent diagonal squares (used for simple moves).
"""
function get_adjacent_squares(row::Int, col::Int)
    adjacents = Tuple{Int,Int}[]
    for dr in [-1, 1]
        for dc in [-1, 1]
            new_row, new_col = row + dr, col + dc
            if is_valid_position(new_row, new_col)
                push!(adjacents, (new_row, new_col))
            end
        end
    end
    return adjacents
end

"""
    get_diagonal_squares(row::Int, col::Int, distance::Int) -> Vector{Tuple{Int,Int}}

Get diagonal squares at a specific distance.
"""
function get_diagonal_squares(row::Int, col::Int, distance::Int)
    squares = Tuple{Int,Int}[]
    for dr in [-distance, distance]
        for dc in [-distance, distance]
            new_row, new_col = row + dr, col + dc
            if is_valid_position(new_row, new_col)
                push!(squares, (new_row, new_col))
            end
        end
    end
    return squares
end

"""
    clear_path(board::CheckersBoard, from_row::Int, from_col::Int, to_row::Int, to_col::Int) -> Bool

Check if the diagonal path between two squares is clear (no pieces in between).
"""
function clear_path(board::CheckersBoard, from_row::Int, from_col::Int, to_row::Int, to_col::Int)
    steps = diag_steps(from_row, from_col, to_row, to_col)
    for (step_row, step_col) in steps
        if !is_empty_square(board, step_row, step_col)
            return false
        end
    end
    return true
end

export CheckersBoard, BOARD_DIM, EMPTY_SQUARE, WHITE_MAN, WHITE_KING, BLACK_MAN, BLACK_KING,
       WHITE_PLAYER, BLACK_PLAYER, square_color, is_dark_square, inside_board, is_valid_position,
       diag_steps, is_diagonal_move, manhattan_distance, diagonal_distance, get_piece_at, set_piece_at,
       is_empty_square, is_white_piece, is_black_piece, is_man_piece, is_king_piece, get_piece_owner,
       promote_to_king, should_promote, get_forward_direction, create_empty_board, create_initial_board,
       count_pieces, count_kings, get_all_pieces, board_to_string, get_adjacent_squares,
       get_diagonal_squares, clear_path
