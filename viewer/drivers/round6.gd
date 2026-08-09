extends "res://viewer/drivers/base_driver.gd"
## Round 6 — Procedural character animation. Node2D submission that draws
## itself (body/eyes) via _draw. We drive tick_animation each frame and
## expose moving / attack toggles.

var _anim: Node2D = null
var _moving: bool = false
var _auto: bool = false
var _auto_accum: float = 0.0
var _center_deferred: bool = false
var _view: Control
var _status_readout: Label


func _build() -> String:
	var anim_script: Script = _load_live(str(cfg["files"][0]))
	if anim_script == null or not anim_script.can_instantiate():
		return "char_animator.gd failed to load/compile"
	_anim = anim_script.new()
	world.add_child(_anim)
	_center_deferred = true
	_anim.call("set_moving", false)
	if _anim.has_signal("attacked"):
		_anim.attacked.connect(func() -> void: _set_status("ATTACK!"))

	_status_readout = _add_label("scale: 1.0  offset: 0,0")
	var mv := _add_toggle("Moving (walk)", func(on: bool) -> void:
		_moving = on
		if _anim != null:
			_anim.call("set_moving", on))
	_add_button("Trigger attack", func() -> void:
		if _anim != null:
			_anim.call("trigger_attack"))
	_add_toggle("Auto demo", func(on: bool) -> void: _auto = on)
	return ""


func _process(delta: float) -> void:
	if _center_deferred and _anim != null:
		_center_deferred = false
		_anim.position = world.size * 0.5
	if _anim == null:
		return
	if _auto:
		_auto_accum += delta
		if _auto_accum >= 2.0:
			_auto_accum = 0.0
			_moving = not _moving
			_anim.call("set_moving", _moving)
			if _moving:
				_anim.call("trigger_attack")
	_anim.call("tick_animation", delta)
	var s: Vector2 = _anim.call("get_body_scale")
	var o: Vector2 = _anim.call("get_body_offset")
	_status_readout.text = "scale: %.2f,%.2f  offset: %.1f,%.1f" % [s.x, s.y, o.x, o.y]