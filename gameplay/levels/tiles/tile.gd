@abstract
class_name Tile
extends Area2D


var current_level : Level :
	get:
		if not current_level:
			# Assuming this is Level vvv
			current_level = get_parent().get_parent()
		return current_level

var object_unit : ObjectUnit = null

var neighbor_tiles : Dictionary[String, Tile] = {}
var current_tile : Vector2i = Vector2i.ZERO

var walkable : bool = true :
	get = is_walkable


func get_neighbor_tiles() -> void:
	var top : Tile = current_level.tiles[
		clamp(
			current_tile + Vector2i.UP,
			Vector2i(0, 0),
			Vector2i(
				current_level.sand_columns + current_level.water_columns,
				current_level.tile_rows - 1)
	)]
	if top == current_level.tiles[current_tile]:
		top = null

	var left : Tile = current_level.tiles[
		clamp(
			current_tile + Vector2i.LEFT,
			Vector2i(0, 0),
			Vector2i(
				current_level.sand_columns + current_level.water_columns,
				current_level.tile_rows - 1)
	)]
	if left == current_level.tiles[current_tile]:
		left = null

	var right : Tile = current_level.tiles[
		clamp(
			current_tile + Vector2i.RIGHT,
			Vector2i(0, 0),
			Vector2i(
				current_level.sand_columns + current_level.water_columns,
				current_level.tile_rows - 1)
	)]
	if right == current_level.tiles[current_tile]:
		right = null

	print(current_level.tile_rows - 1)

	var down : Tile = current_level.tiles[
		clamp(
			current_tile + Vector2i.DOWN,
			Vector2i(0, 0),
			Vector2i(
				current_level.sand_columns + current_level.water_columns,
				current_level.tile_rows - 1)
	)]
	if down == current_level.tiles[current_tile]:
		down = null

	neighbor_tiles["top"] = top
	neighbor_tiles["left"] = left
	neighbor_tiles["right"] = right
	neighbor_tiles["down"] = down


func is_walkable() -> bool:
	return walkable
