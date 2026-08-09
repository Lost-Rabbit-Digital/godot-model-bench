You are an expert Godot 4.7 GDScript programmer. Implement a small, self-contained GREENHOUSE AUTOMATION system as REAL scene-tree nodes.

CONTEXT / HARD CONSTRAINTS
- Two scripts, both loaded by path with load() at runtime by the harness. Do NOT rely on
  class_name globals (a class_name line is optional and harmless, but you must NEVER
  reference another script's class by name, never preload it, never type against it).
  Attach child scripts with set_script(load(...)) as shown below.
- Strongly typed GDScript: every variable, parameter, and function return type annotated.
- No autoloads, no @export, no .tscn files, no RNG. Deterministic.
- All nodes are created in code and added to the tree. The harness instantiates your
  Greenhouse and adds it to the SceneTree root; your _ready() builds the children.

=====================================================================
FILE 1: thermostat.gd — temperature sensor + heater controller node
=====================================================================

API contract (names, signatures, and semantics must match EXACTLY):

class_name Thermostat          # optional
extends Node

signal temperature_changed(value: float)
signal heater_state_changed(on: bool)

var temperature: float = 20.0
var ambient: float = 10.0        # drift target when the heater is off
var heater_on: bool = false

const HEAT_RATE: float = 2.0     # degrees per second while heating
const COOL_RATE: float = 0.5     # degrees per second while off
const MAX_TEMP: float = 25.0

func set_heater(on: bool) -> void
    # Sets heater_on = on and emits heater_state_changed(on).

func _process(delta: float) -> void
    # Drift temperature every frame:
    #   heater_on: temperature = min(temperature + HEAT_RATE * delta, MAX_TEMP)
    #   heater off: temperature = max(temperature - COOL_RATE * delta, ambient)
    # After the value changes, emit temperature_changed(temperature).

=====================================================================
FILE 2: greenhouse.gd — the automation controller
=====================================================================

class_name Greenhouse          # optional
extends Node2D

signal watered(amount: float)
signal report_generated(report: Dictionary)

const WATER_AMOUNT: float = 5.0
const HEATING_THRESHOLD: float = 12.0

var watering_interval: float = 1.5    # seconds — keep this value
var watered_total: float = 0.0
var watered_events: int = 0
var thermostat: Node = null           # duck-typed handle to the Thermostat child

func _ready() -> void
    # Build the children IN THIS ORDER and exactly like this:
    #   1. var t := Node.new()
    #      t.set_script(load("res://submission2/thermostat.gd"))
    #      t.name = "Thermostat"
    #      add_child(t)
    #      thermostat = t
    #   2. var s := Timer.new()
    #      s.name = "Sprinkler"
    #      s.wait_time = watering_interval
    #      s.autostart = true          # set BEFORE add_child, or the timer never starts
    #      add_child(s)
    #      s.timeout.connect(_on_sprinkler_timeout)

func _on_sprinkler_timeout() -> void
    # watered_total += WATER_AMOUNT
    # watered_events += 1
    # watered.emit(WATER_AMOUNT)

func _process(_delta: float) -> void
    # If thermostat != null: thermostat.set_heater(thermostat.temperature < HEATING_THRESHOLD)

func generate_report() -> Dictionary
    # Emits report_generated(report), then returns:
    #   {"moisture": watered_total,
    #    "temperature": thermostat.temperature,
    #    "heater_on": thermostat.heater_on,
    #    "watered_events": watered_events}

=====================================================================
OUTPUT FORMAT (strict)
=====================================================================
Output greenhouse.gd's complete source in one fenced code block tagged gdscript, then
thermostat.gd's complete source in a second fenced code block. No prose before, between,
or after the fences. No tests, no usage examples, no comments outside the code blocks.
