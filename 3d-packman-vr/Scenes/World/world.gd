extends Node3D

@export_category("Scenes")
@export var wall_scene: PackedScene
@export var door_scene: PackedScene
@export var ghost_scene: PackedScene
@export var dot_scene: PackedScene
@export var energizer_scene: PackedScene

@export_category("Enemies")
@export var ghosts_height: float = 1.0

var ghosts_spawn: Vector3 = Vector3.ZERO
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
	
	instantiate_walls()
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
	
	UtilsGrid.grid_origin = Vector3(-x_offset + UtilsGrid.cell_size * 0.5, 0.0, -z_offset + UtilsGrid.cell_size * 0.5)
	
	for x in range(UtilsGrid.grid_size_x):
		for z in range(UtilsGrid.grid_size_z):
			if UtilsGrid.grid[UtilsGrid.idx(x, z)] == 1:
				var wall: StaticBody3D = wall_scene.instantiate()
				var wall_x: float = (x*UtilsGrid.cell_size) - x_offset + UtilsGrid.cell_size*0.5
				var wall_z: float = (z*UtilsGrid.cell_size) - z_offset + UtilsGrid.cell_size*0.5
				wall.position = Vector3(wall_x, 0, wall_z)
				wall.build(Vector2i(x, z))
				$Walls.add_child(wall)



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
	$UI/DotsRemaining/HBoxContainer/DotNumber.text = str(n)
