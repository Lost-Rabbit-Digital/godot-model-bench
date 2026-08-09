extends SceneTree
## Round-7 benchmark evaluator: particle/VFX burst.
## Usage: godot --headless --path <project> -s res://tests/runner7.gd
## Prints PASS/FAIL per check, then "BENCH_RESULT: <passed>/<total>".
## Categories: api, logic, spec, timing

const VFX_PATH := "res://submission7/spell_vfx.gd"

var _passed := 0
var _total := 0
var _failures: Array = []
var _check_history: Dictionary = {}

func _init() -> void:
	create_timer(40.0).timeout.connect(_watchdog)
	_run_async()

func _watchdog() -> void:
	print("BENCH_TIMEOUT")
	quit(2)

func _check(name: String, ok: bool, detail: String = "", category: String = "") -> void:
	_total += 1
	if not _check_history.has(name):
		_check_history[name] = []
	_check_history[name].append(ok)
	if ok:
		_passed += 1
		print("PASS  " + name + ("  [" + category + "]" if category != "" else ""))
	else:
		var msg := name
		if detail:
			msg += "  --  " + detail
		print("FAIL  " + msg + ("  [" + category + "]" if category != "" else ""))
		_failures.append({"name": name, "category": category, "detail": detail})

func _finish() -> void:
	print("BENCH_RESULT: %d/%d" % [_passed, _total])
	if _failures.size() > 0:
		print("---FAILURES---")
		for f in _failures:
			print("FAIL_CAT  %s  --  %s  --  %s" % [f.category, f.name, f.detail])
		var cats: Dictionary = {}
		for f in _failures:
			cats[f.category] = cats.get(f.category, 0) + 1
		print("---FAILURE_CATEGORIES---")
		for cat in cats:
			print("FAIL_CAT_SUMMARY  %s: %d" % [cat, cats[cat]])
	var flaky: Array = []
	for name in _check_history:
		var history = _check_history[name]
		if history.size() > 1 and history.has(true) and history.has(false):
			flaky.append(name)
	if flaky.size() > 0:
		print("---NONDETERMINISTIC---")
		for name in flaky:
			print("FLAKY  %s" % [name])
	quit(0 if _passed == _total else 1)

func _approx(a: float, b: float, eps: float = 0.01) -> bool:
	return absf(a - b) <= eps

func _run_async() -> void:
	await process_frame
	var vfx_script: Script = load(VFX_PATH)
	_check("spell_vfx.gd loads/parses", vfx_script != null and vfx_script.can_instantiate(), "load() returned null or unparseable script", "spec")
	if vfx_script == null or not vfx_script.can_instantiate():
		_finish()
		return
	var vfx: Object = vfx_script.new()
	_check("spell_vfx extends Node2D", vfx is Node2D, "got %s" % [vfx.get_class()], "logic")
	if not (vfx is Node2D):
		_finish()
		return
	_check("has burst", vfx.has_method("burst"), "missing burst", "spec")
	_check("has get_particle_count", vfx.has_method("get_particle_count"), "missing get_particle_count", "spec")
	_check("has get_particle_lifetime", vfx.has_method("get_particle_lifetime"), "missing get_particle_lifetime", "spec")
	_check("has get_flash_intensity", vfx.has_method("get_flash_intensity"), "missing get_flash_intensity", "spec")
	_check("has is_finished", vfx.has_method("is_finished"), "missing is_finished", "spec")
	_check("has get_particle_node", vfx.has_method("get_particle_node"), "missing get_particle_node", "spec")
	_check("has tick", vfx.has_method("tick"), "missing tick", "spec")
	await _test_particles(vfx_script)
	await _test_flash(vfx_script)
	await _test_lifecycle(vfx_script)
	_finish()

