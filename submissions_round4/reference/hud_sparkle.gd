# hud_sparkle.gd — reference implementation for Round 4
# class_name intentionally omitted (optional per spec)
extends Node2D

const LIFETIME: float = 0.5

var _t: float = 0.0
var _color: Color = Color(1, 1, 1, 1)

func _init(color: Color = Color(1, 1, 1, 1)) -> void:
	_color = color

func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, _color)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= LIFETIME:
		queue_free()

func set_color(c: Color) -> void:
	_color = c
	queue_redraw()
