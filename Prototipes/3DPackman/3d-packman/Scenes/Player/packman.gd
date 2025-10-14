extends CharacterBody3D


@export var moving_speed: float = 3.0
@export var rotation_speed: float = 10.0
@export var center_snap_eps: float = 0.04  
@export var turn_buffer_sec: float = 0.5

var dir: Vector2i = Vector2i(0, -1)
var queued_dir: Vector2i = Vector2i.ZERO
var queued_untill: float = 0.0
var current_cell: Vector2i = Vector2i.ZERO
# cell that packman is ocuppying right now
var current_center: Vector3 = Vector3.ZERO
# world position of the center of the cell packman is currently occupying


func _physics_process(delta: float) -> void:
	# Input pooling
	if Input.is_action_just_pressed("move_right"):
		request_dir(rotate_veci(dir, -1))
	if Input.is_action_just_pressed("move_left"):
		request_dir(rotate_veci(dir, 1))
	if Input.is_action_just_pressed("move_backwards"):
		request_dir(rotate_veci(dir, 2))
	 
	# Where am I in grid space
	current_cell = UtilsGrid.world_to_cell(global_position)
	current_center = UtilsGrid.cell_to_world(current_cell)
	var to_center: Vector2 = Vector2(global_position.x - current_center.x, global_position.z - current_center.z)
	var at_center: bool = false
	if to_center.length() <= center_snap_eps:
		global_position.x = current_center.x
		global_position.z = current_center.z
		at_center = true
	
	# Movement validation
	if at_center and queued_dir != Vector2i.ZERO and turn_still_valid():
		var next_cell: Vector2i = current_cell + queued_dir
		if UtilsGrid.can_walk_to_neighbor_cell(current_cell, next_cell):
			dir = queued_dir
			queued_dir = Vector2i.ZERO
			
	
	var forward_cell: Vector2i = current_cell + dir
	var can_move_forward: bool = UtilsGrid.can_walk_to_neighbor_cell(current_cell, forward_cell)
	if at_center and not can_move_forward:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		velocity.x = dir.x * moving_speed
		velocity.z = dir.y * moving_speed
	
	var target_yaw: float = atan2(-dir.x, -dir.y)
	if Input.is_action_pressed("look_back"):
		target_yaw = atan2(-dir.x, -dir.y) + PI
	rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed*delta)
	
	move_and_slide()

func request_dir(wish: Vector2i) -> void:
	# Instant reverse anywhere 
	if wish == -dir and wish != Vector2i.ZERO:
		dir = wish
		queued_dir = Vector2i.ZERO
	# Otherwise queue left or right turn
	queued_dir = wish
	queued_untill = Time.get_ticks_msec() / 1000.0 + turn_buffer_sec

func rotate_veci(v: Vector2i, times: int) -> Vector2i:
	times = (times % 4 + 4) % 4
	match times:
		0: return v
		1: return Vector2i(v.y, -v.x)
		2: return -v
		3: return Vector2i(-v.y, v.x)
	return v

func turn_still_valid() -> bool:
	return Time.get_ticks_msec() / 1000.0 <= queued_untill

func activate_camera() -> void:
	$Camera.current = true
