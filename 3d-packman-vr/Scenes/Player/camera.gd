extends Camera3D

@export var max_pos_amplitude: float = 0.12    # meters (movement)
@export var max_rot_amplitude_deg: float = 2.0 # degrees (tilt)

var shake_amount: float = 0.0          # 0..1 intensity
var base_position: Vector3
var base_rotation: Vector3             # radians

func _ready() -> void:
	set_process(false)
	base_position = position
	base_rotation = rotation

func _process(_delta: float) -> void:
	# Recompute from base every frame (no drift)
	var pos_jitter := Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	) * (shake_amount * max_pos_amplitude)

	var rot_jitter := Vector3(
		deg_to_rad(randf_range(-max_rot_amplitude_deg, max_rot_amplitude_deg)),
		deg_to_rad(randf_range(-max_rot_amplitude_deg, max_rot_amplitude_deg)),
		deg_to_rad(randf_range(-max_rot_amplitude_deg, max_rot_amplitude_deg))
	) * shake_amount

	position = base_position + pos_jitter
	rotation = base_rotation + rot_jitter

func shake(time: float, amount: float) -> void:
	# Capture current transform as the "home" to return to (works if the camera moved)
	base_position = position
	base_rotation = rotation

	shake_amount = clamp(amount, 0.0, 1.0)
	set_process(true)
	$ShakeTimer.start(time)

func _on_shake_timer_timeout() -> void:
	set_process(false)

	# Ease back to the base transform
	var t := create_tween()
	t.tween_property(self, "position", base_position, 0.2)
	t.parallel().tween_property(self, "rotation", base_rotation, 0.2)

	$ShakeTimer.stop()
