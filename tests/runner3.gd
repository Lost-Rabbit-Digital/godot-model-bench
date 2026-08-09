extends SceneTree
## Round-3 benchmark evaluator: Pegboard Plinko physics simulation.
## Headless eval: instantiates the model's Pegboard, runs physics for ~5.5s,
## checks structure, ball behaviour, and the seamless loop.
## Categories: api, logic, spec, timing, performance, structure

const PEGBOARD_PATH := "res://submission3/pegboard.gd"
const BOUNCY_BALL_PATH := "res://submission3/bouncy_ball.gd"
const BALL_COUNT := 200
const PEG_COUNT := 20
const LOOP_Y := 640.0

var _passed := 0
var _total := 0
var _failures: Array = []
var _check_history: Dictionary = {}
var _recycled := 0

func _init() -> void:
	create_timer(120.0).timeout.connect(_watchdog)
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
		if detail != "":
			msg += "  --  " + detail
		print("FAIL  " + msg + ("  [" + category + "]" if category != "" else ""))
		_failures.append({"name": name, "category": category, "detail": detail})

func _approx(a: float, b: float, eps: float = 0.5) -> bool:
	return absf(a - b) <= eps

func _on_recycled(_id: int) -> void:
	_recycled += 1

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
	var peg_script: Script = load(PEGBOARD_PATH)
	_check("pegboard.gd loads/parses", peg_script != null and peg_script.can_instantiate(), "load failed or unparseable", "spec")
	var ball_script: Script = load(BOUNCY_BALL_PATH)
	_check("bouncy_ball.gd loads/parses", ball_script != null and ball_script.can_instantiate(), "load failed or unparseable", "spec")
	if peg_script == null or ball_script == null or not peg_script.can_instantiate() or not ball_script.can_instantiate():
		_finish()
		return
	var peg_obj: Object = peg_script.new()
	_check("pegboard extends Node2D", peg_obj is Node2D, "got %s" % [peg_obj.get_class()], "logic")
	var ball_obj: Object = ball_script.new()
	_check("bouncy_ball extends RigidBody2D", ball_obj is RigidBody2D, "got %s" % [ball_obj.get_class()], "logic")
	if not (peg_obj is Node2D) or not (ball_obj is RigidBody2D):
		_finish()
		return
	var peg: Node2D = peg_obj as Node2D
	_check("pegboard declares ball_recycled signal", peg.has_signal("ball_recycled"), "missing signal", "spec")
	# Structure
	await _test_structure(peg_script, ball_script)
	# Physics & seamless loop
	await _test_physics(peg_script)
	_finish()

func _test_structure(peg_script: Script, ball_script: Script) -> void:
	var peg: Node2D = peg_script.new()
	root.add_child(peg)
	for i in range(3):
		await physics_frame
	# Count children
	var ridged: Array[Node] = []
	var static_bodies: Array[Node] = []
	for child in peg.get_children():
		if child is RigidBody2D:
			ridged.append(child)
		if child is StaticBody2D:
			static_bodies.append(child)
	_check("200 RigidBody2D balls", ridged.size() == BALL_COUNT, "count=%s" % [ridged.size()], "logic")
	_check("20 StaticBody2D pegs", static_bodies.size() == PEG_COUNT, "count=%s" % [static_bodies.size()], "logic")
	# Ball shapes
	var balls_missing_shape := 0
	var ball_shape_ok := 0
	for b in ridged:
		var shape_node: CollisionShape2D = null
		for bc in b.get_children():
			if bc is CollisionShape2D:
				shape_node = bc as CollisionShape2D
				break
		if shape_node == null:
			balls_missing_shape += 1
		elif shape_node.shape is CircleShape2D:
			var cr: float = (shape_node.shape as CircleShape2D).radius
			if _approx(cr, 4.0, 0.5):
				ball_shape_ok += 1
	_check("all balls have CollisionShape2D", balls_missing_shape == 0, "missing=%s" % [balls_missing_shape], "logic")
	_check("ball shapes are CircleShape2D radius ~4", ball_shape_ok >= mini(10, ridged.size()), "ok=%s total=%s" % [ball_shape_ok, ridged.size()], "logic")
	# Peg shapes
	var peg_shape_ok := 0
	for p in static_bodies:
		var shape_node: CollisionShape2D = null
		for pc in p.get_children():
			if pc is CollisionShape2D:
				shape_node = pc as CollisionShape2D
				break
		if shape_node != null and shape_node.shape is CircleShape2D:
			var pr: float = (shape_node.shape as CircleShape2D).radius
			if _approx(pr, 8.0, 0.5):
				peg_shape_ok += 1
	_check("pegs are CircleShape2D radius ~8", peg_shape_ok == PEG_COUNT, "ok=%s total=%s" % [peg_shape_ok, PEG_COUNT], "logic")
	# Bounce material
	var bounce_ok := 0
	for b in ridged:
		if b is RigidBody2D:
			var rb: RigidBody2D = b as RigidBody2D
			if rb.physics_material_override != null and rb.physics_material_override.bounce >= 0.79:
				bounce_ok += 1
	_check("balls have bouncy physics_material (bounce >= 0.8)", bounce_ok >= mini(10, ridged.size()), "ok=%s" % [bounce_ok], "logic")
	peg.queue_free()
	await process_frame

