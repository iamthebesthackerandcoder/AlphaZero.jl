# Simple demonstration of the board utilities

include("BoardUtils.jl")

println("Checkers Board Utilities Demo")
println("============================")

# Create and display initial board
println("\n1. Initial Board Setup:")
board = create_initial_board()
println(board_to_string(board))

# Demonstrate square utilities
println("2. Square Properties:")
positions = [(1,1), (1,2), (4,4), (8,7)]
for (row, col) in positions
    color = inside_board(row, col) ? square_color(row, col) : "outside"
    valid = is_valid_position(row, col)
    println("  ($row,$col): $color square, valid: $valid")
end

# Show diagonal step calculation
println("\n3. Diagonal Steps:")
from_pos = (2, 1)
to_pos = (6, 5)
steps = diag_steps(from_pos[1], from_pos[2], to_pos[1], to_pos[2])
println("  From $from_pos to $to_pos: $steps")

# Demonstrate piece operations
println("\n4. Piece Information:")
test_pieces = [EMPTY_SQUARE, WHITE_MAN, BLACK_KING]
for piece in test_pieces
    owner = get_piece_owner(piece)
    is_king = is_king_piece(piece)
    promoted = promote_to_king(piece)
    println("  Piece $piece: owner=$owner, king=$is_king, promoted=$promoted")
end

# Show piece counting
println("\n5. Piece Counts:")
white_pieces = count_pieces(board, WHITE_PLAYER)
black_pieces = count_pieces(board, BLACK_PLAYER)
println("  White: $white_pieces pieces")
println("  Black: $black_pieces pieces")

# Demonstrate a simple move
println("\n6. Making a Move:")
piece_at_start = get_piece_at(board, 3, 2)  # Black man
println("  Moving piece at (3,2): $piece_at_start")

# Move the piece to (4,3)
new_board = set_piece_at(board, 4, 3, piece_at_start)  # Place at new position
new_board = set_piece_at(new_board, 3, 2, EMPTY_SQUARE)  # Clear old position

println("  Board after move:")
println(board_to_string(new_board))

println("\nDemo completed!")
