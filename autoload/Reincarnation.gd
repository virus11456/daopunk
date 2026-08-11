extends Node
## 輪迴 (reincarnation) and 靈魂磨損 (soul wear).
##
## Inheritance across a rebirth follows the Kiro design:
##   功德 (karma)       50%
##   五術熟練度         100%
##   Credits / 聲望     0%   (a fresh Player instance resets these)
##   消耗品             0%
##   靈魂磨損           +1% each rebirth
## Definitions/keepsakes will be added when those systems land.

signal reincarnated(run_index: int)
signal soul_wear_changed(value: float)

const KARMA_INHERIT := 0.5
const SOUL_WEAR_PER_RUN := 0.01

var run_index: int = 1
var soul_wear: float = 0.0
var inherited_proficiency: Dictionary = {}
var inherited_karma: int = 0


## Captures inheritance and resets run-scoped state. Split from the reload so it
## can be exercised in isolation (tests, and the future SaveManager).
func capture_and_advance() -> void:
	var player := GameState.player
	if is_instance_valid(player) and player.has_method("get_arts"):
		inherited_proficiency = (player.get_arts().to_save().get("proficiency", {}) as Dictionary).duplicate()

	inherited_karma = int(GameState.karma * KARMA_INHERIT)
	soul_wear = minf(1.0, soul_wear + SOUL_WEAR_PER_RUN)
	soul_wear_changed.emit(soul_wear)
	run_index += 1

	# Reset run-scoped resources (a new Player node resets Credits/inventory).
	GameState.karma = inherited_karma
	GameState.karma_changed.emit(GameState.karma)
	GameState.world_variance = 0.0
	GameState.world_variance_changed.emit(0.0)
	GameState.world_flags.clear()

	reincarnated.emit(run_index)


## Full rebirth: capture inheritance, then reload the scene for a fresh life.
func reincarnate() -> void:
	capture_and_advance()
	get_tree().reload_current_scene()


## Applied by the Player on spawn: restores 100% of inherited 五術 proficiency.
func apply_to_player(player: Node) -> void:
	if run_index <= 1 or inherited_proficiency.is_empty():
		return
	if player.has_method("get_arts"):
		player.get_arts().from_save({"proficiency": inherited_proficiency})


func repair_soul(amount: float) -> void:
	if amount <= 0.0:
		return
	soul_wear = maxf(0.0, soul_wear - amount)
	soul_wear_changed.emit(soul_wear)


func soul_wear_stage() -> String:
	if soul_wear < 0.30:
		return "穩定"
	elif soul_wear < 0.60:
		return "頭痛 · 幻覺"
	elif soul_wear < 0.90:
		return "失憶 · 人格變化"
	return "瀕臨崩潰"
