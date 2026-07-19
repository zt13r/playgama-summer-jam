class_name Tile
extends Area2D


# Temporary/Debug
const SAND_WALL_SCENE : PackedScene = preload("uid://chehuhpiikr44")


var current_level : Level = null
var object_unit : Unit = null
var next_tile : Tile = null

var neighbors : Dictionary[Vector2i, Tile] = {}

var current_position : Vector2i = Vector2i.ZERO

var highlighted : bool = false
var buildable : bool = true
var walkable : bool = true


@onready var unit_target : Marker2D = %UnitTarget


func _ready() -> void:
	if not is_connected("mouse_entered", _on_mouse_entered):
		connect("mouse_entered", _on_mouse_entered)
	if not is_connected("mouse_exited", _on_mouse_exited):
		connect("mouse_exited", _on_mouse_exited)


func _physics_process(_delta: float) -> void:
	if current_level == null:
		push_error("Level reference is null.")
		set_physics_process(false)
		return

	if highlighted:
		_handle_highlighted_tile()


func _handle_highlighted_tile() -> void:
	# Temporary/Debug
	if Input.is_action_just_pressed("ui_accept"):
		var sand_wall = SAND_WALL_SCENE.instantiate() as SandWall
		sand_wall.global_position = unit_target.global_position
		object_unit = sand_wall
		walkable = false
		add_child(sand_wall)


func update_position(direction : Vector2i) -> void:
	current_position += direction


func find_neighbor_tiles() -> void:
	if current_level == null:
		push_error("Level reference is null.")
		return

	var up_position : Vector2i = Vector2i(current_position + Vector2i.UP)
	var left_position : Vector2i = Vector2i(current_position + Vector2i.LEFT)
	var right_position : Vector2i = Vector2i(current_position + Vector2i.RIGHT)
	var down_position : Vector2i = Vector2i(current_position + Vector2i.DOWN)

	for pos in [up_position, left_position, right_position, down_position]:
		if pos not in current_level.get_tiles():
			continue

		var neighbor : Tile = current_level.get_tiles()[pos]
		neighbors[pos] = neighbor


func set_next_tile(tile : Tile) -> void:
	if tile not in neighbors.values():
		push_error("Can't set next tile because passed Tile is not a neighbor.")
		return

	next_tile = neighbors.get(tile.current_position)

	# Cool debug haha animation idk
	$CostLabelDebug.hide()

	# Arrow debug - points the arrow to next_tile, probably
	match (next_tile.current_position - current_position):
		Vector2i.UP : $ArrowDebug.rotation_degrees = 0.0
		Vector2i.LEFT : $ArrowDebug.rotation_degrees = -90.0
		Vector2i.RIGHT : $ArrowDebug.rotation_degrees = 90.0
		Vector2i.DOWN : $ArrowDebug.rotation_degrees = 180.0


# Debug
func update_cost_label(cost : int) -> void:
	$CostLabelDebug.text = str(cost)


func get_next_tile() -> Tile:
	return next_tile


func get_neighbors() -> Dictionary:
	return neighbors


func get_object_unit() -> Unit:
	if (object_unit is not SandObject) or (object_unit is not WaterObject):
		push_error("'object_unit' is not SandObject or WaterObject; returning 'null'.")
		return null
	return object_unit


func is_buildable() -> bool:
	return buildable


func is_walkable() -> bool:
	return walkable


func _on_mouse_entered() -> void:
	highlighted = true
	print("yay") 


func _on_mouse_exited() -> void:
	highlighted = false
	print("nay")
