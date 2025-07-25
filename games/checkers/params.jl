# Training parameters for Checkers - optimized for CPU training

using AlphaZero
import ..GameSpec

# Game specification
const game = GameSpec()

# Neural network parameters - CPU optimized
Network = NetLib.SimpleNet

netparams = NetLib.SimpleNetHP(
    width=64,                    # Reduced network size for CPU training
    depth_common=4,              # Fewer residual blocks
    use_batch_norm=true,
    batch_norm_momentum=1.
)

# Self-play parameters - CPU optimized
self_play = SelfPlayParams(
  sim=SimParams(
    num_games=100,              # Smaller batches for CPU
    num_workers=32,
    batch_size=32,
    use_gpu=false,
    reset_every=4,
    flip_probability=0.,
    alternate_colors=false),
  mcts=MctsParams(
    num_iters_per_turn=200,     # Reduced for CPU
    cpuct=1.0,
    temperature=ConstSchedule(1.0),
    dirichlet_noise_ϵ=0.25,
    dirichlet_noise_α=1.0))

# Arena parameters for evaluation
arena = ArenaParams(
  sim=SimParams(
    num_games=20,               # Fewer games for faster evaluation
    num_workers=20,
    batch_size=20,
    use_gpu=false,
    reset_every=1,
    flip_probability=0.5,
    alternate_colors=true),
  mcts = MctsParams(
    self_play.mcts,
    temperature=ConstSchedule(0.3),
    dirichlet_noise_ϵ=0.1),
  update_threshold=0.00)

# Learning parameters - CPU optimized
learning = LearningParams(
  use_gpu=false,              # CPU training
  samples_weighing_policy=LOG_WEIGHT,
  l2_regularization=1e-4,
  optimiser=CyclicNesterov(
    lr_base=1e-3,
    lr_high=1e-2,
    lr_low=1e-3,
    momentum_high=0.9,
    momentum_low=0.8),
  batch_size=32,              # Smaller batch size
  loss_computation_batch_size=512,
  nonvalidity_penalty=1.,
  min_checkpoints_per_epoch=0,
  max_batches_per_checkpoint=2000,
  num_checkpoints=1)

# Training parameters
params = Params(
  arena=arena,
  self_play=self_play,
  learning=learning,
  num_iters=30,               # More iterations but smaller batches
  memory_analysis=MemAnalysisParams(
    num_game_stages=4),
    ternary_outcome=true,
  use_symmetries=false,       # Checkers doesn't have simple symmetries
  mem_buffer_size=PLSchedule(20_000))  # Smaller buffer for CPU

benchmark_sim = SimParams(
  arena.sim;
  num_games=100,
  num_workers=20,
  batch_size=20)

benchmark = [
  Benchmark.Duel(
    Benchmark.Full(self_play.mcts),
    Benchmark.MctsRollouts(self_play.mcts),
    benchmark_sim),
  Benchmark.Duel(
    Benchmark.NetworkOnly(),
    Benchmark.MinMaxTS(depth=5, amplify_rewards=true, τ=1.),
    benchmark_sim)]

experiment = Experiment(
  "checkers", GameSpec(), params, Network, netparams, benchmark)
