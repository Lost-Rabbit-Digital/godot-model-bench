# juice_hud.gd — reference implementation for Round 4
# class_name intentionally omitted (optional per spec; avoids global-class cache conflicts)
extends Control

var _health_bar: ProgressBar
var _ghost: ProgressBar
var _score_label: Label
var _button: Button
var _score: int = 0
var _health: float = 0.0

func set_health(value: float) -> void:
	_health = clampf(value, 0.0, 100.0)
	_health_bar.value = _health
	var tween := create_tween()
	tween.tween_property(_ghost, "value", _health, 0.4)

func add_score(amount: int) -> void:
	_score += amount
	var from_val: int = _extract_int(_score_label.text)
	var tween := create_tween()
	tween.tween_method(_set_score_label, float(from_val), float(_score), 0.5)

func _set_score_label(v: float) -> void:
	_score_label.text = "Score: %d" % [int(v)]

func _extract_int(s: String) -> int:
	var m := RegEx.new()
	m.compile("[0-9]+")
	var r = m.search(s)
	if r:
		return int(r.get_string())
	return 0

func pulse() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func get_health() -> float:
	return _health

func get_score() -> int:
	return _score

func _ready() -> void:
	_health_bar = ProgressBar.new()
	_health_bar.name = "HealthBar"
	_health_bar.min_value = 0.0
	_health_bar.max_value = 100.0
	_health_bar.anchor_right = 1.0
	_health_bar.anchor_bottom = 0.0
	_health_bar.position = Vector2(8.0, 8.0)
	_health_bar.size = Vector2(180.0, 18.0)
	add_child(_health_bar)

	_ghost = ProgressBar.new()
	_ghost.name = "GhostBar"
	_ghost.min_value = 0.0
	_ghost.max_value = 100.0
	_ghost.anchor_right = 1.0
	_ghost.anchor_bottom = 0.0
	_ghost.position = _health_bar.position
	_ghost.size = _health_bar.size
	_ghost.modulate = Color(1, 1, 1, 0.25)
	_ghost.value = _health_bar.value
	add_child(_ghost)

	_score_label = Label.new()
	_score_label.name = "ScoreLabel"
	_score_label.position = Vector2(8.0, 36.0)
	_score_label.text = "Score: 0"
	add_child(_score_label)

	_button = Button.new()
	_button.name = "JuiceButton"
	_button.text = "Press Me"
	_button.position = Vector2(8.0, 64.0)
	_button.size = Vector2(100.0, 30.0)
	add_child(_button)
	_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_button.connect("mouse_entered", Callable(self, "_on_button_entered"))
	_button.connect("mouse_exited", Callable(self, "_on_button_exited"))

func _on_button_entered() -> void:
	var tween := create_tween()
	tween.tween_property(_button, "scale", Vector2(1.1, 1.1), 0.1)

func _on_button_exited() -> void:
	var tween := create_tween()
	tween.tween_property(_button, "scale", Vector2.ONE, 0.1)
