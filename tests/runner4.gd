extends SceneTree
## Round-4 benchmark evaluator: HUD / juice UI panel.
## Usage: godot --headless --path <project> -s res://tests/runner4.gd
## Prints PASS/FAIL per check, then "BENCH_RESULT: <passed>/<total>".
## Categories: api, logic, spec, style, timing, performance, structure

const HUD_PATH := "res://submission4/juice_hud.gd"
const SPARKLE_PATH := "res://submission4/hud_sparkle.gd"

var _passed := 0
var _total := 0
var _failures: Array = []  # Store {name, category, detail} for each failure

# For non-determinism detection: track check name -> pass/fail history
var _check_history: Dictionary = {}

func _init() -> void:
	create_timer(30.0).timeout.connect(_watchdog)
	_run_async()

func _watchdog() -> void:
	print("BENCH_TIMEOUT")
	quit(2)

func _check(name: String, ok: bool, detail: String = "", category: String = "") -> void:
	_total += 1
	# Track for non-determinism detection
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

func _finish() -> void:
	print("BENCH_RESULT: %d/%d" % [_passed, _total])
	# Output failure breakdown by category
	if _failures.size() > 0:
		print("---FAILURES---")
		for f in _failures:
			print("FAIL_CAT  %s  --  %s  --  %s" % [f.category, f.name, f.detail])
		# Category summary
		var cats: Dictionary = {}
		for f in _failures:
			cats[f.category] = cats.get(f.category, 0) + 1
		print("---FAILURE_CATEGORIES---")
		for cat in cats:
			print("FAIL_CAT_SUMMARY  %s: %d" % [cat, cats[cat]])
	# Non-determinism report
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

func _extract_int(s: String) -> int:
	var m := RegEx.new()
	m.compile("[0-9]+")
	var r := m.search(s)
	if r:
		return int(r.get_string())
	return -1

func _run_async() -> void:
	await process_frame
	var hud_script: Script = load(HUD_PATH)
	_check("juice_hud.gd loads/parses", hud_script != null and hud_script.can_instantiate(), "load() returned null or unparseable script", "spec")
	var spark_script: Script = load(SPARKLE_PATH)
	_check("hud_sparkle.gd loads/parses", spark_script != null and spark_script.can_instantiate(), "load() returned null or unparseable script", "spec")
	if hud_script == null or spark_script == null or not hud_script.can_instantiate() or not spark_script.can_instantiate():
		_finish()
		return
	var hud: Object = hud_script.new()
	_check("juice_hud extends Control", hud is Control, "got %s" % [hud.get_class()], "logic")
	var spark: Object = spark_script.new()
	_check("hud_sparkle extends Node2D", spark is Node2D, "got %s" % [spark.get_class()], "logic")
	if not (hud is Control):
		_finish()
		return
	await _test_structure(hud_script)
	await _test_health(hud_script)
	await _test_score(hud_script)
	await _test_pulse(hud_script)
	await _test_button(hud_script)
	await _test_sparkle(spark_script)
	_finish()

func _test_structure(hud_script: Script) -> void:
	var hud := hud_script.new() as Control
	root.add_child(hud)
	await process_frame
	await process_frame
	var hb := hud.get_node_or_null("HealthBar")
	var ghost := hud.get_node_or_null("GhostBar")
	var label := hud.get_node_or_null("ScoreLabel")
	var btn := hud.get_node_or_null("JuiceButton")
	_check("HealthBar is ProgressBar", hb is ProgressBar, "got %s" % [hb.get_class() if hb else "null"], "structure")
	_check("GhostBar is ProgressBar", ghost is ProgressBar, "got %s" % [ghost.get_class() if ghost else "null"], "structure")
	_check("ScoreLabel is Label", label is Label, "got %s" % [label.get_class() if label else "null"], "structure")
	_check("JuiceButton is Button", btn is Button, "got %s" % [btn.get_class() if btn else "null"], "structure")
	_check("button text == 'Press Me'", btn != null and btn.text == "Press Me", "got %s" % [btn.text if btn else "null"], "spec")
	if hb is ProgressBar and ghost is ProgressBar:
		var a := hb as ProgressBar
		var b := ghost as ProgressBar
		_check("ghost overlaps health bar (same position+size)",
			a.position == b.position and a.size == b.size,
			"a=%s/%s b=%s/%s" % [a.position, a.size, b.position, b.size])
	hud.queue_free()
	await process_frame

