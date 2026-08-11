class_name FiveElements
extends RefCounted
## 五行相剋 damage multipliers (金木水火土). TABLE[attacker][defender] is the
## multiplier applied to an attack. Values from the Kiro balance sheet.

enum Element { METAL, WOOD, WATER, FIRE, EARTH }

const NAMES := ["金", "木", "水", "火", "土"]

const TABLE := [
	[1.0, 1.5, 0.75, 0.75, 1.25],   # 金 attacks 金/木/水/火/土
	[0.75, 1.0, 1.25, 0.75, 1.5],   # 木
	[1.25, 0.75, 1.0, 1.5, 0.75],   # 水
	[1.5, 1.25, 0.75, 1.0, 0.75],   # 火
	[0.75, 0.75, 1.25, 1.25, 1.0],  # 土
]


static func multiplier(attacker: int, defender: int) -> float:
	if attacker < 0 or attacker > 4 or defender < 0 or defender > 4:
		return 1.0
	return TABLE[attacker][defender]


static func element_name(element: int) -> String:
	if element < 0 or element >= NAMES.size():
		return "?"
	return NAMES[element]
