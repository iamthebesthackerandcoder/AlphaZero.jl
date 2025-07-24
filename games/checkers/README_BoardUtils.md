# Checkers Board Representation & Helper Utilities

This module provides an 8×8 matrix board representation for checkers along with comprehensive helper utilities.

## Board Representation

The board uses an 8×8 matrix with `Int8` values representing different piece types:

- `0`: Empty square
- `1`: White man  
- `2`: White king
- `-1`: Black man
- `-2`: Black king

Only dark squares are used for checkers gameplay, as is standard for the game.

## Key Features

### Board Creation
- `create_empty_board()`: Creates an empty 8×8 board
- `create_initial_board()`: Creates standard checkers starting position

### Position Utilities
- `square_color(row, col)`: Returns `:dark` or `:light` for square color
- `inside_board(row, col)`: Check if coordinates are within board bounds
- `is_dark_square(row, col)`: Check if square is dark (valid for checkers)  
- `is_valid_position(row, col)`: Check if position is both inside board and on dark square

### Movement & Distance
- `diag_steps(from_row, from_col, to_row, to_col)`: Get intermediate diagonal squares
- `is_diagonal_move(...)`: Check if move is diagonal
- `manhattan_distance(...)`: Calculate Manhattan distance
- `diagonal_distance(...)`: Calculate diagonal distance (-1 if not diagonal)
- `clear_path(board, ...)`: Check if diagonal path is clear of pieces

### Piece Operations
- `get_piece_at(board, row, col)`: Get piece at position
- `set_piece_at(board, row, col, piece)`: Set piece (returns new board)
- `is_empty_square(board, row, col)`: Check if square is empty

### Piece Identification
- `is_white_piece(piece)`: Check if piece belongs to white
- `is_black_piece(piece)`: Check if piece belongs to black  
- `is_man_piece(piece)`: Check if piece is a man (not king)
- `is_king_piece(piece)`: Check if piece is a king
- `get_piece_owner(piece)`: Get player who owns piece

### Game Logic Support
- `promote_to_king(piece)`: Promote man to king
- `should_promote(piece, row)`: Check if piece should be promoted at row
- `get_forward_direction(player)`: Get forward movement direction for player
- `count_pieces(board, player)`: Count pieces for player
- `count_kings(board, player)`: Count kings for player
- `get_all_pieces(board, player)`: Get positions of all pieces for player

### Board Display
- `board_to_string(board)`: Convert board to readable string representation

### Movement Support
- `get_adjacent_squares(row, col)`: Get adjacent diagonal squares
- `get_diagonal_squares(row, col, distance)`: Get diagonal squares at specific distance

## Usage Example

```julia
include("BoardUtils.jl")

# Create initial board
board = create_initial_board()
println(board_to_string(board))

# Check piece at position
piece = get_piece_at(board, 1, 2)  # Should be black man
println("Piece at (1,2): $piece")

# Move piece (example)
new_board = set_piece_at(board, 4, 3, piece)  # Move to new position
new_board = set_piece_at(new_board, 1, 2, EMPTY_SQUARE)  # Clear old position

# Count pieces
white_count = count_pieces(board, WHITE_PLAYER)
black_count = count_pieces(board, BLACK_PLAYER)
```

## Constants

- `BOARD_DIM = 8`: Board dimensions
- `WHITE_PLAYER = 1`, `BLACK_PLAYER = -1`: Player identifiers
- Piece constants: `EMPTY_SQUARE`, `WHITE_MAN`, `WHITE_KING`, `BLACK_MAN`, `BLACK_KING`

## Testing

Run `julia test_board_utils.jl` to execute comprehensive tests of all functionality.
