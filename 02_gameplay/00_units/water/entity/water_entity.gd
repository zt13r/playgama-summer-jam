class_name WaterEntity
extends Unit


@export var move_duration : float = 0.25

var next_tile : Tile = null
var is_moving : bool = false


func _init_unit() -> void:
	super()

	next_tile = current_tile.get_next_tile()
	move_to_next_tile()


# TEMPORARY
func move_to_next_tile() -> void:
	# really temporary, this line below
	# Please think of a better way to move units bro
	if next_tile == null:
		print("target reached")
		return

	var destination : Marker2D = next_tile.unit_target

	var tween : Tween = create_tween()
	tween.tween_property(
		self,
		"global_position",
		destination.global_position,
		move_duration
	)

	await tween.finished

	if destination.get_parent() is Tile:
		current_tile = destination.get_parent()
		next_tile = current_tile.next_tile
	else: # Debug?
		print("uh oh, can't do that")
		push_error("uh oh, can't do that")
		current_tile = null

	move_to_next_tile()
