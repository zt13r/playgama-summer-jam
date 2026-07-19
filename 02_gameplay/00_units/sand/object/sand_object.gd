@abstract
class_name SandObject
extends SandUnit


func _ready() -> void:
	super()
	current_level.generate_flow_field()
