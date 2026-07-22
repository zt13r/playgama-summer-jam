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

#region Sand Tiles
@export_group("Sand")
@export var sand_path_sprite : Texture :
	get:
		if not sand_path_sprite:
			sand_path_sprite = preload("uid://tnt4o36muulu")
		return sand_path_sprite
@export var sand_tile_sprite : Texture :
	get:
		if not sand_tile_sprite:
			sand_tile_sprite = preload("uid://c1xhmon1q60mt")
		return sand_tile_sprite
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
#endregion

#region Water Tiles
@export_group("Water")
@export var water_path_sprite : Texture :
	get:
		if not water_path_sprite:
			water_path_sprite = preload("uid://cmcgi0e5hvyi2")
		return water_path_sprite
@export var water_tile_sprite : Texture :
	get:
		if not water_tile_sprite:
			water_tile_sprite = preload("uid://diu3jxdokpb7u")
		return water_tile_sprite
@export var water_scene : PackedScene :
	get:
		if not water_scene:
			water_scene = preload("uid://evo53nikddmg")
		return water_scene
@export var water_x : int = 20
@export_subgroup("Water Spawner")
@export var water_spawner_scene : PackedScene :
	get:
		if not water_spawner_scene:
			water_spawner_scene = preload("uid://l00qv8rrs54v")
		return water_spawner_scene
@export var water_spawner_positions : Array[Vector2i] = [
	Vector2i(35, 2),
	Vector2i(35, 5),
	Vector2i(35, 8),
	Vector2i(35, 11),
	Vector2i(35, 14),
]
#endregion

#region Tide
@export_group("Tide")
@export var time_between_tide_steps : float = 1.0
@export_subgroup("High")
@export var high_tide_steps : int = 5
@export var high_tide_duration : float = 7.0
@export_subgroup("Really High")
@export var really_high_tide_steps : int = 10
@export var really_high_tide_duration : float = 4.0
@export var really_high_tide_chance : float = 0.15
#endregion

#region Variables
var sand_units : Node2D = null
var water_units : Node2D = null

var selected_unit_scene : PackedScene = null

var tiles : Dictionary[Vector2i, Tile] = {}

var path_to_sandcastle : Array[Tile] = []

var selected_tile_position : Vector2i = Vector2i.ZERO

var tile_size : int = 0

var really_high_tide : bool = false
var path_blocked : bool = false
#endregion

#region Onready
@onready var sand_tiles : Node2D = %SandTiles
@onready var water_tiles : Node2D = %WaterTiles
@onready var water_spawners : Node2D = %WaterSpawners

@onready var tide_cooldown_timer : Timer = %TideCooldownTimer
@onready var tide_duration_timer : Timer = %TideDurationTimer
#endregion


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
	water_units.add_child(entity)
	selected_unit_scene = load("uid://chehuhpiikr44")


