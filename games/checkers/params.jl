# Training parameters for Checkers - optimized for CPU training

using AlphaZero

# Game specification
const game = GameSpec()

# Neural network parameters - CPU optimized
function NetLib.DefaultNetParams()
    return NetLib.SimpleNetParams(
        # Reduced network size for CPU training
        num_filters=64,          # Smaller than typical GPU settings
        num_blocks=4,            # Fewer residual blocks
        conv_kernel_size=(3,3),
        value_head_hidden_size=64,
        policy_head_hidden_size=64
    )
end

# MCTS parameters - CPU friendly
const mcts = MctsParams(
    num_iters_per_turn=200,      # Reduced for CPU
    cpuct=1.0,
    temperature=TemperatureSchedule([
        (0, 1.0),
        (15, 0.5),
        (25, 0.1)
    ]),
    dirichlet_noise_ϵ=0.25,
    dirichlet_noise_α=1.0
)

# Self-play parameters
const self_play = SelfPlayParams(
    num_games=100,              # Smaller batches for CPU
    reset_mcts_every=nothing,
    mcts=mcts
)

# Learning parameters - CPU optimized
const learning = LearningParams(
    use_gpu=false,              # CPU training
    batch_size=32,              # Smaller batch size
    loss_computation_batch_size=32,
    optimiser=Adam(lr=2e-3),    # Slightly higher learning rate
    l2_regularization=1e-4,
    nonvalidity_penalty=1.0,
    min_checkpoints_per_epoch=1,
    max_batches_per_checkpoint=2000,
    num_checkpoints=4
)

# Arena parameters for evaluation
const arena = ArenaParams(
    num_games=20,               # Fewer games for faster evaluation
    reset_mcts_every=nothing,
    flip_probability=0.5,
    mcts=MctsParams(mcts, num_iters_per_turn=100)  # Even fewer iterations for evaluation
)

# Training schedule - adjusted for CPU
const training = TrainingParams(
    self_play=self_play,
    learning=learning,
    arena=arena,
    num_iters=30,               # More iterations but smaller batches
    memory_analysis=nothing,
    save_intermediate=true
)

# Memory buffer - smaller for CPU
const memory = MemAnalysisParams(
    num_game_stages=4
)

# Benchmark parameters
const benchmark = [
    Benchmark.MctsRollouts(
        MctsParams(
            mcts,
            num_iters_per_turn=50,
            temperature=0.2
        ),
        num_games=20,
        name="MCTS (50 rollouts)"
    ),
    Benchmark.MinMaxTS(
        depth=5,
        τ=0.2,
        num_games=20
    )
]

# Full experiment configuration
const experiment = Experiment(
    name="checkers-cpu",
    game=game,
    params=training,
    network_params=NetLib.DefaultNetParams(),
    benchmark=benchmark,
    dir="games/checkers"
)
