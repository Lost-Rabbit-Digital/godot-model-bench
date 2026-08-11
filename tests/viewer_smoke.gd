extends SceneTree
## Headless smoke test for the submission viewer.
## Usage: godot --headless --path . -s tests/viewer_smoke.gd
## Stages the reference submission for every round, instantiates each round
## driver, runs it for a few frames, and reports errors.
## NOTE: autoload globals aren't resolvable in -s SceneTree mode, so we
## instantiate ViewerState directly here (menu/stage use the autoload).

var vs: Node
var _failures: Array = []

func _init() -> void:
	_run_async()

func _run_async() -> void:
	await process_frame
	var vs_script: Script = load("res://viewer/viewer_state.gd")
	vs = vs_script.new()
	root.add_child(vs)
	await process_frame
	for cfg in vs.ROUNDS:
		vs.round_num = int(cfg["num"])
		vs.model_name = "reference"
		if not vs.stage():
			_failures.append("round %d staging: %s" % [cfg["num"], vs.last_error])
			continue
		var driver_script: Script = load(str(cfg["driver"]))
		if driver_script == null or not driver_script.can_instantiate():
			_failures.append("round %d driver missing" % cfg["num"])
			continue
		var driver: Node = driver_script.new()
		root.add_child(driver)
		await process_frame
		var err: String = await driver.call("build", cfg, "reference", vs)
		if err != "":
			_failures.append("round %d build: %s" % [cfg["num"], err])
		for i in 30:
			await process_frame
			if i == 10:
				_tap_buttons(driver)
		driver.queue_free()
		await process_frame
		print("round %d OK" % cfg["num"])
	if _failures.is_empty():
		print("VIEWER_SMOKE_OK")
		quit(0)
	else:
		print("VIEWER_SMOKE_FAIL")
		for f in _failures:
			print("FAIL  " + f)
		quit(1)

func _tap_buttons(driver: Node) -> void:
	for child in driver.get_children():
		_collect_buttons(child)

func _collect_buttons(node: Node) -> void:
	if node is Button:
		var b := node as Button
		if b.text.begins_with("Set temp") or b.text == "+1 day" or b.text == "Harvest" \
			or b.text.begins_with("Add score") or b.text == "Pulse" \
			or b.text == "Trigger attack" or b.text == "Burst":
			b.emit_signal("pressed")
	for c in node.get_children():
		_collect_buttons(c)