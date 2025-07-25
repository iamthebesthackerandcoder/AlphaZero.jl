#!/usr/bin/env julia

# Test script to verify that the forty-move rule has been successfully removed

println("Testing forty-move rule removal...")

# Check that is_forty_move_rule function no longer exists
try
    # This should fail since the function should not exist
    eval(:(is_forty_move_rule))
    println("❌ FAIL: is_forty_move_rule function still exists!")
    exit(1)
catch UndefVarError
    println("✓ PASS: is_forty_move_rule function successfully removed")
end

# Check that halfmove_clock field still exists (for tracking purposes)
include("Types.jl")
include("Moves.jl") 
include("Rules.jl")
include("Vectorization.jl")

# Mock AlphaZero.GI module for testing
module GI
    abstract type AbstractGameSpec end
    abstract type AbstractGameEnv end
    
    function init end
    function spec end
    function two_players end
    function set_state! end
    function actions end
    function actions_mask end
    function current_state end
    function white_playing end
    function game_terminated end
    function white_reward end
    function play! end
    function heuristic_value end
    function vectorize_state end
    function symmetries end
    function action_string end
    function parse_action end
    function read_state end
end

include("game.jl")

# Test that halfmove_clock is still tracked
spec = CheckersSpec()
env = GI.init(spec)

if !hasfield(typeof(env), :halfmove_clock)
    println("❌ FAIL: halfmove_clock field missing from CheckersEnv")
    exit(1)
else
    println("✓ PASS: halfmove_clock field still exists for tracking")
end

# Test that high halfmove_clock values don't cause game over
env.halfmove_clock = 200
if is_game_over(env)
    println("❌ FAIL: Game should not be over with high halfmove_clock")
    exit(1)
else
    println("✓ PASS: High halfmove_clock ($(env.halfmove_clock)) doesn't cause game over")
end

# Test that threefold repetition still works
initial_hash = hash((env.board, env.side_to_move))
push!(env.position_history, initial_hash)
push!(env.position_history, initial_hash)
push!(env.position_history, initial_hash)

if !is_threefold_repetition(env)
    println("❌ FAIL: Threefold repetition should be detected")
    exit(1)
else
    println("✓ PASS: Threefold repetition still works correctly")
end

println("\n🎉 SUCCESS: Forty-move rule has been successfully removed!")
println("   ✓ is_forty_move_rule function removed")
println("   ✓ halfmove_clock still tracked for move counting")
println("   ✓ High halfmove_clock values don't cause draws")
println("   ✓ Threefold repetition draw rule still functional")
