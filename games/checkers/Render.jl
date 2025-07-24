# Board rendering and visualization for Checkers

using Crayons

# ANSI color codes for better visualization
const RESET = "\033[0m"
const BOLD = "\033[1m"
const RED = "\033[31m"
const BLUE = "\033[34m"
const YELLOW = "\033[33m"
const GREEN = "\033[32m"
const BG_LIGHT = "\033[47m"  # Light background
const BG_DARK = "\033[40m"   # Dark background

# Character representations for pieces
const PIECE_CHARS = Dict(
    EMPTY => " ",
    WHITE_MAN => "○",
    BLACK_MAN => "●", 
    WHITE_KING => "♔",
    BLACK_KING => "♕"
)

# Color representations for pieces
const PIECE_COLORS = Dict(
    EMPTY => "",
    WHITE_MAN => RED,
    BLACK_MAN => BLUE,
    WHITE_KING => RED * BOLD,
    BLACK_KING => BLUE * BOLD
)

# Render the board in ASCII format
function render_board(board::Board; show_coords=true, highlight_moves=Move[])
    println()
    
    if show_coords
        print("   ")
        for c in 1:BOARD_SIZE
            print(" $c ")
        end
        println()
    end
    
    # Convert highlighted moves to position sets for easy lookup
    highlight_from = Set(move.from for move in highlight_moves)
    highlight_to = Set(move.to for move in highlight_moves)
    
    for row in 1:BOARD_SIZE
        if show_coords
            print("$row  ")
        end
        
        for col in 1:BOARD_SIZE
            # Determine if this is a dark square (where pieces can be)
            is_dark = (row + col) % 2 == 1
            
            if is_dark
                # This is a playable square
                pos = coords_to_pos(row, col)
                piece = board[pos]
                
                # Choose background color
                bg_color = BG_DARK
                
                # Choose piece character and color
                char = PIECE_CHARS[piece]
                color = PIECE_COLORS[piece]
                
                # Highlight special squares
                if pos in highlight_from
                    bg_color = "\033[43m"  # Yellow background for source
                elseif pos in highlight_to
                    bg_color = "\033[42m"  # Green background for destination
                end
                
                print(bg_color * color * " $char " * RESET)
            else
                # Light square (not playable)
                print(BG_LIGHT * "   " * RESET)
            end
        end
        
        println()
    end
    println()
end

# Render game state with additional information
function render_game_state(state::GameState; show_moves=false)
    board, current_player = state.board, state.curplayer
    
    println("=" ^ 40)
    println("CHECKERS GAME")
    println("=" ^ 40)
    
    player_name = current_player == WHITE ? "White (○/♔)" : "Black (●/♕)"
    println("Current player: $player_name")
    
    # Show piece counts
    white_men = count(p -> p == WHITE_MAN, board)
    white_kings = count(p -> p == WHITE_KING, board)
    black_men = count(p -> p == BLACK_MAN, board)
    black_kings = count(p -> p == BLACK_KING, board)
    
    println("White: $white_men men, $white_kings kings")
    println("Black: $black_men men, $black_kings kings")
    
    if show_moves
        legal_moves = generate_all_moves(board, current_player)
        println("Legal moves: $(length(legal_moves))")
        render_board(board, highlight_moves=legal_moves)
    else
        render_board(board)
    end
    
    # Check game status
    if is_game_over(board, current_player)
        winner = determine_winner(board, current_player)
        winner_name = winner == WHITE ? "White" : "Black"
        println("🏆 Game Over! Winner: $winner_name")
    end
end

# Simple text representation for debugging
function board_to_string(board::Board)
    result = ""
    for row in 1:BOARD_SIZE
        for col in 1:BOARD_SIZE
            if (row + col) % 2 == 1  # Dark square
                pos = coords_to_pos(row, col)
                piece = board[pos]
                result *= PIECE_CHARS[piece]
            else
                result *= "."  # Light square
            end
        end
        result *= "\n"
    end
    return result
end

# Export board state to FEN-like notation (simplified)
function board_to_fen(state::GameState)
    board, current_player = state.board, state.curplayer
    
    # Create a simplified FEN-like string
    # Format: board_representation current_player
    board_str = ""
    
    for pos in 1:NUM_POSITIONS
        piece = board[pos]
        if piece == EMPTY
            board_str *= "."
        elseif piece == WHITE_MAN
            board_str *= "w"
        elseif piece == BLACK_MAN
            board_str *= "b"
        elseif piece == WHITE_KING
            board_str *= "W"
        elseif piece == BLACK_KING
            board_str *= "B"
        end
    end
    
    player_str = current_player == WHITE ? "w" : "b"
    
    return "$board_str $player_str"
end

# Parse FEN-like notation back to game state
function fen_to_board(fen_string::String)
    parts = split(fen_string, " ")
    board_str = parts[1]
    player_str = parts[2]
    
    # Parse board
    board_array = PieceType[]
    for char in board_str
        if char == '.'
            push!(board_array, EMPTY)
        elseif char == 'w'
            push!(board_array, WHITE_MAN)
        elseif char == 'b'
            push!(board_array, BLACK_MAN)
        elseif char == 'W'
            push!(board_array, WHITE_KING)
        elseif char == 'B'
            push!(board_array, BLACK_KING)
        end
    end
    
    board = Board(board_array)
    current_player = player_str == "w" ? WHITE : BLACK
    
    return GameState((board, current_player))
end

# Render a specific move
function render_move(move::Move)
    from_row, from_col = pos_to_coords(move.from)
    to_row, to_col = pos_to_coords(move.to)
    
    move_str = "$(from_row)$from_col -> $(to_row)$to_col"
    
    if !isempty(move.captures)
        captures_str = join(["$(pos_to_coords(pos)[1])$(pos_to_coords(pos)[2])" 
                           for pos in move.captures], ", ")
        move_str *= " (captures: $captures_str)"
    end
    
    return move_str
end

# Interactive board display with move input
function interactive_display(state::GameState)
    while true
        render_game_state(state, show_moves=true)
        
        if is_game_over(state.board, state.curplayer)
            break
        end
        
        println("Enter move (e.g., '6a 5b') or 'quit':")
        input = readline()
        
        if lowercase(input) == "quit"
            break
        end
        
        # Parse move input (simplified - would need proper implementation)
        # This is a placeholder for interactive play
        println("Move parsing not implemented in this skeleton")
        break
    end
end
