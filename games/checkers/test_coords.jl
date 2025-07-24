#!/usr/bin/env julia

using StaticArrays

const BOARD_SIZE = 8
const NUM_POSITIONS = 32

include("Types.jl")

println("Testing coordinate mapping:")

# Test if pos_to_coords and coords_to_pos are inverses
println("\n=== Testing round-trip conversion ===")
for pos in 1:5
    try
        row, col = pos_to_coords(pos)
        println("Position $pos -> (row $row, col $col), (r+c)%2=$(((row + col) % 2))")
        
        # Try to convert back
        try
            back_pos = coords_to_pos(row, col)
            println("  Round trip: $pos -> ($row, $col) -> $back_pos")
        catch e
            println("  ERROR converting back: $e")
        end
    catch e
        println("Position $pos ERROR: $e")
    end
end

# Test what dark squares should map to
println("\n=== Testing dark square positions ===")
dark_squares = [(1, 2), (1, 4), (1, 6), (1, 8), (2, 1), (2, 3), (2, 5), (2, 7)]
for (row, col) in dark_squares
    println("Dark square (row $row, col $col): is_valid=$(is_valid_square(row, col)), (r+c)%2=$(((row + col) % 2))")
    if is_valid_square(row, col)
        try
            pos = coords_to_pos(row, col)
            println("  Maps to position: $pos")
        catch e
            println("  ERROR: $e")
        end
    end
end
