class_name Level
extends Node2D


const COST_INCREMENT : int = 1


@export var unit_selection : UnitSelection :
	get:
		if not unit_selection:
			unit_selection = get_tree().get_first_node_in_group("UnitSelection")
		return unit_selection

@export_category("Tiles")
@export var tile_y : int = 17
@export_group("Sand")
@export var sand_scene : PackedScene :
	get:
		if not sand_scene:
			sand_scene = preload("uid://3vrxcdogc3cr")
		return sand_scene
@export var sand_x : int = 32
@export_subgroup("Sandcastle")
@export var sandcastle_scene : PackedScene :
	get:
		if not sandcastle_scene:
			sandcastle_scene = preload("uid://81xce2bpxx7n")
		return sandcastle_scene
@export var sand_castle_position : Vector2i = Vector2i(3, 8)
@export_group("Water")
@export var water_scene : PackedScene :
	get:
		if not water_scene:
			water_scene = preload("uid://evo53nikddmg")
		return water_scene
@export var water_x : int = 20
@export_subgroup("Water Spawner")

@export_group("Tide")
@export var time_between_tide_steps : float = 1.0
@export_subgroup("High")
@export var high_tide_steps : int = 5
@export var high_tide_duration : float = 7.0
@export_subgroup("Really High")
@export var really_high_tide_steps : int = 10
@export var really_high_tide_duration : float = 4.0
@export var really_high_tide_chance : float = 0.15


var tiles : Dictionary[Vector2i, Tile] = {}

var tile_size : int = 0

var really_high_tide : bool = false


@onready var sand_tiles : Node2D = %SandTiles
@onready var water_tiles: Node2D = %WaterTiles

@onready var tide_cooldown_timer : Timer = %TideCooldownTimer
@onready var tide_duration_timer : Timer = %TideDurationTimer


func _ready() -> void:
	#tile_size = Game.get_tile_size()
	tile_size = 32

	tide_cooldown_timer.one_shot = true
	tide_duration_timer.one_shot = true

	_load_sand_tiles()
	_load_water_tiles()
	_find_neighbor_tiles_for_each_tile()

	generate_flow_field()

	# Debug
	var entity_scene : PackedScene = load("uid://c725irxxehf6b")
	var entity : WaterEntity = entity_scene.instantiate()
	entity.global_position = get_tile(Vector2i(20, 16)).unit_target.global_position
	entity.current_position = Vector2i(20, 16)
	var water_units : Node2D = get_tree().get_first_node_in_group("WaterUnits")
	water_units.add_child(entity)


func _load_sand_tiles() -> void:
	for x in sand_x:
		for y in tile_y:

			var sand_tile : SandTile = sand_scene.instantiate() as SandTile
			if sand_tile == null:
				push_error("SandTile instance is null.")
				break

			var tile_position : Vector2i = Vector2i(x, y)

			tiles[tile_position] = sand_tile

			sand_tile.current_level = self
			sand_tile.global_position = tile_position * tile_size
			sand_tile.current_position = tile_position
			sand_tiles.add_child(sand_tile)

			if tile_position == sand_castle_position:
				var sandcastle : Sandcastle = sandcastle_scene.instantiate() as Sandcastle
				sandcastle.global_position = get_tile(tile_position).unit_target.global_position
				# Please note of this line ^^^^^
				# It's the way to move units, probably, idk
				sandcastle.current_position = tile_position
				sand_tile.object_unit = sandcastle
				sand_tiles.add_child(sandcastle)


func _load_water_tiles() -> void:
	var x_offset : int = sand_x

	for x in water_x:
		for y in tile_y:

			var water_tile : WaterTile = water_scene.instantiate() as WaterTile
			if water_tile == null:
				push_error("WaterTile instance is null.")
				break

			var tile_position : Vector2i = Vector2i(x + x_offset, y)

			tiles[tile_position] = water_tile

			water_tile.current_level = self
			water_tile.global_position = tile_position * tile_size
			water_tile.current_position = tile_position
			water_tiles.add_child(water_tile)


func _find_neighbor_tiles_for_each_tile() -> void:
	for tile in tiles.values():
		tile.find_neighbor_tiles()


