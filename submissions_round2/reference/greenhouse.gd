extends Node2D

signal watered(amount: float)
signal report_generated(report: Dictionary)

const WATER_AMOUNT: float = 5.0
const HEATING_THRESHOLD: float = 12.0

var watering_interval: float = 1.5
var watered_total: float = 0.0
var watered_events: int = 0
var thermostat: Node = null

func _ready() -> void:
	var t: Node = Node.new()
	t.set_script(load("res://submission2/thermostat.gd"))
	t.name = "Thermostat"
	add_child(t)
	thermostat = t
	var s: Timer = Timer.new()
	s.name = "Sprinkler"
	s.wait_time = watering_interval
	s.autostart = true
	add_child(s)
	s.timeout.connect(_on_sprinkler_timeout)

func _on_sprinkler_timeout() -> void:
	watered_total += WATER_AMOUNT
	watered_events += 1
	watered.emit(WATER_AMOUNT)

func _process(_delta: float) -> void:
	if thermostat != null:
		thermostat.set_heater(float(thermostat.get("temperature")) < HEATING_THRESHOLD)

func generate_report() -> Dictionary:
	var report: Dictionary = {
		"moisture": watered_total,
		"temperature": float(thermostat.get("temperature")) if thermostat != null else 0.0,
		"heater_on": bool(thermostat.get("heater_on")) if thermostat != null else false,
		"watered_events": watered_events,
	}
	report_generated.emit(report)
	return report
