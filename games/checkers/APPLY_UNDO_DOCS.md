# State Update and Undo Implementation

This document describes the implementation of the `apply!(env, move)` and `undo!(env)` functions for the checkers game environment, as required for MCTS playout reversibility.

## Overview

The implementation provides two main functions:

1. **`apply!(env::CheckersEnv, move::Move)`** - Applies a move to the game environment
2. **`undo!(env::CheckersEnv)`** - Reverses the last applied move

## Key Features

### `apply!(env, move)`

This function mutates the board state and handles:

- **Multi-captures**: Properly processes moves that capture multiple pieces in sequence
- **Promotion on back rank**: Automatically promotes men to kings when they reach the opposite end
- **Side switching**: Changes the active player after each move
- **Repetition hash updates**: Maintains a hash for detecting repetitions
- **Move stack management**: Stores reversible move information for undo functionality

### `undo!(env)`

This function provides perfect reversibility by:

- **Popping the move stack**: Retrieves the last applied move with full state information
- **Board state reversal**: Restores the exact previous board position
- **Capture restoration**: Puts back all captured pieces in their original positions
- **Promotion reversal**: Demotes kings back to men if they were promoted in the undone move
- **Side switching**: Returns the turn to the previous player
- **Hash updates**: Restores the previous repetition hash

## Implementation Details

### ReversibleMove Structure

The implementation uses a `ReversibleMove` struct that stores complete information needed for perfect undo:

```julia
struct ReversibleMove
    from::Int                    # Source position (1-32)
    to::Int                      # Destination position (1-32)
    captures::Vector{Int}        # Positions of captured pieces
    captured_pieces::Vector{Int8} # The actual captured pieces
    was_promoted::Bool           # Whether this move resulted in a promotion
    original_piece::Int8         # The original piece before promotion
end
```

### Key Functions

1. **`create_reversible_move(board, move)`** - Creates a reversible move with all necessary undo information
2. **`revert_move(board, reversible_move)`** - Reverses a move using stored information
3. **`apply_move(board, move)`** - Applies a move to the board (existing function)

### Environment Modifications

The `CheckersEnv` structure was modified to use:
- `move_stack::Vector{ReversibleMove}` instead of `Vector{Move}`
- This ensures perfect reversibility for MCTS playouts

## Usage Example

```julia
# Initialize game
spec = CheckersSpec()
env = GI.init(spec)

# Get a legal move
legal_moves = generate_all_moves(env.board, env.side_to_move)
move = legal_moves[1]

# Apply the move
apply!(env, move)

# The environment state is now updated:
# - Board reflects the move
# - Side to move is switched
# - Move is stored on the stack
# - Repetition hash is updated

# Undo the move
undo!(env)

# The environment is back to the exact previous state
```

## Testing

The implementation includes comprehensive tests that verify:

1. **Basic functionality**: Single move apply and undo
2. **Multiple moves**: Sequence of moves and their reversal
3. **State preservation**: Exact restoration of board, player turn, and hash
4. **Stack management**: Proper push/pop behavior

All tests pass successfully, confirming that the implementation provides perfect reversibility required for MCTS.

## Integration with AlphaZero

The functions integrate seamlessly with the AlphaZero framework:

- `apply!` can be used during MCTS tree exploration
- `undo!` allows backing out of explored paths
- The move stack enables efficient game tree traversal
- Perfect reversibility ensures no state corruption during search

This implementation fulfills the Step 5 requirement: "State update and undo - `apply!(env, move)` mutates board, handles multi-captures, promotion on back rank, switches side, updates repetition hash. `undo!(env)` pops move_stack for MCTS playout reversibility."
