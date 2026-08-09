extends CharacterBody2D

enum State { IDLE, PATROL, CHASE, ATTACK }

const SPEED_WALK: float = 60.0
const SPEED_CHASE: float = 140.0
const DETECTION_RANGE: float = 120.0
const ATTACK_RANGE: float = 28.0
const ATTACK_COOLDOWN: float = 1.0
const PATROL_POINTS: PackedVector2Array = [
	Vector2(100.0, 0.0),
	Vector2(300.0, 0.0),
	Vector2(300.0, 200.0),
	Vector2(100.0, 200.0),
]

signal attacked(target_pos: Vector2)

var state: State = State.IDLE
var target_position: Vector2 = Vector2.ZERO
var current_patrol: int = 0
var _last_attack_time: float = -9999.0
var _clock: float = 0.0

func set_target(pos: Vector2) -> void:
	target_position = pos

func tick_physics(delta: float) -> void:
	_clock += delta
	var to_target: Vector2 = target_position - global_position
	var dist: float = to_target.length()

	# State transitions
	match state:
		State.IDLE:
			if dist <= DETECTION_RANGE:
				state = State.CHASE
			else:
				state = State.PATROL
		State.PATROL:
			if dist <= DETECTION_RANGE:
				state = State.CHASE
		State.CHASE:
			if dist <= ATTACK_RANGE:
				state = State.ATTACK
			elif dist > DETECTION_RANGE:
				state = State.PATROL
		State.ATTACK:
			if dist > ATTACK_RANGE:
				if dist > DETECTION_RANGE:
					state = State.PATROL
				else:
					state = State.CHASE

	# Per-state behavior
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.PATROL:
			var goal: Vector2 = PATROL_POINTS[current_patrol]
			var dir: Vector2 = (goal - global_position).normalized()
			velocity = dir * SPEED_WALK
			if (goal - global_position).length() < 8.0:
				current_patrol = (current_patrol + 1) % PATROL_POINTS.size()
		State.CHASE:
			var dir: Vector2 = to_target.normalized()
			velocity = dir * SPEED_CHASE
		State.ATTACK:
			velocity = Vector2.ZERO
			if _clock - _last_attack_time >= ATTACK_COOLDOWN:
				_last_attack_time = _clock
				attacked.emit(global_position)

	move_and_slide()

func get_state() -> State:
	return state

func get_npc_position() -> Vector2:
	return global_position

func get_patrol_index() -> int:
	return current_patrol
