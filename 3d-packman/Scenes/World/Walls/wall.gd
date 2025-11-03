extends StaticBody3D

var wall_center_bevel_0: PackedScene = preload("res://Assets/Walls/wall_center.glb")
var wall_center_bevel_1: PackedScene = preload("res://Assets/Walls/wall_center_bevel_1.glb")
var wall_center_bevel_2: PackedScene = preload("res://Assets/Walls/wall_center_bevel_2.glb")
var wall_center_bevel_4: PackedScene = preload("res://Assets/Walls/wall_center_bevel_4.glb")
var wall_side: PackedScene = preload("res://Assets/Walls/wall_side.glb")

func build(
	wall_cell: Vector2i,
	use_corridor: bool = false,
	corridor_cell: Vector2i = Vector2i.ZERO
) -> void:
	var neighbors: Array[int] = []

	if use_corridor:
		# Use corridor_grid + also check main grid at the boundary
		for i in range(4):
			var dir: Vector2i = UtilsGrid.DIRS[i]

			# Neighbor in corridor coordinates
			var ncx: int = corridor_cell.x + dir.x
			var ncz: int = corridor_cell.y + dir.y

			var val: int = -1

			if ncx >= 0 and ncx < UtilsGrid.corridor_size_x \
			and ncz >= 0 and ncz < UtilsGrid.corridor_size_z:
				var c_idx: int = ncx + ncz * UtilsGrid.corridor_size_x
				val = UtilsGrid.corridor_grid[c_idx]

			# Also check neighbor in main grid – this makes corridor connect to world walls
			var world_n: Vector2i = wall_cell + dir
			if UtilsGrid.in_bounds(world_n.x, world_n.y) \
			and UtilsGrid.grid[UtilsGrid.idx(world_n.x, world_n.y)] == 1:
				val = 1

			neighbors.append(val)
	else:
		# Original behavior for normal world walls
		for i in range(4):
			var dir: Vector2i = UtilsGrid.DIRS[i]
			var temp_cell: Vector2i = wall_cell + dir
			if UtilsGrid.in_bounds(temp_cell.x, temp_cell.y):
				neighbors.append(UtilsGrid.grid[UtilsGrid.idx(temp_cell.x, temp_cell.y)])
			else:
				neighbors.append(-1)

	var surrounding_walls_count: int = neighbors.count(1)
	var wall_center: Node3D = get_wall_center(neighbors, surrounding_walls_count)
	prep_wall_piece(wall_center)
	add_child(wall_center)
	var wall_sides: Array[Node3D] = get_wall_sides(neighbors)
	for wall_side_inst in wall_sides:
		add_child(wall_side_inst)


func get_wall_sides(neighbors: Array[int]) -> Array[Node3D]:
	var wall_sides: Array[Node3D] = []
	for i in range(neighbors.size()):
		if neighbors[i] == 1:
			var wall_side_inst: Node3D = wall_side.instantiate()
			match i:
				0:
					wall_side_inst.rotation.y = PI/2
					wall_side_inst.position.z -= 0.375
				1:
					wall_side_inst.position.x += 0.375
				2:
					wall_side_inst.rotation.y = PI/2
					wall_side_inst.position.z += 0.375
				3:
					wall_side_inst.position.x -= 0.375
			wall_sides.append(wall_side_inst)
	return wall_sides

func get_wall_center(neighbors: Array[int], count: int) -> Node3D:
	match count:
		0:
			return wall_center_bevel_4.instantiate()
		1:
			var first_1: int = get_idx_in_array(neighbors, 1, 1)
			var wall_center: Node3D = wall_center_bevel_2.instantiate()
			wall_center.rotate_y(-PI/2 * (first_1+1))
			return wall_center
		2:
			var first_1: int = get_idx_in_array(neighbors, 1, 1)
			var second_1: int = get_idx_in_array(neighbors, 1, 2)
			if second_1 - first_1 == 1:
				var wall_center: Node3D = wall_center_bevel_1.instantiate()
				wall_center.rotate_y(-PI/2 * (first_1-2))
				return wall_center
			elif second_1 - first_1 == 3:
				var wall_center: Node3D = wall_center_bevel_1.instantiate()
				wall_center.rotate_y(-PI/2)
				return wall_center
			else:
				return wall_center_bevel_0.instantiate()
		_:
			return wall_center_bevel_0.instantiate()

func prep_wall_piece(wall: Node3D) -> void:
	for c in wall.get_children():
		if c is GeometryInstance3D:
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED

func get_idx_in_array(array: Array[int], value: int, n: int) -> int:
	for i in range(array.size()):
		if array[i] == value:
			n -= 1
			if n == 0:
				return i
	return -1
