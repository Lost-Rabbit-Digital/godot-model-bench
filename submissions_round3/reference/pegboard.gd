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
const SPAWN_TOP: float = -140.0
const LOOP_Y: float = 640.0

var balls: Array = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 20260806
	_build_pegs()
	_spawn_balls()

func _build_pegs() -> void:
	for r in range(PEG_ROWS):
		for c in range(PEG_COLS):
			var peg := StaticBody2D.new()
			var shape := CollisionShape2D.new()
			var circle := CircleShape2D.new()
			circle.radius = PEG_RADIUS
			shape.shape = circle
			peg.add_child(shape)
			peg.position = Vector2(
				BOARD_LEFT + float(c) * PEG_COL_SPACING + float(r % 2) * (PEG_COL_SPACING * 0.5),
				PEG_TOP + float(r) * PEG_ROW_SPACING)
			add_child(peg)

func _spawn_balls() -> void:
	var ball_script: Script = load("res://submission3/bouncy_ball.gd")
	for i in range(BALL_COUNT):
		var ball: RigidBody2D = ball_script.new()
		ball.set("ball_id", i)
		ball.position = Vector2(
			BOARD_LEFT + 20.0 + float(i % 10) * 44.0 + _rng.randf_range(-3.0, 3.0),
			SPAWN_TOP + float(i / 10) * 12.0)
		add_child(ball)
		balls.append(ball)

func _physics_process(_delta: float) -> void:
	for ball in balls:
		if ball.global_position.y > LOOP_Y:
			ball.linear_velocity = Vector2(_rng.randf_range(-60.0, 60.0), 0.0)
			ball.global_position = Vector2(_rng.randf_range(80.0, 400.0), SPAWN_TOP)
			ball_recycled.emit(int(ball.get("ball_id")))