func _test_particles(script: Script) -> void:
	var vfx_obj := script.new() as Node2D
	root.add_child(vfx_obj)
	await process_frame
	var pnode_obj: Object = vfx_obj.call("get_particle_node")
	_check("has CPUParticles2D child", pnode_obj is CPUParticles2D, "got %s" % [pnode_obj.get_class() if pnode_obj else "null"], "structure")
	if pnode_obj is not CPUParticles2D:
		vfx_obj.queue_free()
		await process_frame
		return
	var pp := pnode_obj as CPUParticles2D
	_check("particle amount == 32", pp.amount == 32, "got %s" % [pp.amount], "logic")
	_check("particle lifetime == 0.6", _approx(pp.lifetime, 0.6, 0.01), "got %s" % [pp.lifetime], "logic")
	_check("one_shot == true", pp.one_shot == true, "got %s" % [pp.one_shot], "logic")
	_check("texture is not null", pp.texture != null, "null texture", "api")
	_check("particles have get_particle_material method", vfx_obj.has_method("get_particle_material"), "missing method", "spec")
	# Duck-type the material via get()
	var mat: Object = vfx_obj.call("get_particle_material")
	_check("process_material exists", mat != null, "got null", "logic")
	if mat != null:
		var mclass: String = mat.get_class()
		_check("process_material is ParticleProcessMaterial", mclass == "ParticleProcessMaterial", "got %s" % [mclass], "logic")
		# scale is Vector2 on this engine build (ParticleProcessMaterial)
		var scale_raw = mat.get("scale")
		var scale_val: float = 0.0
		if scale_raw is float:
			scale_val = scale_raw as float
		elif scale_raw is Vector2:
			scale_val = (scale_raw as Vector2).x
		_check("particle scale ~ 4", absf(scale_val - 4.0) < 1.0, "got %s" % [scale_val], "logic")
		var vel_raw = mat.get("initial_velocity")
		var vel: float = 0.0
		if vel_raw is float:
			vel = vel_raw as float
		elif vel_raw is Vector2:
			vel = (vel_raw as Vector2).x
		elif vel_raw is Vector3:
			vel = (vel_raw as Vector3).x
		_check("initial_velocity ~ 120", _approx(vel, 120.0, 20.0), "got %s" % [vel], "logic")
		var spread: float = mat.get("spread") as float
		_check("spread == 360 (omnidirectional)", _approx(spread, 360.0, 1.0), "got %s" % [spread], "logic")
	_check("get_particle_count() == 32", vfx_obj.call("get_particle_count") == 32, "got %s" % [vfx_obj.call("get_particle_count")], "logic")
	_check("get_particle_lifetime() ~ 0.6", _approx(vfx_obj.call("get_particle_lifetime") as float, 0.6), "got %s" % [vfx_obj.call("get_particle_lifetime")], "logic")
	vfx_obj.queue_free()
	await process_frame

func _test_flash(script: Script) -> void:
	var vfx_obj := script.new() as Node2D
	root.add_child(vfx_obj)
	await process_frame
	var pre_obj: Variant = vfx_obj.call("get_flash_intensity")
	var pre: float = pre_obj as float
	_check("flash starts at 0 (idle)", pre < 0.01, "pre=%s" % [pre], "logic")
	vfx_obj.call("burst")
	for i in 5:
		vfx_obj.call("tick", 0.016)
		await physics_frame
	var post_obj: Variant = vfx_obj.call("get_flash_intensity")
	var post: float = post_obj as float
	_check("flash visible after burst (>0)", post > 0.0, "post=%s" % [post], "timing")
	for i in 30:
		vfx_obj.call("tick", 0.016)
		await physics_frame
	var faded_obj: Variant = vfx_obj.call("get_flash_intensity")
	var faded: float = faded_obj as float
	_check("flash fades to ~0 after duration", faded < 0.01, "faded=%s" % [faded], "timing")
	vfx_obj.queue_free()
	await process_frame

func _test_lifecycle(script: Script) -> void:
	var vfx_obj := script.new() as Node2D
	root.add_child(vfx_obj)
	await process_frame
	_check("finished=true before burst (idle)", bool(vfx_obj.call("is_finished")), "finished=%s" % [vfx_obj.call("is_finished")], "logic")
	vfx_obj.call("burst")
	await process_frame
	_check("not finished right after burst", not bool(vfx_obj.call("is_finished")), "finished=%s" % [vfx_obj.call("is_finished")], "logic")
	for i in 120:
		vfx_obj.call("tick", 0.016)
		await physics_frame
		if bool(vfx_obj.call("is_finished")):
			break
	_check("becomes finished after burst + enough ticks", bool(vfx_obj.call("is_finished")),
		"finished=%s" % [vfx_obj.call("is_finished")], "timing")
	vfx_obj.queue_free()
	await process_frame
