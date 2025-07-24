# Game rules and win conditions for Checkers

# Count pieces for each player
function count_pieces(board::Board, player::Player)
    count = 0
    for pos in 1:NUM_POSITIONS
        piece = board[pos]
        if !is_empty(piece) && piece_owner(piece) == player
            count += 1
        end
    end
    return count
end

# Count kings for each player
function count_kings(board::Board, player::Player)
    count = 0
    for pos in 1:NUM_POSITIONS
        piece = board[pos]
        if is_king(piece) && piece_owner(piece) == player
            count += 1
        end
    end
    return count
end

# Check if a player has any pieces left
function has_pieces(board::Board, player::Player)
    return count_pieces(board, player) > 0
end

# Check if a player has any legal moves
function has_legal_moves(board::Board, player::Player)
    return !isempty(generate_all_moves(board, player))
end

# Determine the winner of the game
function determine_winner(board::Board, current_player::Player)
    # A player loses if they have no pieces or no legal moves
    if !has_pieces(board, current_player) || !has_legal_moves(board, current_player)
        return !current_player  # The other player wins
    end
    
    opponent = !current_player
    if !has_pieces(board, opponent) || !has_legal_moves(board, opponent)
        return current_player
    end
    
    return nothing  # Game not over
end

# Check if the game is over
function is_game_over(board::Board, current_player::Player)
    return !isnothing(determine_winner(board, current_player))
end

# Get the reward for the white player (1.0 if white wins, -1.0 if black wins, 0.0 for draw)
function get_white_reward(board::Board, current_player::Player)
    winner = determine_winner(board, current_player)
    if winner === nothing
        return 0.0  # Game not over or draw
    elseif winner == WHITE
        return 1.0
    else
        return -1.0
    end
end

# Simple heuristic evaluation function for the current player
function heuristic_evaluation(board::Board, player::Player)
    if is_game_over(board, player)
        winner = determine_winner(board, player)
        if winner == player
            return 1000.0  # Win
        else
            return -1000.0  # Loss
        end
    end
    
    # Material count with king bonus
    my_men = 0
    my_kings = 0
    opp_men = 0
    opp_kings = 0
    
    for pos in 1:NUM_POSITIONS
        piece = board[pos]
        if !is_empty(piece)
            owner = piece_owner(piece)
            if owner == player
                if is_king(piece)
                    my_kings += 1
                else
                    my_men += 1
                end
            else
                if is_king(piece)
                    opp_kings += 1
                else
                    opp_men += 1
                end
            end
        end
    end
    
    # Simple evaluation: men worth 1, kings worth 3
    my_score = my_men + 3 * my_kings
    opp_score = opp_men + 3 * opp_kings
    
    # Add positional bonuses
    position_bonus = 0.0
    for pos in 1:NUM_POSITIONS
        piece = board[pos]
        if !is_empty(piece) && piece_owner(piece) == player
            row, _ = pos_to_coords(pos)
            if is_man(piece)
                # Bonus for advanced men
                if player == WHITE
                    position_bonus += (BOARD_SIZE - row) * 0.1
                else
                    position_bonus += (row - 1) * 0.1
                end
            end
            
            # Bonus for center control
            if 3 <= row <= 6
                position_bonus += 0.2
            end
        end
    end
    
    return (my_score - opp_score) + position_bonus
end

# Check for draw conditions (simplified - could be extended)
function is_draw(board::Board, move_history::Vector{Board}=Board[])
    # Simple repetition check - if the same position appears multiple times
    if length(move_history) >= 6
        recent_positions = move_history[end-5:end]
        if sum(b == board for b in recent_positions) >= 3
            return true
        end
    end
    
    # Material draw - only kings left with low piece count
    white_kings = count_kings(board, WHITE)
    black_kings = count_kings(board, BLACK)
    total_pieces = count_pieces(board, WHITE) + count_pieces(board, BLACK)
    
    if total_pieces <= 4 && white_kings > 0 && black_kings > 0
        # This is a simplified draw condition
        # In real checkers, there are more complex draw rules
        return false  # For now, let the game continue
    end
    
    return false
end

# Validate that a board state is legal
function is_valid_board_state(board::Board)
    white_count = count_pieces(board, WHITE)
    black_count = count_pieces(board, BLACK)
    
    # Basic sanity checks
    if white_count > 12 || black_count > 12
        return false
    end
    
    # Check that pieces are only on dark squares (implicit in our representation)
    # and that the piece types are valid
    for pos in 1:NUM_POSITIONS
        piece = board[pos]
        if !(piece in instances(PieceType))
            return false
        end
    end
    
    return true
end
