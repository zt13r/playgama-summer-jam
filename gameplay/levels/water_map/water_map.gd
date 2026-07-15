class_name WaterMap
extends Node2D


const really_high_tide_chance : float = 0.15


var spawnable_water_units : Array[WaterUnit] = []

var tile_size : int = 0


@onready var hitbox : Area2D = $Hitbox


func _ready() -> void:
	tile_size = Game.get_tile_size()


func high_tide() -> void:
	if randf() < really_high_tide_chance:
		really_high_tide()
		return

	


func really_high_tide() -> void:
	pass


func _on_hitbox_area_entered(unit_hurtbox : Hurtbox) -> void:
	# Only destroy Sand Units
	if not unit_hurtbox.unit_actor is SandUnit:
		return

	var sand_unit : SandUnit = unit_hurtbox.unit_actor as SandUnit
	sand_unit.destroy()
