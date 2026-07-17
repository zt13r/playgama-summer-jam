class_name Tile
extends Area2D


# Pathfinding vars
# Why am I trying to make my own A*?
var f_cost : float = 0.0
var g_cost : float = 0.0
var h_cost : float = 0.0


var current_level : Level :
	get:
		if not current_level:
			# Assuming this is Level vvv
			current_level = get_parent().get_parent()
		return current_level

var object_unit : ObjectUnit = null

var neighbor_tiles : Dictionary[Vector2i, Tile] = {}
var current_position : Vector2i = Vector2i.ZERO

var walkable : bool = true :
	get = is_walkable


var selected : bool = false


@onready var selected_overlay : Sprite2D = $Sprite/SelectedOverlay
@onready var move_target : Marker2D = $MoveTarget


func _ready() -> void:
	selected_overlay.hide()


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


func get_neighbor_tiles() -> void:
	var up : Vector2i = Vector2i.UP
	var left : Vector2i = Vector2i.LEFT
	var right : Vector2i = Vector2i.RIGHT
	var down : Vector2i = Vector2i.DOWN

	var up_position : Vector2i = Vector2i(current_position + up)
	var left_position : Vector2i = Vector2i(current_position + left)
	var right_position : Vector2i = Vector2i(current_position + right)
	var down_position : Vector2i = Vector2i(current_position + down)

	for pos in [up_position, left_position, right_position, down_position]:
		if pos not in current_level.tiles:
			continue

		var direction : Vector2i = Vector2i.ZERO
		match pos:
			up_position: direction = up
			left_position: direction = left
			right_position: direction = right
			down_position: direction = down
			_: direction = Vector2i.ZERO

		var neighbor : Tile = current_level.tiles[pos]
		neighbor_tiles[direction] = neighbor


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
