class_name Region
extends Node2D
## Root of a playable area. Builds the ground, the buildings (visual + solid),
## and the navigation mesh (carved around the buildings) at runtime, then
## registers itself with GameState. Player and NPC instances are placed in the
## scene; everything environmental is generated here so the .tscn stays tiny.

@export var region_name: String = "歸墟 · 蔓哈頓深坑星"
@export var size_tiles: Vector2i = Vector2i(40, 30)

## Building footprints in world pixels. Kept as data so nav carving and visuals
## stay in sync from one source. Locations from 第一宇宙·歸墟.
const BUILDINGS := [
	{"name": "破爛一條街 · 黑市", "rect": Rect2(96, 96, 224, 160), "color": Color(0.36, 0.24, 0.20)},
	{"name": "方舟隱修院", "rect": Rect2(896, 112, 240, 176), "color": Color(0.30, 0.30, 0.36)},
	{"name": "數據陵墓入口", "rect": Rect2(128, 640, 208, 160), "color": Color(0.22, 0.26, 0.30)},
	{"name": "燭龍遺骸", "rect": Rect2(896, 632, 240, 184), "color": Color(0.34, 0.30, 0.24)},
	{"name": "廢土公寓", "rect": Rect2(544, 96, 160, 128), "color": Color(0.32, 0.29, 0.25)},
	{"name": "地心入口", "rect": Rect2(560, 704, 160, 128), "color": Color(0.40, 0.24, 0.12)},
]

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	GameState.current_region = region_name

	_build_ground()
	_build_buildings()
	_build_navigation()


func _build_ground() -> void:
	var ground := WorldMap.build_ground(size_tiles, _rng)
	ground.z_index = -10
	add_child(ground)
	move_child(ground, 0)


func _build_buildings() -> void:
	var container := Node2D.new()
	container.name = "Buildings"
	add_child(container)
	for data in BUILDINGS:
		container.add_child(_make_building(data))


func _make_building(data: Dictionary) -> Node2D:
	var rect: Rect2 = data["rect"]
	var color: Color = data["color"]
	var root := Node2D.new()
	root.name = String(data["name"])
	root.position = rect.position

	# Solid body.
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	shape.position = rect.size * 0.5
	body.add_child(shape)
	root.add_child(body)

	# Visual fill + outline.
	var fill := Polygon2D.new()
	fill.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(rect.size.x, 0),
		rect.size,
		Vector2(0, rect.size.y),
	])
	fill.color = color
	fill.z_index = -5
	root.add_child(fill)

	var outline := Line2D.new()
	outline.points = PackedVector2Array([
		Vector2.ZERO,
		Vector2(rect.size.x, 0),
		rect.size,
		Vector2(0, rect.size.y),
		Vector2.ZERO,
	])
	outline.width = 2.0
	outline.default_color = color.darkened(0.4)
	outline.z_index = -4
	root.add_child(outline)

	# Name tag.
	var tag := Label.new()
	tag.text = String(data["name"])
	tag.position = Vector2(6, 6)
	tag.z_index = -4
	tag.add_theme_font_size_override("font_size", 13)
	tag.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
	tag.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	tag.add_theme_constant_override("outline_size", 3)
	root.add_child(tag)

	return root


func _build_navigation() -> void:
	var nav := NavigationRegion2D.new()
	nav.name = "Navigation"

	var poly := NavigationPolygon.new()
	poly.agent_radius = 12.0

	var source := NavigationMeshSourceGeometryData2D.new()

	# Outer walkable boundary, inset by one tile so agents keep off the edge.
	var inset := float(WorldMap.TILE_PX)
	var w := float(size_tiles.x * WorldMap.TILE_PX)
	var h := float(size_tiles.y * WorldMap.TILE_PX)
	source.add_traversable_outline(PackedVector2Array([
		Vector2(inset, inset),
		Vector2(w - inset, inset),
		Vector2(w - inset, h - inset),
		Vector2(inset, h - inset),
	]))

	# Each building is an obstruction, carved out of the walkable area.
	for data in BUILDINGS:
		var rect: Rect2 = data["rect"]
		source.add_obstruction_outline(PackedVector2Array([
			rect.position,
			Vector2(rect.position.x + rect.size.x, rect.position.y),
			rect.position + rect.size,
			Vector2(rect.position.x, rect.position.y + rect.size.y),
		]))

	NavigationServer2D.bake_from_source_geometry_data(poly, source)
	nav.navigation_polygon = poly
	add_child(nav)
