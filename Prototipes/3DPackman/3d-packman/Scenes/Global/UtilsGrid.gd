extends Node

var grid: PackedByteArray
var grid_origin: Vector3
var cell_size: float = 1.0
var grid_size_x: int = 25
var grid_size_z: int = 25

var player_spawn: Rect2i = Rect2i(12, 8, 5, 5)
var ghosts_spawn: Rect2i = Rect2i(12, 16, 5, 5)

var wall_density: float = 0.7

var reserved_rules: Array[Callable] = []
var reserved_cells: Array

# Maze generation:
var straight_bias: float = 0.90
var extra_loop_ration: float = 0.20
var target_max_deadends: int = 3


func _ready() -> void:
	# add reserved predicates and rects
	add_reserved_rect(player_spawn)
	add_reserved_rect(ghosts_spawn)
	reserved_rules.append(is_container_cells)

func cell_to_world(cell: Vector2i) -> Vector3:
	return grid_origin + Vector3(cell.x*cell_size, 0, cell.y*cell_size)

func world_to_cell(world_pos: Vector3) -> Vector2i:
	var rel: Vector3 = world_pos - grid_origin
	return Vector2i(round(rel.x / cell_size), round(rel.z / cell_size))

func cell_walkable(cell: Vector2i) -> bool:
	return in_bounds(cell.x, cell.y) and grid[idx(cell.x, cell.y)] == 0

func in_bounds(x: int, z: int) -> bool:
	return x >= 0 and x < grid_size_x and z >= 0 and z < grid_size_z

func idx(x: int, z: int) -> int:
	return z*grid_size_x + x

func add_reserved_rect(rect: Rect2i) -> void:
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for z in range(rect.position.y, rect.position.y + rect.size.y):
			reserved_cells.append(Vector2i(x, z))

func is_reserved(x:int, z:int) -> bool:
	var cell: Vector2i = Vector2i(x, z)
	if reserved_cells.has(cell):
		return true
	for rule in reserved_rules:
		if rule.call(cell):
			return true
	return false

func build_grid(rng: RandomNumberGenerator) -> void:
	start_grid()
	carve_connectivity(rng)
	add_extra_loops(rng)

func start_grid() -> void:
	grid = PackedByteArray()
	grid.resize(grid_size_x * grid_size_z)
	for i in range(grid.size()):
		grid[i] = 1
	for x in range(grid_size_x):
		grid[idx(x, 0)] = 1
		grid[idx(x, grid_size_z - 1)] = 1
	for z in range(grid_size_z):
		grid[idx(0, z)] = 1
		grid[idx(grid_size_x - 1, z)] = 1
	
	carve_room(player_spawn, 0)
	carve_room(ghosts_spawn, 0)

func carve_connectivity(rng: RandomNumberGenerator) -> void:
	var start: Vector2i = pick_random_odd_cell(rng)
	if start == Vector2i(-1, -1):
		return
	
	var active: Array[Vector2i] = []
	var last_dir: Dictionary = {}
	set_corridor(start)
	active.append(start)
	
	while active.size() > 0:
		var current: Vector2i = active.back()
		var dirs: Array[Vector2i] = [Vector2i(0, -2), Vector2i(0, 2), Vector2i(2, 0), Vector2i(-2, 0)]
		shuffle_dirs(rng, dirs)
		var prefered: int = -1
		if last_dir.has(current) and rng.randf() < straight_bias:
			prefered = last_dir[current]
		var carved: bool = false
		
		if prefered != -1:
			var dir: Vector2i = dirs[prefered]
			if can_carve(current, dir):
				var next: Vector2i = current + dir
				carve_passage(current, next)
				active.append(next)
				last_dir[next] = prefered
				carved = true
			else:
				pass
		
		if not carved:
			for i in range(dirs.size()):
				var dir2: Vector2i = dirs[i]
				if prefered == i:
					continue
				if can_carve(current, dir2):
					var next2: Vector2i = current + dir2
					carve_passage(current, next2)
					active.append(next2)
					last_dir[next2] = i
					carved = true
					break
		
		if not carved:
			active.pop_back()


func set_corridor(cell: Vector2i) -> void:
	set_floor(cell.x, cell.y)

