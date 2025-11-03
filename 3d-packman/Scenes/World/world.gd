extends Node3D

@export_category("Scenes")
@export var wall_scene: PackedScene
@export var door_scene: PackedScene
@export var world_door_scene: PackedScene
@export var ghost_scene: PackedScene
@export var dot_scene: PackedScene
@export var energizer_scene: PackedScene

@export_category("Enemies")
@export var ghosts_height: float = 1.0

var ghosts_spawn: Vector3 = Vector3.ZERO
var world_door_segments: Array[Node3D] = []
var prob_scatter: float = 0.10
var prob_chase: float = 0.10
var change_chase_bias: float = 0.002
var prob_min: float = 0.05
var prob_max: float = 0.95
var min_time_scatter: float = 10.0
var min_time_chase: float = 15.0
var time_elapsed: float = 0.0
var ghost_time_elapsed: float = 0.0
var flicker_started: bool = false
const FLICKER_THRESHOLD: float = 5.0
var fov_tween: Tween
var disable_input: bool = false

var energizer_cells = [
	Vector2i(1, 1),
	Vector2i(1, UtilsGrid.grid_size_z - 2),
	Vector2i(UtilsGrid.grid_size_x - 2, 1),
	Vector2i(UtilsGrid.grid_size_x - 2, UtilsGrid.grid_size_z - 2)
]



var game_over_scene: PackedScene = preload("res://Scenes/UI/GameOver/game_over_menu.tscn")


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	UtilsGrid.build_win_corridor()
	instantiate_walls()
	instantiate_world_door()
	ghosts_spawn = get_ghosts_spawn()
	instantiate_ghosts()
	instantiate_energizers()
	instantiate_dots()
	position_player()
	
	#Ghost Spawn Door
	var door_inst: StaticBody3D = door_scene.instantiate()
	door_inst.color_id = 1
	add_child(door_inst)
	door_inst.global_position = UtilsGrid.cell_to_world(UtilsGrid.get_door_cell(UtilsGrid.ghosts_spawn))
	
	for energizer in get_tree().get_nodes_in_group("energizers"):
		energizer.connect("collected", Callable(self, "_on_energizer_collected"))
	
	UtilsPackman.packman = $Packman
	$UI/HPContainer.set_lives($Packman.lifes)
	
	# Music
	FxManager.play_ambient()


func _process(_delta: float) -> void:
	if $UI/TimerContainer.visible:
		$UI/TimerContainer/RevengeTimer/Time.text = "00 : %02d" % int($Timers/FrightenedTimer.time_left)
	
	if !flicker_started and $Timers/FrightenedTimer.time_left > 0.0 and $Timers/FrightenedTimer.time_left <= FLICKER_THRESHOLD:
		flicker_started = true
		for ghost in $Ghosts.get_children():
			ghost.start_frightened_flicker()


func _on_cell_changed():
	instantiate_walls()

