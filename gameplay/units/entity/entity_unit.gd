@abstract
class_name EntityUnit
extends Unit


var move_target : Marker2D = null

var move_speed : float = 100.0
var is_moving = false


func _physics_process(delta: float) -> void:
	if is_moving == true:
		_move(delta)


func _move(delta : float) -> void:
	global_position = global_position.lerp(
		move_target.global_position, move_speed * delta
	)


func move_to(direction : Vector2i) -> void:
	current_position += direction
	current_tile = get_tile(current_position)

	if current_tile == null:
		return

	move_target = current_tile.move_target
	is_moving = true
