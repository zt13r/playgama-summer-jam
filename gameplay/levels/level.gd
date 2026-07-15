class_name Level
extends Node2D


@onready var sand : SandMap = $Sand
@onready var water : WaterMap = $Water

@onready var high_tide_timer : Timer = $HighTideTimer


func _on_high_tide_timer_timeout() -> void:
	print("High tide!")
	water.high_tide()
