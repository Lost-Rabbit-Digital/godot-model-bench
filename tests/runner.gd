extends SceneTree
## Headless benchmark evaluator for the Godot Model Bench challenge.
## Usage: godot --headless --path <project> -s res://tests/runner.gd
## Prints one PASS/FAIL line per check, then "BENCH_RESULT: <passed>/<total>".
## Exit code 0 iff all checks pass.
## Categories: api, logic, spec, timing, performance, structure

const BEEHIVE_PATH := "res://submission/beehive.gd"
const HONEY_MATH_PATH := "res://submission/honey_math.gd"
const DAYS_PER_YEAR := 360
const BASE_RATE := 0.5

var _passed := 0
var _total := 0
var _failures: Array = []
var _check_history: Dictionary = {}

func _init() -> void:
	_run()
	print("BENCH_RESULT: %d/%d" % [_passed, _total])
	# Failure breakdown
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

func _approx(a: float, b: float, eps: float = 0.001) -> bool:
	return absf(a - b) <= eps

# Reference implementation of the spec formulas
func _ref_season(d: int) -> float:
	return 0.6 + 0.4 * cos(float(posmod(d, DAYS_PER_YEAR)) / float(DAYS_PER_YEAR) * TAU)

func _ref_production(hive: Object, day: int) -> float:
	var up: Dictionary = hive.get("upgrades")
	var frames: float = float(int(up.get("frames", 0)))
	var body: float = float(int(up.get("hive_body", 0)))
	var rj: bool = bool(up.get("royal_jelly", false))
	var mult: float = (1.0 + 0.25 * frames) * (1.0 + 0.5 * body) * (1.5 if rj else 1.0)
	return BASE_RATE * float(int(hive.get("workers"))) * mult * _ref_season(day)

func _new_hive(script: Script, workers: int = 3) -> Object:
	# Pass worker_count to the constructor so the model's clamping logic runs
	return script.new(workers)

func _missing_api(script: Script, required: Array) -> Array:
	var inst: Object = script.new()
	var missing: Array = []
	for r in required:
		if not inst.has_method(String(r)):
			missing.append(r)
	return missing

func _run() -> void:
	var beehive_script: Script = load(BEEHIVE_PATH)
	_check("beehive.gd loads/parses", beehive_script != null and beehive_script.can_instantiate(), "load() returned null or unparseable script", "spec")
	var math_script: Script = load(HONEY_MATH_PATH)
	_check("honey_math.gd loads/parses", math_script != null and math_script.can_instantiate(), "load() returned null or unparseable script", "spec")
	if beehive_script == null or math_script == null or not beehive_script.can_instantiate() or not math_script.can_instantiate():
		return
	var missing_b: Array = _missing_api(beehive_script, ["tick", "harvest", "buy_upgrade", "daily_production", "season_factor"])
	_check("beehive.gd exposes required API", missing_b.is_empty(), "missing: %s" % [missing_b], "spec")
	var missing_m: Array = _missing_api(math_script, ["bottles_for", "jar_price", "short_label"])
	_check("honey_math.gd exposes required API", missing_m.is_empty(), "missing: %s" % [missing_m], "spec")
	if not missing_b.is_empty() or not missing_m.is_empty():
		return
	_test_defaults(beehive_script)
	_test_season(beehive_script)
	_test_production(beehive_script)
	_test_tick(beehive_script)
	_test_harvest(beehive_script)
	_test_upgrades(beehive_script)
	_test_math(math_script)

func _test_defaults(script: Script) -> void:
	var h: Object = _new_hive(script)
	_check("defaults: workers == 3", int(h.get("workers")) == 3, "workers=%s" % [h.get("workers")], "logic")
	_check("defaults: honey == 0.0", float(h.get("honey")) == 0.0, "honey=%s" % [h.get("honey")], "logic")
	var up: Dictionary = h.get("upgrades")
	_check("defaults: upgrade keys present", up.has("frames") and up.has("hive_body") and up.has("royal_jelly"), "keys=%s" % [up.keys()], "logic")
	_check("defaults: upgrade values", int(up.get("frames", -1)) == 0 and int(up.get("hive_body", -1)) == 0 and bool(up.get("royal_jelly", true)) == false, "upgrades=%s" % [up])

