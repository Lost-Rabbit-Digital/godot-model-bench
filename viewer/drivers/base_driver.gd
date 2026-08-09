extends Control
## Base class for round viewer drivers.
## Each round driver fills the stage body: a world area (left) for the
## submission's node(s) plus a control panel (right) with buttons/labels.
## Subclasses implement `_build()` (returns "" or an error message) and
## may override `_process` / `_physics_process`.

var cfg: Dictionary = {}
var model_name: String = ""
var world: Control          # area where the submission node(s) go
var panel_box: VBoxContainer  # where driver buttons/labels go
var status_label: Label

func build(round_cfg: Dictionary, model: String) -> String:
	cfg = round_cfg
	model_name = model
	_build_ui()
	return await _build()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hbox)
	world = Control.new()
	world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world.clip_contents = false
	hbox.add_child(world)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320.0, 0.0)
	hbox.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	panel.add_child(margin)
	panel_box = VBoxContainer.new()
	panel_box.add_theme_constant_override("separation", 6)
	margin.add_child(panel_box)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(280.0, 60.0)
	panel_box.add_child(status_label)


## Override in subclass. Return "" on success, or an error message.
func _build() -> String:
	return ""


## Load a script from the round's live dir, forcing a fresh read from disk
## (the file is overwritten each time a different model is selected).
func _load_live(fname: String) -> Script:
	var path: String = str(cfg["live"]) + "/" + fname
	var s: Script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	return s


func _add_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	panel_box.add_child(b)
	return b


func _add_toggle(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.toggled.connect(cb)
	panel_box.add_child(b)
	return b


func _add_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	panel_box.add_child(l)
	return l


func _set_status(msg: String) -> void:
	status_label.text = msg