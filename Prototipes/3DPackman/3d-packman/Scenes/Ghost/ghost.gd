extends Area3D
class_name Ghost

var ghost_type: int = 0
enum GhostState { SCATTER, CHASE, RUN }

var state: GhostState = GhostState.SCATTER
var time_in_mode: float = 0.0

var speed: float = 2.1

var path: Array[Vector2i] = []
var path_index: int = 0
var last_plan_target: Vector2i
var last_packman_cell: Vector2i
var time_since_repath: float = 0.0
var repath_every: float = 1.0

var center_snap_eps: float = 0.02
var dir: Vector2i = Vector2i(0, -1)
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]
var current_cell: Vector2i



func set_ghost_type(type: int) -> void:
	ghost_type = type
	# Change Later
	var color: Color = Color(1, 0, 0)
	match ghost_type:
		1: color = Color(1, 0, 0)
		2: color = Color(1, 0.6, 1)
		3: color = Color(0, 1, 1)
		4: color = Color(1.0, 0.5, 0.0)
		_: color = Color(0, 0, 0)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color =  color
	$MeshInstance3D.set_surface_override_material(0, mat)

func _physics_process(delta: float) -> void:
	current_cell = UtilsGrid.world_to_cell(global_position)
	if current_cell == get_corner_cell() and state == GhostState.SCATTER:
		state = GhostState.CHASE
		time_in_mode = 0.0
	var target_cell: Vector2i = compute_target_cell()
	var packman_cell: Vector2i = UtilsPackman.packman.current_cell
	# Testing if it needs replan
	var need_replan: bool = false
	if path.is_empty():
		need_replan = true
	elif target_cell != last_plan_target:
		need_replan = true
	elif state == GhostState.CHASE:
		if packman_cell != last_packman_cell:
			last_packman_cell = packman_cell
			need_replan = true
	else:
		time_since_repath += delta
		if time_since_repath >= repath_every:
			time_since_repath = 0.0
			need_replan = true
	
	if need_replan:
		replan(current_cell, target_cell)
	
	follow_path(delta)



func follow_path(delta) -> void:
	if path.is_empty() or path_index >= path.size():
		return
	
	var current_center: Vector3 = UtilsGrid.cell_to_world(current_cell)
	var to_center: Vector2 = Vector2(global_position.x - current_center.x, global_position.z - current_center.z)
	if to_center.length() <= center_snap_eps:
		global_position.x = current_center.x
		global_position.z = current_center.z
	
	var waypoint_cell: Vector2i = path[path_index]
	if waypoint_cell == current_cell and path_index < path.size() - 1:
		path_index += 1
		waypoint_cell = path[path_index]
	
	var next_center: Vector3 = UtilsGrid.cell_to_world(waypoint_cell)
	var to_next: Vector3 = (next_center-global_position).normalized()
	to_next.y = 0.0
	var dist: float = to_next.length()
	if dist <= center_snap_eps:
		global_position.x = next_center.x
		global_position.z = next_center.z
		var step: Vector2i = waypoint_cell - current_cell
		if step != Vector2i.ZERO:
			dir = step
		if path_index < path.size() - 1:
			path_index += 1
	else:
		var move_dir: Vector3 = to_next.normalized()
		var velocity: Vector3 = speed * move_dir * delta
		if velocity.length() > dist:
			velocity = move_dir * dist
		global_position += Vector3(velocity.x, 0, velocity.z)



func replan(start_cell: Vector2i, goal_cell: Vector2i) -> void:
	last_plan_target = goal_cell
	time_since_repath = 0.0
	path = a_star(start_cell, goal_cell)
	path_index = 0



func compute_target_cell() -> Vector2i:
	if state == GhostState.CHASE:
		return UtilsPackman.packman.current_cell
	else:
		return get_corner_cell()



func manhattan(start: Vector2i, end: Vector2i) -> float:
	return abs(start.x - end.x) + abs(start.y - end.y)



func a_star(start: Vector2i, goal: Vector2i, reverse_penalty: float = 0.0) -> Array[Vector2i]:
	if start == goal:
		return []
	var open: Array[Dictionary] = []
	var closed: Dictionary = {}
	var g_cost: Dictionary = {}
	var came_from: Dictionary = {}
	g_cost[start] = 0.0
	open.append({"cell": start, "g": 0.0, "f": manhattan(start, goal)})
	
	while open.size() > 0:
		open.sort_custom(func(a, b): return a["f"]<b["f"])
		var current_entry: Dictionary = open.pop_front()
		var current: Vector2i = current_entry["cell"]
		if current == goal:
			return reconstruct_path(came_from, current, start)
		closed[current] = true
		
		for d in DIRS:
			var neighbor: Vector2i = current + d
			if not UtilsGrid.cell_walkable(neighbor):
				continue
			if neighbor in closed:
				continue
			var step_cost: float = 1.0
			if reverse_penalty > 0.0 and current == start and d == -dir:
				step_cost += reverse_penalty
			var tentative_g: float = g_cost[current] + step_cost
			if not g_cost.has(neighbor) or tentative_g < g_cost[neighbor]:
				came_from[neighbor] = current
				g_cost[neighbor] = tentative_g
				var f: float = tentative_g + manhattan(neighbor, goal)
				open.append({"cell": neighbor, "g": tentative_g, "f": f})
	
	return []



func reconstruct_path(came_from: Dictionary, current: Vector2i, start: Vector2i) -> Array[Vector2i]:
	var re_path: Array[Vector2i] = []
	var node: Vector2i = current
	while node != null and node != start:
		re_path.append(node)
		if not came_from.has(node):
			break
		node = came_from[node]
	re_path.reverse()
	return re_path



func get_corner_cell() -> Vector2i:
	match ghost_type:
		1: # Blinky
			return Vector2i(UtilsGrid.grid_size_x-2, 1)
		2: # Pinky
			return Vector2i(1, 1)
		3: # Inky
			return Vector2i(UtilsGrid.grid_size_x-2, UtilsGrid.grid_size_z-2)
		4: # Clyde
			return Vector2i(1, UtilsGrid.grid_size_z-2)
		_:
			return Vector2i(1, 1)



func _on_body_entered(body: Node3D) -> void:
	if body.name == "Packman":
		print("U died noob")
