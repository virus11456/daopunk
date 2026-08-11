class_name WorldMap
extends RefCounted
## Builds the placeholder tile ground entirely in code so the prototype needs no
## imported art. A later art pass swaps `_make_tile_texture()` for real atlases
## and this builder keeps its shape.

const TILE_PX := 32

# Atlas tile indices.
const TILE_GRASS_A := 0
const TILE_GRASS_B := 1
const TILE_PATH := 2
const TILE_COUNT := 3


## Creates and returns a painted TileMapLayer covering `size_tiles`.
static func build_ground(size_tiles: Vector2i, rng: RandomNumberGenerator) -> TileMapLayer:
	var tile_set := _make_tile_set()
	var layer := TileMapLayer.new()
	layer.name = "Ground"
	layer.tile_set = tile_set

	for y in size_tiles.y:
		for x in size_tiles.x:
			var pick := TILE_GRASS_A
			var roll := rng.randf()
			if roll > 0.85:
				pick = TILE_GRASS_B
			layer.set_cell(Vector2i(x, y), 0, Vector2i(pick, 0))

	return layer


static func _make_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_PX, TILE_PX)

	var source := TileSetAtlasSource.new()
	source.texture = _make_tile_texture()
	source.texture_region_size = Vector2i(TILE_PX, TILE_PX)
	for i in TILE_COUNT:
		source.create_tile(Vector2i(i, 0))

	tile_set.add_source(source, 0)
	return tile_set


## A 3-tile horizontal atlas: two grass shades and a path tile, with a little
## per-pixel jitter so the ground does not look flat.
static func _make_tile_texture() -> ImageTexture:
	var img := Image.create(TILE_PX * TILE_COUNT, TILE_PX, false, Image.FORMAT_RGBA8)
	# Wasteland palette for 歸墟 (grey/brown dust, faint rust).
	var bases := [
		Color(0.26, 0.25, 0.23),
		Color(0.30, 0.28, 0.24),
		Color(0.34, 0.28, 0.20),
	]
	var jitter := RandomNumberGenerator.new()
	jitter.seed = 12345
	for tile in TILE_COUNT:
		var base: Color = bases[tile]
		for py in TILE_PX:
			for px in TILE_PX:
				var n := jitter.randf_range(-0.03, 0.03)
				var c := Color(
					clampf(base.r + n, 0.0, 1.0),
					clampf(base.g + n, 0.0, 1.0),
					clampf(base.b + n, 0.0, 1.0))
				img.set_pixel(tile * TILE_PX + px, py, c)
	return ImageTexture.create_from_image(img)