func _test_health(hud_script: Script) -> void:
	var hud := hud_script.new() as Control
	root.add_child(hud)
	await process_frame
	# Use duck typing
	_check("get_health() == 0.0", hud.call("get_health") == 0.0, "got %s" % [hud.call("get_health")], "logic")
	_check("get_score() == 0", hud.call("get_score") == 0, "got %s" % [hud.call("get_score")], "logic")
	hud.call("set_health", 50.0)
	var hb := hud.get_node("HealthBar") as ProgressBar
	_check("set_health(50) live bar == 50", hb != null and hb.value == 50.0, "got %s" % [hb.value if hb else "null"], "logic")
	hud.call("set_health", 150.0)
	hb = hud.get_node("HealthBar") as ProgressBar
	_check("set_health(150) clamped to 100", hb != null and hb.value == 100.0, "got %s" % [hb.value if hb else "null"], "logic")
	hud.call("set_health", -10.0)
	hb = hud.get_node("HealthBar") as ProgressBar
	_check("set_health(-10) clamped to 0", hb != null and hb.value == 0.0, "got %s" % [hb.value if hb else "null"], "logic")
	# Ghost should NOT jump instantly
	hud.call("set_health", 80.0)
	var ghost := hud.get_node("GhostBar") as ProgressBar
	var ghost_immediate: float = ghost.value if ghost else -1.0
	await create_timer(0.05).timeout
	var ghost_after: float = ghost.value if ghost else -1.0
	_check("ghost lags behind live bar (not instant)", ghost_immediate != 80.0 or ghost_after < 80.0,
		"immediate=%s after=%s" % [ghost_immediate, ghost_after], "timing")
	await create_timer(0.5).timeout
	ghost = hud.get_node("GhostBar") as ProgressBar
	_check("ghost reaches target after delay", ghost != null and ghost.value >= 78.0, "got %s" % [ghost.value if ghost else "null"], "timing")
	hud.queue_free()
	await process_frame

func _test_score(hud_script: Script) -> void:
	var hud := hud_script.new() as Control
	root.add_child(hud)
	await process_frame
	hud.call("add_score", 150)
	await create_timer(0.1).timeout
	var label := hud.get_node("ScoreLabel") as Label
	var text: String = label.text if label else "ERR"
	var n: int = _extract_int(text)
	_check("score label started counting toward 150", n >= 0, "text=%s n=%s" % [text, n], "timing")
	await create_timer(1.0).timeout
	label = hud.get_node("ScoreLabel") as Label
	n = _extract_int(label.text)
	_check("score label reaches 150 after tween", n == 150, "got %s (text=%s)" % [n, label.text], "timing")
	hud.call("add_score", 50)
	await create_timer(1.0).timeout
	label = hud.get_node("ScoreLabel") as Label
	n = _extract_int(label.text)
	_check("score continues from 150 to 200", n == 200, "got %s" % [n], "timing")
	hud.queue_free()
	await process_frame

func _test_pulse(hud_script: Script) -> void:
	var hud := hud_script.new() as Control
	root.add_child(hud)
	await process_frame
	var start_scale: Vector2 = hud.scale
	hud.call("pulse")
	await create_timer(0.05).timeout
	var mid_scale: Vector2 = hud.scale
	_check("pulse scales up (>1.0)", mid_scale.x > 1.0, "mid=%s" % [mid_scale], "logic")
	await create_timer(0.4).timeout
	var end_scale: Vector2 = hud.scale
	_check("pulse returns to ~1.0 after completion", end_scale.x >= 0.98 and end_scale.x <= 1.02, "end=%s" % [end_scale], "timing")
	hud.queue_free()
	await process_frame

func _test_button(hud_script: Script) -> void:
	var hud := hud_script.new() as Control
	root.add_child(hud)
	await process_frame
	var btn := hud.get_node("JuiceButton") as Button
	if btn == null:
		_check("button hover juice", false, "no button")
		hud.queue_free()
		await process_frame
		return
	var start_scale: Vector2 = btn.scale
	btn.emit_signal("mouse_entered")
	await create_timer(0.15).timeout
	var entered_scale: Vector2 = btn.scale
	_check("button scales up on mouse_entered", entered_scale.x > start_scale.x,
		"start=%s entered=%s" % [start_scale, entered_scale], "api")
	btn.emit_signal("mouse_exited")
	await create_timer(0.15).timeout
	var exited_scale: Vector2 = btn.scale
	_check("button scales back down on mouse_exited", exited_scale.x < entered_scale.x,
		"entered=%s exited=%s" % [entered_scale, exited_scale], "api")
	hud.queue_free()
	await process_frame

func _test_sparkle(spark_script: Script) -> void:
	var spark := spark_script.new() as Node2D
	root.add_child(spark)
	_check("sparkle has _draw", spark.has_method("_draw"), "missing _draw", "spec")
	_check("sparkle has _process", spark.has_method("_process"), "missing _process", "spec")
	_check("sparkle has set_color", spark.has_method("set_color"), "missing set_color", "spec")
	await create_timer(0.6).timeout
	var spark_id = spark.get_instance_id() if is_instance_valid(spark) else 0
	_check("sparkle auto-frees after lifetime", spark_id == 0 or not is_instance_id_valid(spark_id),
		"still alive", "logic")
