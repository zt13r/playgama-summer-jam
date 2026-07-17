extends Node


var _tile_size : int = 16 :
	get = get_tile_size
var _current_wave : int = 1
var first_wave_grace_period : float = 5.0 # Seconds

func get_tile_size() -> int:
	return _tile_size


func get_spawn_interval_decrement() -> float:
	return (float(_current_wave) * 0.2)
	# 1 * 0.2 = 0.2
	# 2 * 0.2 = 0.4
	# 3 * 0.2 = 0.6
	# 4 * 0.2 = 0.8
	# 5 * 0.2 = 1.0
	# and so on; essentially 0.(multiple of 20)
