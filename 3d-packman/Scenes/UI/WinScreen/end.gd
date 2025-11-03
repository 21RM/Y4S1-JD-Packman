extends CanvasLayer

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func on_main_menu_mouse_entered() -> void:
	FxManager.play_button_houver()

func on_main_menu_mouse_exited() -> void:
	FxManager.play_button_houver_exit()

func _on_main_menu_button_up() -> void:
	FxManager.play_button_press()
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu/main_menu.tscn")
