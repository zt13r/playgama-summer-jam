@abstract
class_name ObjectUnit
extends Unit


func move_to(direction : Vector2i) -> void:
	current_position += direction
	current_tile = get_tile(current_position)
	current_tile.receive_object_unit(self)
