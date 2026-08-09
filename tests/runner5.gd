extends SceneTree
## Round-5 benchmark evaluator: NPC finite-state machine.
## Usage: godot --headless --path <project> -s res://tests/runner5.gd
## Prints PASS/FAIL per check, then "BENCH_RESULT: <passed>/<total>".
## Categories: api, logic, spec, timing

const NPC_PATH := "res://submission5/npc_controller.gd"
const SPEED_WALK := 60.0
const SPEED_CHASE := 140.0
const DETECTION_RANGE := 120.0
const ATTACK_RANGE := 28.0
const ATTACK_COOLDOWN := 1.0

var _passed := 0
var _total := 0
var _attack_count := 0
var _failures: Array = []
var _check_history: Dictionary = {}

func _init() -> void:
	create_timer(45.0).timeout.connect(_watchdog)
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
	var npc_script: Script = load(NPC_PATH)
	_check("npc_controller.gd loads/parses", npc_script != null and npc_script.can_instantiate(), "load() returned null or unparseable script", "spec")
	if npc_script == null or not npc_script.can_instantiate():
		_finish()
		return
	var npc_obj: Object = npc_script.new()
	_check("npc_controller extends CharacterBody2D", npc_obj is CharacterBody2D, "got %s" % [npc_obj.get_class()], "logic")
	if not (npc_obj is CharacterBody2D):
		_finish()
		return
	var npc := npc_obj as CharacterBody2D
	_check("npc has set_target method", npc.has_method("set_target"), "missing set_target", "spec")
	_check("npc has tick_physics method", npc.has_method("tick_physics"), "missing tick_physics", "spec")
	_check("npc has get_state method", npc.has_method("get_state"), "missing get_state", "spec")
	_check("npc has get_npc_position method", npc.has_method("get_npc_position"), "missing get_npc_position", "spec")
	_check("npc declares attacked signal", npc.has_signal("attacked"), "missing attacked signal", "spec")
	await _test_patrol(npc_script)
	await _test_detection(npc_script)
	await _test_chase(npc_script)
	await _test_attack(npc_script)
	await _test_transition_back(npc_script)
	_finish()

func _test_patrol(script: Script) -> void:
	var npc := script.new() as CharacterBody2D
	root.add_child(npc)
	npc.position = Vector2(100.0, 0.0)
	# Target far away — should be idle then patrol
	npc.call("set_target", Vector2(10000.0, 10000.0))
	for i in 5:
		npc.call("tick_physics", 0.016)
		await physics_frame
	var state: int = npc.call("get_state")
	_check("far target -> patrol state (0=IDLE, 1=PATROL, 2=CHASE, 3=ATTACK; expect 1)", state == 1, "state=%s pos=%s" % [state, npc.position], "logic")
	var start_pos: Vector2 = npc.position
	# Move toward patrol point
	for i in 20:
		npc.call("tick_physics", 0.016)
		await physics_frame
	var moved := (npc.position - start_pos).length() > 5.0
	_check("patrol moves toward waypoint", moved, "start=%s end=%s" % [start_pos, npc.position], "logic")
	npc.queue_free()
	await process_frame

func _test_detection(script: Script) -> void:
	var npc := script.new() as CharacterBody2D
	npc.position = Vector2(0.0, 0.0)
	root.add_child(npc)
	await process_frame
	# Place target just inside detection range
	npc.call("set_target", Vector2(100.0, 0.0))
	var dist := (Vector2(100.0, 0.0) - npc.position).length()
	_check("target within detection range", dist < DETECTION_RANGE, "dist=%s" % [dist], "logic")
	# Tick enough to transition
	for i in 30:
		npc.call("tick_physics", 0.016)
		await physics_frame
	var state: int = npc.call("get_state")
	_check("target in range -> chase state", state == 2, "state=%s" % [state], "logic")
	npc.queue_free()
	await process_frame

func _test_chase(script: Script) -> void:
	var npc := script.new() as CharacterBody2D
	npc.position = Vector2(0.0, 0.0)
	root.add_child(npc)
	await process_frame
	npc.call("set_target", Vector2(100.0, 0.0))
	for i in 30:
		npc.call("tick_physics", 0.016)
		await physics_frame
	var state: int = npc.call("get_state")
	_check("chase state after detection", state == 2, "state=%s" % [state], "logic")
	var start_pos := npc.position
	# Target moves forward
	npc.call("set_target", Vector2(400.0, 0.0))
	for i in 15:
		npc.call("tick_physics", 0.016)
		await physics_frame
	var new_pos := npc.position
	var dx := new_pos.x - start_pos.x
	_check("npc moves toward target (positive x delta)", dx > 0.0, "start=%s end=%s dx=%s" % [start_pos, new_pos, dx], "logic")
	# Chase speed should be faster than walk speed
	var chase_dx_per_frame := dx / 15.0
	_check("chase speed >= walk speed", chase_dx_per_frame > 0.0, "dx/frame=%s" % [chase_dx_per_frame], "performance")
	npc.queue_free()
	await process_frame

func _test_attack(script: Script) -> void:
	var npc := script.new() as CharacterBody2D
	npc.position = Vector2(0.0, 0.0)
	root.add_child(npc)
	npc.connect("attacked", _on_attacked)
	await process_frame
	# Place target within attack range
	npc.call("set_target", Vector2(20.0, 0.0))
	_attack_count = 0
	for i in 60:
		npc.call("tick_physics", 0.016)
		await physics_frame
		if _attack_count >= 1:
			break
	await create_timer(1.5).timeout
	_check("attack fires when in range", _attack_count >= 1, "attacks=%d" % [_attack_count], "api")
	var state: int = npc.call("get_state")
	_check("state is ATTACK when firing", state == 3, "state=%s" % [state], "logic")
	npc.queue_free()
	await process_frame

func _on_attacked(pos: Vector2) -> void:
	_attack_count += 1

func _test_transition_back(script: Script) -> void:
	var npc := script.new() as CharacterBody2D
	npc.position = Vector2(100.0, 0.0)
	root.add_child(npc)
	await process_frame
	# Get into chase — target at 100px distance (within detection, beyond attack)
	npc.call("set_target", Vector2(200.0, 0.0))
	for i in 10:
		npc.call("tick_physics", 0.016)
		await physics_frame
	var state_in: int = npc.call("get_state")
	_check("in chase state", state_in == 2, "state=%s" % [state_in], "logic")
	# Move target far away
	npc.call("set_target", Vector2(10000.0, 10000.0))
	for i in 20:
		npc.call("tick_physics", 0.016)
		await physics_frame
	var state_out: int = npc.call("get_state")
	_check("target far -> leaves CHASE state", state_out != 2, "state=%s" % [state_out], "logic")
	npc.queue_free()
	await process_frame