func _test_season(script: Script) -> void:
	var f: Variant = script.call("season_factor", 0)
	_check("season_factor(0) == 1.0 (spring peak)", _approx(float(f), 1.0, 0.001), "got %s" % [f], "logic")
	f = script.call("season_factor", 180)
	_check("season_factor(180) == 0.2 (winter trough)", _approx(float(f), 0.2, 0.001), "got %s" % [f], "logic")
	f = script.call("season_factor", -90)
	var g: Variant = script.call("season_factor", 270)
	_check("season_factor wraps negatives (-90 == 270)", _approx(float(f), float(g), 0.0001), "got %s vs %s" % [f, g], "logic")

func _test_production(script: Script) -> void:
	var h: Object = _new_hive(script)
	var d: Variant = h.call("daily_production", 0)
	_check("daily_production(0) == 1.5 (3 workers, peak)", _approx(float(d), 1.5, 0.001), "got %s" % [d], "logic")
	var h2: Object = _new_hive(script, 10)
	d = h2.call("daily_production", 180)
	_check("10 workers midwinter: 0.5*10*1*1*0.2 == 1.0", _approx(float(d), 1.0, 0.001), "got %s" % [d], "logic")
	var h3: Object = _new_hive(script, -2)
	_check("negative workers clamp to 0", int(h3.get("workers")) == 0, "workers=%s" % [h3.get("workers")], "logic")

func _test_tick(script: Script) -> void:
	var h: Object = _new_hive(script)
	var r: Dictionary = h.call("tick", 1)
	_check("tick(1): honey == 1.5", _approx(float(h.get("honey")), 1.5, 0.001), "honey=%s" % [h.get("honey")], "logic")
	_check("tick() returns honey/produced/day keys", r.has("honey") and r.has("produced") and r.has("day"), "keys=%s" % [r.keys()], "logic")
	_check("tick(1): produced == 1.5", _approx(float(r.get("produced", -1.0)), 1.5, 0.001), "produced=%s" % [r.get("produced")], "logic")
	_check("tick(1): day == 1", int(r.get("day", -1)) == 1, "day=%s" % [r.get("day")], "logic")

	var h2: Object = _new_hive(script)
	var expect: float = 0.0
	for day in range(10):
		expect += _ref_production(h2, day)
	h2.call("tick", 10)
	_check("tick(10) matches reference season sum", _approx(float(h2.get("honey")), expect, 0.01), "got %s want %s" % [h2.get("honey"), expect], "logic")

	var h3: Object = _new_hive(script)
	h3.call("tick", 10)
	var before: float = float(h3.get("honey"))
	h3.call("tick", 1)
	var after: float = float(h3.get("honey"))
	_check("day counter advances across tick calls", _approx(after - before, _ref_production(h3, 10), 0.01), "delta=%s want %s" % [after - before, _ref_production(h3, 10)], "logic")

	var h4: Object = _new_hive(script)
	var r4: Dictionary = h4.call("tick", 360)
	_check("tick(360): day wraps to 0", int(r4.get("day", -1)) == 0, "day=%s" % [r4.get("day")], "logic")
	_check("tick(360): produced accumulates (> 100)", float(r4.get("produced", 0.0)) > 100.0, "produced=%s" % [r4.get("produced")], "logic")

	var h5: Object = _new_hive(script)
	h5.call("tick", 7)
	var snap: float = float(h5.get("honey"))
	var r5: Dictionary = h5.call("tick", 0)
	_check("tick(0) is a no-op", _approx(float(h5.get("honey")), snap, 0.0001) and float(r5.get("produced", -1.0)) == 0.0, "honey=%s produced=%s" % [h5.get("honey"), r5.get("produced")], "logic")
	var r6: Dictionary = h5.call("tick", -5)
	_check("tick(-5) is a no-op", _approx(float(h5.get("honey")), snap, 0.0001) and float(r6.get("produced", -1.0)) == 0.0, "honey=%s produced=%s" % [h5.get("honey"), r6.get("produced")], "logic")

func _test_harvest(script: Script) -> void:
	var h: Object = _new_hive(script)
	h.call("tick", 10)
	var got: Variant = h.call("harvest")
	_check("harvest returns accumulated honey (> 0)", float(got) > 0.0, "got %s" % [got], "logic")
	_check("harvest zeroes the hive", _approx(float(h.get("honey")), 0.0, 0.0001), "honey=%s" % [h.get("honey")], "logic")
	var h2: Object = _new_hive(script)
	_check("harvest on empty hive == 0.0", float(h2.call("harvest")) == 0.0, "got %s" % [h2.call("harvest")], "logic")

