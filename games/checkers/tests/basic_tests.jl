using Test
include("../main.jl")
using .Checkers

@testset "Checkers Basic Tests" begin
    
    @testset "Types and Constants" begin
        @test BOARD_SIZE == 8
        @test NUM_POSITIONS == 32
        @test WHITE == true
        @test BLACK == false
        @test length(INITIAL_BOARD) == NUM_POSITIONS
    end
    
    @testset "Coordinate Conversion" begin
        # Test some known conversions
        @test pos_to_coords(1) == (1, 1)
        @test pos_to_coords(4) == (1, 7)
        @test pos_to_coords(5) == (2, 2)
        
        # Test round-trip conversion
        for pos in 1:NUM_POSITIONS
            row, col = pos_to_coords(pos)
            @test coords_to_pos(row, col) == pos
            @test is_valid_square(row, col)
        end
    end
    
    @testset "Piece Functions" begin
        @test is_white_piece(WHITE_MAN)
        @test is_white_piece(WHITE_KING)
        @test !is_white_piece(BLACK_MAN)
        @test !is_white_piece(BLACK_KING)
        @test !is_white_piece(EMPTY)
        
        @test is_black_piece(BLACK_MAN)
        @test is_black_piece(BLACK_KING)
        @test !is_black_piece(WHITE_MAN)
        
        @test is_king(WHITE_KING)
        @test is_king(BLACK_KING)
        @test !is_king(WHITE_MAN)
        @test !is_king(BLACK_MAN)
        
        @test piece_owner(WHITE_MAN) == WHITE
        @test piece_owner(BLACK_MAN) == BLACK
        @test piece_owner(EMPTY) === nothing
    end
    
    @testset "Initial Board Setup" begin
        # Check initial piece counts
        @test count_pieces(INITIAL_BOARD, WHITE) == 12
        @test count_pieces(INITIAL_BOARD, BLACK) == 12
        @test count_kings(INITIAL_BOARD, WHITE) == 0
        @test count_kings(INITIAL_BOARD, BLACK) == 0
        
        # Check that initial board is valid
        @test is_valid_board_state(INITIAL_BOARD)
        
        # Check piece positions
        for pos in 1:12
            @test INITIAL_BOARD[pos] == BLACK_MAN
        end
        for pos in 13:20
            @test INITIAL_BOARD[pos] == EMPTY
        end
        for pos in 21:32
            @test INITIAL_BOARD[pos] == WHITE_MAN
        end
    end
    
    @testset "Move Generation" begin
        # Test initial position has legal moves
        moves = generate_all_moves(INITIAL_BOARD, WHITE)
        @test length(moves) > 0
        
        # White should have exactly 7 possible opening moves
        # (4 pieces on row 6 can each move to 2 squares, but edge pieces have fewer options)
        @test length(moves) == 7
        
        # Test that all moves are simple moves (no captures initially)
        for move in moves
            @test isempty(move.captures)
        end
    end
    
    @testset "Move Application" begin
        # Test a simple move
        move = Move(21, 17)  # Move from position 21 to 17
        new_board = apply_move(INITIAL_BOARD, move)
        
        @test new_board[21] == EMPTY
        @test new_board[17] == WHITE_MAN
        @test count_pieces(new_board, WHITE) == 12
        @test count_pieces(new_board, BLACK) == 12
    end
    
    @testset "Game Rules" begin
        # Test initial game state
        @test !is_game_over(INITIAL_BOARD, WHITE)
        @test has_pieces(INITIAL_BOARD, WHITE)
        @test has_pieces(INITIAL_BOARD, BLACK)
        @test has_legal_moves(INITIAL_BOARD, WHITE)
        @test has_legal_moves(INITIAL_BOARD, BLACK)
    end
    
    @testset "AlphaZero Interface" begin
        game_spec = GameSpec()
        env = GI.init(game_spec)
        
        @test GI.two_players(game_spec)
        @test GI.white_playing(env)
        @test !GI.game_terminated(env)
        @test GI.white_reward(env) == 0.0
        
        # Test actions mask
        mask = GI.actions_mask(env)
        @test length(mask) == NUM_POSITIONS * NUM_POSITIONS
        @test any(mask)  # Should have some legal moves
        
        # Test vectorization
        state = GI.current_state(env)
        vector = GI.vectorize_state(game_spec, state)
        @test size(vector) == (8, 4, 8)  # 8x4 board with 8 channels
    end
    
    @testset "Rendering" begin
        # Test that rendering doesn't crash
        @test_nowarn render_board(INITIAL_BOARD)
        state = INITIAL_STATE
        @test_nowarn render_game_state(state)
        
        # Test FEN conversion
        fen = board_to_fen(state)
        @test typeof(fen) == String
        @test length(fen) > 30  # Should be reasonably long
        
        # Test round-trip FEN conversion
        restored_state = fen_to_board(fen)
        @test restored_state.board == state.board
        @test restored_state.curplayer == state.curplayer
    end
end
