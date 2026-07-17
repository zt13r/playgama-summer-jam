class_name Level
extends Node2D


@export_group("Sand")
@export var sand_scene : PackedScene :
	get:
		if not sand_scene:
			sand_scene = preload("uid://3vrxcdogc3cr")
		return sand_scene
@export var sand_core_scene : PackedScene :
	get:
		if not sand_core_scene:
			sand_core_scene = load("uid://cd8d5qqtl442s")
		return sand_core_scene
@export var sand_core_spawn_x : int = 2
@export var sand_core_spawn_y : int = -1
@export var sand_columns : int = 32

@export_group("Water")
@export var water_scene : PackedScene :
	get:
		if not water_scene:
			water_scene = preload("uid://evo53nikddmg")
		return water_scene
@export var water_unit_spawner_scene : PackedScene :
	get:
		if not water_unit_spawner_scene:
			water_unit_spawner_scene = preload("uid://djgsglwuvfv6w")
		return water_unit_spawner_scene
@export var water_unit_spawner_x : int = 3
@export var water_columns : int = 20

@export_group("Tide")
@export var high_tide_steps : int = 5
@export var really_high_tide_steps : int = 10
@export var really_high_tide_chance : float = 0.15
@export var time_between_steps : float = 1.0
@export var tide_duration : float = 7.0


var tiles : Dictionary[Vector2i, Tile] = {}

var selected_tile_location : Vector2i = Vector2i.ZERO

var tile_size : int = 0
var tile_rows : int = 17

var really_high_tide_active = false


@onready var sand_tiles : Node2D = $SandTiles
@onready var water_tiles: Node2D = $WaterTiles
@onready var water_unit_spawners : Node2D = $WaterTiles/Spawners

@onready var high_tide_timer : Timer = $HighTideTimer
@onready var tide_duration_timer : Timer = $TideDurationTimer


func _ready() -> void:
	tile_size = Game.get_tile_size()

	high_tide_timer.one_shot = true
	tide_duration_timer.one_shot = true
	tide_duration_timer.wait_time = tide_duration

	_spawn_sand_tiles()
	_spawn_water_tiles()
	_get_neighbor_tiles_for_each_tile()

	# Debug
	#really_high_tide_chance = 1.0
	high_tide_timer.start()


func _physics_process(_delta: float) -> void:
	_cool_wave_animation()


func _spawn_sand_tiles() -> void:
	var sand_core : SandCore = sand_core_scene.instantiate() as SandCore
	if sand_core == null:
		push_error("Sand core instance is null.")
		return

	if sand_core_spawn_y == -1:
		@warning_ignore("integer_division")
		sand_core_spawn_y = tile_rows / 2

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

			# Add SandCore
			if Vector2i(vec_x, vec_y) == Vector2i(sand_core_spawn_x, sand_core_spawn_y):
				sand_core.global_position = tile_position * tile_size
				sand_core.current_position = tile_position
				sand_tile.object_unit = sand_core
				add_child(sand_core)

			# Tile stuff and adding the tile to the scene
			sand_tile.global_position = tile_position * tile_size
			sand_tile.current_position = tile_position
			sand_tiles.add_child(sand_tile)


func _spawn_water_tiles() -> void:
	var x_offset : int = sand_columns

	for vec_x in water_columns:
		for vec_y in tile_rows:

			# Some vars
			var water_tile : WaterTile = water_scene.instantiate() as WaterTile
			if water_tile == null:
				push_error("WaterTile instance is null.")
				break

			var tile_position : Vector2i = Vector2i(vec_x + x_offset, vec_y)

			# Add to dictionary
			tiles[tile_position] = water_tile

			# Tile stuff and adding the tile to the scene
			water_tile.global_position = tile_position * tile_size
			water_tile.current_position = tile_position
			water_tiles.add_child(water_tile)

			var water_unit_spawner : WaterUnitSpawner = water_unit_spawner_scene.instantiate() as WaterUnitSpawner
			if water_unit_spawner == null:
				push_error("WaterUnitSpawner instance is null.")
				continue

			# Add WaterUnitSpawner
			if vec_x == (water_unit_spawner_x):
				water_unit_spawner.global_position = tile_position * tile_size
				water_unit_spawner.current_position = tile_position
				water_tile.object_unit = water_unit_spawner
				water_unit_spawners.add_child(water_unit_spawner)


func _cool_wave_animation() -> void:
	pass


func _get_neighbor_tiles_for_each_tile() -> void:
	for tile in tiles.values():
		tile.get_neighbor_tiles()


func high_tide() -> void:
	if randf() <= really_high_tide_chance:
		# Really high tide
		for i in really_high_tide_steps:
			water_tiles.position.x += Vector2i.LEFT.x * tile_size
			# Update tile positions
			for tile in tiles.values():
				tile.update_position(Vector2i.LEFT)
			await get_tree().create_timer(time_between_steps).timeout
		really_high_tide_active = true
	else:
		# High tide
		for i in high_tide_steps:
			water_tiles.position.x += Vector2i.LEFT.x * tile_size
			# Update tile positions
			for tile in tiles.values():
				tile.update_position(Vector2i.LEFT)
			await get_tree().create_timer(time_between_steps).timeout

	tide_duration_timer.start()


func low_tide() -> void:
	if really_high_tide_active == true:
		# Really high tide reverse
		for step in really_high_tide_steps:
			water_tiles.position.x += Vector2i.RIGHT.x * tile_size
			# Update tile positions
			for tile in tiles.values():
				tile.update_position(Vector2i.LEFT)
			await get_tree().create_timer(time_between_steps).timeout
		really_high_tide_active = false
	else:
		# High tide reverse
		for step in high_tide_steps:
			water_tiles.position.x += Vector2i.RIGHT.x * tile_size
			# Update tile positions
			for tile in tiles.values():
				tile.update_position(Vector2i.LEFT)
			await get_tree().create_timer(time_between_steps).timeout


func _on_tide_timer_timeout() -> void:
	high_tide()


func _on_tide_duration_timer_timeout() -> void:
	low_tide()
