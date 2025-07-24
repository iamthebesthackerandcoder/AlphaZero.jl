import AlphaZero.GI
using DataStructures: CircularBuffer, push!, length
import Base: hash

# Game specification for AlphaZero
struct CheckersSpec <: GI.AbstractGameSpec
    # Board dimensions
    board_size::Int
    num_players::Int
    action_space_dim::Int
    
    # Default constructor with standard checkers parameters
    function CheckersSpec()
        new(BOARD_SIZE, 2, NUM_POSITIONS * NUM_POSITIONS)
    end
end

# Game environment
mutable struct CheckersEnv <: GI.AbstractGameEnv
    # Core game state
    board::SVector{32, Int8}  # 8×8 board encoded as Int8 in 32 dark squares
    side_to_move::Bool        # true = WHITE, false = BLACK
    
    # Game tracking
    repetition_hash::UInt64   # Hash for detecting repetitions
    move_stack::Vector{ReversibleMove}  # Stack of reversible moves played
    outcome::Union{Nothing, Int8}  # Nothing if game ongoing, 1 = white wins, -1 = black wins, 0 = draw
    
    # Cached values for efficiency
    finished::Bool
    actions_mask::Vector{Bool}
end

# Initialize game
function GI.init(::CheckersSpec)
    CheckersEnv(
        INITIAL_BOARD,
        WHITE,
        0x0000000000000000,  # Initial hash
        Vector{ReversibleMove}(),
        nothing,
        false,
        Vector{Bool}(undef, NUM_POSITIONS * NUM_POSITIONS)
    )
end

# Get game spec from environment
GI.spec(::CheckersEnv) = CheckersSpec()

# Two player game
GI.two_players(::CheckersSpec) = true

# Set state (for loading saved games or testing)
function GI.set_state!(g::CheckersEnv, state)
    g.board = state.board
    g.side_to_move = state.curplayer
end

#####
##### Game API Implementation
#####

# All possible actions (from-to combinations)
const ACTIONS = collect(1:(NUM_POSITIONS * NUM_POSITIONS))

GI.actions(::CheckersSpec) = ACTIONS

# Get mask of legal actions
function GI.actions_mask(g::CheckersEnv)
    return get_action_mask(g.board, g.side_to_move)
end

# Get current state
GI.current_state(g::CheckersEnv) = (board=g.board, curplayer=g.side_to_move)

# Check which player is currently playing
GI.white_playing(g::CheckersEnv) = g.side_to_move == WHITE

# Check if game is terminated
GI.game_terminated(g::CheckersEnv) = is_game_over(g.board, g.side_to_move)

# Get white player's reward
function GI.white_reward(g::CheckersEnv)
    if !GI.game_terminated(g)
        return 0.0
    end
    return get_white_reward(g.board, g.side_to_move)
end

# Apply a move in the environment
function apply!(env::CheckersEnv, move::Move)
    # Create a reversible move with all necessary information for undo
    reversible_move = create_reversible_move(env.board, move)
    
    # Store the reversible move on the stack for undo purposes
    push!(env.move_stack, reversible_move)

    # Update the board state with multi-captures and promotion
    env.board = apply_move(env.board, move)

    # Switch the side to move
    env.side_to_move = !env.side_to_move

    # Update repetition hash
    env.repetition_hash = hash((env.board, env.side_to_move))

    # Update game state to handle termination and action masking
    update_game_state!(env)
end

# Undo the last move for reversibility
function undo!(env::CheckersEnv)
    # Pop the last move from the stack
    move = pop!(env.move_stack)

    # Reverse the move
    env.board = revert_move(env.board, move)

    # Switch the side to move back
    env.side_to_move = !env.side_to_move

    # Update repetition hash and game state
    env.repetition_hash = hash((env.board, env.side_to_move))
    update_game_state!(env)
end

# Play a move
function GI.play!(g::CheckersEnv, action_idx::Int)
    # Convert action index to move
    move = action_index_to_move(action_idx)
    
    # Find the actual legal move with captures
    legal_moves = generate_all_moves(g.board, g.side_to_move)
    actual_move = nothing
    
    for legal_move in legal_moves
        if legal_move.from == move.from && legal_move.to == move.to
            actual_move = legal_move
            break
        end
    end
    
    if actual_move === nothing
        error("Invalid move: $(move.from) -> $(move.to)")
    end
    
    # Use the apply! function for consistency
    apply!(g, actual_move)
end

