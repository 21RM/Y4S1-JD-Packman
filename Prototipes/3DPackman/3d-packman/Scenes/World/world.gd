extends Node3D


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("toggle_camera"):
		if $WorldCamera.current == true:
			$Packman.activate_camera()
		else:
			$WorldCamera.current = true
