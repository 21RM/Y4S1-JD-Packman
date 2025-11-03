extends Node

var packman: CharacterBody3D


const CURSOR_NORMAL: CompressedTexture2D = preload("res://Assets/Mouse/1.png")
const CURSOR_PRESSED: CompressedTexture2D = preload("res://Assets/Mouse/3.png")
const HOTSPOT := Vector2(1, 8)


func _ready() -> void:
	Input.set_custom_mouse_cursor(CURSOR_NORMAL, Input.CURSOR_ARROW, HOTSPOT)

func get_current_cell() -> Vector2i:
	if packman == null:
		return Vector2i(-1, -1)
	return UtilsGrid.world_to_cell(packman.global_position)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			Input.set_custom_mouse_cursor(CURSOR_PRESSED, Input.CURSOR_ARROW, HOTSPOT)
		else:
			Input.set_custom_mouse_cursor(CURSOR_NORMAL, Input.CURSOR_ARROW, HOTSPOT)