# Helper function to update game state after a move
function update_game_state!(g::CheckersEnv)
    # Update repetition hash
    g.repetition_hash = hash((g.board, g.side_to_move))
    
    # Check if game is finished
    if is_game_over(g.board, g.side_to_move)
        g.finished = true
        winner = determine_winner(g.board, g.side_to_move)
        if winner === nothing
            g.outcome = Int8(0)  # Draw
        elseif winner == WHITE
            g.outcome = Int8(1)  # White wins
        else
            g.outcome = Int8(-1)  # Black wins
        end
    else
        g.finished = false
        g.outcome = nothing
    end
    
    # Update actions mask
    g.actions_mask = get_action_mask(g.board, g.side_to_move)
end

#####
##### Heuristic for minimax
#####

function GI.heuristic_value(g::CheckersEnv)
    return heuristic_evaluation(g.board, g.side_to_move)
end

#####
##### Machine Learning API
#####

# Vectorize state for neural network
function GI.vectorize_state(::CheckersSpec, state)
    return vectorize_state(state)
end

#####
##### Symmetries (Checkers has 4-fold rotational symmetry)
#####

# Generate board symmetries for data augmentation
function generate_symmetries()
    # Checkers board has some symmetries, but they're complex due to the 
    # asymmetric nature of piece movement. For now, we'll implement
    # horizontal flip and vertical flip.
    
    symmetries = []
    
    # Identity (no transformation)
    identity_perm = collect(1:NUM_POSITIONS)
    push!(symmetries, identity_perm)
    
    # Horizontal flip
    h_flip = Int[]
    for pos in 1:NUM_POSITIONS
        row, col = pos_to_coords(pos)
        new_col = BOARD_SIZE - col + 1
        # Make sure it's still a dark square
        if (row + new_col) % 2 == 1
            new_pos = coords_to_pos(row, new_col)
            push!(h_flip, new_pos)
        else
            # This shouldn't happen with proper dark square mapping
            push!(h_flip, pos)
        end
    end
    push!(symmetries, h_flip)
    
    return symmetries
end

const SYMMETRIES = generate_symmetries()

function apply_symmetry_to_board(board::Board, symmetry::Vector{Int})
    new_board_array = Int8[]
    for i in 1:NUM_POSITIONS
        push!(new_board_array, board[symmetry[i]])
    end
    return Board(new_board_array)
end

function apply_symmetry_to_action(action_idx::Int, symmetry::Vector{Int})
    move = action_index_to_move(action_idx)
    
    # Map the from and to positions through the symmetry
    new_from = findfirst(==(move.from), symmetry)
    new_to = findfirst(==(move.to), symmetry)
    
    if new_from === nothing || new_to === nothing
        return action_idx  # Return original if mapping fails
    end
    
    new_move = Move(new_from, new_to)
    return move_to_action_index(new_move)
end

function GI.symmetries(::CheckersSpec, state)
    symmetries_result = []
    
    for sym in SYMMETRIES
        # Apply symmetry to board
        new_board = apply_symmetry_to_board(state.board, sym)
        new_state = (board=new_board, curplayer=state.curplayer)
        
        # Create action mapping function
        action_mapping = action_idx -> apply_symmetry_to_action(action_idx, sym)
        
        push!(symmetries_result, (new_state, action_mapping))
    end
    
    return symmetries_result
end

#####
##### Interaction API (for human play)
#####

function GI.action_string(::CheckersSpec, action_idx)
    move = action_index_to_move(action_idx)
    return "$(move.from)->$(move.to)"
end

function GI.parse_action(::CheckersSpec, str)
    # Parse strings like "12->8" or "12-8"
    parts = split(str, r"->|-")
    if length(parts) != 2
        return nothing
    end
    
    try
        from_pos = parse(Int, parts[1])
        to_pos = parse(Int, parts[2])
        
        if 1 <= from_pos <= NUM_POSITIONS && 1 <= to_pos <= NUM_POSITIONS
            move = Move(from_pos, to_pos)
            return move_to_action_index(move)
        end
    catch
        return nothing
    end
    
    return nothing
end

# Read board state from user input (for interactive play)
function GI.read_state(::CheckersSpec)
    println("Enter board state (32 characters, one for each dark square):")
    println("Use: '.' for empty, 'w' for white man, 'b' for black man, 'W' for white king, 'B' for black king")
    
    board_input = readline()
    if length(board_input) != NUM_POSITIONS
        error("Board input must be exactly $NUM_POSITIONS characters")
    end
    
    board_array = Int8[]
    for char in board_input
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
        else
            error("Invalid character '$char' in board input")
        end
    end
    
    board = Board(board_array)
    
    println("Who plays next? (w/b)")
    player_input = readline()
    current_player = (player_input == "w") ? WHITE : BLACK
    
    return (board=board, curplayer=current_player)
end
