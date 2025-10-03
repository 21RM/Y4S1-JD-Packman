extends CharacterBody3D


@export var moving_speed: float = 2
@export var rotation_speed: float = 5
var moving_direction: Vector2 = Vector2(0, -1)


func _physics_process(delta: float) -> void:
	
	# INPUTS HANDLING
	if Input.is_action_just_pressed("move_right"):
		moving_direction = moving_direction.rotated(-PI/2)
	if Input.is_action_just_pressed("move_left"):
		moving_direction = moving_direction.rotated(PI/2)
	if Input.is_action_just_pressed("move_backwards"):
		moving_direction = moving_direction.rotated(PI)
	
	var target_yaw: float = atan2(moving_direction.x, -moving_direction.y)
	rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed*delta)
	
	velocity = Vector3(-moving_direction.x, 0, moving_direction.y) * moving_speed
	move_and_slide()


func activate_camera() -> void:
	$Camera.current = true
