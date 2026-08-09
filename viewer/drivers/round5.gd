extends "res://viewer/drivers/base_driver.gd"
## Round 5 — NPC finite-state machine. CharacterBody2D submission. We add it
## to the world, let the user click to set a target, and drive tick_physics
## each physics frame. Draw patrol points, detection range, and state.

var _npc: CharacterBody2D = null
var _world2d: Node2D
var _target_pos: Vector2 = Vector2(600.0, 300.0)
var _state_label: Label
var _guide: Control
var _attacks: int = 0


func _build() -> String:
	var npc_script: Script = _load_live(str(cfg["files"][0]))
	if npc_script == null or not npc_script.can_instantiate():
		return "npc_controller.gd failed to load/compile"
	_npc = npc_script.new()
	_npc.position = Vector2(200.0, 300.0)
	world.add_child(_npc)
	_npc.call("set_target", _target_pos)
	if _npc.has_signal("attacked"):
		_npc.attacked.connect(func(_p: Vector2) -> void: _attacks += 1)

	_guide = Control.new()
	_guide.set_anchors_preset(Control.PRESET_FULL_RECT)
	_guide.clip_contents = true
	_guide.draw.connect(_draw_guide)
	world.add_child(_guide)

	_state_label = _add_label("state: --")
	_add_label("Click in the world to move the target.")
	_add_button("Reset target", func() -> void: _set_target(Vector2(600.0, 300.0)))
	_add_button("Teleport NPC to center", func() -> void: _npc.position = Vector2(200.0, 300.0))
	_set_status("attacks: 0")
	return ""


func _set_target(p: Vector2) -> void:
	_target_pos = p
	if _npc != null:
		_npc.call("set_target", p)


func _draw_guide() -> void:
	if _npc == null:
		return
	var size: Vector2 = _guide.size
	var npc_pos: Vector2 = _npc.position
	# detection range
	_guide.draw_arc(npc_pos, 120.0, 0.0, TAU, 64, Color(1.0, 0.6, 0.2, 0.4), 2.0)
	_guide.draw_arc(npc_pos, 28.0, 0.0, TAU, 32, Color(1.0, 0.2, 0.2, 0.6), 2.0)
	# patrol points
	var pp: PackedVector2Array = _npc.get("PATROL_POINTS") if _npc.get("PATROL_POINTS") != null else PackedVector2Array()
	for i in pp.size():
		var p: Vector2 = pp[i] + npc_pos
		_guide.draw_circle(p, 5.0, Color(0.4, 0.8, 1.0))
		if i > 0:
			_guide.draw_line(pp[i - 1] + npc_pos, p, Color(0.4, 0.8, 1.0, 0.4), 1.0)
	# target
	_guide.draw_circle(_target_pos, 10.0, Color(1.0, 0.2, 0.2))
	_guide.draw_circle(_target_pos, 3.0, Color.WHITE)
	# NPC body
	_guide.draw_rect(Rect2(npc_pos - Vector2(12, 12), Vector2(24, 24)), Color(0.8, 0.8, 0.9))
	var state_name := _state_name()
	_guide.draw_string(ThemeDB.fallback_font, npc_pos + Vector2(-20, -20), state_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)


func _state_name() -> String:
	if _npc == null or not _npc.has_method("get_state"):
		return "?"
	var st: int = int(_npc.call("get_state"))
	match st:
		0: return "IDLE"
		1: return "PATROL"
		2: return "CHASE"
		3: return "ATTACK"
	return "?"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_target(world.get_global_mouse_position() - world.global_position)


func _physics_process(delta: float) -> void:
	if _npc != null:
		_npc.call("tick_physics", delta)
	if _guide != null:
		_guide.queue_redraw()
	if _state_label != null:
		_state_label.text = "state: %s  attacks: %d" % [_state_name(), _attacks]