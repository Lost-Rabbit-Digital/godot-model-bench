extends SceneTree
## Verify review console keyboard-navigation logic by calling the handler
## methods directly (Input.parse_input_event injection is flaky in headless).
## Also confirms the review scene parses and Enter-handoff stages.
## Usage: godot --headless --path . -s tests/review_keys.gd

var _failures: Array[String] = []
var _vs: Node
var _rev: Node
var _tree: Tree

func _init() -> void:
	_run_async()

func _find_tree(node: Node) -> Node:
	for c in node.get_children():
		if c is Tree:
			return c
		var f := _find_tree(c)
		if f != null:
			return f
	return null

func _run_async() -> void:
	await process_frame
	var vs_script: Script = load("res://viewer/viewer_state.gd")
	_vs = vs_script.new()
	root.add_child(_vs)
	await process_frame
	var rev_script: Script = load("res://viewer/review.gd")
	_rev = rev_script.new()
	_rev.set("_vs", _vs)
	root.add_child(_rev)
	await process_frame
	await process_frame
	_tree = _find_tree(_rev)
	print("tree found:", _tree != null)
	if _tree == null:
		_failures.append("no tree")
		quit(1)

	var count := _tree.get_root().get_child_count()
	print("rows:", count)
	if count < 3:
		_failures.append("expected >=3 rows, got %d" % count)

	# initial = first row selected
	var before: String = _tree.get_root().get_child(0).get_text(0)
	print("initial[0]:", before)

	# Down -> row 1
	_rev.call("_move_tree_selection", 1)
	await process_frame
	var r1: String = _tree.get_root().get_child(1).get_text(0)
	print("after DOWN row1:", r1)
	if int(_rev.get("_sel_index")) != 1:
		_failures.append("DOWN: _sel_index != 1 (got %s)" % str(_rev.get("_sel_index")))

	# Up -> row 0
	_rev.call("_move_tree_selection", -1)
	await process_frame
	if int(_rev.get("_sel_index")) != 0:
		_failures.append("UP: _sel_index != 0 (got %s)" % str(_rev.get("_sel_index")))

	# cycle bench right -> tool
	var bid: String = _rev.get("_bench_id")
	_rev.call("_cycle_bench", 1)
	await process_frame
	var bid2: String = _rev.get("_bench_id")
	print("bench: %s -> %s" % [bid, bid2])
	if bid2 != "tool":
		_failures.append("cycle right: expected tool, got %s" % bid2)

	# cycle left -> back to godot
	_rev.call("_cycle_bench", -1)
	await process_frame
	if _rev.get("_bench_id") != "godot":
		_failures.append("cycle left: expected godot, got %s" % str(_rev.get("_bench_id")))

	# round key 5 on godot
	_rev.call("_set_round", 5)
	await process_frame
	if int(_rev.get("_round")) != 5:
		_failures.append("set_round(5): expected 5, got %d" % int(_rev.get("_round")))

	# reset to all-rounds, select a godot model, then Enter-handoff stages
	_rev.call("_set_round", 0)
	await process_frame
	_rev.set("_selected_model", {"slug": "meta_muse-spark-1.2", "label": "Muse Spark 1.2", "round_scores": {5: 99.4}})
	_rev.set("_round", 5)
	_rev.call("_open_viewer")
	await process_frame
	await process_frame
	var staged: bool = FileAccess.file_exists("res://submission5/npc_controller.gd")
	print("staged after Enter-handoff:", staged)
	if not staged:
		_failures.append("Enter-handoff did not stage round 5")

	if _failures.is_empty():
		print("REVIEW_KEYS_OK")
		quit(0)
	else:
		print("REVIEW_KEYS_FAIL")
		for f in _failures:
			print("FAIL " + f)
		quit(1)