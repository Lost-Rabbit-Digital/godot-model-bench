extends Control
## Stage shell — hosts one round driver for the selected model submission.
## Reads ViewerState (set by the menu), loads the round's driver script,
## and calls build(). Shows errors inline if the submission fails.

var _driver: Node = null
var _title_label: Label
var _error_label: Label
var _body: Control


func _ready() -> void:
	_build_ui()
	var cfg: Dictionary = ViewerState.round_cfg(ViewerState.round_num)
	if cfg.is_empty():
		_show_error("Unknown round %d" % ViewerState.round_num)
		return
	_title_label.text = "Round %d: %s — %s" % [cfg["num"], cfg["title"], ViewerState.model_name]

	if not ViewerState.stage():
		_show_error("Staging failed: %s" % ViewerState.last_error)
		return

	var driver_script: Script = load(str(cfg["driver"]))
	if driver_script == null or not driver_script.can_instantiate():
		_show_error("Driver script missing: %s" % cfg["driver"])
		return
	_driver = driver_script.new()
	_body.add_child(_driver)
	# Give the driver a frame to size itself before it starts drawing.
	await get_tree().process_frame
	var err: String = await _driver.build(cfg, ViewerState.model_name)
	if err != "":
		_show_error(err)
		if _has_shot_arg():
			_quit_cleanly.call_deferred(1)
		return
	await _handle_shot()
	_dump_debug()


func _dump_debug() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--layout-debug"):
		return
	print("LAYOUT body=%s driver=%s" % [str(_body.size), str(_driver.size) if _driver != null else "null"])
	if _driver != null:
		for c in _driver.get_children():
			print("LAYOUT driver_child %s size=%s" % [c.name, str(c.size)])
			if c is HBoxContainer:
				for c2 in (c as HBoxContainer).get_children():
					print("LAYOUT   hbox_child size=%s" % str(c2.size))


## Debug: godot --path . -- --round 3 --model X --shot /tmp/r3.png
## Saves a screenshot of the running stage then quits.
func _handle_shot() -> void:
	var shot := _shot_path()
	if shot == "":
		return
	# let animations/physics run a bit before freezing the frame
	await get_tree().create_timer(2.0).timeout
	var viewport := get_viewport()
	var texture := viewport.get_texture()
	if texture == null:
		print("SHOT_ERROR viewport texture unavailable; use xvfb-run without --headless for screenshots")
		_quit_cleanly.call_deferred(2)
		return
	var img := texture.get_image()
	if img == null:
		print("SHOT_ERROR viewport image unavailable")
		_quit_cleanly.call_deferred(2)
		return
	var save_err: Error = img.save_png(shot)
	if save_err != OK:
		print("SHOT_ERROR save_png failed: %s" % save_err)
		_quit_cleanly.call_deferred(2)
		return
	print("SHOT_SAVED " + shot)
	_quit_cleanly.call_deferred(0)


func _quit_cleanly(code: int) -> void:
	if _driver != null:
		_driver.queue_free()
		_driver = null
	get_tree().quit(code)


func _shot_path() -> String:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--shot" and i + 1 < args.size():
			return args[i + 1]
	return ""


func _has_shot_arg() -> bool:
	return _shot_path() != ""


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var back := Button.new()
	back.text = "<- Back to menu"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://viewer/menu.tscn"))
	top.add_child(back)
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 20)
	top.add_child(_title_label)

	_body = Control.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_body)

	_error_label = Label.new()
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_error_label.visible = false
	root.add_child(_error_label)


func _show_error(msg: String) -> void:
	_error_label.text = msg
	_error_label.visible = true
	if _driver != null:
		_driver.queue_free()
		_driver = null