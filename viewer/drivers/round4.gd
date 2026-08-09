extends "res://viewer/drivers/base_driver.gd"
## Round 4 — HUD / juice UI. Control submission. We add it to the world and
## provide buttons to drive set_health / add_score / pulse, plus a sparkle
## spawner.

var _hud: Control = null
var _sparkle_script: Script = null
var _hud_view: Control
var _status_readout: Label


func _build() -> String:
	var hud_script: Script = _load_live(str(cfg["files"][0]))
	if hud_script == null or not hud_script.can_instantiate():
		return "juice_hud.gd failed to load/compile"
	_sparkle_script = _load_live(str(cfg["files"][1]))
	_hud = hud_script.new()
	world.add_child(_hud)

	_status_readout = _add_label("health: 0  score: 0")
	_add_button("Set health 50", func() -> void: _hud.call("set_health", 50.0))
	_add_button("Set health 100", func() -> void: _hud.call("set_health", 100.0))
	_add_button("Set health 0", func() -> void: _hud.call("set_health", 0.0))
	_add_button("Add score 150", func() -> void: _hud.call("add_score", 150))
	_add_button("Pulse", func() -> void: _hud.call("pulse"))
	_add_button("Spawn sparkle", _on_sparkle)
	_set_status("Click the 'Press Me' button to see hover juice.")
	return ""


func _on_sparkle() -> void:
	if _sparkle_script == null or not _sparkle_script.can_instantiate():
		return
	var spark: Node2D = _sparkle_script.new()
	var c: Color = Color(randf(), randf(), randf(), 1.0)
	if spark.has_method("set_color"):
		spark.call("set_color", c)
	world.add_child(spark)
	spark.position = Vector2(randf_range(60.0, world.size.x - 60.0), randf_range(60.0, world.size.y - 60.0))


func _process(_delta: float) -> void:
	if _hud != null and _status_readout != null:
		var h: float = _hud.call("get_health") if _hud.has_method("get_health") else 0.0
		var s: int = _hud.call("get_score") if _hud.has_method("get_score") else 0
		_status_readout.text = "health: %.0f  score: %d" % [h, s]