func pick_random_odd_cell(rng: RandomNumberGenerator) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for z in range(1, grid_size_z-1, 2):
		for x in range(1, grid_size_x-1, 2):
			if not is_reserved(x, z) and grid[idx(x, z)] == 1:
				candidates.append(Vector2i(x, z))
	if candidates.is_empty():
		return Vector2i(-1, -1)
	return candidates[rng.randi_range(0, candidates.size()-1)]


func is_carvable(cell: Vector2i) -> bool:
	return in_bounds(cell.x, cell.y) and not is_reserved(cell.x, cell.y)

func can_carve(cell: Vector2i, dir: Vector2i) -> bool:
	var to_cell: Vector2i = cell + dir
	var mid_cell: Vector2i = Vector2i((cell.x + dir.x)/2, (cell.y + dir.y)/2)
	if !is_carvable(to_cell) or !is_carvable(mid_cell) or grid[idx(to_cell.x, to_cell.y)]!=1:
		return false
	return true

func carve_passage(cell: Vector2i, next_cell: Vector2i) -> void:
	var mid_cell: Vector2i = Vector2i((cell.x + next_cell.x)/2, (cell.y + next_cell.y)/2)
	set_floor(mid_cell.x, mid_cell.y)
	set_floor(next_cell.x, next_cell.y)

func add_extra_loops(rng: RandomNumberGenerator) -> void:
	var candidates: Array[Vector2i] = []
	for z in range(1, grid_size_z-1):
		for x in range(1, grid_size_x-1):
			if is_reserved(x, z): continue
			if grid[idx(x, z)] != 1: continue
			var floors: int = 0
			if grid[idx(x+1, z)] == 0 and grid[idx(x-1, z)] == 0: floors += 2
			if grid[idx(x, z+1)] == 0 and grid[idx(x, z-1)] == 0: floors += 2
			if floors >= 2:
				candidates.append(Vector2i(x, z))
	shuffle_dirs(rng, candidates)
	var sel_num: int = int(floor(extra_loop_ration*float(candidates.size())))
	for i in range(sel_num):
		var cell: Vector2i = candidates[i]
		set_floor(cell.x, cell.y)


func carve_room(rect: Rect2i, door_side: int = -1) -> void:
	var px: int = rect.position.x
	var pz: int = rect.position.y
	var sx: int = rect.size.x
	var sz: int = rect.size.y

	for x in range(px, px+sx):
		set_wall(x, pz)
		set_wall(x, pz+sz-1)
	for z in range(pz, pz+sz):
		set_wall(px, z)
		set_wall(px+sx-1, z)
	
	for x in range(px+1, px+sx-1):
		for z in range(pz+1, pz+sz-1):
			set_floor(x, z)
	
	if door_side != -1:
		match door_side:
			0: 
				set_floor(px+sx/2, pz) # top
				grid[idx(px+sx/2, pz-1)] = 0
				reserved_cells.append(Vector2i(px+sx/2, pz-1))
			1: 
				set_floor(px+sx-1, pz+sz/2) # right
				grid[idx(px+sx, pz+sz/2)] = 0
				reserved_cells.append(Vector2i(px+sx, pz+sz/2))
			2: 
				set_floor(px+sx/2, pz+sz-1) # bottom
				grid[idx(px+sx/2, pz+sz)] = 0
				reserved_cells.append(Vector2i(px+sx/2, pz+sz))
			3: 
				set_floor(px, pz+sz/2) # left
				grid[idx(px-1, pz+sz/2)] = 0
				reserved_cells.append(Vector2i(px-1, pz+sz/2))

func set_wall(x: int, z: int) -> void:
	if in_bounds(x, z):
		grid[idx(x, z)] = 1

func set_floor(x: int, z: int) -> void:
	if in_bounds(x, z):
		grid[idx(x, z)] = 0

func shuffle_dirs(rng: RandomNumberGenerator, dirs: Array[Vector2i]) -> void:
	for i in range(dirs.size()-1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: Vector2i = dirs[i]
		dirs[i] = dirs[j]
		dirs[j] = temp

'''
------------- RESERVED FUNCTIONS -----------------
'''
func is_container_cells(cell: Vector2i) -> bool:
	return cell.x == 0 or cell.x == grid_size_x - 1 or cell.y == 0 or cell.y == grid_size_z - 1
