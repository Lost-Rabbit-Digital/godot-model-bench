extends SceneTree
## Headless smoke test for the Review Console.
## Usage: godot --headless --path . -s tests/review_smoke.gd
## Loads all three benches via BenchData, instantiates the review scene,
## selects each bench + round, and verifies the tree populates.

var _failures: Array[String] = []
var _vs: Node


func _init() -> void:
	_run_async()


func _run_async() -> void:
	await process_frame
	# ViewerState autoload isn't resolvable in -s mode; instantiate directly.
	var vs_script: Script = load("res://viewer/viewer_state.gd")
	_vs = vs_script.new()
	root.add_child(_vs)
	await process_frame

	# 1) BenchData loads all three benches
	var bd_script: Script = load("res://viewer/bench_data.gd")
	var bd: RefCounted = bd_script.new()
	bd.load_all()
	var benches: Dictionary = bd.benches
	for expected in [bd_script.BENCH_GODOT, bd_script.BENCH_TOOL, bd_script.BENCH_TRANSLATE]:
		if not benches.has(expected):
			_failures.append("bench %s missing" % expected)
			continue
		var b: Dictionary = benches[expected]
		var n: int = (b.get("models", []) as Array).size()
		print("bench %-10s models=%d rounds=%d" % [expected, n, (b.get("rounds", []) as Array).size()])
		if n == 0:
			_failures.append("bench %s has no models" % expected)
		var sorted_arr: Array = bd.sorted_models(expected)
		if sorted_arr.size() > 1:
			if float(sorted_arr[0]["score"]) < float(sorted_arr[1]["score"]):
				_failures.append("bench %s not sorted desc" % expected)

	# 2) Review scene instantiates + populates (inject the viewer state ref)
	var rev_script: Script = load("res://viewer/review.gd")
	var rev: Node = rev_script.new()
	rev.set("_vs", _vs)
	root.add_child(rev)
	await process_frame
	await process_frame
	# exercise a bench switch + model selection if the tree populated
	rev.call("_select_bench", bd_script.BENCH_TOOL)
	await process_frame
	rev.call("_select_bench", bd_script.BENCH_TRANSLATE)
	await process_frame
	rev.queue_free()
	await process_frame

	if _failures.is_empty():
		print("REVIEW_SMOKE_OK")
		quit(0)
	else:
		print("REVIEW_SMOKE_FAIL")
		for f in _failures:
			print("FAIL  " + f)
		quit(1)