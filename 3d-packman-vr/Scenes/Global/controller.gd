extends Node

func _ready():
	print("Joypads:", Input.get_connected_joypads())
	Input.joy_connection_changed.connect(func(id, connected, _name): print("Joy:", id, connected, _name))

func _unhandled_input(e):
	if e is InputEventJoypadButton and e.pressed:
		print("JOY BUTTON:", e.button_index)
	elif e is InputEventJoypadMotion:
		if abs(e.axis_value) > 0.5:
			print("JOY AXIS:", e.axis, "val:", e.axis_value)
	elif e is InputEventKey and e.pressed:
		print("KEY:", OS.get_keycode_string(e.keycode))
