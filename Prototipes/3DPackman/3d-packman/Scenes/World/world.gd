extends Node3D

@export_category("Scenes")
@export var wall_scene: PackedScene
@export var ghost_scene: PackedScene
@export var dot_scene: PackedScene
@export var energizer_scene: PackedScene

@export_category("World Config")
@export var game_seed: int = 0
@export var wall_height: float = 3.0

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

var energizer_cells = [
	Vector2i(1, 1),
	Vector2i(1, UtilsGrid.grid_size_z - 2),
	Vector2i(UtilsGrid.grid_size_x - 2, 1),
	Vector2i(UtilsGrid.grid_size_x - 2, UtilsGrid.grid_size_z - 2)
]


var rng: RandomNumberGenerator


func _ready() -> void:
	rng = RandomNumberGenerator.new()
	if game_seed == 0:
		rng.randomize()
	else:
		rng.seed = game_seed
	
	UtilsGrid.build_grid(rng)
	instantiate_walls()
	ghosts_spawn = get_ghosts_spawn()
	instantiate_ghosts()
	instantiate_energizers()
	instantiate_dots()
	position_player()
	
	for energizer in get_tree().get_nodes_in_group("energizers"):
		energizer.connect("collected", Callable(self, "_on_energizer_collected"))
	
	UtilsPackman.packman = $Packman

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
				wall.position = Vector3(wall_x, wall_height/2, wall_z)
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
				$Dots.add_child(dot)

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
	if time_elapsed >= 0.0 and $Ghosts.get_child_count() == 0:
		var blinky: Ghost = ghost_scene.instantiate()
		blinky.set_ghost_type(1)
		UtilsGhosts.Blinky = blinky
		$Ghosts.add_child(blinky)
		blinky.global_position = ghosts_spawn
	if time_elapsed >= 5.0 and $Ghosts.get_child_count() == 1:
		var pinky: Ghost = ghost_scene.instantiate()
		pinky.set_ghost_type(2)
		UtilsGhosts.Pinky = pinky
		$Ghosts.add_child(pinky)
		pinky.global_position = ghosts_spawn
	if time_elapsed >= 10.0 and $Ghosts.get_child_count() == 2:
		var inky: Ghost = ghost_scene.instantiate()
		inky.set_ghost_type(3)
		UtilsGhosts.Inky = inky
		$Ghosts.add_child(inky)
		inky.global_position = ghosts_spawn
	if time_elapsed >= 15.0 and $Ghosts.get_child_count() == 3:
		var clyde: Ghost = ghost_scene.instantiate()
		clyde.set_ghost_type(4)
		UtilsGhosts.Clyde = clyde
		$Ghosts.add_child(clyde)
		clyde.global_position = ghosts_spawn


func position_player() -> void:
	var spawn_cell: Vector2i = UtilsGrid.player_spawn.position + UtilsGrid.player_spawn.size/2
	$Packman.global_position = UtilsGrid.cell_to_world(spawn_cell)

func get_ghosts_spawn() -> Vector3:
	var spawn_cell: Vector2i = UtilsGrid.ghosts_spawn.position + UtilsGrid.ghosts_spawn.size/2
	return Vector3(UtilsGrid.cell_to_world(spawn_cell).x, ghosts_height, UtilsGrid.cell_to_world(spawn_cell).z)

func _on_energizer_collected(duration: float):
	print("ENERGIZER COLLECTED")
	for ghost in $Ghosts.get_children():
		ghost.become_frightened(duration)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("toggle_camera"):
		if $WorldCamera.current == true:
			$Packman.activate_camera()
		else:
			$WorldCamera.current = true


func _on_game_tick() -> void:
	time_elapsed += $GameTicker.wait_time
	instantiate_ghosts()
	var base_prob_scatter: float = clamp(prob_scatter - change_chase_bias * time_elapsed, prob_min, prob_max)
	var base_prob_chase: float = clamp(prob_chase + change_chase_bias * time_elapsed, prob_min, prob_max)
	var sum_prob: float = base_prob_scatter + base_prob_chase
	if sum_prob > 1.0:
		base_prob_scatter /= sum_prob
		base_prob_chase /= sum_prob
	for ghost in $Ghosts.get_children():
		ghost.time_in_mode += $GameTicker.wait_time
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
