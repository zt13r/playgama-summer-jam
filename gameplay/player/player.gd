class_name Player
extends CharacterBody2D


@export var move_duration : float = 0.25

var move_tween : Tween = null

var tile_size : int = 0
var moving : bool = false


func _ready() -> void:
	tile_size = Game.get_tile_size()


func _physics_process(_delta: float) -> void:
	pass


func _move(direction : Vector2) -> void:
	if not moving:
		moving = true

		# Actual animation
		move_tween = create_tween()
		move_tween.tween_property(
			self,
			"position",
			position + (direction * tile_size),
			move_duration
		)

		await move_tween.finished
		moving = false
