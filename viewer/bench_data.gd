class_name BenchData
extends RefCounted
## Cross-bench results loader for the Review Console.
##
## Reads all three benchmark repos' results/all_results.json (+ attempt meta)
## into a normalized structure so one scoreboard can review them side by side.
## The godot bench is read from res:// (this project); tool-use + translate are
## sibling repos resolved relative to the project dir (../tool-use-model-bench,
## ../translate-model-bench).

const BENCH_GODOT := "godot"
const BENCH_TOOL := "tool"
const BENCH_TRANSLATE := "translate"

## Normalized benches: {id, title, description, rounds: [{num, name, checks}], models: [...]}
var benches: Dictionary = {}


## Resolve the sibling project's results/all_results.json path.
func _sibling_results(subdir: String) -> String:
	var project_dir := ProjectSettings.globalize_path("res://")
	# strip trailing slash so get_base_dir() goes up to the projects/ root
	var normalized := project_dir.trim_suffix("/")
	var parent := normalized.get_base_dir()
	return parent.path_join(subdir).path_join("results").path_join("all_results.json")


## Load a JSON file to a Dictionary ({} on any failure).
func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var txt := FileAccess.get_file_as_string(path)
	if txt.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(txt)
	return parsed if parsed is Dictionary else {}


func load_all() -> void:
	benches = {}
	_load_godot()
	_load_tool()
	_load_translate()


func _norm_model(bench_id: String, m: Dictionary) -> Dictionary:
	return {
		"bench": bench_id,
		"model_id": m.get("model_id", m.get("label", "")),
		"label": m.get("label", "?"),
		"score": float(m.get("score", 0.0)),
		"passed": int(m.get("passed", 0)),
		"total": int(m.get("total", 0)),
		"cost": float(m.get("cost", 0.0)),
		"in_tok": int(m.get("in_tok", 0)),
		"out_tok": int(m.get("out_tok", 0)),
		"wall": float(m.get("wall", 0.0)),
	}


func _load_godot() -> void:
	var data := _load_json("res://results/all_results.json")
	var rounds := data.get("rounds", []) as Array
	var bench_rounds: Array = []
	var all_models: Dictionary = {}  # slug -> merged model
	for r in rounds:
		var rd := r as Dictionary
		var rnum := int(rd.get("num", 0))
		bench_rounds.append({"num": rnum, "name": rd.get("name", "Round %d" % rnum),
			"checks": int(rd.get("checks", 0))})
		for m in rd.get("models", []) as Array:
			var md := m as Dictionary
			var mid: String = md.get("label", "?")
			var slug := ViewerState.model_slug(mid)
			if not all_models.has(slug):
				all_models[slug] = _norm_model(BENCH_GODOT, md)
				all_models[slug]["slug"] = slug
				all_models[slug]["round_scores"] = {}
				all_models[slug]["rounds_detail"] = {}
			var entry: Dictionary = all_models[slug]
			entry["round_scores"][rnum] = float(md.get("score", 0.0))
			entry["rounds_detail"][rnum] = md
			entry["cost"] += float(md.get("cost", 0.0))
			entry["in_tok"] += int(md.get("in_tok", 0))
			entry["out_tok"] += int(md.get("out_tok", 0))
			entry["wall"] = maxf(entry["wall"], float(md.get("wall", 0.0)))
	benches[BENCH_GODOT] = {
		"id": BENCH_GODOT, "title": "Godot Bench",
		"description": "Godot 4.7 GDScript — 7 rounds (logic, scene-tree, physics, UI, NPC, animation, VFX).",
		"rounds": bench_rounds, "models": all_models.values(),
	}


func _load_tool() -> void:
	var data := _load_json(_sibling_results("tool-use-model-bench"))
	var models: Array = []
	for m in data.get("models", []) as Array:
		var md := m as Dictionary
		var entry := _norm_model(BENCH_TOOL, md)
		entry["slug"] = ViewerState.model_slug(str(entry["model_id"]))
		entry["round_scores"] = {}
		for k in (md.get("rounds", {}) as Dictionary).keys():
			entry["round_scores"][int(k)] = float((md.get("rounds", {}) as Dictionary)[k])
		var avg := float(md.get("avg", 0.0))
		entry["score"] = avg
		models.append(entry)
	benches[BENCH_TOOL] = {
		"id": BENCH_TOOL, "title": "Tool-Use Bench",
		"description": "Bash script tool mastery — 4 rounds (ImageMagick, ffmpeg, Xvfb, Blender).",
		"rounds": [
			{"num": 1, "name": "ImageMagick", "checks": 0},
			{"num": 2, "name": "ffmpeg", "checks": 0},
			{"num": 3, "name": "Xvfb", "checks": 0},
			{"num": 4, "name": "Blender", "checks": 0},
		],
		"models": models,
	}


func _load_translate() -> void:
	var data := _load_json(_sibling_results("translate-model-bench"))
	var models: Array = []
	for m in data.get("models", []) as Array:
		var md := m as Dictionary
		var entry := _norm_model(BENCH_TRANSLATE, md)
		entry["slug"] = ViewerState.model_slug(str(entry["model_id"]))
		entry["round_scores"] = {1: entry["score"]}
		entry["lang_avgs"] = md.get("lang_avgs", {})
		entry["projected_cost"] = float(md.get("projected_cost", 0.0))
		entry["category_bonus"] = float(md.get("category_bonus", 0.0))
		entry["time_pts"] = float(md.get("time_pts", 0.0))
		models.append(entry)
	benches[BENCH_TRANSLATE] = {
		"id": BENCH_TRANSLATE, "title": "Translate Bench",
		"description": "Bikini Heaven en → de/fr/ja — 105 samples, 4 categories.",
		"rounds": [{"num": 1, "name": "Translation", "checks": 0}],
		"models": models,
	}


## Sorted list of models for a bench (best score first).
func sorted_models(bench_id: String) -> Array:
	var b: Dictionary = benches.get(bench_id, {})
	var ms: Array = b.get("models", [])
	var sorted := ms.duplicate()
	sorted.sort_custom(func(a, b): return a["score"] > b["score"])
	return sorted