You are an expert Godot 4.7 GDScript programmer. Implement a small, self-contained honey-farm production simulation.

CONSTRAINTS
- Both scripts extend RefCounted and are PURE LOGIC: no nodes, no scene tree, no timers, no autoloads, no RNG. The simulation must be fully deterministic.
- The harness loads your scripts by path with load() at runtime. Do NOT rely on class_name globals (a class_name line is optional and harmless, but never reference another class by name).
- Strongly typed GDScript: every variable, parameter, and function return type must be annotated. No `var x = ...` without a type.
- Handle edge cases explicitly (details below).

You must produce EXACTLY TWO files, in this order.

=====================================================================
FILE 1: beehive.gd
=====================================================================

API contract (method names, signatures, and semantics must match EXACTLY):

class_name Beehive          # optional
extends RefCounted

const BASE_RATE: float = 0.5          # honey per worker per day at peak season
const DAYS_PER_YEAR: int = 360
const UPGRADE_COSTS: Dictionary = {"frames": 25.0, "hive_body": 60.0, "royal_jelly": 150.0}
const UPGRADE_MAX: Dictionary = {"frames": 3, "hive_body": 2, "royal_jelly": 1}

var workers: int = 3                  # clamps to >= 0 in _init
var honey: float = 0.0
var upgrades: Dictionary = {"frames": 0, "hive_body": 0, "royal_jelly": false}
var _day: int = 0                     # internal day-of-year counter, 0..359

func _init(worker_count: int = 3) -> void
    # Negative worker counts clamp to 0.

static func season_factor(day_of_year: int) -> float
    # Seasonal production multiplier. Must equal:
    #   0.6 + 0.4 * cos((posmod(day_of_year, 360) / 360.0) * TAU)
    # i.e. 1.0 on day 0 (spring start), 0.2 on day 180 (mid-winter).

func frames_multiplier() -> float
    # 1.0 + 0.25 * frames level

func hive_body_multiplier() -> float
    # 1.0 + 0.5 * hive_body level

func royal_jelly_multiplier() -> float
    # 1.5 if royal_jelly purchased, else 1.0

func daily_production(day_of_year: int) -> float
    # BASE_RATE * workers * frames_multiplier() * hive_body_multiplier()
    #            * royal_jelly_multiplier() * season_factor(day_of_year)

func tick(days: int) -> Dictionary
    # Simulate `days` days. Zero or negative days = no-op (no production, no state change).
    # For each simulated day: honey += daily_production(_day), then _day advances by 1,
    # wrapping at DAYS_PER_YEAR.
    # Returns {"honey": float, "produced": float, "day": int} where "produced" is the
    # honey added by THIS call and "day" is the internal _day AFTER the call.

func harvest() -> float
    # Returns all accumulated honey and resets honey to 0.0. Empty hive -> 0.0.

func buy_upgrade(key: String) -> bool
    # Costs: frames 25, hive_body 60, royal_jelly 150 (UPGRADE_COSTS).
    # Level caps: frames 3, hive_body 2, royal_jelly 1 (UPGRADE_MAX).
    # Returns false and changes NOTHING if: key is unknown, the upgrade is already at
    # its cap, or honey < cost. On success: deduct the cost from honey, raise the level
    # (royal_jelly becomes true), return true.

=====================================================================
FILE 2: honey_math.gd
=====================================================================

class_name HoneyMath         # optional
extends RefCounted

const BOTTLE_SIZE: float = 250.0      # honey per bottle

static func bottles_for(honey: float) -> int
    # Whole bottles that fit in `honey` (floor division). Never negative: clamp to 0.

static func jar_price(bottles: int, base: float = 3.5) -> float
    # Tiered per-bottle pricing, `base` = full price per bottle:
    #   first 12 bottles        -> base each
    #   bottles 13..48          -> 0.9 * base each
    #   bottles beyond 48       -> 0.8 * base each
    # Round the total to 2 decimals before returning.

static func short_label(amount: float) -> String
    # 1000 honey = 1 kg.
    # amount < 1000      -> "<n> g"   (integer grams, floor, clamped to 0)
    # amount >= 1000     -> "<x.xx> kg"  (2 decimals, e.g. "1.50 kg")

=====================================================================
OUTPUT FORMAT (strict)
=====================================================================
Output beehive.gd's complete source in one fenced code block tagged gdscript, then
honey_math.gd's complete source in a second fenced code block. No prose before,
between, or after the fences. No tests, no usage examples, no comments outside the
code blocks.
