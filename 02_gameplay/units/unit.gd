@abstract
class_name Unit
extends Area2D


@export_range(1, 5) var target_priority : int = 1
@export var base_health : float = 100.0
@export var base_damage : float = 5.0


var current_level : Level = null
var current_tile : Tile = null

var current_position : Vector2i = Vector2i.ZERO

var health : float = 0.0
var damage : float = 0.0


func _ready() -> void:
	_init_unit()


func _init_unit() -> void:
	health = base_health
	damage = base_damage

	current_level = get_tree().get_nodes_in_group("LevelRoot")[0].get_child(0)
	current_tile = get_tile(current_position)


func get_tile(pos : Vector2i) -> Tile:
	if current_level == null:
		push_error("Level reference is null.")
		return null
	if pos not in current_level.get_tiles():
		push_error("Unit's tile is somehow out of bounds?")
		return null
	return current_level.get_tiles()[pos]


func get_priority_level() -> int:
	return target_priority


func take_damage(amount : float) -> void:
	health -= amount
	if health <= 0.0:
		destroy()


func destroy() -> void:
	queue_free()
