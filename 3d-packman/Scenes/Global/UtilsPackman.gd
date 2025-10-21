extends Node

var packman: CharacterBody3D

func get_current_cell() -> Vector2i:
	if packman == null:
		return Vector2i(-1, -1)
	return UtilsGrid.world_to_cell(packman.global_position)
