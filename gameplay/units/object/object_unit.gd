@abstract
class_name ObjectUnit
extends Unit


# Within range
enum TargetType {
	NEAREST, # unit closest to this unit
	LOWEST_HEALTH, # unit with lowest absolute health
	PRIORITY_LEVEL, # unit with highest priority level
	FRONTLINE, # unit closest to the core
}


@export var target_type : TargetType = TargetType.FRONTLINE


func _physics_process(_delta: float) -> void:
	_attack_according_to_target_type()


func _attack_according_to_target_type() -> void:
	match target_type:
		TargetType.NEAREST: _attack_nearest_target()
		TargetType.LOWEST_HEALTH: _attack_lowest_health_target()
		TargetType.PRIORITY_LEVEL: _attack_highest_priority_target()
		TargetType.FRONTLINE: _attack_target_closest_to_core()


func move_to(direction : Vector2i) -> void:
	current_position += direction
	current_tile = get_tile(current_position)
	current_tile.receive_object_unit(self)


@abstract func _attack_nearest_target() -> void
@abstract func _attack_lowest_health_target() -> void
@abstract func _attack_highest_priority_target() -> void
@abstract func _attack_target_closest_to_core() -> void
