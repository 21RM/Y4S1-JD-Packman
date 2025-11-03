extends Area3D

signal collected(cell: Vector2i)

func _ready():
	connect("body_entered", _on_body_entered)
	for c in $Energizer.get_children():
		if c is GeometryInstance3D:
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Packman":
		FxManager.play_energizer_collected()
		collected.emit(UtilsGrid.world_to_cell(global_position))
		queue_free()
