class_name Map
extends Node2D


const SAND_COLUMNS : int = 32
const SAND_ROWS : int = 19
const OCEAN_COLUMNS : int = 8
const OCEAN_ROWS : int = 19

const SAND_TILE_SOURCE_ID : int = 0
const OCEAN_TILE_SOURCE_ID : int = 0
const TRANSITION_TILE_SOURCE_ID : int = 1


var tiles : Dictionary[String, Dictionary] = {}

 # Must match tileset atlas coords
var sand_tile_indices : Array[Vector2i] = [
	Vector2i(1, 1),
	Vector2i(2, 1),
	Vector2i(1, 2),
	Vector2i(2, 2), ]
var ocean_tile_indices : Array[Vector2i] = [
	Vector2i(10, 1),
	Vector2i(11, 1),
	Vector2i(10, 2),
	Vector2i(11, 2), ]
var transition_tile_index_frame_one : Vector2i = Vector2i(7, 2)
var transition_tile_index_frame_two : Vector2i = Vector2i(7, 6)

var tile_size : int = 0
var current_wave_frame : int = 0


@onready var sand_tilemap : TileMapLayer = $Sand
@onready var ocean_tilemap : TileMapLayer = $Ocean

@onready var wave_timer : Timer = $WaveTimer


func _ready() -> void:
	tile_size = Game.get_tile_size()
	_draw_tiles()

	wave_timer.start()


func _draw_tiles() -> void:
	# Sand
	for x in SAND_COLUMNS:
		for y in SAND_ROWS:

			# Store tile type
			tiles[str(Vector2i(x, y))] = {
				"type" : "sand"
			}

			# Draw tile
			sand_tilemap.set_cell(
				Vector2i(x, y),
				SAND_TILE_SOURCE_ID,
				sand_tile_indices.pick_random()
			)

	# Ocean
	for x in OCEAN_COLUMNS:
		for y in OCEAN_ROWS:

			# Start drawing tiles
			# One tile after the last sand column
			var x_offset : int = x + SAND_COLUMNS

			# Store tile type
			tiles[str(Vector2i(x_offset, y))] = {
				"type" : "ocean"
			}

			# Draw tile
			ocean_tilemap.set_cell(
				Vector2i(x_offset, y),
				OCEAN_TILE_SOURCE_ID,
				ocean_tile_indices.pick_random()
			)

	# Sand-Ocean transition
	for y in OCEAN_ROWS:
		var x : int = SAND_COLUMNS # Last sand column

		# Store tile type
		tiles[str(Vector2i(x, y))] = {
			"type" : "transition"
		}

		# Draw tile
		ocean_tilemap.set_cell(
			Vector2i(x, y),
			TRANSITION_TILE_SOURCE_ID,
			transition_tile_index_frame_one
		)

	current_wave_frame = 0


# Move unit to tile
func move(unit, to : Vector2i) -> void:
	pass


func _on_wave_timer_timeout() -> void:
	current_wave_frame = (current_wave_frame + 1) % 2

	# Sand-Ocean transition
	for y in OCEAN_ROWS:
		var x : int = SAND_COLUMNS # Last sand column

		# Store tile type
		tiles[str(Vector2i(x, y))] = {
			"type" : "transition"
		}

		# Draw tile
		ocean_tilemap.set_cell(
			Vector2i(x, y),
			TRANSITION_TILE_SOURCE_ID,
			transition_tile_index_frame_one \
				if current_wave_frame == 0 \
				else transition_tile_index_frame_two
		)
