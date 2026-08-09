extends SceneTree
## Round-6 benchmark evaluator: procedural character animation.
## Usage: godot --headless --path <project> -s res://tests/runner6.gd
## Prints PASS/FAIL per check, then "BENCH_RESULT: <passed>/<total>".
## Categories: api, logic, spec, timing

const ANIM_PATH := "res://submission6/char_animator.gd"

var _passed := 0
var _total := 0
var _attack_count: int = 0
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

func _run_async() -> void:
	await process_frame
	var anim_script: Script = load(ANIM_PATH)
	_check("char_animator.gd loads/parses", anim_script != null and anim_script.can_instantiate(), "load() returned null or unparseable script", "spec")
	if anim_script == null or not anim_script.can_instantiate():
		_finish()
		return
	var anim: Node2D = anim_script.new() as Node2D
	_check("char_animator extends Node2D", anim is Node2D, "got %s" % [anim.get_class()], "logic")
	if not (anim is Node2D):
		_finish()
		return
	_check("has tick_animation", anim.has_method("tick_animation"), "missing tick_animation", "spec")
	_check("has set_moving", anim.has_method("set_moving"), "missing set_moving", "spec")
	_check("has trigger_attack", anim.has_method("trigger_attack"), "missing trigger_attack", "spec")
	_check("has get_body_scale", anim.has_method("get_body_scale"), "missing get_body_scale", "spec")
	_check("has get_body_offset", anim.has_method("get_body_offset"), "missing get_body_offset", "spec")
	_check("has get_eye_offset", anim.has_method("get_eye_offset"), "missing get_eye_offset", "spec")
	_check("declares attacked signal", anim.has_signal("attacked"), "missing attacked signal", "spec")
	await _test_idle_breath(anim_script)
	await _test_walk_bobble(anim_script)
	await _test_attack_lunge(anim_script)
	_finish()

func _approx(a: float, b: float, eps: float = 0.01) -> bool:
	return absf(a - b) <= eps

func _test_idle_breath(script: Script) -> void:
	var anim := script.new() as Node2D
	root.add_child(anim)
	anim.call("set_moving", false)
	await process_frame
	# Run for over one full breath cycle (BREATH_SPEED = 2.5s)
	for i in 180:
		anim.call("tick_animation", 0.016)
		await physics_frame
	var scale: Vector2 = anim.call("get_body_scale")
	# Breath swells scale above 1.0 at some point — check that it has varied
	# At minimum, the scale should have changed from default (1.0, 1.0)
	var base_scale: Vector2 = Vector2(1.0, 1.0)
	var scale_changed := absf(scale.x - base_scale.x) > 0.001 or absf(scale.y - base_scale.x) > 0.001
	if not scale_changed:
		# Try running more — check that at some point during the cycle scale > 1
		# Re-run and sample in the middle
		var anim2 := script.new() as Node2D
		root.add_child(anim2)
		anim2.call("set_moving", false)
		await process_frame
		var max_scale_x: float = 0.0
		for i in 180:
			anim2.call("tick_animation", 0.016)
			await physics_frame
			var s: Vector2 = anim2.call("get_body_scale")
			if s.x > max_scale_x:
				max_scale_x = s.x
		_check("idle breath scales body above 1.0 (swell)", max_scale_x > 1.01, "max_x=%s" % [max_scale_x], "logic")
		anim2.queue_free()
		await process_frame
	else:
		_check("idle breath scales body above 1.0 (swell)", scale.x > 1.0 or scale.y > 1.0, "scale=%s" % [scale], "logic")
	# Eyes should be neutral (0.0) when idle
	var eye: float = anim.call("get_eye_offset")
	_check("idle eyes are neutral (~0)", absf(eye) < 0.1, "eye=%s" % [eye], "logic")
	anim.queue_free()
	await process_frame

func _test_walk_bobble(script: Script) -> void:
	var anim := script.new() as Node2D
	root.add_child(anim)
	anim.call("set_moving", true)
	await process_frame
	var offsets: Array[float] = []
	for i in 60:
		anim.call("tick_animation", 0.016)
		await physics_frame
		var off: Vector2 = anim.call("get_body_offset")
		offsets.append(off.y)
	var min_y: float = offsets.min() if offsets.size() > 0 else 0.0
	var max_y: float = offsets.max() if offsets.size() > 0 else 0.0
	_check("walk bobble produces vertical movement range", (max_y - min_y) > 2.0,
		"min=%s max=%s range=%s" % [min_y, max_y, max_y - min_y], "logic")
	var eye: float = anim.call("get_eye_offset")
	_check("walk eyes look in movement direction (|eye| > 0)", absf(eye) > 0.0, "eye=%s" % [eye], "logic")
	anim.queue_free()
	await process_frame

func _test_attack_lunge(script: Script) -> void:
	var anim := script.new() as Node2D
	root.add_child(anim)
	anim.connect("attacked", Callable(self, "_on_attacked"))
	_attack_count = 0
	anim.call("set_moving", false)
	await process_frame
	anim.call("trigger_attack")
	# During lunge, body should shift horizontally
	var max_shift: float = 0.0
	var shifted := false
	for i in 30:
		anim.call("tick_animation", 0.016)
		await physics_frame
		var off: Vector2 = anim.call("get_body_offset")
		var shift := absf(off.x)
		if shift > max_shift:
			max_shift = shift
		if shift > 1.0:
			shifted = true
	_check("lunge produces horizontal body shift", shifted, "max_shift=%s" % [max_shift], "logic")
	_check("attacked signal fired", _attack_count >= 1, "count=%d" % [_attack_count], "api")
	# After lunge completes, should snap back
	for i in 30:
		anim.call("tick_animation", 0.016)
		await physics_frame
	var post_off: Vector2 = anim.call("get_body_offset")
	_check("body returns near origin after lunge", absf(post_off.x) < 2.0 and absf(post_off.y) < 2.0,
		"off=%s" % [post_off], "logic")
	anim.queue_free()
	await process_frame

func _on_attacked() -> void:
	_attack_count += 1
