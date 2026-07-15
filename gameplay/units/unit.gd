@abstract
class_name Unit
extends Node2D


@export var base_health : float = 100.0
@export var base_damage : float = 5.0


var current_position : Vector2i = Vector2i.ZERO

var health : float = 0.0
var damage : float = 0.0


func _ready() -> void:
	_init_unit()


func _init_unit() -> void:
	health = base_health
	damage = base_damage


func take_damage(amount : float) -> void:
	health -= amount
	if health <= 0.0:
		destroy()


func destroy() -> void:
	queue_free()
