# Test draw conditions for checkers game

include("Types.jl")
include("Moves.jl")
include("Rules.jl")
include("Vectorization.jl")

# Simple test macro since we can't import Test
macro test(expr)
    quote
        if !($expr)
            error("Test failed: $($expr)")
        end
    end
end

# Mock the GI module for testing
module GI
    abstract type AbstractGameSpec end
    abstract type AbstractGameEnv end

    function init end
    function game_terminated end
    function white_reward end
    function white_playing end
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
    
    @test !is_threefold_repetition(env)
    @test !is_game_over(env)
    
    # Add the same hash a third time (now it's a draw)
    push!(env.position_history, test_hash)
    
    @test is_threefold_repetition(env)
    @test is_game_over(env)
    
    # Check that determine_winner returns draw
    outcome = determine_winner(env)
    @test outcome == Int8(0)  # Draw
    
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
    
    # Find a non-capture move (man move)
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
        piece = env.board[non_capture_move.to]  # The piece after the move
        if is_man(piece) || !isempty(non_capture_move.captures)
            @test env.halfmove_clock == 0
        else
            # For king-only moves without captures, it should increment
            @test env.halfmove_clock == initial_clock + 1
        end
        
        # Test undo
        undo!(env)
        @test env.halfmove_clock == initial_clock
        
        println("✓ Halfmove clock update test passed!")
        return true
    else
        println("No suitable moves found for testing halfmove clock")
        return false
    end
end

function test_halfmove_clock_king_increment()
    # Custom board with isolated kings
    custom_board = SVector{32, Int8}(fill(EMPTY, 32))
    # Place white king at position 13 (adjust as needed for legal move)
    custom_board = setindex(custom_board, WHITE_KING, 13)
    # Place black king far away
    custom_board = setindex(custom_board, BLACK_KING, 30)
    env = CheckersEnv(custom_board, WHITE, hash((custom_board, WHITE)), Vector{ReversibleMove}(), Vector{UInt64}(), 0, nothing, false, fill(false, NUM_POSITIONS * NUM_POSITIONS))
    initial_clock = env.halfmove_clock
    legal_moves = generate_all_moves(env.board, env.side_to_move)
    # Find a non-capture king move
    king_move = nothing
    for move in legal_moves
        if isempty(move.captures) && is_king(env.board[move.from])
            king_move = move
            break
        end
    end
    @test king_move !== nothing
    apply!(env, king_move)
    @test env.halfmove_clock == initial_clock + 1
    undo!(env)
    @test env.halfmove_clock == initial_clock
    return true
end

function test_halfmove_clock_man_reset()
    # Custom board with isolated kings and a man
    custom_board = SVector{32, Int8}(fill(EMPTY, 32))
    # Place white king at position 13 (adjust as needed for legal move)
    custom_board = setindex(custom_board, WHITE_KING, 13)
    # Place black king far away
    custom_board = setindex(custom_board, BLACK_KING, 30)
    # Place a white man at position 14
    custom_board = setindex(custom_board, WHITE_MAN, 14)
    env = CheckersEnv(custom_board, WHITE, hash((custom_board, WHITE)), Vector{ReversibleMove}(), Vector{UInt64}(), 0, nothing, false, fill(false, NUM_POSITIONS * NUM_POSITIONS))
    initial_clock = env.halfmove_clock
    legal_moves = generate_all_moves(env.board, env.side_to_move)
    # Find a non-capture man move
    man_move = nothing
    for move in legal_moves
        if isempty(move.captures) && is_man(env.board[move.from])
            man_move = move
            break
        end
    end
    @test man_move !== nothing
    apply!(env, man_move)
    @test env.halfmove_clock == 0
    undo!(env)
    @test env.halfmove_clock == initial_clock
    return true
end

function test_halfmove_clock_capture_reset()
    # Custom board with isolated kings and a capture
    custom_board = SVector{32, Int8}(fill(EMPTY, 32))
    # Place white king at position 13 (adjust as needed for legal move)
    custom_board = setindex(custom_board, WHITE_KING, 13)
    # Place black king far away
    custom_board = setindex(custom_board, BLACK_KING, 30)
    # Place a white man at position 14
    custom_board = setindex(custom_board, WHITE_MAN, 14)
    # Place a black man at position 25
    custom_board = setindex(custom_board, BLACK_MAN, 25)
    env = CheckersEnv(custom_board, WHITE, hash((custom_board, WHITE)), Vector{ReversibleMove}(), Vector{UInt64}(), 0, nothing, false, fill(false, NUM_POSITIONS * NUM_POSITIONS))
    initial_clock = env.halfmove_clock
    legal_moves = generate_all_moves(env.board, env.side_to_move)
    # Find a capture move
    capture_move = nothing
    for move in legal_moves
        if !isempty(move.captures)
            capture_move = move
            break
        end
    end
    @test capture_move !== nothing
    apply!(env, capture_move)
    @test env.halfmove_clock == 0
    undo!(env)
    @test env.halfmove_clock == initial_clock
    return true
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
    @test length(env.position_history) == initial_history_length + 1
    
    # Undo the move
    undo!(env)
    
    # Position history should be back to original length
    @test length(env.position_history) == initial_history_length
    
    println("✓ Position history tracking test passed!")
    return true
end

function test_threefold_repetition_sequence()
    println("Testing threefold repetition sequence...")
    spec = CheckersSpec()
    env = GI.init(spec)

    # Set up a position that will repeat
    initial_board = env.board
    initial_side = env.side_to_move
    initial_hash = hash((initial_board, initial_side))

    # Apply a sequence of moves that will result in a threefold repetition
    # This sequence should be long enough to ensure a repetition
    # For simplicity, let's assume a sequence of 30 moves, including captures
    # and some kings becoming kings.
    for i in 1:30
        legal_moves = generate_all_moves(env.board, env.side_to_move)
        if isempty(legal_moves)
            println("No legal moves available for sequence move $i")
            return false
        end
        move = legal_moves[1] # Take the first legal move
        apply!(env, move)
        # Add a small delay to ensure different hashes for repeated positions
        sleep(0.001)
    end

    # Check if the position history has repeated
    @test is_threefold_repetition(env)
    @test is_game_over(env)
    @test GI.game_terminated(env)

    # Check that determine_winner returns draw
    outcome = determine_winner(env)
    @test outcome == Int8(0)  # Draw

    println("✓ Threefold repetition sequence test passed!")
    return true
end

# Forty-move rule sequence test removed - the forty-move rule has been removed from the checkers implementation

function run_all_tests()
    println("Running draw condition tests...")
    
    tests = [
        test_threefold_repetition,
        test_halfmove_clock_updates,
        test_position_history_tracking,
        test_halfmove_clock_king_increment,
        test_halfmove_clock_man_reset,
        test_halfmove_clock_capture_reset,
        test_threefold_repetition_sequence
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
