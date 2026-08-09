extends SceneTree
## Round-2 benchmark evaluator: greenhouse automation (scene-tree challenge).
## Usage: godot --headless --path <project> -s res://tests/runner2.gd
## Async test battery: instantiates the model's Greenhouse under the tree root and
## drives it with real timers/process frames. Prints PASS/FAIL per check, then
## "BENCH_RESULT: <passed>/<total>". Exit 0 iff all checks pass.
## Categories: api, logic, spec, timing, performance, structure

const GREENHOUSE_PATH := "res://submission2/greenhouse.gd"
const THERMOSTAT_PATH := "res://submission2/thermostat.gd"
const WATER_AMOUNT := 5.0
const HEAT_THRESHOLD := 12.0

var _passed := 0
var _total := 0
var _failures: Array = []
var _check_history: Dictionary = {}
var _watered_count := 0
var _last_watered := -1.0
var _heater_signal_count := 0
var _reports := 0

func _init() -> void:
	create_timer(90.0).timeout.connect(_watchdog)
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

func _approx(a: float, b: float, eps: float = 0.01) -> bool:
	return absf(a - b) <= eps

func _on_watered(amount: float) -> void:
	_watered_count += 1
	_last_watered = amount

func _on_heater(_on: bool) -> void:
	_heater_signal_count += 1

func _on_report(_report: Dictionary) -> void:
	_reports += 1

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
	var gh_script: Script = load(GREENHOUSE_PATH)
	_check("greenhouse.gd loads/parses", gh_script != null and gh_script.can_instantiate(), "load() returned null or unparseable script", "spec")
	var th_script: Script = load(THERMOSTAT_PATH)
	_check("thermostat.gd loads/parses", th_script != null and th_script.can_instantiate(), "load() returned null or unparseable script", "spec")
	if gh_script == null or th_script == null or not gh_script.can_instantiate() or not th_script.can_instantiate():
		_finish()
		return
	var gh_obj: Object = gh_script.new()
	_check("greenhouse extends Node2D", gh_obj is Node2D, "got %s" % [gh_obj.get_class()], "logic")
	var th_obj: Object = th_script.new()
	_check("thermostat extends Node", th_obj is Node, "got %s" % [th_obj.get_class()], "logic")
	if not (gh_obj is Node2D) or not (th_obj is Node):
		_finish()
		return
	var gh: Node2D = gh_obj as Node2D
	var th: Node = th_obj as Node
	_check("greenhouse exposes generate_report", gh.has_method("generate_report"), "missing generate_report", "spec")
	_check("greenhouse declares watered signal", gh.has_signal("watered"), "missing watered signal", "spec")
	_check("greenhouse declares report_generated signal", gh.has_signal("report_generated"), "missing report_generated signal", "spec")
	_check("thermostat exposes set_heater", th.has_method("set_heater"), "missing set_heater", "spec")
	_check("thermostat declares temperature_changed", th.has_signal("temperature_changed"), "missing temperature_changed signal", "spec")
	_check("thermostat declares heater_state_changed", th.has_signal("heater_state_changed"), "missing heater_state_changed signal", "spec")
	_check("thermostat defaults temperature 20.0", _approx(float(th.get("temperature")), 20.0, 0.001), "got %s" % [th.get("temperature")], "logic")
	await _test_tree(gh_script, th_script)
	await _test_watering(gh_script)
	await _test_heating(gh_script)
	await _test_report(gh_script)
	_finish()

func _test_tree(gh_script: Script, th_script: Script) -> void:
	var gh: Node2D = gh_script.new()
	root.add_child(gh)
	await process_frame
	await process_frame
	var thermo: Node = gh.get_node_or_null("Thermostat")
	_check("greenhouse builds Thermostat child", thermo != null, "missing 'Thermostat' node", "spec")
	var sprinkler: Node = gh.get_node_or_null("Sprinkler")
	_check("greenhouse builds Sprinkler child", sprinkler != null, "missing 'Sprinkler' node", "spec")
	if thermo != null:
		_check("Thermostat has thermostat.gd attached", thermo.get_script() == th_script, "script=%s" % [thermo.get_script()], "spec")
		# live node drifts ~0.017/2 frames; use a loose tolerance
		_check("Thermostat temperature readable", _approx(float(thermo.get("temperature")), 20.0, 0.1), "got %s" % [thermo.get("temperature")], "logic")
	if sprinkler != null:
		if sprinkler is Timer:
			var t := sprinkler as Timer
			_check("Sprinkler wait_time == 1.5", _approx(t.wait_time, 1.5, 0.01), "wait_time=%s" % [t.wait_time], "logic")
			# NOTE: Timer.autostart reads back false once the timer has started
			# (value consumed at start) — the behavioral check is is_stopped().
			# A timer whose autostart was set AFTER add_child never starts -> stopped.
			_check("Sprinkler timer is running", not t.is_stopped(), "stopped=%s" % [t.is_stopped()], "timing")
		else:
			_check("Sprinkler is a Timer", false, "got %s" % [sprinkler.get_class()], "logic")
	gh.queue_free()
	await process_frame

