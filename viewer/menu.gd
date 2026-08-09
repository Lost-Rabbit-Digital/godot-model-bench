extends Control
## Main menu — lists rounds and their model submissions.
## Clicking a model stages its files and opens the stage scene.

var _round_box: VBoxContainer
var _model_box: VBoxContainer
var _status: Label
var _current_round: Dictionary = {}
var _model_buttons: Array = []


func _ready() -> void:
	_build_ui()
	_populate_rounds()
	_handle_cmdline()


## Support: godot --path . -- --round 3 --model meta_muse-spark-1.2
## Jumps straight into the stage for a round/model without clicking.
func _handle_cmdline() -> void:
	var args := OS.get_cmdline_user_args()
	var rnd := 0
	var model := ""
	for i in args.size():
		if args[i] == "--round" and i + 1 < args.size():
			rnd = int(args[i + 1])
		elif args[i] == "--model" and i + 1 < args.size():
			model = args[i + 1]
	if rnd > 0 and model != "":
		for cfg in ViewerState.ROUNDS:
			if int(cfg["num"]) == rnd:
				ViewerState.round_num = rnd
				ViewerState.model_name = model
				if ViewerState.stage():
					# defer so we're not mid-_ready when the scene swap happens
					get_tree().call_deferred("change_scene_to_file", "res://viewer/stage.tscn")
				else:
					_status.text = "Stage error: %s" % ViewerState.last_error
					print("VIEWER_STAGE_ERROR %s" % ViewerState.last_error)
					get_tree().quit(1)
				return
		_status.text = "Unknown round %d" % rnd


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var title := Label.new()
	title.text = "Godot Model Bench — Submission Viewer"
	title.add_theme_font_size_override("font_size", 30)
	root.add_child(title)
	var sub := Label.new()
	sub.text = "Pick a round, then a model.  Reference = the human-written solution."
	sub.add_theme_font_size_override("font_size", 14)
	root.add_child(sub)

	var hbox := HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 12)
	root.add_child(hbox)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(360.0, 0.0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 4)
	hbox.add_child(left)
	var lh := Label.new()
	lh.text = "Rounds"
	lh.add_theme_font_size_override("font_size", 18)
	left.add_child(lh)
	_round_box = VBoxContainer.new()
	_round_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_round_box.add_theme_constant_override("separation", 4)
	left.add_child(_round_box)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 4)
	hbox.add_child(right)
	var rh := Label.new()
	rh.text = "Models"
	rh.add_theme_font_size_override("font_size", 18)
	right.add_child(rh)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	_model_box = VBoxContainer.new()
	_model_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_model_box.add_theme_constant_override("separation", 4)
	scroll.add_child(_model_box)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.text = "Select a round to see models."
	root.add_child(_status)


func _populate_rounds() -> void:
	for cfg in ViewerState.ROUNDS:
		var btn := Button.new()
		btn.text = "Round %d  —  %s" % [cfg["num"], cfg["title"]]
		btn.pressed.connect(func(): _select_round(cfg))
		_round_box.add_child(btn)
	# Select round 1 on start
	if ViewerState.ROUNDS.size() > 0:
		_select_round(ViewerState.ROUNDS[0])


func _select_round(cfg: Dictionary) -> void:
	_current_round = cfg
	for b in _model_buttons:
		b.queue_free()
	_model_buttons.clear()
	var dir := DirAccess.open(str(cfg["dir"]))
	if dir == null:
		_status.text = "No submissions dir for %s (run the benchmark first)." % cfg["dir"]
		return
	dir.list_dir_begin()
	var names: Array = []
	var f: String = dir.get_next()
	while f != "":
		if dir.current_is_dir() and not f.begins_with("."):
			names.append(f)
		f = dir.get_next()
	dir.list_dir_end()
	names.sort()
	if names.has("reference"):
		names.erase("reference")
		names.push_front("reference")
	for name in names:
		var btn := Button.new()
		if name == "reference":
			btn.text = "[reference]  (expected / human-written solution)"
		else:
			btn.text = name
		btn.pressed.connect(func(): _launch(name))
		_model_box.add_child(btn)
		_model_buttons.append(btn)
	if names.is_empty():
		_status.text = "No model submissions found in %s." % cfg["dir"]
	else:
		_status.text = "%d submission(s) for Round %d." % [names.size(), cfg["num"]]


func _launch(model: String) -> void:
	if _current_round.is_empty():
		return
	ViewerState.round_num = int(_current_round["num"])
	ViewerState.model_name = model
	if not ViewerState.stage():
		_status.text = "Stage error: %s" % ViewerState.last_error
		return
	get_tree().change_scene_to_file("res://viewer/stage.tscn")