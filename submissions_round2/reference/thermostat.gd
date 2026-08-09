extends Node

signal temperature_changed(value: float)
signal heater_state_changed(on: bool)

var temperature: float = 20.0
var ambient: float = 10.0
var heater_on: bool = false

const HEAT_RATE: float = 2.0
const COOL_RATE: float = 0.5
const MAX_TEMP: float = 25.0

func set_heater(on: bool) -> void:
	heater_on = on
	heater_state_changed.emit(on)

func _process(delta: float) -> void:
	var before: float = temperature
	if heater_on:
		temperature = minf(temperature + HEAT_RATE * delta, MAX_TEMP)
	else:
		temperature = maxf(temperature - COOL_RATE * delta, ambient)
	if not is_equal_approx(before, temperature):
		temperature_changed.emit(temperature)