func instantiate_walls() -> void:
	for child in $Walls.get_children():
		child.free()
	
	var x_offset: float = (UtilsGrid.grid_size_x * UtilsGrid.cell_size) * 0.5
	var z_offset: float = (UtilsGrid.grid_size_z * UtilsGrid.cell_size) * 0.5
	
	UtilsGrid.grid_origin = Vector3(
		-x_offset + UtilsGrid.cell_size * 0.5,
		0.0,
		-z_offset + UtilsGrid.cell_size * 0.5
	)
	
	# Get door rectangle from UtilsGrid
	var door_rect: Rect2i = UtilsGrid.get_door_rect(UtilsGrid.door_direction)
	var has_door: bool = door_rect.size != Vector2i.ZERO
	
	# 1) WORLD WALLS (main grid)
	for x in range(UtilsGrid.grid_size_x):
		for z in range(UtilsGrid.grid_size_z):
			# Clear door area in main grid
			if has_door:
				if x >= door_rect.position.x and x < door_rect.position.x + door_rect.size.x \
				and z >= door_rect.position.y and z < door_rect.position.y + door_rect.size.y:
					UtilsGrid.grid[UtilsGrid.idx(x, z)] = 0
			
			if UtilsGrid.grid[UtilsGrid.idx(x, z)] == 1:
				var wall: StaticBody3D = wall_scene.instantiate()
				var wall_x: float = (x * UtilsGrid.cell_size) - x_offset + UtilsGrid.cell_size * 0.5
				var wall_z: float = (z * UtilsGrid.cell_size) - z_offset + UtilsGrid.cell_size * 0.5
				wall.position = Vector3(wall_x, 0.0, wall_z)
				wall.build(Vector2i(x, z))
				$Walls.add_child(wall)
	
	# 2) WIN CORRIDOR WALLS (corridor_grid, positioned relative to the door)
	if UtilsGrid.corridor_grid.size() == 0 or not has_door:
		return
	
	# Must match build_win_corridor()
	var door_span: int = door_rect.size.x * door_rect.size.y  # 3 or 4
	
	if UtilsGrid.door_direction == 0 or UtilsGrid.door_direction == 2:
		# Vertical door: corridor width along X, depth along Z
		UtilsGrid.corridor_size_x = door_span + 2
		UtilsGrid.corridor_size_z = UtilsGrid.win_corridor_depth
	else:
		# Horizontal door: corridor width along Z, depth along X
		UtilsGrid.corridor_size_x = UtilsGrid.win_corridor_depth
		UtilsGrid.corridor_size_z = door_span + 2
	
	for cz in range(UtilsGrid.corridor_size_z):
		for cx in range(UtilsGrid.corridor_size_x):
			var corr_idx: int = cx + cz * UtilsGrid.corridor_size_x
			if UtilsGrid.corridor_grid[corr_idx] != 1:
				continue  # only place walls where corridor_grid == 1
			
			var world_cell := Vector2i.ZERO
			
			match UtilsGrid.door_direction:
				0:
					var origin_x_0: int = door_rect.position.x - 1
					var origin_z_0: int = door_rect.position.y - (UtilsGrid.corridor_size_z - 1)
					world_cell.x = origin_x_0 + cx
					world_cell.y = origin_z_0 + cz
				
				2:
					var origin_x_2: int = door_rect.position.x - 1
					var origin_z_2: int = door_rect.position.y + 1
					world_cell.x = origin_x_2 + cx
					world_cell.y = origin_z_2 + cz
				
				1:
					var origin_x_1: int = door_rect.position.x + 1
					var origin_z_1: int = door_rect.position.y - 1
					world_cell.x = origin_x_1 + cx
					world_cell.y = origin_z_1 + cz
				
				3:
					var origin_x_3: int = door_rect.position.x - UtilsGrid.corridor_size_x
					var origin_z_3: int = door_rect.position.y - 1
					world_cell.x = origin_x_3 + cx
					world_cell.y = origin_z_3 + cz
			
			var wall_world_x: float = (world_cell.x * UtilsGrid.cell_size) - x_offset + UtilsGrid.cell_size * 0.5
			var wall_world_z: float = (world_cell.y * UtilsGrid.cell_size) - z_offset + UtilsGrid.cell_size * 0.5
			
			var corridor_wall: StaticBody3D = wall_scene.instantiate()
			corridor_wall.position = Vector3(wall_world_x, 0.0, wall_world_z)

			corridor_wall.build(world_cell, true, Vector2i(cx, cz))

			$Walls.add_child(corridor_wall)



func instantiate_world_door() -> void:
	if world_door_scene == null:
		push_warning("world_door_scene is not set on World node.")
		return

	# Clear any previous barrier (e.g., when regenerating the world)
	for segment in world_door_segments:
		if is_instance_valid(segment):
			segment.queue_free()
	world_door_segments.clear()

	# Door rectangle is precomputed in UtilsGrid
	var door_rect: Rect2i = UtilsGrid.door
	if door_rect.size == Vector2i.ZERO:
		push_warning("UtilsGrid.door is empty — cannot place WorldDoor.")
		return

	# Parent node to keep things organized
	var parent: Node3D
	if has_node("WorldDoor"):
		parent = $WorldDoor
	else:
		parent = Node3D.new()
		parent.name = "WorldDoor"
		add_child(parent)

	# Spawn a WorldDoor instance for each cell in the door rectangle
	for x in range(door_rect.position.x, door_rect.position.x + door_rect.size.x):
		for z in range(door_rect.position.y, door_rect.position.y + door_rect.size.y):
			var door_inst: Node3D = world_door_scene.instantiate()
			parent.add_child(door_inst)
			world_door_segments.append(door_inst)

			# Use the existing helper to convert cell → world
			var cell := Vector2i(x, z)
			door_inst.global_position = UtilsGrid.cell_to_world(cell)

			# Orient door depending on whether it's horizontal or vertical
			if door_rect.size.y == 1:
				door_inst.rotation.y = 0.0        # horizontal door (north/south edge)
			elif door_rect.size.x == 1:
				door_inst.rotation.y = PI * 0.5    # vertical door (east/west edge)

