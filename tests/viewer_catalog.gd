extends SceneTree
## Catalog smoke test for every reviewable cached submission.
## Usage: godot --headless --path . -s tests/viewer_catalog.gd
## This intentionally accepts model build errors as per-submission failures so
## one broken model cannot prevent the rest of the catalog from being checked.

var vs: Node
var _failures: Array[String] = []
var _checked: int = 0


func _init() -> void:
	_run_async()


func _run_async() -> void:
	await process_frame
	var vs_script: Script = load("res://viewer/viewer_state.gd")
	vs = vs_script.new()
	root.add_child(vs)
	await process_frame
	for cfg in vs.ROUNDS:
		var round_num: int = int(cfg["num"])
		var names: Array = vs.list_models(cfg)
		for model_name in names:
			if not vs.submission_is_complete(cfg, model_name):
				continue
			_checked += 1
			vs.round_num = round_num
			vs.model_name = model_name
			if not vs.stage():
				_failures.append("round %d/%s staging: %s" % [round_num, model_name, vs.last_error])
				continue
			var driver_script: Script = load(str(cfg["driver"]))
			if driver_script == null or not driver_script.can_instantiate():
				_failures.append("round %d/%s driver missing" % [round_num, model_name])
				continue
			var driver: Node = driver_script.new()
			root.add_child(driver)
			await process_frame
			var err: String = await driver.call("build", cfg, model_name)
			if err != "":
				_failures.append("round %d/%s build: %s" % [round_num, model_name, err])
			for _frame in 4:
				await process_frame
			driver.queue_free()
			await process_frame
	print("VIEWER_CATALOG checked=%d failures=%d" % [_checked, _failures.size()])
	if _failures.is_empty():
		print("VIEWER_CATALOG_OK")
		quit(0)
	else:
		for failure in _failures:
			print("FAIL " + failure)
		quit(1)
