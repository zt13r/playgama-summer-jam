class_name Level
extends Node2D


const COST_INCREMENT : int = 1
const MAX_COST : int = 9999


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


var sand_units : Node2D = null
var water_units : Node2D = null

var selected_unit_scene : PackedScene = null

var tiles : Dictionary[Vector2i, Tile] = {}

var selected_tile_position : Vector2i = Vector2i.ZERO

var tile_size : int = 0

var really_high_tide : bool = false

# Flow field
var costs : Dictionary[Vector2i, int] = {}
var visited : Dictionary[Vector2i, bool] = {}
var queue : Array[Vector2i] = []


@onready var sand_tiles : Node2D = %SandTiles
@onready var water_tiles : Node2D = %WaterTiles

@onready var tide_cooldown_timer : Timer = %TideCooldownTimer
@onready var tide_duration_timer : Timer = %TideDurationTimer


func _ready() -> void:
	tile_size = Game.get_tile_size()

	tide_cooldown_timer.one_shot = true
	tide_duration_timer.one_shot = true

	unit_selection.unit_selected.connect(_on_unit_selected)

	sand_units = get_tree().get_first_node_in_group("SandUnits")
	water_units = get_tree().get_first_node_in_group("WaterUnits")

	_load_sand_tiles()
	_load_water_tiles()
	_find_neighbor_tiles_for_each_tile()

	generate_flow_field()

	# Debug
	var entity_scene : PackedScene = load("uid://c725irxxehf6b")
	var entity : WaterEntity = entity_scene.instantiate()
	entity.global_position = get_tile(Vector2i(20, 16)).unit_target.global_position
	entity.current_position = Vector2i(20, 16)
	water_units = get_tree().get_first_node_in_group("WaterUnits")
	water_units.add_child(entity)
	selected_unit_scene = load("uid://chehuhpiikr44")


func _input(event: InputEvent) -> void:
	if event.is_pressed():
		if can_place_unit():
			_place_unit()


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
				sandcastle.global_position = get_placement(tile_position)
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


func _place_unit() -> void:
	var unit : Unit = selected_unit_scene.instantiate() as Unit
	var tile : Tile = get_tile(selected_tile_position)

	unit.current_position = selected_tile_position
	unit.global_position = get_placement(selected_tile_position)

	if unit is SandUnit:
		sand_units.add_child(unit)

		if unit is SandObject:
			if not can_pathfind():
				push_error("Don't block the route!")
				return
			tile.set_walkable(false)
			_update_costs(selected_tile_position)
			_update_flow(selected_tile_position)

	elif unit is WaterUnit:

		if unit is WaterObject:
			if not can_pathfind():
				push_error("Don't block the route!")
				return
			tile.set_walkable(false)
			_update_costs(selected_tile_position)
			_update_flow(selected_tile_position)

		water_units.add_child(unit)

	else:
		push_error("'selected_unit' is neither SandUnit nor WaterUnit.")

	tile.set_buildable(false)


func _update_costs(tile_position : Vector2i) -> void:
	var current_tile : Tile = get_tile(tile_position)
	var neighbors : Dictionary[Vector2i, Tile] = \
		current_tile.get_neighbors()

	# Loop through current_tile's neighbors
	for neighbor_position in neighbors:
		var neighbor_tile : Tile = neighbors[neighbor_position]

		# Skip if not walkable
		if not neighbor_tile.is_walkable():
			costs[neighbor_position] = MAX_COST
			continue

		# Skip if already visited
		if neighbor_position in visited:
			continue

		queue.append(neighbor_position)

		visited[neighbor_position] = true
		costs[neighbor_position] = costs[tile_position] + COST_INCREMENT

		# Debug
		neighbor_tile.update_cost_label(costs[neighbor_position])


func _update_flow(tile_position : Vector2i) -> void:
	var current_tile : Tile = get_tile(tile_position)
	var neighbors : Dictionary[Vector2i, Tile] = \
		current_tile.get_neighbors()

	for neighbor_position in neighbors:
		if neighbor_position not in costs or \
			tile_position not in costs:
				continue

		if costs[neighbor_position] <= costs[tile_position]:
			var neighbor_tile : Tile = neighbors[neighbor_position]
			current_tile.set_next_tile(neighbor_tile)
			break


func generate_flow_field() -> void:
	# Clear
	costs.clear()
	visited.clear()
	queue.clear()

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
		_update_costs(current_position)

		# Uncomment to see the calculations much slower,
		# as long as this line vvvvv
		# "neighbor_tile.update_cost_label(costs[neighbor_position])"
		# is not commented out ^^^^^
		# vvvvv
		#await get_tree().process_frame

	# Flow direction
	for tile_position in tiles:
		_update_flow(tile_position)

		# Uncomment to see the calculations much slower
		#await get_tree().process_frame


func get_tile(pos : Vector2i) -> Tile:
	if not pos in tiles:
		push_error("Tile is out of bounds; cannot retrieve reference.")
		return null
	return tiles[pos]


func get_placement(pos : Vector2i) -> Vector2:
	return get_tile(pos).unit_target.global_position


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


func can_place_unit() -> bool:
	return (selected_unit_scene != null) and \
		(selected_tile_position != Vector2i.ZERO) and \
		get_tile(selected_tile_position).is_buildable()


func can_pathfind() -> bool:
	return true


func _on_tide_cooldown_timer_timeout() -> void:
	high_tide()


func _on_tide_duration_timer_timeout() -> void:
	low_tide()


func _on_unit_selected(unit_scene : PackedScene) -> void:
	selected_unit_scene = unit_scene
