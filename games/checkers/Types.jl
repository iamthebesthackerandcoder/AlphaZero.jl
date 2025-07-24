using StaticArrays

# Board dimensions
const BOARD_SIZE = 8
const NUM_SQUARES = 32  # Only dark squares are used in checkers
const NUM_POSITIONS = NUM_SQUARES

# Player types
const Player = Bool
const WHITE = true
const BLACK = false

# Piece types (using Int8 for efficient storage)
const EMPTY = Int8(0)
const WHITE_MAN = Int8(1)
const BLACK_MAN = Int8(2)
const WHITE_KING = Int8(3)
const BLACK_KING = Int8(4)

# For backward compatibility, define the enum as well
@enum PieceType begin
    EMPTY_PIECE = 0
    WHITE_MAN_PIECE = 1
    BLACK_MAN_PIECE = 2
    WHITE_KING_PIECE = 3
    BLACK_KING_PIECE = 4
end

# Convert between Int8 and PieceType for compatibility
int8_to_piecetype(val::Int8) = PieceType(val)
piecetype_to_int8(piece::PieceType) = Int8(piece)

# Cell representation
const Cell = Int8
const Board = SVector{NUM_POSITIONS, Cell}

# Initial board setup - standard checkers starting position
const INITIAL_BOARD = Board([
    BLACK_MAN, BLACK_MAN, BLACK_MAN, BLACK_MAN,  # Row 1
    BLACK_MAN, BLACK_MAN, BLACK_MAN, BLACK_MAN,  # Row 2
    BLACK_MAN, BLACK_MAN, BLACK_MAN, BLACK_MAN,  # Row 3
    EMPTY, EMPTY, EMPTY, EMPTY,                  # Row 4
    EMPTY, EMPTY, EMPTY, EMPTY,                  # Row 5
    WHITE_MAN, WHITE_MAN, WHITE_MAN, WHITE_MAN,  # Row 6
    WHITE_MAN, WHITE_MAN, WHITE_MAN, WHITE_MAN,  # Row 7
    WHITE_MAN, WHITE_MAN, WHITE_MAN, WHITE_MAN   # Row 8
])

# Game state
const GameState = NamedTuple{(:board, :curplayer), Tuple{Board, Player}}
const INITIAL_STATE = GameState((INITIAL_BOARD, WHITE))

# Move representation
struct Move
    from::Int  # Source position (1-32)
    to::Int    # Destination position (1-32)
    captures::Vector{Int}  # Positions of captured pieces
end

# Simple move constructor
Move(from::Int, to::Int) = Move(from, to, Int[])

# Utility functions for piece identification (for Int8)
is_white_piece(piece::Int8) = piece == WHITE_MAN || piece == WHITE_KING
is_black_piece(piece::Int8) = piece == BLACK_MAN || piece == BLACK_KING
is_man(piece::Int8) = piece == WHITE_MAN || piece == BLACK_MAN
is_king(piece::Int8) = piece == WHITE_KING || piece == BLACK_KING
is_empty(piece::Int8) = piece == EMPTY

# Get piece owner
function piece_owner(piece::Int8)
    is_white_piece(piece) ? WHITE : 
    is_black_piece(piece) ? BLACK : 
    nothing
end

# Utility functions for piece identification (for PieceType - backward compatibility)
is_white_piece(piece::PieceType) = Int8(piece) == WHITE_MAN || Int8(piece) == WHITE_KING
is_black_piece(piece::PieceType) = Int8(piece) == BLACK_MAN || Int8(piece) == BLACK_KING
is_man(piece::PieceType) = Int8(piece) == WHITE_MAN || Int8(piece) == BLACK_MAN
is_king(piece::PieceType) = Int8(piece) == WHITE_KING || Int8(piece) == BLACK_KING
is_empty(piece::PieceType) = Int8(piece) == EMPTY

# Get piece owner (PieceType version)
function piece_owner(piece::PieceType)
    is_white_piece(piece) ? WHITE : 
    is_black_piece(piece) ? BLACK : 
    nothing
end

# Convert between 32-square indexing and 8x8 board coordinates
function pos_to_coords(pos::Int)
    row = (pos - 1) ÷ 4 + 1
    col = 2 * ((pos - 1) % 4) + (row % 2 == 0 ? 2 : 1)
    return (row, col)
end

function coords_to_pos(row::Int, col::Int)
    # Only valid for dark squares
    if (row + col) % 2 == 0
        error("Invalid coordinates for checkers: must be dark square")
    end
    return (row - 1) * 4 + (col - (row % 2 == 0 ? 1 : 0)) ÷ 2 + 1
end

# Check if coordinates are valid dark squares
function is_valid_square(row::Int, col::Int)
    return 1 <= row <= BOARD_SIZE && 1 <= col <= BOARD_SIZE && (row + col) % 2 == 1
end
