class_name Player
extends CharacterBody2D


@export var move_duration : float = 0.25

var input_direction : Vector2 = Vector2.ZERO

var tile_size : int = 0
var moving : bool = false


func _ready() -> void:
	tile_size = Game.get_tile_size()


func _physics_process(_delta: float) -> void:
	if input_direction.y == 0:
		input_direction.x = Input.get_axis("move_left", "move_right")
		_move()
	if input_direction.x == 0:
		input_direction.y = Input.get_axis("move_up", "move_down")
		_move()


func _move() -> void:
	if not moving:
		moving = true

		# Actual animation
		var tween : Tween = create_tween()
		tween.tween_property(
			self,
			"position",
			position + (input_direction * tile_size),
			move_duration
		)

		await tween.finished
		moving = false
