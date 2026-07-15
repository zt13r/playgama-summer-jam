class_name Hurtbox
extends Area2D


@export var unit_actor : Unit :
	get:
		if not unit_actor:
			unit_actor = (get_parent()) if (get_parent() is Unit) else null
		return unit_actor
