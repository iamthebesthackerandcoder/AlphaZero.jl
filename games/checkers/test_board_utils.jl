# Test file for BoardUtils.jl
# Demonstrates the functionality of the 8×8 matrix board representation

include("BoardUtils.jl")

function test_board_utilities()
    println("Testing Board Utilities")
    println("======================")
    
    # Test 1: Board creation and basic functions
    println("\n1. Board Creation and Basic Functions")
    println("-------------------------------------")
    
    empty_board = create_empty_board()
    println("Empty board created: ", size(empty_board))
    
    initial_board = create_initial_board()
    println("Initial board created with standard setup")
    println("Board representation:")
    println(board_to_string(initial_board))
    
    # Test 2: Square color and position validation
    println("\n2. Square Color and Position Validation")
    println("---------------------------------------")
    
    test_positions = [(1, 1), (1, 2), (8, 8), (4, 5), (0, 0), (9, 9)]
    for (row, col) in test_positions
        println("Position ($row, $col):")
        println("  - Inside board: $(inside_board(row, col))")
        if inside_board(row, col)
            println("  - Square color: $(square_color(row, col))")
            println("  - Is dark square: $(is_dark_square(row, col))")
            println("  - Is valid position: $(is_valid_position(row, col))")
        end
    end
    
    # Test 3: Diagonal steps and distance calculations
    println("\n3. Diagonal Steps and Distance Calculations")
    println("------------------------------------------")
    
    test_moves = [
        ((1, 1), (3, 3)),  # Normal diagonal
        ((2, 2), (4, 4)),  # Another diagonal
        ((1, 1), (1, 3)),  # Not diagonal
        ((3, 1), (5, 3)),  # Diagonal with steps
    ]
    
    for ((from_row, from_col), (to_row, to_col)) in test_moves
        println("Move from ($from_row, $from_col) to ($to_row, $to_col):")
        println("  - Is diagonal: $(is_diagonal_move(from_row, from_col, to_row, to_col))")
        println("  - Manhattan distance: $(manhattan_distance(from_row, from_col, to_row, to_col))")
        println("  - Diagonal distance: $(diagonal_distance(from_row, from_col, to_row, to_col))")
        steps = diag_steps(from_row, from_col, to_row, to_col)
        println("  - Diagonal steps: $steps")
    end
    
    # Test 4: Piece identification and manipulation
    println("\n4. Piece Identification and Manipulation")
    println("----------------------------------------")
    
    test_pieces = [EMPTY_SQUARE, WHITE_MAN, WHITE_KING, BLACK_MAN, BLACK_KING]
    piece_names = ["Empty", "White Man", "White King", "Black Man", "Black King"]
    
    for (piece, name) in zip(test_pieces, piece_names)
        println("$name (value: $piece):")
        println("  - Is white: $(is_white_piece(piece))")
        println("  - Is black: $(is_black_piece(piece))")
        println("  - Is man: $(is_man_piece(piece))")
        println("  - Is king: $(is_king_piece(piece))")
        println("  - Owner: $(get_piece_owner(piece))")
        println("  - Promoted: $(promote_to_king(piece))")
    end
    
    # Test 5: Board piece counting
    println("\n5. Board Piece Counting")
    println("----------------------")
    
    white_pieces = count_pieces(initial_board, WHITE_PLAYER)
    black_pieces = count_pieces(initial_board, BLACK_PLAYER)
    white_kings = count_kings(initial_board, WHITE_PLAYER)
    black_kings = count_kings(initial_board, BLACK_PLAYER)
    
    println("White pieces: $white_pieces")
    println("Black pieces: $black_pieces")
    println("White kings: $white_kings")
    println("Black kings: $black_kings")
    
    # Test 6: Get all pieces positions
    println("\n6. Piece Positions")
    println("-----------------")
    
    white_positions = get_all_pieces(initial_board, WHITE_PLAYER)
    black_positions = get_all_pieces(initial_board, BLACK_PLAYER)
    
    println("White piece positions: $white_positions")
    println("Black piece positions: $black_positions")
    
    # Test 7: Adjacent and diagonal squares
    println("\n7. Adjacent and Diagonal Squares")
    println("-------------------------------")
    
    test_pos = (4, 4)  # Center of board
    adjacent = get_adjacent_squares(test_pos[1], test_pos[2])
    diagonal_2 = get_diagonal_squares(test_pos[1], test_pos[2], 2)
    
    println("From position $test_pos:")
    println("  - Adjacent squares: $adjacent")
    println("  - Diagonal squares at distance 2: $diagonal_2")
    
    # Test 8: Path checking
    println("\n8. Path Checking")
    println("---------------")
    
    # Create a board with a piece in the middle of a potential path
    test_board = create_empty_board()
    test_board = set_piece_at(test_board, 3, 3, WHITE_MAN)  # Piece in middle
    
    path_clear = clear_path(test_board, 1, 1, 5, 5)  # Path blocked by piece at (3,3)
    path_clear2 = clear_path(test_board, 1, 3, 3, 1)  # Different path
    
    println("Path from (1,1) to (5,5) clear: $path_clear")
    println("Path from (1,3) to (3,1) clear: $path_clear2")
    
    # Test 9: Promotion rules
    println("\n9. Promotion Rules")
    println("-----------------")
    
    promotion_tests = [
        (WHITE_MAN, 1),    # White man reaches row 1 - should promote
        (WHITE_MAN, 8),    # White man at row 8 - no promotion
        (BLACK_MAN, 8),    # Black man reaches row 8 - should promote
        (BLACK_MAN, 1),    # Black man at row 1 - no promotion
        (WHITE_KING, 1),   # King - no promotion needed
    ]
    
    for (piece, row) in promotion_tests
        should_promote_result = should_promote(piece, row)
        piece_name = piece == WHITE_MAN ? "White Man" : 
                    piece == BLACK_MAN ? "Black Man" : "White King"
        println("$piece_name at row $row should promote: $should_promote_result")
    end
    
    # Test 10: Forward direction
    println("\n10. Forward Direction")
    println("--------------------")
    
    white_forward = get_forward_direction(WHITE_PLAYER)
    black_forward = get_forward_direction(BLACK_PLAYER)
    
    println("White player forward direction (row increment): $white_forward")
    println("Black player forward direction (row increment): $black_forward")
    
    println("\nAll tests completed successfully!")
end

# Run the tests
if abspath(PROGRAM_FILE) == @__FILE__
    test_board_utilities()
end