func _test_physics(peg_script: Script) -> void:
	var peg: Node2D = peg_script.new()
	root.add_child(peg)
	peg.connect("ball_recycled", _on_recycled)
	for i in range(3):
		await physics_frame
	# Record initial positions
	var initial_ys: Array[float] = []
	var initial_xs: Array[float] = []
	for child in peg.get_children():
		if child is RigidBody2D:
			initial_ys.append(child.global_position.y)
			initial_xs.append(child.global_position.x)
	if initial_ys.size() == 0:
		_check("balls exist for physics test", false, "no RigidBody2D children found", "logic")
		peg.queue_free()
		await process_frame
		return
	var mean_y_init: float = _mean(initial_ys)
	# Wait for balls to fall
	await create_timer(1.2).timeout
	var ys1: Array[float] = []
	for child in peg.get_children():
		if child is RigidBody2D:
			ys1.append(child.global_position.y)
	var mean_y1: float = _mean(ys1)
	_check("balls fall under gravity (mean y increased)", mean_y1 > mean_y_init + 30.0, "init_y=%.1f after_y=%.1f" % [mean_y_init, mean_y1], "physics")
	# Check deflection (peg collisions spread x positions)
	await create_timer(1.3).timeout  # total ~2.5s
	# Balls loop back to the top over time, so instead of tracking individual
	# spawn x positions, measure the x-range of balls currently in the board:
	# a working Galton board scatters them far wider than the ~44px spawn grid.
	var xs_now: Array[float] = []
	for child in peg.get_children():
		if child is RigidBody2D and child.global_position.y < LOOP_Y - 50:
			xs_now.append(child.global_position.x)
	if xs_now.size() >= 20:
		var x_range: float = xs_now.max() - xs_now.min()
		_check("balls spread horizontally from pegs (x-range > 120)", x_range > 120.0, "range=%.1f samples=%d" % [x_range, xs_now.size()], "physics")
	else:
		_check("balls spread horizontally from pegs (x-range > 120)", false, "too few in-bounds samples=%d" % [xs_now.size()], "logic")
	# Seamless loop: wait for recycling
	await create_timer(3.0).timeout  # total ~5.5s
	_check("loop recycled balls (signal fired)", _recycled >= 50, "recycled=%s" % [_recycled], "spec")
	_check("ball count still 200 after loop", _count_balls(peg) == BALL_COUNT, "count=%s" % [_count_balls(peg)], "timing")
	var stuck := 0
	for child in peg.get_children():
		if child is RigidBody2D and child.global_position.y > LOOP_Y + 20:
			stuck += 1
	_check("no balls stuck below LOOP_Y", stuck == 0, "stuck=%s" % [stuck], "timing")
	peg.queue_free()
	await process_frame
	_recycled = 0

func _mean(arr: Array[float]) -> float:
	if arr.size() == 0:
		return 0.0
	var s: float = 0.0
	for v in arr:
		s += v
	return s / float(arr.size())

func _count_balls(node: Node2D) -> int:
	var n := 0
	for c in node.get_children():
		if c is RigidBody2D:
			n += 1
	return n
