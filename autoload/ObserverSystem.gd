extends Node
## 世界變動率 (world variance) staging and natural decay.
##
## Defying fate raises 世界變動率; it slowly falls on its own (等待自然降低).
## The stage governs how much attention the Observers (觀察者) pay — the physical
## hunt (patrols / 天使機甲) arrives with the combat phase; K4 provides the
## detection, staging and warnings the combat layer will react to.

enum Stage { SAFE, ALERT, DANGER, RED_ALERT, CRITICAL }

signal stage_changed(stage: int, name: String)

## Points of 變動率 shed per real second while above zero.
@export var decay_per_second: float = 0.5

var _stage: int = Stage.SAFE
var _acc: float = 0.0


func _ready() -> void:
	GameState.world_variance_changed.connect(_on_variance_changed)


func _process(delta: float) -> void:
	if GameState.world_variance <= 0.0:
		return
	_acc += delta
	if _acc >= 0.5:
		GameState.add_world_variance(-decay_per_second * _acc)
		_acc = 0.0


func _on_variance_changed(value: float) -> void:
	var s := stage_for(value)
	if s != _stage:
		_stage = s
		stage_changed.emit(s, stage_name(s))


func current_stage() -> int:
	return _stage


static func stage_for(value: float) -> int:
	if value < 30.0:
		return Stage.SAFE
	elif value < 50.0:
		return Stage.ALERT
	elif value < 70.0:
		return Stage.DANGER
	elif value < 90.0:
		return Stage.RED_ALERT
	return Stage.CRITICAL


static func stage_name(stage: int) -> String:
	match stage:
		Stage.SAFE:
			return "安全區"
		Stage.ALERT:
			return "警戒區"
		Stage.DANGER:
			return "危險區"
		Stage.RED_ALERT:
			return "紅色警報"
		Stage.CRITICAL:
			return "極限狀態"
	return "?"


static func stage_color(stage: int) -> Color:
	match stage:
		Stage.SAFE:
			return Color(0.6, 0.85, 0.6)
		Stage.ALERT:
			return Color(0.9, 0.85, 0.4)
		Stage.DANGER:
			return Color(0.95, 0.6, 0.3)
		Stage.RED_ALERT:
			return Color(0.95, 0.35, 0.3)
		Stage.CRITICAL:
			return Color(1.0, 0.2, 0.25)
	return Color.WHITE
