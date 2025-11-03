extends Area3D
class_name Ghost

var ghost_type: int = 0
enum GhostState { SCATTER, CHASE, FRIGHTENED, EATEN, JUMPSCARING}

var state: GhostState = GhostState.SCATTER
var time_in_mode: float = 0.0

const base_speed: float = 2.7
var speed: float = base_speed
var rotation_speed: float = 5.0
var float_t: float = 0
var float_frequency: float = 3
var float_amplitude: float = 0.1

var last_packman_cell: Vector2i

var center_snap_eps: float = 0.02
var dir: Vector2i = Vector2i(0, -1)
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]
var current_cell: Vector2i
var next_cell: Vector2i
var face_override: bool = false
var face_yaw: float = 0.0


@export var blinky_model: PackedScene
@export var pinky_model: PackedScene
@export var inky_model: PackedScene
@export var clyde_model: PackedScene
@export var scared1_model: PackedScene
@export var scared2_model: PackedScene
var ghost_model: Node3D
var frightened_model1: Node3D = null
var frightened_model2: Node3D = null
var flicker: bool = false



func become_frightened() -> void:
	if state == GhostState.EATEN:
		return
	state = GhostState.FRIGHTENED
	speed = base_speed * 0.5
	dir = -dir
	set_frightened_appearance(true)

func frightened_timer_timeout() -> void:
	dir = -dir
	if state == GhostState.FRIGHTENED:
		state = GhostState.CHASE
		speed = base_speed
	set_frightened_appearance(false)

func set_frightened_appearance(frightened: bool):
	if frightened:
		flicker = false
		$FlickerTimer.wait_time = 0.4
		frightened_model1.visible = true
		frightened_model2.visible = false
		ghost_model.visible = false
		$OmniLights/GhostModel.visible = false
		$OmniLights/FrightenedModel1.visible = true
		$OmniLights/FrightenedModel2.visible = false
	elif state != GhostState.EATEN:
		flicker = false
		frightened_model1.visible = false
		frightened_model2.visible = false
		$OmniLights/GhostModel.visible = true
		$OmniLights/FrightenedModel1.visible = false
		$OmniLights/FrightenedModel2.visible = false
		ghost_model.visible = true

func start_frightened_flicker() -> void:
	if state == GhostState.FRIGHTENED:
		flicker = true
		$FlickerTimer.start()

func _on_flicker_timer_timeout() -> void:
	if flicker:
		if frightened_model1.visible == true:
			frightened_model1.visible = false
			frightened_model2.visible = true
			$OmniLights/FrightenedModel1.visible = false
			$OmniLights/FrightenedModel2.visible = true
		elif frightened_model2.visible == true:
			frightened_model1.visible = true
			frightened_model2.visible = false
			$OmniLights/FrightenedModel1.visible = true
			$OmniLights/FrightenedModel2.visible = false
		if $FlickerTimer.wait_time > 0.5:
			$FlickerTimer.wait_time -= 0.015
		$FlickerTimer.start()

