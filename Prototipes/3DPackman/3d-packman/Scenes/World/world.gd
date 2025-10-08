extends Node3D

@export_category("Scenes")
@export var wall_scene: PackedScene
@export var ghost_scene: PackedScene

@export_category("World Config")
@export var game_seed: int = 0
@export var wall_height: float = 3.0

@export_category("Enemies")
@export var ghosts_height: float = 1.0

var rng: RandomNumberGenerator


func _ready() -> void:
	rng = RandomNumberGenerator.new()
	if game_seed == 0:
		rng.randomize()
	else:
		rng.seed = game_seed
	
	UtilsGrid.build_grid(rng)
	instantiate_walls()
	instantiate_ghosts()
	position_player()
	position_ghosts()
	
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

func instantiate_ghosts() -> void:
	var ghost: Area3D = ghost_scene.instantiate()
	ghost.ghost_type = 0
	$Ghosts.add_child(ghost)

func position_player() -> void:
	var spawn_cell: Vector2i = UtilsGrid.player_spawn.position + UtilsGrid.player_spawn.size/2
	$Packman.global_position = UtilsGrid.cell_to_world(spawn_cell)

func position_ghosts() -> void:
	var spawn_cell: Vector2i = UtilsGrid.ghosts_spawn.position + UtilsGrid.ghosts_spawn.size/2
	for ghost in $Ghosts.get_children():
		ghost.global_position =  UtilsGrid.cell_to_world(spawn_cell)
		ghost.global_position.y = ghosts_height

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("toggle_camera"):
		if $WorldCamera.current == true:
			$Packman.activate_camera()
		else:
			$WorldCamera.current = true
