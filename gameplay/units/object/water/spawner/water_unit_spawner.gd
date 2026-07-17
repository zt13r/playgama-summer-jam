class_name WaterUnitSpawner
extends WaterObjectUnit

## Key (PackedScene) will be WaterEntityUnits.
## Value (String) will be their spawn-picking weights.
## Higher value = higher chance of being picked,
## in relation to other Unit's weights)
@export var water_entity_units : Dictionary[PackedScene, int] = {}

@export var spawner_minimum_interval : float = 3.0
@export var spawner_maximum_interval : float = 10.0


var entity_units : Node2D = null

var minimum_spawn_interval : float = 0.0
var maximum_spawn_interval : float = 0.0
var spawner_interval_decrement : float = 0.0


@onready var spawn_interval_timer : Timer = $SpawnIntervalTimer


func _ready() -> void:
	spawner_interval_decrement = Game.get_spawn_interval_decrement()
	minimum_spawn_interval = spawner_minimum_interval - spawner_interval_decrement
	maximum_spawn_interval = spawner_maximum_interval - spawner_interval_decrement

	entity_units = get_tree().get_first_node_in_group("EntityUnits")

	#await get_tree().create_timer(Game.first_wave_grace_period).timeout
	spawn_interval_timer.start()
	spawn_interval_timer.stop()


func _spawn_unit(water_unit_scene : PackedScene) -> void:
	if entity_units == null:
		push_error("EntityUnit reference is null")
		return

	var water_unit : WaterEntityUnit = water_unit_scene.instantiate() as WaterEntityUnit
	if water_unit == null:
		push_error("WaterUnit instance is null.")
		return

	water_unit.current_position = current_position
	entity_units.add_child.call_deferred(water_unit)


func _on_spawn_interval_timer_timeout() -> void:
	if water_entity_units.is_empty():
		push_error("WaterUnitSpawner has no units")
		return
	var unit_to_spawn_scene : PackedScene = null

	var weight_sum : int = 0

	# Get weight
	for w in water_entity_units.values():
		weight_sum += w

	var weight : int = randi_range(0, weight_sum)

	# Get random WaterEntityUnit according to its weight value
	for unit in water_entity_units:
		if weight <= water_entity_units[unit]:
			unit_to_spawn_scene = unit
			break
		weight -= water_entity_units[unit]

	# Fallback if unit_to_spawn_scene is null,
	# Assign first WaterEntityUnit in the list
	if unit_to_spawn_scene == null:
		unit_to_spawn_scene = water_entity_units.keys()[0]

	# Spawn
	_spawn_unit(unit_to_spawn_scene)

	# Update for next spawn
	var wait_time : float = randf_range(minimum_spawn_interval, maximum_spawn_interval)
	spawn_interval_timer.wait_time = wait_time
