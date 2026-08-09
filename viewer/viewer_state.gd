extends Node
## ViewerState — autoload singleton for the Godot Model Bench submission viewer.
## Holds the selected round/model and stages submission files into the generated
## live dirs (submission/, submission2/, ...) exactly like run_bench.py does, so that
## scripts which reference each other by path (e.g. pegboard.gd loads
## res://submission3/bouncy_ball.gd) resolve correctly.

const ROUNDS: Array = [
	{
		"num": 1,
		"title": "Beehive Simulation",
		"dir": "res://submissions_round1",
		"live": "res://submission",
		"files": ["beehive.gd", "honey_math.gd"],
		"main": "beehive.gd",
		"kind": "logic",
		"driver": "res://viewer/drivers/round1.gd",
	},
	{
		"num": 2,
		"title": "Greenhouse Automation",
		"dir": "res://submissions_round2",
		"live": "res://submission2",
		"files": ["greenhouse.gd", "thermostat.gd"],
		"main": "greenhouse.gd",
		"kind": "node",
		"driver": "res://viewer/drivers/round2.gd",
	},
	{
		"num": 3,
		"title": "Pegboard Physics",
		"dir": "res://submissions_round3",
		"live": "res://submission3",
		"files": ["pegboard.gd", "bouncy_ball.gd"],
		"main": "pegboard.gd",
		"kind": "node",
		"driver": "res://viewer/drivers/round3.gd",
	},
	{
		"num": 4,
		"title": "HUD / Juice UI",
		"dir": "res://submissions_round4",
		"live": "res://submission4",
		"files": ["juice_hud.gd", "hud_sparkle.gd"],
		"main": "juice_hud.gd",
		"kind": "control",
		"driver": "res://viewer/drivers/round4.gd",
	},
	{
		"num": 5,
		"title": "NPC State Machine",
		"dir": "res://submissions_round5",
		"live": "res://submission5",
		"files": ["npc_controller.gd"],
		"main": "npc_controller.gd",
		"kind": "node",
		"driver": "res://viewer/drivers/round5.gd",
	},
	{
		"num": 6,
		"title": "Procedural Animation",
		"dir": "res://submissions_round6",
		"live": "res://submission6",
		"files": ["char_animator.gd"],
		"main": "char_animator.gd",
		"kind": "node",
		"driver": "res://viewer/drivers/round6.gd",
	},
	{
		"num": 7,
		"title": "Particles / VFX",
		"dir": "res://submissions_round7",
		"live": "res://submission7",
		"files": ["spell_vfx.gd"],
		"main": "spell_vfx.gd",
		"kind": "node",
		"driver": "res://viewer/drivers/round7.gd",
	},
]

var round_num: int = 0
var model_name: String = ""
var last_error: String = ""


func round_cfg(num: int) -> Dictionary:
	for r in ROUNDS:
		if int(r["num"]) == num:
			return r
	return {}


func model_slug(name: String) -> String:
	return name.replace("/", "_").replace(":", "_")


func submission_path(cfg: Dictionary, name: String) -> String:
	return str(cfg["dir"]) + "/" + model_slug(name)


func submission_is_complete(cfg: Dictionary, name: String) -> bool:
	if name == "reference":
		return true
	var dir: String = submission_path(cfg, name)
	for fname in cfg["files"]:
		var path: String = dir + "/" + str(fname)
		if not FileAccess.file_exists(path):
			return false
		if FileAccess.get_file_as_string(path).strip_edges().is_empty():
			return false
	return true


func list_models(cfg: Dictionary) -> Array:
	var dir := DirAccess.open(str(cfg["dir"]))
	if dir == null:
		return []
	dir.list_dir_begin()
	var names: Array = []
	var entry: String = dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			names.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	names.sort()
	if names.has("reference"):
		names.erase("reference")
		names.push_front("reference")
	return names


func _strip_class_name(src: String) -> String:
	var lines: PackedStringArray = src.split("\n")
	var out: PackedStringArray = PackedStringArray()
	for line in lines:
		if line.strip_edges().begins_with("class_name "):
			out.append("# " + line)
		else:
			out.append(line)
	return "\n".join(out)


## Copy the selected model's .gd files into the round's live dir,
## stripping class_name (mirrors run_bench.write_submission).
func stage() -> bool:
	last_error = ""
	var cfg := round_cfg(round_num)
	if cfg.is_empty():
		last_error = "Unknown round %d" % round_num
		return false
	var source_dir: String = submission_path(cfg, model_name)
	var live_dir: String = cfg["live"]
	var files: Array = cfg["files"]
	var expected_names: Dictionary = {}
	for fname in files:
		expected_names[str(fname)] = true
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(source_dir)):
		last_error = "Submission not found: %s" % source_dir
		return false
	# Validate every file before touching the live directory. This prevents a
	# failed selection from leaving a half-staged submission active.
	for fname in files:
		var source_path: String = source_dir + "/" + str(fname)
		if not FileAccess.file_exists(source_path):
			last_error = "Missing file: %s" % source_path
			return false
		if FileAccess.get_file_as_string(source_path).strip_edges().is_empty():
			last_error = "Empty file: %s" % source_path
			return false
	# Ensure the live dir exists (res:// paths can be written in dev mode)
	var live_abs := ProjectSettings.globalize_path(live_dir)
	DirAccess.make_dir_recursive_absolute(live_abs)
	var live_listing := DirAccess.open(live_dir)
	if live_listing != null:
		live_listing.list_dir_begin()
		var stale_name: String = live_listing.get_next()
		while stale_name != "":
			if not live_listing.current_is_dir() and stale_name.ends_with(".gd") and not expected_names.has(stale_name):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(live_dir + "/" + stale_name))
			stale_name = live_listing.get_next()
		live_listing.list_dir_end()
	for fname in files:
		var src: String = source_dir + "/" + fname
		var content := FileAccess.get_file_as_string(src)
		content = _strip_class_name(content)
		var f := FileAccess.open(live_dir + "/" + fname, FileAccess.WRITE)
		if f == null:
			last_error = "Cannot write to %s" % (live_dir + "/" + fname)
			return false
		f.store_string(content)
		f.close()
	# All drivers use CACHE_MODE_REPLACE as well, but replacing every staged
	# script here is necessary for submissions that load a sibling script with
	# plain load() from _ready().
	for fname in files:
		ResourceLoader.load(live_dir + "/" + str(fname), "", ResourceLoader.CACHE_MODE_REPLACE)
	return true