func _physics_process(_delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
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

			if tile_position in water_spawner_positions:
				var water_spawner : WaterSpawner = water_spawner_scene.instantiate() as WaterSpawner
				water_spawner.global_position = get_placement(tile_position)
				water_spawner.current_position = tile_position
				water_tile.object_unit = water_spawner
				water_spawners.add_child(water_spawner)


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
			if path_blocked:
				push_error("Don't block the route!")
				return
			tile.set_walkable(false)
			generate_flow_field()

	elif unit is WaterUnit:

		if unit is WaterObject:
			if path_blocked:
				push_error("Don't block the route!")
				return
			tile.set_walkable(false)
			tile.set_next_tile(null)
			generate_flow_field()

		water_units.add_child(unit)

	else:
		push_error("'selected_unit' is neither SandUnit nor WaterUnit.")

	tile.set_buildable(false)


func generate_flow_field() -> void:
	var costs : Dictionary[Vector2i, int] = {}
	var visited : Dictionary[Vector2i, bool] = {}
	var queue : Array[Vector2i] = []
	var target_position : Vector2i = Vector2i(-1, -1)

	# Reset path tile sprites
	for path in path_to_sandcastle:
		if path is WaterTile:
			path.sprite.texture = water_tile_sprite
		elif path is SandTile:
			path.sprite.texture = sand_tile_sprite

	# Find target position
	for tile in tiles.values():
		if tile.object_unit is Sandcastle:
			target_position = tile.current_position
			tile.set_next_tile(null)

	if target_position == Vector2i(-1, -1):
		push_error("Sandcastle not found; cannot start Flow Field.")
		return

	costs[target_position] = 0
	visited[target_position] = true
	queue.append(target_position)

	# Cost calculation using BFS
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
				costs[neighbor_position] = MAX_COST
				continue

			# Skip if already visited
			if neighbor_position in visited:
				continue

			queue.append(neighbor_position)

			visited[neighbor_position] = true
			costs[neighbor_position] = costs[current_position] + COST_INCREMENT

			# Debug
			neighbor_tile.update_cost_label(costs[neighbor_position])

		# Uncomment to see the calculations much slower,
		# as long as this line vvvvv
		# "neighbor_tile.update_cost_label(costs[neighbor_position])"
		# is not commented out ^^^^^
		# vvvvv
		#await get_tree().process_frame

	# Flow calculation
	for tile_position in tiles:
		var current_tile : Tile = get_tile(tile_position)
		var neighbors : Dictionary[Vector2i, Tile] = \
			current_tile.get_neighbors()

		var possible_next_tiles : Array[Tile] = []

		for neighbor_position in neighbors:
			if neighbor_position not in costs or \
				tile_position not in costs:
					continue

			if costs[neighbor_position] <= costs[tile_position]:
				var neighbor_tile : Tile = neighbors[neighbor_position]
				possible_next_tiles.append(neighbor_tile)
				continue

		if possible_next_tiles.is_empty():
			continue

		# Randomize next_tile idk
		var chosen_tile : Tile = possible_next_tiles.pick_random()
		current_tile.set_next_tile(chosen_tile)

		# Uncomment to see the calculations much slower
		#await get_tree().process_frame

	if water_spawners.get_child_count() <= 0:
		push_error("WaterSpawners not real?")
		return

	var spawners : Array[Node] = water_spawners.get_children()
	var can_path : Array[WaterSpawner] = []

	# Path from Spawners to Sandcastle
	for spawner in spawners:
		if not spawner is WaterSpawner:
			push_error("How did a non-WaterSpawner get here?")
			continue
		var spawner_tile : Tile = spawner.current_tile
		var spawner_next_tile : Tile = spawner_tile.get_next_tile()
		if spawner_next_tile == null:
			push_error("Spawner has no next tile.")
			return

		var next_tile : Tile = spawner_next_tile

		# Actual path-ing
		while next_tile.get_next_tile() != null:
			next_tile = next_tile.get_next_tile()
			if next_tile == null:
				break

			# Find path find (?)
			if next_tile.object_unit != null:
				if next_tile.object_unit is Sandcastle:
					can_path.append(spawner)
					break

			# Visual stuff
			if next_tile is SandTile:
				next_tile.sprite.texture = sand_path_sprite
			elif next_tile is WaterTile:
				next_tile.sprite.texture = water_path_sprite

			# Actual-er path-ing (?)
			if next_tile in path_to_sandcastle:
				continue
			path_to_sandcastle.append(next_tile)

		# Last pathfind check idk
		if can_path.is_empty():
			path_blocked = true
		else:
			path_blocked = false


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
		get_tile(selected_tile_position).is_buildable() and \
		get_tile(selected_tile_position).object_unit == null


func _on_tide_cooldown_timer_timeout() -> void:
	high_tide()


func _on_tide_duration_timer_timeout() -> void:
	low_tide()


func _on_unit_selected(unit_scene : PackedScene) -> void:
	selected_unit_scene = unit_scene
