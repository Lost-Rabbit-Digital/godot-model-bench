extends Node2D

const BODY_COLOR: Color = Color(0.2, 0.6, 1.0)
const EYE_COLOR: Color = Color(0.05, 0.05, 0.05)
const BODY_W: float = 20.0
const BODY_H: float = 36.0
const EYE_RADIUS: float = 3.0

const BREATH_SCALE: float = 1.05
const BREATH_SPEED: float = 2.5
const WALK_BOBBLE: float = 4.0
const WALK_SPEED: float = 6.0
const LUNGE_DIST: float = 18.0
const LUNGE_SPEED: float = 12.0

signal attacked()

var _moving: bool = false
var _anim_time: float = 0.0
var _attacking: bool = false
var _lunge_time: float = 0.0

func set_moving(moving: bool) -> void:
	_moving = moving

func trigger_attack() -> void:
	if not _attacking:
		_attacking = true
		_lunge_time = 0.0
		attacked.emit()

func tick_animation(delta: float) -> void:
	_anim_time += delta
	if _attacking:
		_lunge_time += delta
		var duration := 1.0 / LUNGE_SPEED
		if _lunge_time >= duration:
			_attacking = false
	queue_redraw()

func get_body_scale() -> Vector2:
	var base := Vector2.ONE
	if _attacking:
		var t := _lunge_time / (1.0 / LUNGE_SPEED)
		base.x = 1.0 + 0.1 * sin(t * PI)
		base.y = 1.0 - 0.1 * sin(t * PI)
	else:
		var breath := (sin(_anim_time * TAU / BREATH_SPEED) * 0.5 + 0.5)
		var swell := 1.0 + breath * (BREATH_SCALE - 1.0)
		base = Vector2(swell, swell)
	return base

func get_body_offset() -> Vector2:
	var off := Vector2.ZERO
	if _attacking:
		var t := _lunge_time / (1.0 / LUNGE_SPEED)
		if t < 0.5:
			var prog := t * 2.0
			off.x = prog * prog * LUNGE_DIST
		else:
			var prog := (1.0 - t) * 2.0
			off.x = prog * prog * LUNGE_DIST
	else:
		if _moving:
			off.y = sin(_anim_time * WALK_SPEED * TAU) * WALK_BOBBLE * 0.5
	return off

func get_eye_offset() -> float:
	if _attacking:
		var t := _lunge_time / (1.0 / LUNGE_SPEED)
		if t < 0.5:
			return 1.0
		return 0.0
	if _moving:
		return 0.5
	return 0.0

func _draw() -> void:
	var scale := get_body_scale()
	var offset := get_body_offset()
	var eye_dir := get_eye_offset()
	var body_rect := Rect2(-BODY_W * 0.5 + offset.x, -BODY_H * 0.5 + offset.y, BODY_W, BODY_H)
	body_rect.position *= scale
	body_rect.size *= scale
	draw_rect(body_rect, BODY_COLOR)
	var eye_l := Vector2(-4.0 + eye_dir * 2.0 + offset.x, -4.0 + offset.y) * scale
	var eye_r := Vector2(4.0 + eye_dir * 2.0 + offset.x, -4.0 + offset.y) * scale
	draw_circle(eye_l, EYE_RADIUS, EYE_COLOR)
	draw_circle(eye_r, EYE_RADIUS, EYE_COLOR)
