extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Packman":
		FxManager.play_dot()
		queue_free()
