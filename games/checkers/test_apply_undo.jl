#!/usr/bin/env julia

# Test file for apply! and undo! functions

# Load all necessary modules
include("Types.jl")
include("Moves.jl")
include("Rules.jl")
include("Vectorization.jl")
include("game.jl")

using Test

# Test basic apply! and undo! functionality
function test_apply_undo()
    println("Testing apply! and undo! functions...")
    
    # Initialize a game
    spec = CheckersSpec()
    env = GI.init(spec)
    
    # Store the initial state
    initial_board = env.board
    initial_side = env.side_to_move
    initial_stack_size = length(env.move_stack)
    
    # Generate a legal move
    legal_moves = generate_all_moves(env.board, env.side_to_move)
    if isempty(legal_moves)
        println("No legal moves available - test cannot proceed")
        return false
    end
    
    move = legal_moves[1]
    println("Testing move: $(move.from) -> $(move.to)")
    
    # Apply the move
    apply!(env, move)
    
    # Verify the move was applied
    @test env.board != initial_board
    @test env.side_to_move != initial_side
    @test length(env.move_stack) == initial_stack_size + 1
    
    # Store the state after the move
    after_move_board = env.board
    after_move_side = env.side_to_move
    
    # Undo the move
    undo!(env)
    
    # Verify the move was undone
    @test env.board == initial_board
    @test env.side_to_move == initial_side
    @test length(env.move_stack) == initial_stack_size
    
    println("Apply and undo test passed!")
    return true
end

# Test with multiple moves
function test_multiple_moves()
    println("Testing multiple moves and undos...")
    
    # Initialize a game
    spec = CheckersSpec()
    env = GI.init(spec)
    
    initial_board = env.board
    initial_side = env.side_to_move
    
    moves_applied = Move[]
    
    # Apply several moves
    for i in 1:3
        legal_moves = generate_all_moves(env.board, env.side_to_move)
        if !isempty(legal_moves)
            move = legal_moves[1]
            push!(moves_applied, move)
            apply!(env, move)
            println("Applied move $i: $(move.from) -> $(move.to)")
        else
            println("No more legal moves available after move $(i-1)")
            break
        end
    end
    
    # Undo all moves
    for i in length(moves_applied):-1:1
        undo!(env)
        println("Undid move $i")
    end
    
    # Verify we're back to the initial state
    @test env.board == initial_board
    @test env.side_to_move == initial_side
    @test length(env.move_stack) == 0
    
    println("Multiple moves test passed!")
    return true
end

# Test with capture moves
function test_capture_moves()
    println("Testing capture moves...")
    
    # Create a custom board position with a capture opportunity
    # This is simplified - in practice you'd set up a specific position
    spec = CheckersSpec()
    env = GI.init(spec)
    
    # For now, just test with whatever legal moves are available
    legal_moves = generate_all_moves(env.board, env.side_to_move)
    capture_moves = filter(m -> !isempty(m.captures), legal_moves)
    
    if !isempty(capture_moves)
        println("Found $(length(capture_moves)) capture moves")
        
        initial_board = env.board
        initial_side = env.side_to_move
        
        move = capture_moves[1]
        println("Testing capture move: $(move.from) -> $(move.to), captures: $(move.captures)")
        
        apply!(env, move)
        undo!(env)
        
        @test env.board == initial_board
        @test env.side_to_move == initial_side
        
        println("Capture move test passed!")
    else
        println("No capture moves available in initial position - skipping capture test")
    end
    
    return true
end

# Run all tests
function run_tests()
    println("Starting apply!/undo! tests...")
    
    try
        test_apply_undo()
        test_multiple_moves()
        test_capture_moves()
        println("All tests passed!")
        return true
    catch e
        println("Test failed: $e")
        return false
    end
end

# Run the tests
if abspath(PROGRAM_FILE) == @__FILE__
    run_tests()
end
