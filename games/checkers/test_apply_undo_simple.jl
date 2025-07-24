#!/usr/bin/env julia

# Simplified test file for apply! and undo! functions
# This mocks the AlphaZero.GI interface

# Mock AlphaZero.GI module
module GI
    abstract type AbstractGameSpec end
    abstract type AbstractGameEnv end
    
    # Mock functions - these would normally be implemented by AlphaZero
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

# Load all necessary modules
include("Types.jl")
include("Moves.jl")
include("Rules.jl")
include("Vectorization.jl")

# Define the structures and functions from game.jl manually
struct CheckersSpec <: GI.AbstractGameSpec
    board_size::Int
    num_players::Int
    action_space_dim::Int
    
    function CheckersSpec()
        new(BOARD_SIZE, 2, NUM_POSITIONS * NUM_POSITIONS)
    end
end

mutable struct CheckersEnv <: GI.AbstractGameEnv
    board::SVector{32, Int8}
    side_to_move::Bool
    repetition_hash::UInt64
    move_stack::Vector{ReversibleMove}
    outcome::Union{Nothing, Int8}
    finished::Bool
    actions_mask::Vector{Bool}
end

function GI.init(::CheckersSpec)
    CheckersEnv(
        INITIAL_BOARD,
        WHITE,
        0x0000000000000000,
        Vector{ReversibleMove}(),
        nothing,
        false,
        Vector{Bool}(undef, NUM_POSITIONS * NUM_POSITIONS)
    )
end

function apply!(env::CheckersEnv, move::Move)
    reversible_move = create_reversible_move(env.board, move)
    push!(env.move_stack, reversible_move)
    env.board = apply_move(env.board, move)
    env.side_to_move = !env.side_to_move
    env.repetition_hash = hash((env.board, env.side_to_move))
end

function undo!(env::CheckersEnv)
    move = pop!(env.move_stack)
    env.board = revert_move(env.board, move)
    env.side_to_move = !env.side_to_move
    env.repetition_hash = hash((env.board, env.side_to_move))
end

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

# Run all tests
function run_tests()
    println("Starting apply!/undo! tests...")
    
    try
        test_apply_undo()
        test_multiple_moves()
        println("All tests passed!")
        return true
    catch e
        println("Test failed: $e")
        rethrow(e)
        return false
    end
end

# Run the tests
if abspath(PROGRAM_FILE) == @__FILE__
    run_tests()
end
