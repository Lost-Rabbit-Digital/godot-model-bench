extends Control
## Review Console — cross-bench benchmark results browser.
##
## Loads all three benches (godot, tool-use, translate) via BenchData and
## presents a scoreboard Tree with per-model accent colors + metadata, plus a
## detail panel. For the godot bench, a "View in viewer" button stages the
## selected model and opens res://viewer/stage.tscn (the interactive viewer).

const BenchDataScript := preload("res://viewer/bench_data.gd")

var _data: RefCounted
var _bench_id: String = BenchDataScript.BENCH_GODOT
var _round: int = 0            # 0 = all rounds aggregated, else specific round
var _selected_model: Dictionary = {}
var _sel_index: int = -1       # current row index in the tree (keyboard nav)
var _vs: Node = null           # ViewerState ref (autoload in normal mode, injected in tests)

# UI refs
var _bench_buttons: Dictionary = {}
var _round_box: HBoxContainer
var _desc_label: Label
var _tree: Tree
var _detail: VBoxContainer
var _view_btn: Button
var _status: Label


func _ready() -> void:
	_vs = _find_viewer_state()
	_data = BenchDataScript.new()
	_data.load_all()
	_build_ui()
	_select_bench(BenchDataScript.BENCH_GODOT)
	# Auto-select the top model so the detail panel is populated on launch.
	call_deferred("_auto_select_first")
	_handle_shot()


func _auto_select_first() -> void:
	if _tree.get_root() != null and _tree.get_root().get_child_count() > 0:
		_sel_index = 0
		var item := _tree.get_root().get_child(0)
		item.select(0)
		_on_tree_select()


# ── Keyboard navigation ──────────────────────────────────────────────────
# Up/Down        move selection through the model list
# Left/Right     switch bench (godot -> tool -> translate -> godot)
# Enter / Space  open the selected godot submission in the interactive viewer
# 0-7            (godot bench) "all rounds" / round 1-7
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_DOWN:
				_move_tree_selection(1)
				accept_event()
			KEY_UP:
				_move_tree_selection(-1)
				accept_event()
			KEY_RIGHT, KEY_TAB:
				_cycle_bench(1)
				accept_event()
			KEY_LEFT:
				_cycle_bench(-1)
				accept_event()
			KEY_ENTER, KEY_SPACE:
				_open_viewer()
				accept_event()
			KEY_0:
				if _bench_id == BenchDataScript.BENCH_GODOT:
					_set_round(0)
					accept_event()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7:
				if _bench_id == BenchDataScript.BENCH_GODOT:
					var r: int = event.keycode - KEY_0
					_set_round(r)
					accept_event()


func _bench_ids() -> Array:
	return _data.benches.keys()


func _cycle_bench(dir: int) -> void:
	var ids: Array = _bench_ids()
	if ids.is_empty():
		return
	var idx := ids.find(_bench_id)
	idx = (idx + dir) % ids.size()
	if idx < 0:
		idx += ids.size()
	_select_bench(str(ids[idx]))


func _move_tree_selection(dir: int) -> void:
	if _tree.get_root() == null:
		return
	var count := _tree.get_root().get_child_count()
	if count == 0:
		return
	if _sel_index < 0:
		_sel_index = 0
	_sel_index = (_sel_index + dir) % count
	if _sel_index < 0:
		_sel_index += count
	var item := _tree.get_root().get_child(_sel_index)
	item.select(0)
	_tree.scroll_to_item(item)
	_on_tree_select()


## Debug: godot --path . -- --shot /tmp/review.png
## Saves a screenshot then quits (mirrors stage.gd).
func _handle_shot() -> void:
	var args := OS.get_cmdline_user_args()
	var shot := ""
	for i in args.size():
		if args[i] == "--shot" and i + 1 < args.size():
			shot = args[i + 1]
	if shot == "":
		return
	await get_tree().create_timer(1.5).timeout
	var texture := get_viewport().get_texture()
	if texture == null:
		print("SHOT_ERROR viewport texture unavailable; use xvfb-run without --headless")
		get_tree().quit(2)
		return
	var img := texture.get_image()
	if img == null:
		print("SHOT_ERROR viewport image unavailable")
		get_tree().quit(2)
		return
	var err: Error = img.save_png(shot)
	if err != OK:
		print("SHOT_ERROR save_png failed: %s" % err)
		get_tree().quit(2)
		return
	print("SHOT_SAVED " + shot)
	get_tree().quit(0)


## Locate the ViewerState autoload (child of the root window). In normal
## (non -s) runs the autoload is registered; in tests we inject `_vs` directly.
func _find_viewer_state() -> Node:
	if _vs != null:
		return _vs
	var rootn := get_tree().root
	if rootn != null:
		var n := rootn.get_node_or_null("ViewerState")
		if n != null:
			return n
	return null


func _model_accent(name: String) -> Color:
	if _vs != null:
		return _vs.model_accent(name)
	return Color.WHITE


func _score_color(score: float, passed: int, total: int) -> Color:
	if _vs != null:
		return _vs.score_color(score, passed, total)
	return Color.WHITE


