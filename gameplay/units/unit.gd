@abstract
class_name Unit
extends Area2D


@export var base_health : float = 100.0
@export var base_damage : float = 5.0


var current_level : Level = null
var current_tile : Tile = null

var current_position : Vector2i = Vector2i.ZERO

var health : float = 0.0
var damage : float = 0.0


@onready var level_root : Node2D = %LevelRoot


func _ready() -> void:
	_init_unit()


func _init_unit() -> void:
	health = base_health
	damage = base_damage

	if level_root == null:
		push_error("LevelRoot is null.")
		return
	if level_root.get_child_count() != 1:
		if level_root.get_child_count() == 0:
			push_error("LevelRoot has no levels.")
		if level_root.get_child_count() >= 2:
			push_error("LevelRoot should only have one loaded level at a time.")
		return

	current_level = level_root.get_child(0)
	current_tile = get_tile(current_position)


func get_tile(pos : Vector2i) -> Tile:
	if current_level == null:
		return null
	return current_level.tiles[pos]


func take_damage(amount : float) -> void:
	health -= amount
	if health <= 0.0:
		destroy()


func destroy() -> void:
	queue_free()


@abstract func move_to(direction : Vector2i) -> void
