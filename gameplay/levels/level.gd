class_name Level
extends Node2D


@export var really_high_tide_chance : float = 0.15

@export_group("Sand")
@export var sand_scene : PackedScene :
	get:
		if not sand_scene:
			sand_scene = preload("uid://3vrxcdogc3cr")
		return sand_scene
@export var sand_columns : int = 32

@export_group("Water")
@export var water_scene : PackedScene :
	get:
		if not water_scene:
			water_scene = preload("uid://evo53nikddmg")
		return water_scene
@export var water_columns : int = 20


var tiles : Dictionary[Vector2i, Tile] = {}

var selected_tile_location : Vector2i = Vector2i.ZERO

var tile_size : int = 0
var tile_rows : int = 18


@onready var sand_tiles : Node2D = $SandTiles
@onready var water_tiles: Node2D = $WaterTiles


func _ready() -> void:
	tile_size = Game.get_tile_size()

	_spawn_sand_tiles()
	_spawn_water_tiles()
	_get_neighbor_tiles_for_each_tile()


func _spawn_sand_tiles() -> void:
	for vec_x in sand_columns:
		for vec_y in tile_rows:

			# Some vars
			var sand_tile : SandTile = sand_scene.instantiate() as SandTile
			if sand_tile == null:
				push_error("Sand tile instance is null.")
				break

			var tile_position : Vector2i = Vector2i(vec_x, vec_y)

			# Add to dictionary
			tiles[tile_position] = sand_tile

			# Tile stuff and adding the tile to the scene
			sand_tile.global_position.x = tile_size * tile_position.x
			sand_tile.global_position.y = tile_size * tile_position.y
			sand_tile.current_position = tile_position
			sand_tiles.add_child(sand_tile)


func _spawn_water_tiles() -> void:
	for vec_x in water_columns:
		for vec_y in tile_rows:

			# Some vars
			var water_tile : WaterTile = water_scene.instantiate() as WaterTile
			if water_tile == null:
				push_error("Water tile instance is null.")
				break

			var tile_position : Vector2i = Vector2i(vec_x + sand_columns, vec_y)

			# Add to dictionary
			tiles[tile_position] = water_tile

			# Tile stuff and adding the tile to the scene
			water_tile.global_position.x = tile_size * tile_position.x
			water_tile.global_position.y = tile_size * tile_position.y
			water_tile.current_position = tile_position
			water_tiles.add_child(water_tile)


func _get_neighbor_tiles_for_each_tile() -> void:
	for tile in tiles.values():
		tile.get_neighbor_tiles()


func high_tide() -> void:
	if randf() <= really_high_tide_chance:
		_really_high_tide()
		return


func _really_high_tide() -> void:
	pass


func _on_tide_timer_timeout() -> void:
	high_tide()
