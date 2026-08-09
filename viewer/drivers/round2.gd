extends "res://viewer/drivers/base_driver.gd"
## Round 2 — Greenhouse automation. Node2D submission that builds its own
## Thermostat + Sprinkler Timer children. We add it to the world, draw a
## greenhouse frame, and surface live temperature / moisture / heater state.

var _gh: Node2D = null
var _thermo: Node = null
var _view: Control
var _temp_label: Label
var _moisture: float = 0.0
var _events: int = 0


func _build() -> String:
	var gh_script: Script = _load_live(str(cfg["files"][0]))
	if gh_script == null or not gh_script.can_instantiate():
		return "greenhouse.gd failed to load/compile"
	_gh = gh_script.new()
	world.add_child(_gh)
	# Wait a couple frames so the submission's _ready builds its children.
	await get_tree().process_frame
	await get_tree().process_frame
	_thermo = _gh.get_node_or_null("Thermostat")
	if _thermo != null and _thermo.has_signal("heater_state_changed"):
		_thermo.heater_state_changed.connect(_on_heater_state)
	if _gh.has_signal("watered"):
		_gh.watered.connect(_on_watered)

	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.clip_contents = true
	_view.draw.connect(_draw_greenhouse)
	world.add_child(_view)

	_temp_label = _add_label("temp: --")
	_add_label("heater: off")
	_add_button("Set temp to 5\u00b0C (heater ON)", func() -> void: _set_temp(5.0))
	_add_button("Set temp to 30\u00b0C (heater OFF)", func() -> void: _set_temp(30.0))
	_add_button("Generate report", _on_report)
	return ""


func _on_watered(amount: float) -> void:
	_moisture += float(amount)
	_events += 1


func _on_heater_state(on: bool) -> void:
	if _temp_label != null:
		# update on next frame for a fresh reading
		pass


func _set_temp(v: float) -> void:
	if _thermo != null:
		_thermo.set("temperature", v)


func _on_report() -> void:
	if _gh != null and _gh.has_method("generate_report"):
		var rep: Dictionary = _gh.call("generate_report")
		_set_status("Report: moisture=%.1f temp=%.1f heater=%s events=%d" %
			[rep.get("moisture", 0.0), rep.get("temperature", 0.0), rep.get("heater_on", false), rep.get("watered_events", 0)])


func _draw_greenhouse() -> void:
	var size: Vector2 = _view.size
	var cx: float = size.x * 0.5
	var cy: float = size.y * 0.5
	var w: float = 300.0
	var h: float = 220.0
	var tl := Vector2(cx - w * 0.5, cy - h * 0.5)
	# frame
	_view.draw_rect(Rect2(tl, Vector2(w, h)), Color(0.9, 0.9, 0.9, 0.08))
	_view.draw_rect(Rect2(tl, Vector2(w, h)), Color(0.7, 0.95, 0.7), false, 3.0)
	# heater
	var heater_on: bool = _thermo.get("heater_on") if _thermo != null else false
	_view.draw_circle(Vector2(cx - 60.0, cy), 22.0, Color(1.0, 0.4, 0.1, 0.9) if heater_on else Color(0.3, 0.3, 0.3))
	_view.draw_string(ThemeDB.fallback_font, Vector2(cx - 100.0, cy - 40.0), "HEATER", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	# sprinkler drops
	for i in range(mini(_events % 6, 6)):
		var x: float = cx + 40.0 + float(i) * 30.0
		var ypos: float = tl.y + 20.0 + float((Time.get_ticks_msec() / 120 + i * 7) % 180)
		_view.draw_circle(Vector2(x, ypos), 3.0, Color(0.4, 0.7, 1.0))
	# labels
	if _thermo != null:
		var t: float = float(_thermo.get("temperature"))
		_view.draw_string(ThemeDB.fallback_font, Vector2(cx + 30.0, cy - 40.0), "Temp %.1f\u00b0C" % t, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)


func _process(_delta: float) -> void:
	if _thermo != null and _temp_label != null:
		_temp_label.text = "temp: %.1f\u00b0C  heater: %s" % [float(_thermo.get("temperature")), _thermo.get("heater_on")]
	if _view != null:
		_view.queue_redraw()