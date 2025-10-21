extends Area3D

signal collected(duration: float)

@export var duration := 8.0  # seconds ghosts stay frightened

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Packman":
		collected.emit(duration)
		queue_free()
