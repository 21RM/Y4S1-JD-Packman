extends CanvasLayer

var text_messages: Array = ["Pac-Man woke up very hungry in his cell...",\
 							"The doors have been opened!",\
							"Go, Pac-Man! Enjoy your meal!",\
							"But beware...",\
							"There are ghosts around..."]

var counter = 0

func _ready():
	$ColorRect/HBoxContainer/VBoxContainer/Label.text = text_messages[0]

func _on_timer_timeout() -> void:
	FxManager.play_button_houver_exit()
	counter += 1
	if (counter == 5):
		get_tree().change_scene_to_file("res://Scenes/UI/MainMenu/main_menu.tscn")
		return
	$ColorRect/HBoxContainer/VBoxContainer/Label.text = text_messages[counter]
	