# ── UI construction ──────────────────────────────────────────────────────
func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	# Header
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	root.add_child(head)
	var title := Label.new()
	title.text = "Benchmark Review Console"
	title.add_theme_font_size_override("font_size", 24)
	head.add_child(title)
	head.add_child(HSeparator.new())
	var back := Button.new()
	back.text = "Open sequence viewer"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://viewer/menu.tscn"))
	head.add_child(back)

	# Bench selector
	var bench_row := HBoxContainer.new()
	bench_row.add_theme_constant_override("separation", 6)
	root.add_child(bench_row)
	var bcaption := Label.new()
	bcaption.text = "Bench:"
	bcaption.add_theme_font_size_override("font_size", 14)
	bench_row.add_child(bcaption)
	for b in _data.benches.values():
		var btn := Button.new()
		btn.text = str(b["title"])
		btn.toggle_mode = true
		btn.pressed.connect(_select_bench.bind(str(b["id"])))
		bench_row.add_child(btn)
		_bench_buttons[str(b["id"])] = btn

	_desc_label = Label.new()
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.84))
	root.add_child(_desc_label)

	# Round selector (godot only)
	_round_box = HBoxContainer.new()
	_round_box.add_theme_constant_override("separation", 4)
	root.add_child(_round_box)

	# Main: tree + detail
	var hbox := HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 8)
	root.add_child(hbox)

	_tree = Tree.new()
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree.columns = 6
	_tree.set_column_titles_visible(true)
	_tree.set_column_title(0, "Model")
	_tree.set_column_title(1, "Score")
	_tree.set_column_title(2, "Cost $")
	_tree.set_column_title(3, "In tok")
	_tree.set_column_title(4, "Out tok")
	_tree.set_column_title(5, "Wall s")
	_tree.columns = 6
	_tree.set_column_expand(0, true)
	for c in range(1, 6):
		_tree.set_column_expand(c, false)
	_tree.item_selected.connect(_on_tree_select)
	hbox.add_child(_tree)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360.0, 0.0)
	hbox.add_child(panel)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 6)
	panel.add_child(_detail)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status)

	var hints := Label.new()
	hints.text = "⌨  ↑/↓ select model · ←/→ switch bench · Enter/␣ open in viewer · 0-7 round (godot only)"
	hints.add_theme_font_size_override("font_size", 12)
	hints.add_theme_color_override("font_color", Color(0.55, 0.6, 0.68))
	root.add_child(hints)


# ── Bench + round selection ──────────────────────────────────────────────
func _select_bench(bench_id: String) -> void:
	_bench_id = bench_id
	_round = 0
	for bid in _bench_buttons.keys():
		(_bench_buttons[bid] as Button).button_pressed = (bid == bench_id)
	var b: Dictionary = _data.benches.get(bench_id, {})
	_desc_label.text = str(b.get("description", ""))
	_build_round_buttons()
	_populate_tree()


func _build_round_buttons() -> void:
	for c in _round_box.get_children():
		c.queue_free()
	if _bench_id != BenchDataScript.BENCH_GODOT:
		return
	_round_box.add_child(HSeparator.new())
	var all_btn := Button.new()
	all_btn.text = "All rounds"
	all_btn.toggle_mode = true
	all_btn.button_pressed = (_round == 0)
	all_btn.pressed.connect(func(): _set_round(0))
	_round_box.add_child(all_btn)
	var b: Dictionary = _data.benches.get(_bench_id, {})
	for r in b.get("rounds", []) as Array:
		var btn := Button.new()
		btn.text = str("R%d" % int((r as Dictionary)["num"]))
		btn.tooltip_text = str((r as Dictionary)["name"])
		btn.toggle_mode = true
		btn.button_pressed = (_round == int((r as Dictionary)["num"]))
		btn.pressed.connect(_set_round.bind(int((r as Dictionary)["num"])))
		_round_box.add_child(btn)


func _set_round(r: int) -> void:
	_round = r
	_build_round_buttons()
	_populate_tree()


# ── Tree population ──────────────────────────────────────────────────────
func _populate_tree() -> void:
	_tree.clear()
	_sel_index = -1
	var b: Dictionary = _data.benches.get(_bench_id, {})
	var models: Array = _data.sorted_models(_bench_id)
	if _bench_id == BenchDataScript.BENCH_GODOT and _round > 0:
		# Aggregate only the selected round
		models = []
		for m in _data.benches[_bench_id]["models"] as Array:
			var md := m as Dictionary
			if md["round_scores"].has(_round):
				var agg := md.duplicate(true)
				agg["score"] = md["round_scores"][_round]
				agg["round_sc"] = md["round_scores"][_round]
				models.append(agg)
		models.sort_custom(func(a, b): return a["score"] > b["score"])

	var root_item := _tree.create_item()
	root_item.set_text(0, str(b.get("title", "")))
	root_item.set_selectable(0, false)
	for m in models:
		var md := m as Dictionary
		var item := _tree.create_item(root_item)
		var accent: Color = _model_accent(str(md.get("slug", md.get("label", ""))))
		var label := str(md.get("label", "?"))
		if _bench_id == BenchDataScript.BENCH_GODOT and _round > 0:
			label += "  (R%d)" % _round
		item.set_text(0, label)
		item.set_custom_color(0, accent.lightened(0.25))
		item.set_text(1, "%.1f" % float(md.get("score", 0.0)))
		item.set_text(2, "%.4f" % float(md.get("cost", 0.0)))
		item.set_text(3, str(md.get("in_tok", 0)))
		item.set_text(4, str(md.get("out_tok", 0)))
		item.set_text(5, "%.0f" % float(md.get("wall", 0.0)))
		item.set_metadata(0, md)
	_selected_model = {}
	_clear_detail()
	if models.is_empty():
		_status.text = "No models for this bench/round."
	else:
		_status.text = "%d model(s) — click a row for details." % models.size()


