extends TileMapLayer

const MAP_SIZE := Vector2i(40, 23)

func _ready() -> void:
	for y: int in range(MAP_SIZE.y):
		for x: int in range(MAP_SIZE.x):
			set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
