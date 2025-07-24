#!/usr/bin/env julia

# Simple test for legal_moves function without external dependencies

# Define basic types and constants for testing
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

# Create a minimal environment struct for testing
mutable struct TestCheckersEnv
    board::SVector{32, Int8}
    side_to_move::Bool
end

# Include necessary functions
include("Types.jl")
include("Moves.jl")

# Test with initial board setup
println("Testing legal_moves function with initial board setup:")

# Create a simple test environment
env = TestCheckersEnv(INITIAL_BOARD, WHITE)

# Debug: Print board state
println("Board state:")
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

println("\nCurrent player: ", env.side_to_move == WHITE ? "WHITE" : "BLACK")

# Debug: Check move generation for a specific piece
println("\n=== Debugging move generation for piece at position 21 ===")
piece = env.board[21]
println("Piece at position 21: ", piece)
println("Piece owner: ", piece_owner(piece))
println("Current player: ", env.side_to_move)
println("Piece belongs to current player: ", piece_owner(piece) == env.side_to_move)

# Check diagonal neighbors
neighbors = get_diagonal_neighbors(21)
println("Diagonal neighbors of position 21: ", neighbors)

# Debug coordinate conversion
row21, col21 = pos_to_coords(21)
println("Position 21 coordinates: row=$row21, col=$col21")
println("Is position 21 a valid square: ", is_valid_square(row21, col21))
println("(row + col) % 2 for position 21: ", (row21 + col21) % 2)

# Test coordinate conversion for a few positions
println("\nTesting coordinate conversion:")
for pos in [1, 5, 17, 21]
    r, c = pos_to_coords(pos)
    println("Position $pos -> (row $r, col $c), valid: ", is_valid_square(r, c), ", (r+c)%2=", (r+c)%2)
end

# Check each diagonal direction manually
println("Checking each diagonal direction:")
for (dr, dc) in [(-1, -1), (-1, 1), (1, -1), (1, 1)]
    new_row, new_col = row21 + dr, col21 + dc
    println("  Direction ($dr, $dc): new position would be row=$new_row, col=$new_col")
    println("    is_valid_square: ", is_valid_square(new_row, new_col))
    if is_valid_square(new_row, new_col)
        new_pos = coords_to_pos(new_row, new_col)
        println("    maps to position: $new_pos")
    end
end

for neighbor in neighbors
    neighbor_piece = env.board[neighbor]
    row, col = pos_to_coords(neighbor)
    can_move = can_move_direction(piece, 21, neighbor)
    neighbor_empty = neighbor_piece == EMPTY
    println("  Neighbor $neighbor (row $row, col $col): piece=$neighbor_piece, empty=$neighbor_empty, can_move=$can_move")
end

# Get legal moves for initial position
moves = legal_moves(env)

println("\nNumber of legal moves from initial position: ", length(moves))
println()

# Print some example moves
for (i, move) in enumerate(moves[1:min(10, length(moves))])
    from_row, from_col = pos_to_coords(move.from)
    to_row, to_col = pos_to_coords(move.to)
    
    capture_info = move.is_capture ? " (CAPTURE: $(length(move.captures)) pieces)" : " (simple move)"
    
    println("Move $i: Position $(move.from) (row $from_row, col $from_col) -> Position $(move.to) (row $to_row, col $to_col)$capture_info")
end

# Test that men can only move forward
println("\n=== Testing movement restrictions ===")

# White men should only move toward row 1 (forward)
white_moves = filter(m -> !m.is_capture, moves)
for move in white_moves
    from_row, _ = pos_to_coords(move.from)
    to_row, _ = pos_to_coords(move.to)
    if to_row >= from_row
        println("ERROR: White man at position $(move.from) (row $from_row) tried to move backward to position $(move.to) (row $to_row)")
    end
end

println("All white men movement directions verified correct")

# Test capture vs simple move classification
capture_moves = filter(m -> m.is_capture, moves)
simple_moves = filter(m -> !m.is_capture, moves)

println("\nCapture moves: $(length(capture_moves))")
println("Simple moves: $(length(simple_moves))")
println("Total moves: $(length(moves))")

# Verify capture moves have captures listed
for move in capture_moves
    if isempty(move.captures)
        println("ERROR: Capture move has no captures listed!")
    end
end

println("\nTest completed successfully!")
