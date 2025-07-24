# Checkers (American Draughts)

This directory contains a complete implementation of American Checkers (English Draughts) for the AlphaZero.jl framework, optimized for CPU training.

## Game Rules

- 8x8 board with pieces on dark squares only (32 playable squares)
- Each player starts with 12 men
- Men move diagonally forward only
- Kings can move diagonally in any direction
- Captures are mandatory when available
- Multiple jumps are allowed and required
- Men promote to kings when reaching the opposite end

## Files

- **main.jl**: Main module file that includes all components
- **Types.jl**: Core data structures and types
- **Moves.jl**: Move generation and validation logic
- **Rules.jl**: Game rules, win conditions, and evaluation
- **Vectorization.jl**: State representation for neural networks
- **Render.jl**: Board visualization and rendering
- **game.jl**: AlphaZero.jl interface implementation
- **params.jl**: Training parameters optimized for CPU
- **Config.toml**: Configuration settings
- **tests/**: Basic functionality tests

## CPU Optimization

This implementation is specifically optimized for CPU training:

- Reduced network size (64 filters, 4 blocks)
- Smaller batch sizes (32)
- Fewer MCTS iterations (200 for training, 100 for evaluation)
- Efficient state representation using StaticArrays
- Action masking to reduce invalid move exploration

## Usage

### Quick Start

```julia
using AlphaZero
import AlphaZero.Examples

# Load the checkers game
game_spec = Examples.games["checkers"]
env = GI.init(game_spec)

# Play a game interactively
AlphaZero.interactive!(game_spec)
```

### Training

```julia
# Start training with CPU-optimized parameters
experiment = Examples.experiments["checkers"]
AlphaZero.train!(experiment)
```

### Testing

```julia
# Run basic tests
include("games/checkers/tests/basic_tests.jl")
```

## Board Representation

The game uses a compressed 32-square representation:
- Positions 1-32 correspond to dark squares only
- Row-major order from top-left (position 1) to bottom-right (position 32)
- State vectorization creates 8x4x8 tensor for neural network input

## State Channels

The neural network input has 8 channels:
1. Empty squares
2. White men
3. Black men
4. White kings
5. Black kings
6. White to move indicator
7. Black to move indicator
8. Pieces that can capture

## Performance Notes

- Expected training time on Intel Ultra 7: 2-4 hours for basic convergence
- Memory usage: ~2GB during training
- Game length: Typically 40-80 moves
- Action space: 1024 possible from-to combinations (most invalid)

## Customization

Modify `Config.toml` to adjust:
- Piece values for heuristic evaluation
- Display preferences
- Performance settings

Modify `params.jl` to adjust:
- Network architecture
- MCTS parameters
- Training schedule
- Batch sizes

## Known Limitations

- Simplified symmetry handling (only horizontal flip implemented)
- Basic draw detection (could be enhanced with official rules)
- Action encoding uses full 32x32 space (could be compressed)
- No endgame tablebase integration

## Future Enhancements

- More sophisticated symmetries
- Better draw detection
- Compressed action representation
- Opening book integration
- Endgame tablebase support
- Multi-threaded MCTS for CPU optimization
