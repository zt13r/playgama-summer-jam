class_name Hitbox
extends Area2D


@export var unit_actor : Unit :
	get:
		if not unit_actor:
			unit_actor = (get_parent()) if (get_parent() is Unit) else null
		return unit_actor


func _on_area_entered(unit_hurtbox: Hurtbox) -> void:
	var unit : Unit = unit_hurtbox.unit_actor as Unit

	unit.take_damage(unit_actor.damage)
