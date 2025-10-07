extends Area3D

var ghost_type: int
enum GhostState { SCATTER, CHASE }

var state: GhostState = GhostState.SCATTER

var speed: float = 2.5

var center_snap_eps: float = 0.02
var dir: Vector2i = Vector2i(0, -1)
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]

func _init(a_ghost_type: int) -> void:
	ghost_type = a_ghost_type

func _physics_process(delta: float) -> void:
	var current_cell: Vector2i = UtilsGrid.world_to_cell(global_position)
	var current_center: Vector3 = UtilsGrid.cell_to_world(current_cell)
	var to_center: Vector2 = Vector2(global_position.x - current_center.x, global_position.z - current_center.z)
	if to_center.length() <= center_snap_eps:
		global_position.x = current_center.x
		global_position.z = current_center.z
		choose_next_dir(current_cell)
	
	var next_center: Vector3 = UtilsGrid.cell_to_world(current_cell + dir)
	var to_next: Vector3 = (next_center-global_position).normalized()
	var velocity: Vector3 = speed * to_next * delta
	global_position += Vector3(velocity.x, 0, velocity.z)

func choose_next_dir(cell: Vector2i) -> void:
	var pac_cell: Vector2i = UtilsGrid.world_to_cell(UtilsPackman.packman.global_position)
	var best_dir: Vector2i = dir
	var best_score: float = INF
	for d in DIRS:
		if d == -dir:
			continue
		var next_cell: Vector2i = cell + d
		if UtilsGrid.cell_walkable(next_cell):
			var score: float = manhatan(next_cell, pac_cell)
			if score < best_score:
				best_score = score
				best_dir = d
	
	if best_score == INF:
		if UtilsGrid.cell_walkable(cell - dir):
			best_dir = -dir
	dir = best_dir

func manhatan(cell_a: Vector2i, cell_b: Vector2i) -> float:
	return abs(cell_a.x - cell_b.x) + abs(cell_a.y - cell_b.y)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Packman":
		print("U died noob")