func _test_watering(gh_script: Script) -> void:
	var gh: Node2D = gh_script.new()
	gh.connect("watered", _on_watered)
	root.add_child(gh)
	await create_timer(2.6).timeout
	_check("watered signal fires within ~2 intervals", _watered_count >= 1, "count=%s" % [_watered_count], "timing")
	if _watered_count >= 1:
		_check("watered carries WATER_AMOUNT (5.0)", _approx(_last_watered, WATER_AMOUNT, 0.001), "got %s" % [_last_watered], "logic")
	_check("watered_total == events * WATER_AMOUNT", _approx(float(gh.get("watered_total")), float(_watered_count) * WATER_AMOUNT, 0.05), "total=%s count=%s" % [gh.get("watered_total"), _watered_count], "logic")
	_check("watered_events counter matches", int(gh.get("watered_events")) == _watered_count, "events=%s count=%s" % [gh.get("watered_events"), _watered_count], "logic")
	var before: int = _watered_count
	await create_timer(1.8).timeout
	_check("watering repeats over time", _watered_count >= before + 1, "before=%s after=%s" % [before, _watered_count], "timing")
	gh.queue_free()
	await process_frame
	_watered_count = 0
	_last_watered = -1.0

func _test_heating(gh_script: Script) -> void:
	var gh: Node2D = gh_script.new()
	root.add_child(gh)
	await process_frame
	var thermo: Node = gh.get_node_or_null("Thermostat")
	if thermo == null:
		_check("heater logic needs a Thermostat child", false, "missing Thermostat", "logic")
		gh.queue_free()
		await process_frame
		return
	thermo.connect("heater_state_changed", _on_heater)
	thermo.set("temperature", 5.0)
	await create_timer(1.0).timeout
	_check("heater turns ON below 12.0 threshold", bool(thermo.get("heater_on")), "heater_on=%s temp=%s" % [thermo.get("heater_on"), thermo.get("temperature")], "timing")
	_check("heater_state_changed signal emitted", _heater_signal_count >= 1, "count=%s" % [_heater_signal_count], "spec")
	var t1: float = float(thermo.get("temperature"))
	await create_timer(0.6).timeout
	var t2: float = float(thermo.get("temperature"))
	_check("temperature RISES while heating", t2 > t1 + 0.2, "t1=%s t2=%s" % [t1, t2], "timing")
	thermo.set("temperature", 30.0)
	await create_timer(1.0).timeout
	_check("heater turns OFF at/above threshold", not bool(thermo.get("heater_on")), "heater_on=%s temp=%s" % [thermo.get("heater_on"), thermo.get("temperature")], "timing")
	var t3: float = float(thermo.get("temperature"))
	await create_timer(0.6).timeout
	var t4: float = float(thermo.get("temperature"))
	_check("temperature FALLS while heater off", t4 < t3 - 0.1, "t3=%s t4=%s" % [t3, t4], "timing")
	gh.queue_free()
	await process_frame
	_heater_signal_count = 0

func _test_report(gh_script: Script) -> void:
	var gh: Node2D = gh_script.new()
	root.add_child(gh)
	await process_frame
	gh.connect("report_generated", _on_report)
	var r: Variant = gh.call("generate_report")
	_check("generate_report returns a Dictionary", r is Dictionary, "got %s" % [r], "logic")
	var rep: Dictionary = r if r is Dictionary else {}
	_check("report has all four keys", rep.has("moisture") and rep.has("temperature") and rep.has("heater_on") and rep.has("watered_events"), "keys=%s" % [rep.keys()], "spec")
	var thermo: Node = gh.get_node_or_null("Thermostat")
	if thermo != null:
		_check("report.moisture == watered_total", _approx(float(rep.get("moisture", -1.0)), float(gh.get("watered_total")), 0.001), "rep=%s live=%s" % [rep.get("moisture"), gh.get("watered_total")], "logic")
		_check("report.temperature == thermostat.temperature", _approx(float(rep.get("temperature", -999.0)), float(thermo.get("temperature")), 0.001), "rep=%s live=%s" % [rep.get("temperature"), thermo.get("temperature")], "logic")
		_check("report.heater_on == thermostat.heater_on", bool(rep.get("heater_on", false)) == bool(thermo.get("heater_on")), "rep=%s live=%s" % [rep.get("heater_on"), thermo.get("heater_on")], "logic")
	_check("fresh greenhouse reports watered_events == 0", int(rep.get("watered_events", -1)) == 0, "events=%s" % [rep.get("watered_events")], "logic")
	_check("report_generated signal emitted", _reports >= 1, "count=%s" % [_reports], "spec")
	gh.queue_free()
	await process_frame
	_reports = 0