func instantiate_dots() -> void:
	for child in $Dots.get_children():
		child.queue_free()
	
	var x_offset = (UtilsGrid.grid_size_x * UtilsGrid.cell_size) * 0.5
	var z_offset = (UtilsGrid.grid_size_z * UtilsGrid.cell_size) * 0.5
	
	for x in range(UtilsGrid.grid_size_x):
		for z in range(UtilsGrid.grid_size_z):
			if UtilsGrid.grid[UtilsGrid.idx(x, z)] != 0: # s
				continue
			
			if UtilsGrid.is_reserved(x, z):
				continue
			
			if UtilsGrid.grid[UtilsGrid.idx(x, z)] == 0:
				var dot = dot_scene.instantiate()
				var dot_x = (x * UtilsGrid.cell_size) - x_offset + UtilsGrid.cell_size * 0.5
				var dot_z = (z * UtilsGrid.cell_size) - z_offset + UtilsGrid.cell_size * 0.5
				dot.position = Vector3(dot_x, 0.2, dot_z)
				dot.connect("remove_dot_from_map", _on_dot_remove_dot_from_map)
				$Dots.add_child(dot)
			break

func _on_dot_remove_dot_from_map(cell: Vector2i):
	$Map.remove_dot_at(cell)

func instantiate_energizers() -> void:
	for child in $Energizers.get_children():
		child.queue_free()
	
	var x_offset = (UtilsGrid.grid_size_x * UtilsGrid.cell_size) * 0.5
	var z_offset = (UtilsGrid.grid_size_z * UtilsGrid.cell_size) * 0.5
	
	var corner_cells = [
		Vector2i(1, 1),
		Vector2i(1, UtilsGrid.grid_size_z - 2),
		Vector2i(UtilsGrid.grid_size_x - 2, 1),
		Vector2i(UtilsGrid.grid_size_x - 2, UtilsGrid.grid_size_z - 2)
	]
	
	for cell in corner_cells:
		var x = cell.x
		var z = cell.y
		var energizer = energizer_scene.instantiate()
		var energizer_x = (x * UtilsGrid.cell_size) - x_offset + UtilsGrid.cell_size * 0.5
		var energizer_z = (z * UtilsGrid.cell_size) - z_offset + UtilsGrid.cell_size * 0.5
		energizer.position = Vector3(energizer_x, 0.2, energizer_z)
		energizer.connect("collected", _on_energizer_collected)
		$Energizers.add_child(energizer)



func instantiate_ghosts() -> void:
	
	if ghost_time_elapsed >= 0.0 and $Ghosts.get_child_count() == 0:
		var blinky: Ghost = ghost_scene.instantiate()
		blinky.set_ghost_type(1)
		UtilsGhosts.Blinky = blinky
		$Ghosts.add_child(blinky)
		blinky.global_position = ghosts_spawn
	if ghost_time_elapsed >= 5.0 and $Ghosts.get_child_count() == 1:
		var pinky: Ghost = ghost_scene.instantiate()
		pinky.set_ghost_type(2)
		UtilsGhosts.Pinky = pinky
		$Ghosts.add_child(pinky)
		pinky.global_position = ghosts_spawn
	if ghost_time_elapsed >= 10.0 and $Ghosts.get_child_count() == 2:
		var inky: Ghost = ghost_scene.instantiate()
		inky.set_ghost_type(3)
		UtilsGhosts.Inky = inky
		$Ghosts.add_child(inky)
		inky.global_position = ghosts_spawn
	if ghost_time_elapsed >= 15.0 and $Ghosts.get_child_count() == 3:
		var clyde: Ghost = ghost_scene.instantiate()
		clyde.set_ghost_type(4)
		UtilsGhosts.Clyde = clyde
		$Ghosts.add_child(clyde)
		clyde.global_position = ghosts_spawn


func position_player() -> void:
	for child in $Door.get_children():
		child.queue_free()
	var spawn_cell: Vector2i = UtilsGrid.player_spawn.position + UtilsGrid.player_spawn.size/2
	$Packman.global_position = UtilsGrid.cell_to_world(spawn_cell)

func get_ghosts_spawn() -> Vector3:
	var spawn_cell: Vector2i = UtilsGrid.ghosts_spawn.position + UtilsGrid.ghosts_spawn.size/2
	return Vector3(UtilsGrid.cell_to_world(spawn_cell).x, ghosts_height, UtilsGrid.cell_to_world(spawn_cell).z)

func _on_energizer_collected(cell: Vector2i):
	$Map.remove_dot_at(cell)
	for ghost in $Ghosts.get_children():
		ghost.become_frightened()
	$Timers/FrightenedTimer.start()
	flicker_started = false
	$UI/TimerContainer.visible = true
	$ScreenEffects/ColorRect/ScreenAnimations.play("HuntingRed")
	FxManager.enter_energy()
	fov_tween = create_tween()
	fov_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fov_tween.tween_property($Packman/Camera, "fov", 120, 0.6)

