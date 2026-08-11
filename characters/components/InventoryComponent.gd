class_name InventoryComponent
extends Node
## A slot-based inventory of stacked items, shared by Player and NPC.
##
## Stacks are `{ "item": ItemData, "count": int }`. Stacking respects each item's
## max_stack. Capacity is a slot count; overflow is reported back to the caller
## rather than silently dropped.

signal inventory_changed()

@export var capacity: int = 24

var _stacks: Array[Dictionary] = []


func get_stacks() -> Array[Dictionary]:
	return _stacks


func is_full() -> bool:
	return _stacks.size() >= capacity


## Adds `count` of `item`. Returns the number that did NOT fit.
func add(item: ItemData, count: int = 1) -> int:
	if item == null or count <= 0:
		return count

	var remaining := count
	# Top up existing stacks first.
	if item.is_stackable():
		for stack in _stacks:
			if _same_item(stack["item"], item):
				var space: int = item.max_stack - int(stack["count"])
				if space > 0:
					var moved: int = mini(space, remaining)
					stack["count"] = int(stack["count"]) + moved
					remaining -= moved
					if remaining == 0:
						break

	# New stacks for the rest.
	while remaining > 0 and not is_full():
		var chunk: int = mini(item.max_stack, remaining)
		_stacks.append({"item": item, "count": chunk})
		remaining -= chunk

	if remaining < count:
		inventory_changed.emit()
	return remaining


## Removes up to `count` of `item`. Returns true if the full amount was removed.
func remove(item: ItemData, count: int = 1) -> bool:
	if item == null or count <= 0:
		return false
	if count_of(item) < count:
		return false

	var remaining := count
	for i in range(_stacks.size() - 1, -1, -1):
		if _same_item(_stacks[i]["item"], item):
			var take: int = mini(int(_stacks[i]["count"]), remaining)
			_stacks[i]["count"] = int(_stacks[i]["count"]) - take
			remaining -= take
			if int(_stacks[i]["count"]) <= 0:
				_stacks.remove_at(i)
			if remaining == 0:
				break
	inventory_changed.emit()
	return true


func remove_by_id(item_id: StringName, count: int = 1) -> bool:
	var item := find_by_id(item_id)
	if item == null:
		return false
	return remove(item, count)


func has(item: ItemData, count: int = 1) -> bool:
	return count_of(item) >= count


func has_id(item_id: StringName, count: int = 1) -> bool:
	return count_of_id(item_id) >= count


func count_of(item: ItemData) -> int:
	if item == null:
		return 0
	var total := 0
	for stack in _stacks:
		if _same_item(stack["item"], item):
			total += int(stack["count"])
	return total


func count_of_id(item_id: StringName) -> int:
	var total := 0
	for stack in _stacks:
		if (stack["item"] as ItemData).id == item_id:
			total += int(stack["count"])
	return total


func find_by_id(item_id: StringName) -> ItemData:
	for stack in _stacks:
		if (stack["item"] as ItemData).id == item_id:
			return stack["item"]
	return null


func _same_item(a: ItemData, b: ItemData) -> bool:
	if a == b:
		return true
	return a != null and b != null and a.id != &"" and a.id == b.id
