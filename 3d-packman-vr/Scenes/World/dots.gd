extends Node3D

var dots_count: int = 0

signal update_dot_count(n: int)

func _process(_delta: float) -> void:
	dots_count = get_child_count()
	update_dot_count.emit(dots_count)
