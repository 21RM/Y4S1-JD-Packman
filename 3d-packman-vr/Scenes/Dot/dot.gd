extends Area3D

signal remove_dot_from_map(cell: Vector2i)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Packman":
		remove_dot_from_map.emit(UtilsGrid.world_to_cell(position))
		FxManager.play_dot()
		queue_free()
