class_name Player
extends CharacterBody2D


@export var move_duration : float = 0.25

var tile_size : int = 0
var moving : bool = false


func _ready() -> void:
	tile_size = Game.get_tile_size()


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("move_up"):
		_move(Vector2(0, -1))
	elif Input.is_action_pressed("move_left"):
		_move(Vector2(-1, 0))
	elif Input.is_action_pressed("move_down"):
		_move(Vector2(0, 1))
	elif Input.is_action_pressed("move_right"):
		_move(Vector2(1, 0))

	move_and_slide()


func _move(direction : Vector2) -> void:
	if not moving:
		moving = true

		var tween : Tween = create_tween()
		tween.tween_property(
			self,
			"position",
			position + (direction * tile_size),
			move_duration
		)

		await tween.finished
		moving = false
