#!/usr/bin/env julia

# Simple test script for Checkers implementation
# Run this to verify the basic functionality works

using Pkg

# Make sure we're in the right directory
if !isfile("Project.toml")
    error("Please run this script from the AlphaZero.jl root directory")
end

# Activate the project
Pkg.activate(".")

# Load required packages
using AlphaZero
import AlphaZero.GI
import AlphaZero.Examples

println("🔧 Testing Checkers implementation...")
println("=" ^ 50)

try
    # Test 1: Load the game
    println("1. Loading Checkers game...")
    game_spec = Examples.games["checkers"]
    println("   ✓ Game loaded successfully")
    
    # Test 2: Initialize environment
    println("2. Initializing game environment...")
    env = GI.init(game_spec)
    println("   ✓ Environment initialized")
    
    # Test 3: Check basic properties
    println("3. Checking game properties...")
    @assert GI.two_players(game_spec) "Should be a two-player game"
    @assert GI.white_playing(env) "White should play first"
    @assert !GI.game_terminated(env) "Game should not be terminated initially"
    println("   ✓ Basic properties correct")
    
    # Test 4: Generate legal moves
    println("4. Testing move generation...")
    mask = GI.actions_mask(env)
    legal_actions = findall(mask)
    println("   ✓ Found $(length(legal_actions)) legal actions")
    @assert length(legal_actions) > 0 "Should have legal moves initially"
    
    # Test 5: Test vectorization
    println("5. Testing state vectorization...")
    state = GI.current_state(env)
    vector = GI.vectorize_state(game_spec, state)
    println("   ✓ State vectorized to size $(size(vector))")
    @assert size(vector) == (8, 4, 8) "Vector should be 8x4x8"
    
    # Test 6: Play a few moves
    println("6. Testing game play...")
    for i in 1:3
        if GI.game_terminated(env)
            break
        end
        
        mask = GI.actions_mask(env)
        legal_actions = findall(mask)
        
        if !isempty(legal_actions)
            # Pick a random legal action
            action = rand(legal_actions)
            GI.play!(env, action)
            println("   ✓ Played move $i")
        end
    end
    
    # Test 7: Check training parameters
    println("7. Testing training configuration...")
    experiment = Examples.experiments["checkers"]
    println("   ✓ Training experiment loaded")
    println("   - Experiment name: $(experiment.name)")
    println("   - CPU optimized: $(experiment.params.learning.use_gpu ? "No" : "Yes")")
    
    println()
    println("🎉 All tests passed! Checkers implementation is working correctly.")
    println()
    println("💡 Next steps:")
    println("   - Run training: AlphaZero.train!(Examples.experiments[\"checkers\"])")
    println("   - Play interactively: AlphaZero.interactive!(Examples.games[\"checkers\"])")
    println("   - Run unit tests: include(\"games/checkers/tests/basic_tests.jl\")")
    
catch e
    println("❌ Error during testing:")
    println(e)
    if isa(e, LoadError)
        println("\n📋 Troubleshooting:")
        println("   - Make sure you're in the AlphaZero.jl directory")
        println("   - Try: using Pkg; Pkg.instantiate()")
        println("   - Check that all files were created correctly")
    end
    rethrow(e)
end
