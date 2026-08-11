extends SceneTree
## Verify the review console's "Open in interactive viewer" handoff stages the
## selected godot submission and switches to stage.tscn.
## Usage: godot --headless --path . -s tests/review_handoff.gd
var _failures: Array[String] = []
var _vs: Node

func _init() -> void:
	_run_async()

func _run_async() -> void:
	await process_frame
	var vs_script: Script = load("res://viewer/viewer_state.gd")
	_vs = vs_script.new()
	root.add_child(_vs)
	await process_frame
	var rev_script: Script = load("res://viewer/review.gd")
	var rev: Node = rev_script.new()
	rev.set("_vs", _vs)
	root.add_child(rev)
	await process_frame
	await process_frame
	# pick a known-good submission on round 5
	rev.set("_selected_model", {"slug": "meta_muse-spark-1.2", "label": "Muse Spark 1.2", "round_scores": {5: 99.4}})
	rev.set("_round", 5)
	rev.call("_open_viewer")
	await process_frame
	await process_frame
	# stage() should have staged into submission5 and stage.tscn loaded
	var staged: bool = FileAccess.file_exists("res://submission5/npc_controller.gd")
	print("staged npc_controller.gd:", staged)
	if not staged:
		_failures.append("open_viewer did not stage round 5 submission")
	# confirm round/model set on ViewerState
	print("vs.round_num:", _vs.round_num, " vs.model_name:", _vs.model_name)
	if _vs.round_num != 5 or _vs.model_name != "meta_muse-spark-1.2":
		_failures.append("ViewerState not set by handoff")
	if _failures.is_empty():
		print("REVIEW_HANDOFF_OK")
		quit(0)
	else:
		for f in _failures:
			print("FAIL " + f)
		quit(1)
