class_name Main
extends Node


var current_level : Level = null

@onready var level_root : Node2D = %LevelRoot

# Debug
@onready var water_entity_unit: WaterEntityUnit = %WaterEntityUnit


func _ready() -> void:
	_init_level()


# Debug
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		water_entity_unit.move_to(Vector2i.RIGHT)
		print("move")


func _init_level() -> void:
	pass
