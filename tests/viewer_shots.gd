extends SceneTree
## Captures a screenshot of each round's stage (reference submission) for
## visual QA. Usage:
##   xvfb-run -a godot --path . -s tests/viewer_shots.gd --rendering-driver opengl3
## Saves PNGs to tests/viewer_shots/.

var vs: Node

func _init() -> void:
	_run_async()

func _run_async() -> void:
	await process_frame
	var vs_script: Script = load("res://viewer/viewer_state.gd")
	vs = vs_script.new()
	root.add_child(vs)
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/viewer_shots"))
	for cfg in vs.ROUNDS:
		vs.round_num = int(cfg["num"])
		vs.model_name = "reference"
		if not vs.stage():
			print("skip round %d staging" % cfg["num"])
			continue
		var driver_script: Script = load(str(cfg["driver"]))
		if driver_script == null:
			continue
		var driver: Node = driver_script.new()
		root.add_child(driver)
		await process_frame
		await driver.call("build", cfg, "reference")
		# give animations/physics time to visibly run
		for i in 60:
			await process_frame
		await process_frame
		var img := root.get_viewport().get_texture().get_image()
		var path := "res://tests/viewer_shots/round%d.png" % cfg["num"]
		img.save_png(ProjectSettings.globalize_path(path))
		print("saved " + path)
		driver.queue_free()
		await process_frame
	quit(0)