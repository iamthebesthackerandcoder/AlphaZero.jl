#!/usr/bin/env julia

# Test capture scenarios for legal_moves function

using StaticArrays

const BOARD_SIZE = 8
const NUM_SQUARES = 32
const NUM_POSITIONS = NUM_SQUARES

const Player = Bool
const WHITE = true
const BLACK = false

const EMPTY = Int8(0)
const WHITE_MAN = Int8(1)
const BLACK_MAN = Int8(2)
const WHITE_KING = Int8(3)
const BLACK_KING = Int8(4)

const Cell = Int8
const Board = SVector{NUM_POSITIONS, Cell}

# Create a minimal environment struct for testing
mutable struct TestCheckersEnv
    board::SVector{32, Int8}
    side_to_move::Bool
end

# Include necessary functions
include("Types.jl")
include("Moves.jl")

println("Testing capture scenarios:")

# Create a board with capture opportunities
# White man at position 21 (row 6, col 1) can capture black man at position 17 (row 5, col 2)
# and land on position 14 (row 4, col 3)
test_board = [
    BLACK_MAN, BLACK_MAN, BLACK_MAN, BLACK_MAN,  # Row 1: 1-4
    BLACK_MAN, BLACK_MAN, BLACK_MAN, BLACK_MAN,  # Row 2: 5-8
    BLACK_MAN, BLACK_MAN, BLACK_MAN, BLACK_MAN,  # Row 3: 9-12
    EMPTY, EMPTY, EMPTY, EMPTY,                  # Row 4: 13-16
    EMPTY, BLACK_MAN, EMPTY, EMPTY,              # Row 5: 17-20 (black piece at 18)
    WHITE_MAN, EMPTY, WHITE_MAN, WHITE_MAN,      # Row 6: 21-24 (white at 21, 23, 24)
    WHITE_MAN, WHITE_MAN, WHITE_MAN, WHITE_MAN,  # Row 7: 25-28
    WHITE_MAN, WHITE_MAN, WHITE_MAN, WHITE_MAN   # Row 8: 29-32
]

env = TestCheckersEnv(Board(test_board), WHITE)

# Print the test board
println("\nTest board setup:")
for pos in 1:NUM_POSITIONS
    piece = env.board[pos]
    row, col = pos_to_coords(pos)
    piece_name = if piece == EMPTY
        "empty"
    elseif piece == WHITE_MAN
        "white_man"
    elseif piece == BLACK_MAN
        "black_man"
    elseif piece == WHITE_KING
        "white_king"
    elseif piece == BLACK_KING
        "black_king"
    else
        "unknown($piece)"
    end
    println("Position $pos (row $row, col $col): $piece_name")
end

# Get legal moves
moves = legal_moves(env)

println("\nNumber of legal moves: ", length(moves))

# Separate capture and simple moves
capture_moves = filter(m -> m.is_capture, moves)
simple_moves = filter(m -> !m.is_capture, moves)

println("Capture moves: $(length(capture_moves))")
println("Simple moves: $(length(simple_moves))")

# Print all moves
println("\nAll moves:")
for (i, move) in enumerate(moves)
    from_row, from_col = pos_to_coords(move.from)
    to_row, to_col = pos_to_coords(move.to)
    
    if move.is_capture
        captured_info = "CAPTURE: " * join([string(cap) for cap in move.captures], ", ")
    else
        captured_info = "simple move"
    end
    
    println("Move $i: Position $(move.from) (row $from_row, col $from_col) -> Position $(move.to) (row $to_row, col $to_col) [$captured_info]")
end

# Test that we have both captures and simple moves when captures are available
if length(capture_moves) > 0 && length(simple_moves) > 0
    println("\n✓ SUCCESS: Both capture and simple moves are available (captures are NOT mandatory)")
elseif length(capture_moves) > 0 && length(simple_moves) == 0
    println("\n✗ WARNING: Only capture moves available (captures appear to be mandatory)")
else
    println("\n? INFO: No capture moves available in this position")
end

println("\nTest completed!")
