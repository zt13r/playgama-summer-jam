class_name WaterUnitSpawner
extends WaterObjectUnit

## Key (PackedScene) will be WaterEntityUnits.
## Value (String) will be their spawn-picking weights.
## Higher value = higher chance of being picked,
## in relation to other Unit's weights)
@export var water_entity_units : Dictionary[PackedScene, int] = {}

@export var spawner_minimum_interval : float = 3.0
@export var spawner_maximum_interval : float = 10.0


var minimum_spawn_interval : float = 0.0
var maximum_spawn_interval : float = 0.0
var spawner_interval_decrement : float = 0.0


@onready var entity_root : Node2D = %EntityRoot
@onready var spawn_interval_timer : Timer = $SpawnIntervalTimer


func _ready() -> void:
	spawner_interval_decrement = Game.get_spawn_interval_decrement()
	minimum_spawn_interval = spawner_minimum_interval - spawner_interval_decrement
	maximum_spawn_interval = spawner_maximum_interval - spawner_interval_decrement

	await get_tree().create_timer(Game.first_wave_grace_period).timeout
	spawn_interval_timer.start()
	spawn_interval_timer.stop()


func _on_spawn_interval_timer_timeout() -> void:
	if water_entity_units.is_empty():
		return

	

	# Update for next spawn
	var wait_time : float = randf_range(minimum_spawn_interval, maximum_spawn_interval)
	spawn_interval_timer.wait_time = wait_time