func _on_tree_select() -> void:
	var item := _tree.get_selected()
	if item == null:
		return
	_sel_index = item.get_index()
	var md: Variant = item.get_metadata(0)
	if md is Dictionary:
		_selected_model = md
		_show_detail(md)


# ── Detail panel ─────────────────────────────────────────────────────────
func _clear_detail() -> void:
	for c in _detail.get_children():
		c.queue_free()
	_view_btn = null


func _add_detail_row(icon: String, key: String, value: String, value_color: Color = Color.WHITE) -> void:
	var hb := HBoxContainer.new()
	var k := Label.new()
	k.text = "%s  %s" % [icon, key]
	k.custom_minimum_size = Vector2(170.0, 0.0)
	k.add_theme_color_override("font_color", Color(0.62, 0.66, 0.74))
	hb.add_child(k)
	var v := Label.new()
	v.text = value
	v.add_theme_color_override("font_color", value_color)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(v)
	_detail.add_child(hb)


func _show_detail(md: Dictionary) -> void:
	_clear_detail()
	var accent: Color = _model_accent(str(md.get("slug", md.get("label", ""))))
	var title := Label.new()
	title.text = str(md.get("label", "?"))
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", accent.lightened(0.25))
	_detail.add_child(title)
	_detail.add_child(HSeparator.new())

	var score := float(md.get("score", 0.0))
	var passed := int(md.get("passed", 0))
	var total := int(md.get("total", 0))
	var sc: Color = _score_color(score, passed, total)
	_add_detail_row("🎯", "Score", "%.1f  (%d/%d)" % [score, passed, total], sc)
	_add_detail_row("💰", "Cost", "$%.4f" % float(md.get("cost", 0.0)))
	_add_detail_row("🔤", "Tokens", "%s in / %s out" % [md.get("in_tok", 0), md.get("out_tok", 0)])
	_add_detail_row("⏱️", "Wall", "%.1f s" % float(md.get("wall", 0.0)))

	if md.has("projected_cost"):
		_add_detail_row("📈", "Proj $ (100×30)", "$%.2f" % float(md["projected_cost"]))
	if md.has("lang_avgs"):
		var langs := md["lang_avgs"] as Dictionary
		var parts: Array = []
		for lang in ["de", "fr", "ja"]:
			if langs.has(lang):
				parts.append("%s %.1f" % [lang.to_upper(), float(langs[lang])])
		_add_detail_row("🌐", "Per-lang", "  ".join(parts))

	if md.has("round_scores") and (md["round_scores"] as Dictionary).size() > 0:
		var rs := md["round_scores"] as Dictionary
		var parts2: Array = []
		for k in rs.keys():
			parts2.append("R%d %.1f" % [int(k), float(rs[k])])
		_add_detail_row("🏁", "Rounds", "  ".join(parts2))

	# View in interactive viewer (godot only)
	if _bench_id == BenchDataScript.BENCH_GODOT:
		_detail.add_child(HSeparator.new())
		var hint := Label.new()
		hint.text = "View this submission running in Godot:"
		hint.add_theme_font_size_override("font_size", 12)
		_detail.add_child(hint)
		var b := Button.new()
		b.text = "▶ Open in interactive viewer"
		b.pressed.connect(_open_viewer)
		_detail.add_child(b)
		_view_btn = b


func _open_viewer() -> void:
	if _selected_model.is_empty():
		return
	if _vs == null:
		_status.text = "ViewerState not available."
		return
	var round_num: int = _round if _round > 0 else _default_round()
	_vs.round_num = round_num
	_vs.model_name = str(_selected_model.get("slug", _selected_model.get("label", "")))
	if not _vs.stage():
		_status.text = "Stage error: %s" % _vs.last_error
		return
	get_tree().change_scene_to_file("res://viewer/stage.tscn")


func _default_round() -> int:
	# Prefer the round where this model scored best (or first round).
	var rs: Dictionary = _selected_model.get("round_scores", {})
	if rs.is_empty():
		return 1
	var best: int = 0
	var best_score := -1.0
	for k in rs.keys():
		if float(rs[k]) > best_score:
			best_score = float(rs[k])
			best = int(k)
	return best if best > 0 else 1