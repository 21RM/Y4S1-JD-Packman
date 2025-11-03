extends StaticBody3D

@export var red_material: Material
@export var blue_material: Material

var color_id: int = 1 : set = set_color_id

func set_color_id(v: int) -> void:
	color_id = v
	var mat: Material = red_material if color_id == 1 else blue_material
	$MeshInstance3D.material_override = mat
