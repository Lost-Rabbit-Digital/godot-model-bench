extends Control
## Base class for round viewer drivers.
## Each round driver fills the stage body: a world area (left) for the
## submission's node(s) plus a control panel (right) with buttons/labels.
## Subclasses implement `_build()` (returns "" or an error message) and
## may override `_process` / `_physics_process`.
##
## Every driver automatically gets:
##  - a model-identity header strip (accent color, label, round score badge)
##  - a submission metadata block (cost, tokens, response time, wall time,
##    lint) pulled from attemptN_meta.json + results/all_results.json
##  - a subtle accent-tinted background in the world area so switching
##    models is visually obvious even when the submission draws nothing.

var cfg: Dictionary = {}
var model_name: String = ""
var world: Control          # area where the submission node(s) go
var panel_box: VBoxContainer  # where driver buttons/labels go
var status_label: Label

var _accent: Color = Color.WHITE
var _meta_box: VBoxContainer
var _root: VBoxContainer
var _vs: Node = null  # ViewerState ref; set by build() (works in -s test mode too)


func build(round_cfg: Dictionary, model: String, viewer_state: Node = null) -> String:
	cfg = round_cfg
	model_name = model
	_vs = viewer_state
	if _vs == null:
		_vs = _find_viewer_state()
	_accent = _vs.model_accent(model) if _vs != null else Color.WHITE
	_build_ui()
	_build_header()
	_build_meta()
	return await _build()


## Locate the ViewerState autoload (child of the root window). In normal
## (non -s) runs the autoload is registered; in tests we pass it explicitly.
func _find_viewer_state() -> Node:
	var root := get_tree().root
	if root != null:
		var n := root.get_node_or_null("ViewerState")
		if n != null:
			return n
	return null


func _model_label() -> String:
	return _vs.model_label(model_name) if _vs != null else model_name


func _round_result() -> Dictionary:
	return _vs.round_result(cfg, model_name) if _vs != null else {}


func _attempt_meta(attempt: int) -> Dictionary:
	return _vs.attempt_meta(cfg, model_name, attempt) if _vs != null else {}


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root = VBoxContainer.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_theme_constant_override("separation", 4)
	add_child(_root)

	var hbox := HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 8)
	_root.add_child(hbox)

	world = Control.new()
	world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world.clip_contents = false
	hbox.add_child(world)
	# Accent tint behind the submission's visuals — added first so it draws
	# underneath whatever the driver / submission adds.
	var tint := ColorRect.new()
	tint.name = "ModelTint"
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.color = Color(_accent.r, _accent.g, _accent.b, 0.07)
	world.add_child(tint)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340.0, 0.0)
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
	status_label.custom_minimum_size = Vector2(300.0, 60.0)
	panel_box.add_child(status_label)


## Model-identity strip: accent swatch + label + score badge, pinned to the
## top of the stage so the current model is unmistakable.
func _build_header() -> void:
	var strip := PanelContainer.new()
	strip.name = "ModelHeader"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(_accent.r, _accent.g, _accent.b, 0.16)
	sb.border_color = Color(_accent.r, _accent.g, _accent.b, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	strip.add_theme_stylebox_override("panel", sb)
	_root.add_child(strip)
	# Place it at the top of the layout, above the world/panel hbox.
	_root.move_child(strip, 0)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	strip.add_child(hb)

	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(14.0, 14.0)
	swatch.color = _accent
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(swatch)

	var name_label := Label.new()
	name_label.text = _model_label()
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", _accent.lightened(0.25))
	hb.add_child(name_label)

	var res: Dictionary = _round_result()
	if not res.is_empty():
		var badge := Label.new()
		var sc: float = float(res.get("score", 0.0))
		var passed: int = int(res.get("passed", 0))
		var total: int = int(res.get("total", 0))
		var col: Color = _vs.score_color(sc, passed, total) if _vs != null else Color.WHITE
		badge.text = "score %.1f  |  %d/%d checks  |  %s" % [sc, passed, total, res.get("tier", "")]
		badge.add_theme_color_override("font_color", col)
		badge.add_theme_font_size_override("font_size", 15)
		badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hb.add_child(badge)


## Submission metadata block: cost, tokens (in/out + reasoning), response
## time, wall time, lint issues, repair attempts. Reads attempt meta from the
## submission dir and scored data from results/all_results.json.
func _build_meta() -> void:
	var res: Dictionary = _round_result()
	var meta1: Dictionary = _attempt_meta(1)
	var meta2: Dictionary = _attempt_meta(2)
	if res.is_empty() and meta1.is_empty():
		return

	var sep := HSeparator.new()
	panel_box.add_child(sep)
	var head := Label.new()
	head.text = "Submission metadata"
	head.add_theme_font_size_override("font_size", 13)
	head.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
	panel_box.add_child(head)

	_meta_box = VBoxContainer.new()
	_meta_box.add_theme_constant_override("separation", 2)
	panel_box.add_child(_meta_box)

	var usage: Dictionary = meta1.get("usage", {}) if not meta1.is_empty() else {}
	var duration: float = float(meta1.get("duration", 0.0)) if not meta1.is_empty() else 0.0
	var cost: float = float(usage.get("cost", 0.0)) if not usage.is_empty() else float(res.get("cost", 0.0))
	var in_tok: int = int(usage.get("prompt_tokens", 0)) if not usage.is_empty() else int(res.get("in_tok", 0))
	var out_tok: int = int(usage.get("completion_tokens", 0)) if not usage.is_empty() else int(res.get("out_tok", 0))
	var reasoning: int = 0
	if not usage.is_empty():
		var det: Dictionary = usage.get("completion_tokens_details", {})
		reasoning = int(det.get("reasoning_tokens", 0))
	var wall: float = float(res.get("wall", 0.0))
	var lint: int = int(res.get("lint_n", -1))
	var finish: String = meta1.get("finish", "") if not meta1.is_empty() else ""

	_add_meta_row("Cost", "$%.4f" % cost)
	_add_meta_row("Tokens", "%d in / %d out" % [in_tok, out_tok])
	if reasoning > 0:
		_add_meta_row("  reasoning", "%d out tokens (%d%%)" % [reasoning, int(100.0 * reasoning / out_tok) if out_tok > 0 else 0])
	_add_meta_row("API response", "%.1f s" % duration)
	if wall > 0.0:
		_add_meta_row("Total wall", "%.1f s (API + eval)" % wall)
	if lint >= 0:
		_add_meta_row("gdlint issues", "%d" % lint)
	if not meta2.is_empty():
		_add_meta_row("Attempts", "2 (repair round used)")
	elif finish != "":
		_add_meta_row("Finish", finish)


func _add_meta_row(key: String, value: String) -> void:
	var hb := HBoxContainer.new()
	var k := Label.new()
	k.text = key
	k.custom_minimum_size = Vector2(150.0, 0.0)
	k.add_theme_color_override("font_color", Color(0.62, 0.66, 0.74))
	hb.add_child(k)
	var v := Label.new()
	v.text = value
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(v)
	_meta_box.add_child(hb)


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
