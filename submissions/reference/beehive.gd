extends RefCounted

const BASE_RATE: float = 0.5          # honey per worker per day at peak season
const DAYS_PER_YEAR: int = 360
const UPGRADE_COSTS: Dictionary = {"frames": 25.0, "hive_body": 60.0, "royal_jelly": 150.0}
const UPGRADE_MAX: Dictionary = {"frames": 3, "hive_body": 2, "royal_jelly": 1}

var workers: int = 3
var honey: float = 0.0
var upgrades: Dictionary = {"frames": 0, "hive_body": 0, "royal_jelly": false}
var _day: int = 0

func _init(worker_count: int = 3) -> void:
	workers = maxi(worker_count, 0)

static func season_factor(day_of_year: int) -> float:
	var d: int = posmod(day_of_year, DAYS_PER_YEAR)
	return 0.6 + 0.4 * cos(float(d) / float(DAYS_PER_YEAR) * TAU)

func frames_multiplier() -> float:
	return 1.0 + 0.25 * float(int(upgrades.get("frames", 0)))

func hive_body_multiplier() -> float:
	return 1.0 + 0.5 * float(int(upgrades.get("hive_body", 0)))

func royal_jelly_multiplier() -> float:
	return 1.5 if bool(upgrades.get("royal_jelly", false)) else 1.0

func daily_production(day_of_year: int) -> float:
	return BASE_RATE * float(workers) * frames_multiplier() * hive_body_multiplier() * royal_jelly_multiplier() * season_factor(day_of_year)

func tick(days: int) -> Dictionary:
	var produced: float = 0.0
	var n: int = maxi(days, 0)
	for i in range(n):
		produced += daily_production(_day)
		_day = posmod(_day + 1, DAYS_PER_YEAR)
	honey += produced
	return {"honey": honey, "produced": produced, "day": _day}

func harvest() -> float:
	var h: float = honey
	honey = 0.0
	return h

func buy_upgrade(key: String) -> bool:
	if not UPGRADE_COSTS.has(key):
		return false
	var max_level: int = int(UPGRADE_MAX.get(key, 0))
	var current: int = int(upgrades.get(key, 0))
	if current >= max_level:
		return false
	var cost: float = float(UPGRADE_COSTS[key])
	if honey < cost:
		return false
	honey -= cost
	if key == "royal_jelly":
		upgrades[key] = true
	else:
		upgrades[key] = current + 1
	return true
