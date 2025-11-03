extends CanvasLayer



func _ready() -> void:
	FxManager.play_laughs()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	fit_emitter()

	
func fit_emitter() -> void:
	var vp: Vector2 = get_window().size
	$ColorRect/Control/BlinkyEmitter.process_material.emission_box_extents = Vector3(vp.x, 0, 0)



func _on_try_again_button_up() -> void:
	FxManager.play_button_press()
	FxManager.stop_laughs()
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file("res://Scenes/World/world.tscn")

func _on_main_menu_button_up() -> void:
	FxManager.play_button_press()
	FxManager.stop_laughs()
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu/main_menu.tscn")


func _on_try_again_mouse_entered() -> void:
	FxManager.play_button_houver()

func _on_main_menu_mouse_entered() -> void:
	FxManager.play_button_houver()

func _on_main_menu_mouse_exited() -> void:
	FxManager.play_button_houver_exit()

func _on_try_again_mouse_exited() -> void:
	FxManager.play_button_houver_exit()



func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_fullscreen"):
		var w: Window = get_window()
		w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
