extends "res://viewer/drivers/base_driver.gd"
## Round 1 — Beehive simulation. Pure logic (RefCounted), so we build a
## visual hive that drives the submission's API: tick/harvest/buy_upgrade.

var _hive: Object = null
var _math: Object = null
var _auto: bool = false
var _auto_accum: float = 0.0
var _day: int = 0
var _hive_view: Control


func _build() -> String:
	var hive_script: Script = _load_live(str(cfg["files"][0]))
	var math_script: Script = _load_live(str(cfg["files"][1]))
	if hive_script == null or not hive_script.can_instantiate():
		return "beehive.gd failed to load/compile"
	if math_script == null or not math_script.can_instantiate():
		return "honey_math.gd failed to load/compile"
	_hive = hive_script.new()
	_math = math_script.new()
	_day = int(_hive.get("_day")) if _hive.get("_day") != null else 0

	_build_ui_left()
	return ""


func _build_ui_left() -> void:
	_hive_view = Control.new()
	_hive_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hive_view.clip_contents = true
	world.add_child(_hive_view)
	_hive_view.draw.connect(_draw_hive)

	_add_button("+1 day", _on_day1)
	_add_button("+7 days", _on_day7)
	_add_button("Harvest", _on_harvest)
	_add_button("Buy Frames (25)", _on_buy_frames)
	_add_button("Buy Hive Body (60)", _on_buy_body)
	_add_button("Buy Royal Jelly (150)", _on_buy_jelly)
	var auto_btn := _add_toggle("Auto-tick (2 days/s)", func(on: bool) -> void: _auto = on)


func _draw_hive() -> void:
	var size: Vector2 = _hive_view.size
	var cx: float = size.x * 0.5
	var cy: float = size.y * 0.5
	# Season indicator (top-left): a wheel showing season factor
	var season: float = 0.0
	if _hive != null and _hive.has_method("season_factor"):
		season = float(_hive.call("season_factor", _day))
	var wheel_r: float = 40.0
	var wheel_c := Vector2(cx, 70.0)
	_hive_view.draw_arc(wheel_c, wheel_r, 0.0, TAU, 48, Color(1, 1, 1, 0.2), 3.0)
	var ang: float = float(_day) / 360.0 * TAU
	_hive_view.draw_line(wheel_c, wheel_c + Vector2(cos(ang), sin(ang)) * wheel_r, Color(1, 0.8, 0.3), 3.0)
	_hive_view.draw_circle(wheel_c, 5.0, Color(1, 0.8, 0.3))
	# Season bar
	var bar := Rect2(wheel_c.x - wheel_r, wheel_c.y + wheel_r + 10.0, wheel_r * 2.0, 8.0)
	_hive_view.draw_rect(bar, Color(0.2, 0.2, 0.2))
	_hive_view.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(season, 0.0, 1.0), bar.size.y)), Color(0.3, 0.9, 0.4))
	# Hive body (hexagon-ish)
	var hive_r: float = 130.0
	var hive_c := Vector2(cx, cy + 20.0)
	var pts: PackedVector2Array = PackedVector2Array()
	for i in 6:
		var a: float = TAU / 6.0 * float(i) - PI / 2.0
		pts.append(hive_c + Vector2(cos(a), sin(a)) * hive_r)
	_hive_view.draw_colored_polygon(pts, Color(0.55, 0.4, 0.2))
	_hive_view.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.3, 0.2, 0.1), 3.0)
	# Honey fill
	var honey: float = 0.0
	if _hive != null:
		honey = float(_hive.get("honey"))
	var fill: float = clampf(honey / 300.0, 0.0, 1.0)
	var honey_pts: PackedVector2Array = PackedVector2Array()
	for i in 6:
		var a: float = TAU / 6.0 * float(i) - PI / 2.0
		var p := hive_c + Vector2(cos(a), sin(a)) * hive_r
		p.y = lerpf(hive_c.y + hive_r, p.y, fill)
		honey_pts.append(p)
	_hive_view.draw_colored_polygon(honey_pts, Color(0.95, 0.7, 0.15, 0.85))
	# Workers as dots
	var workers: int = int(_hive.get("workers")) if _hive != null else 0
	for i in mini(workers, 24):
		var a: float = float(i) * (TAU / minf(workers, 24)) + Time.get_ticks_msec() / 1000.0 * 0.5
		var r: float = 40.0 + float(i % 5) * 12.0
		var p := hive_c + Vector2(cos(a), sin(a)) * r
		_hive_view.draw_circle(p, 4.0, Color(0.2, 0.2, 0.2))
		_hive_view.draw_circle(p, 2.0, Color(0.9, 0.85, 0.4))
	# Labels
	_hive_view.draw_string(ThemeDB.fallback_font, Vector2(cx - 60.0, hive_c.y - hive_r - 20.0),
		"Day %d   Season %.2f   Honey %.1f" % [_day, season, honey], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)


func _process(delta: float) -> void:
	if _auto and _hive != null:
		_auto_accum += delta
		if _auto_accum >= 0.5:
			_auto_accum = 0.0
			var r: Dictionary = _hive.call("tick", 1)
			_day = int(r.get("day", _day))
	_update_status()
	if _hive_view != null:
		_hive_view.queue_redraw()


func _update_status() -> void:
	if _hive == null:
		return
	var honey: float = float(_hive.get("honey"))
	var workers: int = int(_hive.get("workers"))
	var up: Dictionary = _hive.get("upgrades")
	var bottles: int = int(_math.call("bottles_for", honey)) if _math != null else 0
	var price: float = float(_math.call("jar_price", bottles, 3.5)) if _math != null else 0.0
	var label: String = str(_math.call("short_label", honey)) if _math != null else ""
	_set_status("Honey: %.1f g (%s)\nWorkers: %d\nFrames: %s  Body: %s  Jelly: %s\nBottles: %d  Jar value: %.2f" %
		[honey, label, workers, up.get("frames"), up.get("hive_body"), up.get("royal_jelly"), bottles, price])


func _on_day1() -> void:
	if _hive != null:
		var r: Dictionary = _hive.call("tick", 1)
		_day = int(r.get("day", _day))


func _on_day7() -> void:
	if _hive != null:
		var r: Dictionary = _hive.call("tick", 7)
		_day = int(r.get("day", _day))


func _on_harvest() -> void:
	if _hive != null:
		_hive.call("harvest")


func _on_buy_frames() -> void:
	if _hive != null:
		_hive.call("buy_upgrade", "frames")


func _on_buy_body() -> void:
	if _hive != null:
		_hive.call("buy_upgrade", "hive_body")


func _on_buy_jelly() -> void:
	if _hive != null:
		_hive.call("buy_upgrade", "royal_jelly")