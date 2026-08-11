class_name FortuneService
extends RefCounted
## Resolves a 算命 (fortune-telling) for the player: the player reads someone's
## fortune with 卜術/命術, earning Credits, proficiency and a little 功德.
##
## Reward scales with 卜術 proficiency and the divination tools carried
## (銅錢 / 量子骰子), matching the Kiro economy (算命 路人: 50–200 Credits).

const BASE_MIN := 50
const BASE_MAX := 200

const READINGS: Array[String] = [
	"銅錢落地，三枚皆陽。乾卦——飛龍在天，近日必有貴人自西方來。",
	"梅花逢春，然爻中藏變。財帛宮動，宜守不宜攻，破財可免災。",
	"坎上離下，水火既濟。困局將解，然解局之人，正是你自己。",
	"卦象晦暗，紫氣沉於地底。切莫南行——深坑之下，有眼在窺。",
	"六爻安靜，唯世爻獨發。故人將至，帶來一段你早已遺忘的緣分。",
	"風地觀。卦不言吉凶，只言一字——『看』。你所求之事，答案早已在眼前。",
]

static var _rng: RandomNumberGenerator = null


static func _ensure_rng() -> void:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()


## Returns { credits, divination_gain, fate_gain, karma, reading, accuracy }.
static func divine(player: Player) -> Dictionary:
	_ensure_rng()
	var arts := player.get_arts()
	var inv := player.get_inventory()
	var div_prof := arts.get_proficiency(&"divination")

	var has_coins := inv.has_id(&"tongqian")
	var has_dice := inv.has_id(&"quantum_dice")

	var accuracy := 0.55
	if has_coins:
		accuracy += 0.05
	if has_dice:
		accuracy += 0.10
	accuracy = minf(0.99, accuracy + minf(0.25, float(div_prof) / 40000.0))

	var scale := 1.0 + float(div_prof) / 2000.0
	if has_dice:
		scale += 0.3
	var credits := int(_rng.randi_range(BASE_MIN, BASE_MAX) * scale)

	return {
		"credits": credits,
		"divination_gain": 15 + (5 if has_dice else 0),
		"fate_gain": 5,
		"karma": 2,
		"reading": READINGS[_rng.randi_range(0, READINGS.size() - 1)],
		"accuracy": accuracy,
	}