func generate_flow_field() -> void:
	var costs : Dictionary[Vector2i, int] = {}
	var visited : Dictionary[Vector2i, bool] = {}
	var queue : Array[Vector2i] = []
	var target_position : Vector2i = Vector2i(-1, -1)

	# Find target position
	for tile in tiles.values():
		if tile.object_unit is Sandcastle:
			target_position = tile.current_position

	if target_position == Vector2i(-1, -1):
		push_error("Sandcastle not found; cannot start Flow Field.")
		return

	costs[target_position] = 0
	visited[target_position] = true
	queue.append(target_position)

	# Breadth-first Search
	while not queue.is_empty():
		var current_position : Vector2i = queue.pop_front()
		var current_tile : Tile = get_tile(current_position)
		var neighbors : Dictionary[Vector2i, Tile] = \
			current_tile.get_neighbors()

		# Loop through current_tile's neighbors
		for neighbor_position in neighbors:
			var neighbor_tile : Tile = neighbors[neighbor_position]
 
			# Skip if not walkable
			if not neighbor_tile.is_walkable():
				#if neighbor_tile.get_next_tile() == current_tile:
					#neighbor_tile.set_next_tile(null)
				continue

			queue.append(neighbor_position)

			# Skip if already visited
			if neighbor_position in visited:
				queue.erase(neighbor_position)
				continue

			visited[neighbor_position] = true
			costs[neighbor_position] = costs[current_position] + COST_INCREMENT
			neighbor_tile.update_cost_label(costs[neighbor_position])

		# Uncomment to see the calculations much slower,
		# as long as this line vvvvv
		# "neighbor_tile.update_cost_label(costs[neighbor_position])"
		# is not commented out ^^^^^
		# vvvvv
		#await get_tree().process_frame

	# Flow direction
	for tile_position in tiles:
		var current_tile : Tile = get_tile(tile_position)
		var neighbors : Dictionary[Vector2i, Tile] = \
			current_tile.get_neighbors()

		for neighbor_position in neighbors:
			if costs[neighbor_position] < costs[tile_position]:
				var neighbor_tile : Tile = neighbors[neighbor_position]
				current_tile.set_next_tile(neighbor_tile)
				break

		# Uncomment to see the calculations much slower
		#await get_tree().process_frame


func get_tile(pos : Vector2i) -> Tile:
	if not pos in tiles:
		push_error("Tile is out of bounds; cannot retrieve reference.")
		return null
	return tiles[pos]


func high_tide() -> void:
	if randf() <= really_high_tide_chance:
		# Really high tide
		for i in really_high_tide_steps:
			water_tiles.position.x += Vector2i.LEFT.x * tile_size
			# Update tile positions
			for tile in tiles.values():
				if tile is WaterTile:
					tile.update_position(Vector2i.LEFT)
			# Wait n seconds
			await get_tree().create_timer(time_between_tide_steps).timeout
		really_high_tide = true
	else:
		# High tide
		for i in high_tide_steps:
			water_tiles.position.x += Vector2i.LEFT.x * tile_size
			# Update tile positions
			for tile in tiles.values():
				if tile is WaterTile:
					tile.update_position(Vector2i.LEFT)
			# Wait n seconds
			await get_tree().create_timer(time_between_tide_steps).timeout

	tide_duration_timer.start()


func low_tide() -> void:
	if really_high_tide == true:
		# Really high tide reverse
		for step in really_high_tide_steps:
			water_tiles.position.x += Vector2i.RIGHT.x * tile_size
			# Update tile positions
			for tile in tiles.values():
				if tile is WaterTile:
					tile.update_position(Vector2i.RIGHT)
			# Wait n seconds
			await get_tree().create_timer(time_between_tide_steps).timeout
		really_high_tide = false
	else:
		# High tide reverse
		for step in high_tide_steps:
			water_tiles.position.x += Vector2i.RIGHT.x * tile_size
			# Update tile positions
			for tile in tiles.values():
				if tile is WaterTile:
					tile.update_position(Vector2i.RIGHT)
			# Wait n seconds
			await get_tree().create_timer(time_between_tide_steps).timeout


func get_tiles() -> Dictionary:
	return tiles


func _on_tide_cooldown_timer_timeout() -> void:
	high_tide()


func _on_tide_duration_timer_timeout() -> void:
	low_tide()
