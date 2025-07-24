# State vectorization for neural network input

# Vectorize the board state for neural network input
# Returns a 3D array: 8x4x8 (board_rows x board_cols_compressed x channels)
# Channels: empty, white_man, black_man, white_king, black_king, 
#          white_to_move, black_to_move, can_capture
function vectorize_state(state::GameState)
    board, current_player = state.board, state.curplayer
    
    # We'll represent the board as 8x4 (8 rows, 4 columns for dark squares only)
    # with multiple channels for different piece types and game information
    rows, cols = BOARD_SIZE, 4
    channels = 8
    
    # Initialize the tensor
    tensor = zeros(Float32, rows, cols, channels)
    
    # Channel assignments:
    # 1: Empty squares
    # 2: White men
    # 3: Black men  
    # 4: White kings
    # 5: Black kings
    # 6: White to move (all 1s if white's turn, all 0s if black's turn)
    # 7: Black to move (opposite of channel 6)
    # 8: Squares with pieces that can capture (for current player)
    
    # Fill piece information
    for pos in 1:NUM_POSITIONS
        piece = board[pos]
        row, col = pos_to_coords(pos)
        
        # Convert column to compressed index (1-4)
        col_idx = (col + 1) ÷ 2
        
        # Set piece type channels
        if piece == EMPTY
            tensor[row, col_idx, 1] = 1.0
        elseif piece == WHITE_MAN
            tensor[row, col_idx, 2] = 1.0
        elseif piece == BLACK_MAN
            tensor[row, col_idx, 3] = 1.0
        elseif piece == WHITE_KING
            tensor[row, col_idx, 4] = 1.0
        elseif piece == BLACK_KING
            tensor[row, col_idx, 5] = 1.0
        end
    end
    
    # Fill turn information
    if current_player == WHITE
        tensor[:, :, 6] .= 1.0  # White to move
        tensor[:, :, 7] .= 0.0  # Black to move
    else
        tensor[:, :, 6] .= 0.0  # White to move
        tensor[:, :, 7] .= 1.0  # Black to move
    end
    
    # Fill capture information (squares with pieces that can capture)
    for pos in 1:NUM_POSITIONS
        piece = board[pos]
        if !is_empty(piece) && piece_owner(piece) == current_player
            captures = generate_capture_moves(board, pos)
            if !isempty(captures)
                row, col = pos_to_coords(pos)
                col_idx = (col + 1) ÷ 2
                tensor[row, col_idx, 8] = 1.0
            end
        end
    end
    
    return tensor
end

# Alternative simpler vectorization that flattens to 1D
function vectorize_state_flat(state::GameState)
    board, current_player = state.board, state.curplayer
    
    # Create a flat vector representation
    # 32 positions × 5 piece types + 1 current player = 161 features
    features = zeros(Float32, NUM_POSITIONS * 5 + 1)
    
    # Encode pieces (one-hot encoding)
    for pos in 1:NUM_POSITIONS
        piece = board[pos]
        base_idx = (pos - 1) * 5
        
        if piece == EMPTY
            features[base_idx + 1] = 1.0
        elseif piece == WHITE_MAN
            features[base_idx + 2] = 1.0
        elseif piece == BLACK_MAN
            features[base_idx + 3] = 1.0
        elseif piece == WHITE_KING
            features[base_idx + 4] = 1.0
        elseif piece == BLACK_KING
            features[base_idx + 5] = 1.0
        end
    end
    
    # Encode current player
    features[end] = current_player ? 1.0 : 0.0
    
    return features
end

# Convert move to action index for neural network output
# We need to map from Move objects to integers for the neural network
function move_to_action_index(move::Move)
    # Simple encoding: from_pos * 32 + to_pos
    # This gives us a range of 1 to 32*32 = 1024 possible actions
    # Most will be invalid, but this is a simple encoding scheme
    return (move.from - 1) * NUM_POSITIONS + move.to
end

# Convert action index back to move (for neural network output interpretation)
function action_index_to_move(action_idx::Int)
    action_idx -= 1  # Convert to 0-based
    from_pos = action_idx ÷ NUM_POSITIONS + 1
    to_pos = action_idx % NUM_POSITIONS + 1
    return Move(from_pos, to_pos)  # Captures will need to be inferred from board state
end

# Get all possible action indices (for masking invalid actions)
function get_action_mask(board::Board, player::Player)
    legal_moves = generate_all_moves(board, player)
    mask = zeros(Bool, NUM_POSITIONS * NUM_POSITIONS)
    
    for move in legal_moves
        action_idx = move_to_action_index(move)
        mask[action_idx] = true
    end
    
    return mask
end

# Alternative: encode moves more efficiently by considering only valid board transitions
function efficient_move_encoding(board::Board, player::Player)
    legal_moves = generate_all_moves(board, player)
    
    # Create a mapping from moves to indices
    move_to_idx = Dict{Move, Int}()
    idx_to_move = Dict{Int, Move}()
    
    for (i, move) in enumerate(legal_moves)
        move_to_idx[move] = i
        idx_to_move[i] = move
    end
    
    return move_to_idx, idx_to_move, length(legal_moves)
end
