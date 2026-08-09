extends "res://viewer/drivers/base_driver.gd"
## Round 3 — Pegboard plinko physics. The submission builds 200 RigidBody2D
## balls + 20 pegs and runs them. We add it to the world and let physics do
## the rest; surface a recycled counter and a reset button.

var _peg: Node2D = null
var _recycled: int = 0
var _ball_view: Control
var _count_label: Label
var _guide: Control


func _build() -> String:
	var peg_script: Script = _load_live(str(cfg["files"][0]))
	if peg_script == null or not peg_script.can_instantiate():
		return "pegboard.gd failed to load/compile"
	_peg = peg_script.new()
	if _peg.has_signal("ball_recycled"):
		_peg.ball_recycled.connect(func(_id: int) -> void: _recycled += 1)
	world.add_child(_peg)

	# Draw pegs + balls (submissions are physics-only, no visuals)
	_guide = Control.new()
	_guide.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_guide.clip_contents = true
	_guide.draw.connect(_draw_board)
	world.add_child(_guide)

	_count_label = _add_label("recycled: 0")
	_add_button("Reset", _on_reset)
	_add_button("Freeze/Unfreeze", _on_freeze)
	_set_status("Galton board: 200 balls, 20 pegs")
	return ""


func _draw_board() -> void:
	if _peg == null:
		return
	# pegs: StaticBody2D children with CircleShape2D
	var pegs := 0
	for c in _peg.get_children():
		if c is StaticBody2D:
			pegs += 1
			var r: float = 8.0
			for sc in c.get_children():
				if sc is CollisionShape2D and sc.shape is CircleShape2D:
					r = (sc.shape as CircleShape2D).radius
			_guide.draw_circle(c.position, r, Color(0.75, 0.65, 0.45))
	# balls: RigidBody2D children
	for c in _peg.get_children():
		if c is RigidBody2D:
			_guide.draw_circle(c.position, 4.0, Color(0.3, 0.7, 1.0, 0.9))
	# board frame
	_guide.draw_rect(Rect2(-160.0, -160.0, 720.0, 820.0), Color(0.4, 0.6, 0.4, 0.25), false, 2.0)
	_guide.draw_string(ThemeDB.fallback_font, Vector2(20.0, -100.0), "PEGBOARD (200 balls / 20 pegs)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.9, 0.8))


var _frozen: bool = false


func _on_reset() -> void:
	if _peg != null:
		_peg.queue_free()
	_peg = null
	_recycled = 0
	var peg_script: Script = _load_live(str(cfg["files"][0]))
	_peg = peg_script.new()
	if _peg.has_signal("ball_recycled"):
		_peg.ball_recycled.connect(func(_id: int) -> void: _recycled += 1)
	world.add_child(_peg)


func _on_freeze() -> void:
	_frozen = not _frozen
	if _peg != null:
		_peg.set_physics_process(not _frozen)


func _process(_delta: float) -> void:
	if _count_label != null:
		_count_label.text = "recycled: %d" % _recycled
	if _guide != null:
		_guide.queue_redraw()