func _test_upgrades(script: Script) -> void:
	var h: Object = _new_hive(script)
	var ok: Variant = h.call("buy_upgrade", "frames")
	_check("buy frames with 0 honey -> false", not bool(ok), "got %s" % [ok], "logic")
	_check("failed buy changes nothing", float(h.get("honey")) == 0.0 and int((h.get("upgrades") as Dictionary).get("frames", -1)) == 0, "honey=%s" % [h.get("honey")], "logic")

	var h2: Object = _new_hive(script)
	h2.call("tick", 360)
	var before: float = float(h2.get("honey"))
	ok = h2.call("buy_upgrade", "frames")
	_check("buy frames succeeds with honey", bool(ok), "got %s" % [ok], "logic")
	_check("frames cost (25) deducted", _approx(float(h2.get("honey")), before - 25.0, 0.01), "before=%s after=%s" % [before, h2.get("honey")], "logic")
	_check("frames level == 1", int((h2.get("upgrades") as Dictionary).get("frames", -1)) == 1, "frames=%s" % [(h2.get("upgrades") as Dictionary).get("frames")], "logic")

	var h3: Object = _new_hive(script)
	h3.call("tick", 720)
	for i in range(3):
		h3.call("buy_upgrade", "frames")
	var ok4: Variant = h3.call("buy_upgrade", "frames")
	_check("frames capped at 3, 4th buy fails", int((h3.get("upgrades") as Dictionary).get("frames", -1)) == 3 and not bool(ok4), "frames=%s ok4=%s" % [(h3.get("upgrades") as Dictionary).get("frames"), ok4], "logic")

	var h4: Object = _new_hive(script)
	h4.call("tick", 360)
	var ok5: Variant = h4.call("buy_upgrade", "nectar_brew")
	_check("unknown upgrade key -> false", not bool(ok5), "got %s" % [ok5], "logic")

	var h5: Object = _new_hive(script)
	h5.call("tick", 360)
	h5.call("buy_upgrade", "royal_jelly")
	var r: Dictionary = h5.call("tick", 1)
	_check("royal_jelly -> 1.5x production (2.25 at peak)", _approx(float(r.get("produced", 0.0)), 2.25, 0.001), "produced=%s" % [r.get("produced")], "logic")

func _test_math(script: Script) -> void:
	_check("bottles_for(249.9) == 0", int(script.call("bottles_for", 249.9)) == 0, "got %s" % [script.call("bottles_for", 249.9)], "logic")
	_check("bottles_for(250.0) == 1", int(script.call("bottles_for", 250.0)) == 1, "got %s" % [script.call("bottles_for", 250.0)], "logic")
	_check("bottles_for(1250.0) == 5", int(script.call("bottles_for", 1250.0)) == 5, "got %s" % [script.call("bottles_for", 1250.0)], "logic")
	_check("bottles_for(-10.0) == 0", int(script.call("bottles_for", -10.0)) == 0, "got %s" % [script.call("bottles_for", -10.0)], "logic")
	_check("jar_price(1) == 3.5", _approx(float(script.call("jar_price", 1, 3.5)), 3.5, 0.001), "got %s" % [script.call("jar_price", 1, 3.5)], "logic")
	_check("jar_price(12) == 42.0", _approx(float(script.call("jar_price", 12, 3.5)), 42.0, 0.001), "got %s" % [script.call("jar_price", 12, 3.5)], "logic")
	_check("jar_price(13) == 45.15 (tier boundary)", _approx(float(script.call("jar_price", 13, 3.5)), 45.15, 0.001), "got %s" % [script.call("jar_price", 13, 3.5)], "logic")
	_check("jar_price(49) == 158.2 (two tiers)", _approx(float(script.call("jar_price", 49, 3.5)), 158.2, 0.001), "got %s" % [script.call("jar_price", 49, 3.5)], "logic")
	_check("short_label(500) == '500 g'", str(script.call("short_label", 500.0)) == "500 g", "got %s" % [script.call("short_label", 500.0)], "logic")
	_check("short_label(1500) == '1.50 kg'", str(script.call("short_label", 1500.0)) == "1.50 kg", "got %s" % [script.call("short_label", 1500.0)], "logic")
