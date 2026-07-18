class_name Tile
extends Area2D


var current_level : Level :
	get:
		if not current_level:
			# Assuming this is Level vvv
			current_level = get_parent().get_parent()
		return current_level

var object_unit : ObjectUnit = null

var neighbor_tiles : Dictionary[Vector2i, Tile] = {} :
	get = get_neighbor_tiles

var current_position : Vector2i = Vector2i.ZERO

var next_tile : Tile = null :
	set = set_next_tile,
	get = get_next_tile

var walkable : bool = true :
	get = is_walkable
var selected : bool = false


@onready var selected_overlay : Sprite2D = $Sprite/SelectedOverlay
@onready var move_target : Marker2D = $MoveTarget


func _ready() -> void:
	selected_overlay.hide()
	$PositionXLabel.text = str(current_position.x)
	$PositionYLabel.text = str(current_position.y)


func pathfind() -> bool:
	return false


func move_object_unit(direction : Vector2i) -> void:
	object_unit.move_to(direction)
	if is_instance_valid(object_unit):
		object_unit.queue_free()
		object_unit = null


func receive_object_unit(new_object_unit : ObjectUnit) -> void:
	if is_instance_valid(new_object_unit):
		add_child(new_object_unit)
		object_unit = new_object_unit


func update_position(direction : Vector2i) -> void:
	current_position += direction
	$PositionXLabel.text = str(current_position.x)
	$PositionYLabel.text = str(current_position.y)


func set_neighbor_tiles() -> void:
	var up_position : Vector2i = Vector2i(current_position + Vector2i.UP)
	var left_position : Vector2i = Vector2i(current_position + Vector2i.LEFT)
	var right_position : Vector2i = Vector2i(current_position + Vector2i.RIGHT)
	var down_position : Vector2i = Vector2i(current_position + Vector2i.DOWN)

	for pos in [up_position, left_position, right_position, down_position]:
		if pos not in current_level.tiles:
			continue

		var neighbor : Tile = current_level.tiles[pos]
		neighbor_tiles[pos] = neighbor


func set_next_tile(tile : Tile) -> void:
	if not tile in neighbor_tiles.values():
		push_error("Can't set next tile because passed Tile is not a neigbor.")
		return

	next_tile = neighbor_tiles.get(tile.current_position)


	# Debug idk
	if current_position == Vector2i(1, 1):
		print("neighbors: ", neighbor_tiles.keys())
		print("target next tile: ", tile.current_position)
	var neighbor_index : int = 0
	for neighbor in neighbor_tiles.values():
		if current_position == Vector2i(1, 1):
			print("neighbor #", neighbor_index, ":", neighbor.current_position)
		if neighbor.current_position == tile.current_position:
			if current_position == Vector2i(1, 1):
				print("what #", neighbor_index)
			$ArrowDebug.rotation = 90 * neighbor_index
			break
		neighbor_index += 1


func get_next_tile() -> Tile:
	if next_tile == null:
		push_error("Next tile is null.")
	return next_tile


func get_neighbor_tiles() -> Dictionary:
	return neighbor_tiles


func is_walkable() -> bool:
	return walkable


## Returns true if an object unit is occupying this tile.
func is_occupied() -> bool:
	return object_unit != null


func select() -> void:
	selected = true
	current_level.selected_tile_location = current_position
	selected_overlay.show()


func deselect() -> void:
	selected = false
	selected_overlay.hide()


func _on_mouse_entered() -> void:
	select()


func _on_mouse_exited() -> void:
	deselect()
