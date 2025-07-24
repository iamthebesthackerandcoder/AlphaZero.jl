# Simple test for CheckersSpec and CheckersEnv types
include("Types.jl")
include("game.jl")

# Test CheckersSpec creation
println("Testing CheckersSpec creation...")
spec = CheckersSpec()
println("CheckersSpec created successfully:")
println("  Board size: $(spec.board_size)")
println("  Number of players: $(spec.num_players)")
println("  Action space dimension: $(spec.action_space_dim)")

# Test CheckersEnv initialization
println("\nTesting CheckersEnv initialization...")
import AlphaZero.GI as GI
env = GI.init(spec)
println("CheckersEnv initialized successfully:")
println("  Board type: $(typeof(env.board))")
println("  Side to move: $(env.side_to_move)")
println("  Finished: $(env.finished)")
println("  Outcome: $(env.outcome)")

# Test basic game interface functions
println("\nTesting basic GameInterface functions...")
println("  Two players: $(GI.two_players(spec))")
println("  White playing: $(GI.white_playing(env))")
println("  Game terminated: $(GI.game_terminated(env))")
println("  Current state type: $(typeof(GI.current_state(env)))")
println("  Actions length: $(length(GI.actions(spec)))")

println("\nAll basic tests passed!")
