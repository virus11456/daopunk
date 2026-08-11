extends Node
## Minimal in-game clock.
##
## Milestone 1 only needs a clock for the HUD and debug overlay. The tactical
## pause / time-scale features (Phase 3) will extend this class rather than
## replace it, so gameplay code should read time through here from the start.

signal minute_passed(day: int, hour: int, minute: int)

## How many real seconds equal one in-game minute.
@export var real_seconds_per_game_minute: float = 0.6

## Start the clock at 08:00 on Day 1.
var day: int = 1
var hour: int = 8
var minute: int = 0

var _accumulator: float = 0.0
var _time_scale: float = 1.0


func _process(delta: float) -> void:
	_accumulator += delta * _time_scale
	while _accumulator >= real_seconds_per_game_minute:
		_accumulator -= real_seconds_per_game_minute
		_advance_one_minute()


func _advance_one_minute() -> void:
	minute += 1
	if minute >= 60:
		minute = 0
		hour += 1
	if hour >= 24:
		hour = 0
		day += 1
	minute_passed.emit(day, hour, minute)


## "14:42"
func get_clock_string() -> String:
	return "%02d:%02d" % [hour, minute]


func get_day_string() -> String:
	return "Day %d" % day


func set_time_scale(scale: float) -> void:
	_time_scale = maxf(0.0, scale)


func pause_time() -> void:
	_time_scale = 0.0


func resume_time() -> void:
	_time_scale = 1.0