func _on_frightened_timer_timeout() -> void:
	for ghost in $Ghosts.get_children():
		ghost.frightened_timer_timeout()
	
	$UI/TimerContainer.visible = false
	$ScreenEffects/ColorRect/ScreenAnimations.play("ResetTexture")
	FxManager.exit_energy()
	fov_tween = create_tween()
	fov_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fov_tween.tween_property($Packman/Camera, "fov", 100, 0.6)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("toggle_camera"):
		if $WorldCamera.current == true:
			$Packman.activate_camera()
		else:
			$WorldCamera.current = true
	if Input.is_action_just_pressed("ui_fullscreen"):
		var w: Window = get_window()
		w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	if !disable_input:
		if Input.is_action_just_pressed("open_map"):
			$Map.visible = true
		if event.is_action_released("open_map"):
			$Map.visible = false


func _on_game_tick() -> void:
	time_elapsed += $Timers/GameTicker.wait_time
	ghost_time_elapsed += $Timers/GameTicker.wait_time
	instantiate_ghosts()
	var base_prob_scatter: float = clamp(prob_scatter - change_chase_bias * time_elapsed, prob_min, prob_max)
	var base_prob_chase: float = clamp(prob_chase + change_chase_bias * time_elapsed, prob_min, prob_max)
	var sum_prob: float = base_prob_scatter + base_prob_chase
	if sum_prob > 1.0:
		base_prob_scatter /= sum_prob
		base_prob_chase /= sum_prob
	for ghost in $Ghosts.get_children():
		ghost.time_in_mode += $Timers/GameTicker.wait_time
		match ghost.state:
			Ghost.GhostState.SCATTER:
				if ghost.time_in_mode >= min_time_scatter and randf() < base_prob_chase:
					ghost.state = Ghost.GhostState.CHASE
					ghost.changed_state()
					ghost.time_in_mode = 0.0
			Ghost.GhostState.CHASE:
				if ghost.time_in_mode >= min_time_chase and randf() < base_prob_scatter:
					ghost.state = Ghost.GhostState.SCATTER
					ghost.changed_state()
					ghost.time_in_mode = 0.0
	
	if ($Packman.current_cell.x < -5 or\
	$Packman.current_cell.y < -5 or\
	$Packman.current_cell.x > UtilsGrid.grid_size_x + 5 or\
	$Packman.current_cell.y > UtilsGrid.grid_size_z + 5)\
	and $Timers/EndGameTimer.is_stopped():
		disable_input = true
		$Packman.input_allowed = false
		$ScreenEffects/ColorRect/ScreenAnimations.play("endgame")
		print("pilinha")
		$Timers/EndGameTimer.start()

func _on_packman_deadly_ghost_touched_me() -> void:
	for ghost in $Ghosts.get_children():
		ghost.speed = 0
		ghost.state = Ghost.GhostState.JUMPSCARING
	$ScreenEffects/ColorRect/ScreenAnimations.play("jumpscare_black")
	$Timers/JumpscareTimer.start()
	FxManager.play_jumpscare()
	FxManager.stop_ambient()
	FxManager.exit_energy()
	
	$UI/TimerContainer.visible = false
	$Map.visible = false
	disable_input = true
	$ScreenEffects/ColorRect/ScreenAnimations.play("ResetTexture")
	FxManager.exit_energy()
	$Packman/Camera.fov = 100



func _on_jumpscare_timer_timeout() -> void:
	$ScreenEffects/ColorRect/ScreenAnimations.stop()
	$ScreenEffects/ColorRect/ScreenAnimations.play("transition_black")
	$Timers/EndOfJumpscareTimer.start()


func _on_end_of_jumpscare_timer_timeout() -> void:
	position_player()
	$Packman.reset_player()
	for ghost in $Ghosts.get_children():
		ghost.free()
	ghost_time_elapsed = 0.0
	$Packman.lifes -= 1
	if $Packman.lifes == 0:
		FxManager.stop_ambient()
		get_tree().change_scene_to_packed(game_over_scene)
	else:
		$UI/HPContainer.set_lives($Packman.lifes)
		disable_input = false
		FxManager.play_ambient()


func _on_packman_close_spawn_room_door() -> void:
	var door_inst: StaticBody3D = door_scene.instantiate()
	$Door.add_child(door_inst)
	door_inst.global_position = UtilsGrid.cell_to_world(UtilsGrid.get_door_cell(UtilsGrid.player_spawn))


func _on_dots_update_dot_count(n: int) -> void:
	$UI/DotsRemaining/VBoxContainer/HBoxContainer/DotNumber.text = str(n)
	if n == 0:
		$UI/DotsRemaining/VBoxContainer/Label.visible = true
		for segment in world_door_segments:
			if is_instance_valid(segment):
				segment.queue_free()
		world_door_segments.clear()
		UtilsGrid.door = Rect2i()


func _on_end_game_timer_timeout() -> void:
	print("should change scenes")
	$ScreenEffects/ColorRect/ScreenAnimations.stop()
	FxManager.stop_ambient()
	get_tree().change_scene_to_file("res://Scenes/UI/WinScreen/end.tscn")