func set_ghost_type(type: int) -> void:
	ghost_type = type
	match ghost_type:
		1:
			ghost_model = blinky_model.instantiate()
			$OmniLights/GhostModel.light_color = Color(1, 0, 0)
		2:
			ghost_model = pinky_model.instantiate()
			$OmniLights/GhostModel.light_color = Color(1, 0.0, 0.5)
		3:
			ghost_model = inky_model.instantiate()
			$OmniLights/GhostModel.light_color = Color(0, 1, 1)
		4:
			ghost_model = clyde_model.instantiate()
			$OmniLights/GhostModel.light_color = Color(1, 0.75, 0.25)
	ghost_model.scale = Vector3(0.45, 0.45, 0.45)
	add_child(ghost_model)
	set_cast_shadows_rec(ghost_model, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	
	frightened_model1 = scared1_model.instantiate()
	add_child(frightened_model1)
	set_cast_shadows_rec(frightened_model1, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	frightened_model1.transform = ghost_model.transform
	frightened_model1.visible = false
	
	frightened_model2 = scared2_model.instantiate()
	add_child(frightened_model2)
	set_cast_shadows_rec(frightened_model2, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	frightened_model2.transform = ghost_model.transform
	frightened_model2.visible = false

func _physics_process(delta: float) -> void:
	float_t += delta
	current_cell = UtilsGrid.world_to_cell(global_position)
	if state != GhostState.JUMPSCARING:
		var target_cell: Vector2i = compute_target_cell()
		var current_center: Vector3 = UtilsGrid.cell_to_world(current_cell)
		var at_center: bool = Vector2(global_position.x - current_center.x, global_position.z - current_center.z).length() <= center_snap_eps
		if at_center or next_cell == Vector2i.ZERO:
			next_cell = calculate_next_cell(target_cell)
		move_to_next_cell(delta)
	var base_yaw: float = atan2(-dir.x, -dir.y)
	var target_yaw: float = face_yaw if face_override else base_yaw
	rotation.y = lerp_angle(rotation.y, target_yaw - PI/2, rotation_speed*delta)
	
	# Vertical movement
	var y_val: float = sin(float_t*float_frequency) * float_amplitude
	position.y = 1 + y_val



func calculate_next_cell(target_cell: Vector2i) -> Vector2i:
	var possible_cells: Dictionary = {}
	for d in DIRS:
		var test_cell: Vector2i = current_cell + d
		if !UtilsGrid.in_bounds(test_cell.x, test_cell.y): continue
		if UtilsGrid.can_walk_to_neighbor_cell(current_cell, test_cell):
			possible_cells[test_cell] = d
	if possible_cells.keys().size() == 1:
		return possible_cells.keys()[0]
	var best_cell: Vector2i
	var best_dist: float = INF
	for possible_cell in possible_cells.keys():
		var dist: float = (possible_cell-target_cell).length()
		if dist < best_dist and possible_cells[possible_cell] != -dir:
			best_dist = dist
			best_cell = possible_cell
	return best_cell

func move_to_next_cell(delta: float) -> void:
	var current_center: Vector3 = UtilsGrid.cell_to_world(current_cell)
	var to_center: Vector2 = Vector2(global_position.x - current_center.x, global_position.z - current_center.z)
	if to_center.length() <= center_snap_eps:
		global_position.x = current_center.x
		global_position.z = current_center.z
	var next_center: Vector3 = UtilsGrid.cell_to_world(next_cell)
	var to_next: Vector3 = (next_center-global_position).normalized()
	to_next.y = 0.0
	var dist: float = to_next.length()
	if dist <= center_snap_eps:
		global_position.x = next_center.x
		global_position.z = next_center.z
	else:
		var move_dir: Vector3 = to_next.normalized()
		var step: Vector2i = next_cell - current_cell
		if step != Vector2i.ZERO:
			dir = step
		var velocity: Vector3 = speed * move_dir * delta
		if velocity.length() > dist:
			velocity = move_dir * dist
		global_position += Vector3(velocity.x, 0, velocity.z)


func compute_target_cell() -> Vector2i:
	if UtilsGrid.is_in_spawn_room(current_cell):
		return UtilsGrid.ghost_spawn_room_door
	if state == GhostState.SCATTER:
		return get_corner_cell()
	
	elif state == GhostState.FRIGHTENED:
		var possible_cells: Array = []
		for d in DIRS:
			var test_cell: Vector2i = current_cell + d
			if UtilsGrid.can_walk_to_neighbor_cell(current_cell, test_cell):
				# Avoid going directly back unless trapped
				if d != -dir or possible_cells.is_empty():
					possible_cells.append(test_cell)
		
		if possible_cells.is_empty():
			return current_cell  # stuck, stay in place
		
		return possible_cells[randi() % possible_cells.size()]

	
	else:
		match ghost_type:
			1: # Blinky, directly chases
				return UtilsPackman.packman.current_cell
			2: # Pinky, ambushes ahead
				return UtilsPackman.packman.current_cell + UtilsPackman.packman.dir*8
			3: # Inky, calculates vector with blinky and packman
				var vector: Vector2i = UtilsPackman.packman.current_cell - UtilsGhosts.Blinky.current_cell
				return UtilsPackman.packman.current_cell + vector
			_: # Default
				if (UtilsPackman.packman.current_cell - current_cell).length() > 8:
					return UtilsPackman.packman.current_cell
				else:
					return get_corner_cell()



func changed_state() -> void:
	next_cell = current_cell - dir


func get_corner_cell() -> Vector2i:
	match ghost_type:
		1: # Blinky
			return Vector2i(UtilsGrid.grid_size_x+3, -4)
		2: # Pinky
			return Vector2i(-4, -4)
		3: # Inky
			return Vector2i(UtilsGrid.grid_size_x+3, UtilsGrid.grid_size_z+3)
		4: # Clyde
			return Vector2i(-4, UtilsGrid.grid_size_z+3)
		_:
			return Vector2i(-4, -4)



func _on_body_entered(body: Node3D) -> void:
	if body.name == "Packman":
		if state == GhostState.FRIGHTENED:
			$DeathParticles.emitting = true
			state = GhostState.EATEN
			frightened_model1.visible = false
			frightened_model2.visible = false
			ghost_model.visible = false
			$OmniLights.visible = false
			$DeadTimer.start()
			FxManager.play_ghost_eaten()
		elif state == GhostState.CHASE or state == GhostState.SCATTER:
			UtilsPackman.packman.ghost_made_bad_contact(self)


func set_cast_shadows_rec(node: Node, mode: int) -> void:
	for c in node.get_children():
		if c is GeometryInstance3D:
			c.cast_shadow = mode

func get_jumpscare_camera_position() -> Vector3:
	return $JumpscareMarker.global_position

func _on_dead_timer_timeout() -> void:
	state = GhostState.CHASE
	speed = base_speed
	var spawn_cell: Vector2i = UtilsGrid.ghosts_spawn.position + UtilsGrid.ghosts_spawn.size/2
	global_position = Vector3(UtilsGrid.cell_to_world(spawn_cell).x, 1.0, UtilsGrid.cell_to_world(spawn_cell).z)
	ghost_model.visible = true
	$OmniLights.visible = true
	$OmniLights/GhostModel.visible = true
	$OmniLights/FrightenedModel1.visible = false
	$OmniLights/FrightenedModel2.visible = false
	
	$FlickerTimer.wait_time = 0.4

#================= FUNCTIONS NOT USED NOW BUT MAY BE USED LATER =================#

'func manhattan(start: Vector2i, end: Vector2i) -> float:
	return abs(start.x - end.x) + abs(start.y - end.y)'


# TODO On hold for now, maybe use for trails in the future
'func a_star(start: Vector2i, goal: Vector2i, reverse_penalty: float = 0.0) -> Array[Vector2i]:
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
	
	return []'

'func follow_path(delta) -> void:
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
		global_position += Vector3(velocity.x, 0, velocity.z)'



'func reconstruct_path(came_from: Dictionary, current: Vector2i, start: Vector2i) -> Array[Vector2i]:
	var re_path: Array[Vector2i] = []
	var node: Vector2i = current
	while node != null and node != start:
		re_path.append(node)
		if not came_from.has(node):
			break
		node = came_from[node]
	re_path.reverse()
	return re_path'
