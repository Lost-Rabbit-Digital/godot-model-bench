extends "res://viewer/drivers/base_driver.gd"
## Round 7 — Particle/VFX burst. Node2D submission. We add it to the world,
## expose a Burst button plus auto-repeat, and tick() it each frame.

var _vfx: Node2D = null
var _auto: bool = false
var _auto_accum: float = 0.0
var _center_deferred: bool = false
var _status_readout: Label
var _burst_count: int = 0


func _build() -> String:
	var vfx_script: Script = _load_live(str(cfg["files"][0]))
	if vfx_script == null or not vfx_script.can_instantiate():
		return "spell_vfx.gd failed to load/compile"
	_vfx = vfx_script.new()
	world.add_child(_vfx)

	_status_readout = _add_label("particles: --  lifetime: --")
	_add_button("Burst", _on_burst)
	var auto_btn := _add_toggle("Auto repeat (1.2s)", func(on: bool) -> void: _auto = on)
	auto_btn.button_pressed = true
	_auto = true
	_set_status("bursts: 0")
	# center once layout is known
	_center_deferred = true
	# fire once on load so the effect is immediately visible
	call_deferred("_on_burst")
	return ""


func _on_burst() -> void:
	if _vfx == null:
		return
	if _vfx.has_method("burst"):
		_vfx.call("burst")
		_burst_count += 1
		_set_status("bursts: %d" % _burst_count)


func _process(delta: float) -> void:
	if _center_deferred and _vfx != null:
		_center_deferred = false
		_vfx.position = world.size * 0.5
	if _vfx == null:
		return
	if _auto:
		_auto_accum += delta
		if _auto_accum >= 1.2:
			_auto_accum = 0.0
			_on_burst()
	if _vfx.has_method("tick"):
		_vfx.call("tick", delta)
	if _status_readout != null:
		var count: String = "--"
		var life: String = "--"
		if _vfx.has_method("get_particle_count"):
			count = str(_vfx.call("get_particle_count"))
		if _vfx.has_method("get_particle_lifetime"):
			life = str(_vfx.call("get_particle_lifetime"))
		_status_readout.text = "particles: %s  lifetime: %s" % [count, life]