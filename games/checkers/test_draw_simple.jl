#!/usr/bin/env julia

# Simple test for draw conditions without complex dependencies

include("Types.jl")
include("Moves.jl")
include("Rules.jl")
include("Vectorization.jl")

# Mock AlphaZero.GI module
module GI
    abstract type AbstractGameSpec end
    abstract type AbstractGameEnv end
    
    # Mock functions
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

# Forty-move rule test removed - the forty-move rule has been removed from the checkers implementation

function test_threefold_repetition()
    println("Testing threefold repetition...")
    
    # Initialize game
    spec = CheckersSpec()
    env = GI.init(spec)
    
    # Create a position hash
    test_hash = hash((env.board, env.side_to_move))
    
    # Add the same hash twice (not yet a draw)
    push!(env.position_history, test_hash)
    push!(env.position_history, test_hash)
    
    if is_threefold_repetition(env)
        error("Test failed: Should not be threefold repetition with 2 occurrences")
    end
    if is_game_over(env)
        error("Test failed: Game should not be over with 2 repetitions")
    end
    
    # Add the same hash a third time (now it's a draw)
    push!(env.position_history, test_hash)
    
    if !is_threefold_repetition(env)
        error("Test failed: Should be threefold repetition with 3 occurrences")
    end
    if !is_game_over(env)
        error("Test failed: Game should be over due to threefold repetition")
    end
    
    # Check that determine_winner returns draw
    outcome = determine_winner(env)
    if outcome != Int8(0)
        error("Test failed: Expected draw (0), got $outcome")
    end
    
    println("✓ Threefold repetition test passed!")
    return true
end

function test_halfmove_clock_updates()
    println("Testing halfmove clock updates...")
    
    # Initialize game
    spec = CheckersSpec()
    env = GI.init(spec)
    
    # Get a legal move
    legal_moves = generate_all_moves(env.board, env.side_to_move)
    if isempty(legal_moves)
        println("No legal moves available for testing")
        return false
    end
    
    # Find a non-capture move
    non_capture_move = nothing
    for move in legal_moves
        if isempty(move.captures)
            non_capture_move = move
            break
        end
    end
    
    if non_capture_move !== nothing
        initial_clock = env.halfmove_clock
        
        # Apply the move
        apply!(env, non_capture_move)
        
        # For a man move, the clock should reset to 0
        # For king-only moves without captures, it should increment
        piece = env.board[non_capture_move.to]  # The piece after the move
        if is_man(piece)
            if env.halfmove_clock != 0
                error("Test failed: Halfmove clock should be 0 after man move, got $(env.halfmove_clock)")
            end
        else
            # King move without capture should increment
            if env.halfmove_clock != initial_clock + 1
                error("Test failed: Halfmove clock should be $(initial_clock + 1) after king move, got $(env.halfmove_clock)")
            end
        end
        
        # Test undo
        undo!(env)
        if env.halfmove_clock != initial_clock
            error("Test failed: Halfmove clock should be restored to $initial_clock after undo, got $(env.halfmove_clock)")
        end
        
        println("✓ Halfmove clock update test passed!")
        return true
    else
        println("No suitable moves found for testing halfmove clock")
        return false
    end
end

function test_position_history_tracking()
    println("Testing position history tracking...")
    
    # Initialize game
    spec = CheckersSpec()
    env = GI.init(spec)
    
    initial_history_length = length(env.position_history)
    
    # Get a legal move
    legal_moves = generate_all_moves(env.board, env.side_to_move)
    if isempty(legal_moves)
        println("No legal moves available for testing")
        return false
    end
    
    move = legal_moves[1]
    
    # Apply the move
    apply!(env, move)
    
    # Position history should have one more entry
    if length(env.position_history) != initial_history_length + 1
        error("Test failed: Position history should have $(initial_history_length + 1) entries, got $(length(env.position_history))")
    end
    
    # Undo the move
    undo!(env)
    
    # Position history should be back to original length
    if length(env.position_history) != initial_history_length
        error("Test failed: Position history should be restored to $initial_history_length entries, got $(length(env.position_history))")
    end
    
    println("✓ Position history tracking test passed!")
    return true
end

function run_all_tests()
    println("Running draw condition tests...")
    
    tests = [
        test_threefold_repetition,
        test_halfmove_clock_updates,
        test_position_history_tracking
    ]
    
    passed = 0
    total = length(tests)
    
    for test_func in tests
        try
            if test_func()
                passed += 1
            end
        catch e
            println("Test $(test_func) failed with error: $e")
        end
    end
    
    println("\nTest Results: $passed/$total tests passed")
    
    if passed == total
        println("🎉 All draw condition tests passed!")
        return true
    else
        println("❌ Some tests failed")
        return false
    end
end

# Run tests if this file is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    run_all_tests()
end
