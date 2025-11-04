extends CanvasLayer


var rng: RandomNumberGenerator
@onready var first_option: Button = $HBoxContainer/VBoxContainer/HBoxContainer2/Play


func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	UtilsGrid.build_grid(rng)
	FxManager.play_crickets()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	fit_emitter()
	first_option.grab_focus()
	
func fit_emitter() -> void:
	var vp: Vector2 = get_window().size
	$ColorRect/Control/RedBalls.process_material.emission_box_extents = Vector3(vp.x/2, vp.y/2, 0)
	$ColorRect/Control/RedBalls.global_position = Vector2(vp.x/2, vp.y/2)


func _on_play_button_up() -> void:
	FxManager.stop_crickets()
	FxManager.play_button_press()
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file("res://Scenes/World/world.tscn")

func _on_exit_button_up() -> void:
	FxManager.play_button_press()
	await get_tree().create_timer(0.7).timeout
	get_tree().quit()


func _on_play_mouse_entered() -> void:
	FxManager.play_button_houver()

func _on_play_mouse_exited() -> void:
	FxManager.play_button_houver_exit()


func _on_exit_mouse_entered() -> void:
	FxManager.play_button_houver()

func _on_exit_mouse_exited() -> void:
	FxManager.play_button_houver_exit()




func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_fullscreen"):
		var w: Window = get_window()
		w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
