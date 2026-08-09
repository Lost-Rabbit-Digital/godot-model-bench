You are an expert Godot 4.7 GDScript programmer. Implement a 2D PHYSICS SIMULATION: a Galton-board-style pegboard with 200 bouncy balls falling through 20 pegs, with a SEAMLESS LOOP that recycles balls from the bottom back to the top.

CONTEXT / HARD CONSTRAINTS
- Real physics: RigidBody2D balls, StaticBody2D pegs, CircleShape2D collisions, PhysicsMaterial bounce. The harness instantiates your Pegboard and adds it to the SceneTree root; physics runs headless at 60Hz.
- Two scripts, both loaded by path with load() at runtime by the harness. Do NOT rely on class_name globals (a class_name line is optional but never reference another script's class by name, never preload it, never type against it). Attach/instantiate via load("res://submission3/<file>.gd").
- Strongly typed GDScript: every variable, parameter, and function return type annotated.
- No autoloads, no @export, no .tscn files. Fully deterministic: seed your RandomNumberGenerator with a FIXED constant.
- The simulation must run forever without intervention: balls that fall below the board are repositioned to the top (the "seamless loop"). The ball count NEVER changes.

=====================================================================
FILE 1: bouncy_ball.gd — a single bouncy ball
=====================================================================

class_name BouncyBall          # optional
extends RigidBody2D

const RADIUS: float = 4.0

var ball_id: int = -1          # unique id, assigned by the Pegboard

func _init() -> void:
    # Build the body IN CODE:
    #   - CollisionShape2D child with a CircleShape2D of radius RADIUS
    #   - physics_material_override = a PhysicsMaterial with bounce = 0.9
    #   - gravity_scale = 1.0

=====================================================================
FILE 2: pegboard.gd — the board, the balls, and the seamless loop
=====================================================================

class_name Pegboard            # optional
extends Node2D

signal ball_recycled(ball_id: int)

const BALL_COUNT: int = 200
const PEG_COUNT: int = 20
const BALL_RADIUS: float = 4.0
const PEG_RADIUS: float = 8.0
const PEG_COLS: int = 5
const PEG_ROWS: int = 4
const PEG_COL_SPACING: float = 100.0
const PEG_ROW_SPACING: float = 70.0
const BOARD_LEFT: float = 40.0
const PEG_TOP: float = 120.0
const SPAWN_TOP: float = -140.0     # balls spawn above the pegs
const LOOP_Y: float = 640.0         # balls below this line are recycled

var balls: Array = []              # the 200 RigidBody2D ball nodes
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
    # 1. _rng.seed = 20260806   (fixed constant — determinism)
    # 2. Build exactly PEG_COUNT pegs: StaticBody2D nodes, each with a
    #    CollisionShape2D child holding a CircleShape2D of radius PEG_RADIUS.
    #    Layout: PEG_ROWS rows x PEG_COLS columns, staggered like a diamond
    #    (odd rows offset by half a column). Row r, col c position:
    #      x = BOARD_LEFT + c * PEG_COL_SPACING + (r % 2) * (PEG_COL_SPACING * 0.5)
    #      y = PEG_TOP + r * PEG_ROW_SPACING
    # 3. Spawn BALL_COUNT balls from bouncy_ball.gd (load() it, .new() it),
    #    assign ball_id 0..199, place them in a dense grid ABOVE the pegs:
    #      x = BOARD_LEFT + 20.0 + (i % 10) * 44.0 + _rng.randf_range(-3.0, 3.0)
    #      y = SPAWN_TOP + (i / 10) * 12.0
    #    (10 columns x 20 rows; x spacing 44 keeps them from overlapping;
    #    the columns line up with the peg columns below so every ball hits pegs.)
    #    Keep the nodes in the balls array.

func _physics_process(_delta: float) -> void:
    # THE SEAMLESS LOOP: for every ball whose global_position.y > LOOP_Y:
    #   - reset its velocity to Vector2(_rng.randf_range(-60.0, 60.0), 0.0)
    #   - teleport it back to the top: position = Vector2(_rng.randf_range(80.0, 400.0), SPAWN_TOP)
    #   - emit ball_recycled(ball.ball_id)
    # This runs every physics frame; balls cycle forever, count stays at BALL_COUNT.

=====================================================================
OUTPUT FORMAT (strict)
=====================================================================
Output pegboard.gd's complete source in one fenced code block tagged gdscript, then
bouncy_ball.gd's complete source in a second fenced code block. No prose before, between,
or after the fences. No tests, no usage examples, no comments outside the code blocks.
