module Checkers
  export GameEnv, GameSpec, Board
  include("Types.jl")
  include("Moves.jl")
  include("Rules.jl")
  include("Vectorization.jl")
  include("Render.jl")
  include("game.jl")
  
  module Training
    using AlphaZero
    import ..GameSpec
    include("params.jl")
  end
end
