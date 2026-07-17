class_name WaterTile
extends Tile


func _on_sand_overlap(area : Area2D) -> void:
	if area is SandTile:
		var sand : SandTile = area as SandTile
		if sand.is_occupied():
			sand.object_unit.destroy()
			sand.object_unit = null
