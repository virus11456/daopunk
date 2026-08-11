class_name WalletComponent
extends Node
## Carried money, shared by Player and NPC (NPCs need funds to trade).

signal money_changed(amount: int)

@export var starting_money: int = 0

var _money: int = 0


func _ready() -> void:
	_money = maxi(0, starting_money)


func get_money() -> int:
	return _money


func can_afford(cost: int) -> bool:
	return _money >= cost


func add(amount: int) -> void:
	if amount == 0:
		return
	_money = maxi(0, _money + amount)
	money_changed.emit(_money)


## Spends `cost` if affordable. Returns true on success.
func spend(cost: int) -> bool:
	if cost < 0 or not can_afford(cost):
		return false
	_money -= cost
	money_changed.emit(_money)
	return true


func to_save() -> Dictionary:
	return {"money": _money}


func from_save(data: Dictionary) -> void:
	_money = maxi(0, int(data.get("money", 0)))
	money_changed.emit(_money)
