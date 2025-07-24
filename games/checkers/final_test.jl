include("Types.jl")
include("Moves.jl")
include("Rules.jl")

# Test that ReversibleMove works correctly
board = INITIAL_BOARD
moves = generate_all_moves(board, WHITE)
println("Generated $(length(moves)) moves for WHITE")

if !isempty(moves)
    move = moves[1]
    println("Testing move: $(move.from) -> $(move.to), captures: $(move.captures)")
    
    # Create reversible move
    rmove = create_reversible_move(board, move)
    println("Created reversible move: promoted=$(rmove.was_promoted), original_piece=$(rmove.original_piece)")
    
    # Apply move
    new_board = apply_move(board, move)
    println("Applied move successfully")
    
    # Revert move
    reverted_board = revert_move(new_board, rmove)
    println("Reverted move successfully")
    
    # Check if boards match
    if reverted_board == board
        println("✓ Perfect reversibility achieved!")
    else
        println("✗ Boards don't match after revert")
    end
end
