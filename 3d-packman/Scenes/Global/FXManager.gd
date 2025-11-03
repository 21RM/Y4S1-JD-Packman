extends Node


@export var dot_sound: AudioStream

const MUTE_DB : float = -60.0
const PLAY_DB : float = -3.0


func _ready() -> void:
	$Ambient/ScaryTheme.volume_db = PLAY_DB
	$Ambient/HeartBeat.volume_db = MUTE_DB


func play_ambient() -> void:
	$Ambient/ScaryTheme.play()

func stop_ambient() -> void:
	$Ambient/ScaryTheme.stop()

func enter_energy() -> void:
	$Ambient/HeartBeat.play()
	crossfade($Ambient/ScaryTheme, $Ambient/HeartBeat, 1)

func exit_energy() -> void:
	crossfade($Ambient/HeartBeat, $Ambient/ScaryTheme, 1)

func crossfade(from_p: AudioStreamPlayer, to_p: AudioStreamPlayer, time: float) -> void:
	if !to_p.playing:
		to_p.play(from_p.get_playback_position())
	var tw := create_tween()
	tw.tween_property(from_p, "volume_db", -60.0, time)
	tw.parallel().tween_property(to_p, "volume_db", 0.0, time)


func play_dot() -> void:
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = dot_sound
	player.volume_db = -15.0
	$Dots.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func play_energizer_collected() -> void:
	$Energizer/Collected.play()

func play_jumpscare() -> void:
	$Jumpscare/JumpscareSound.play()

func play_button_houver() -> void:
	$UI/Button/HouverSound.play()

func play_button_houver_exit() -> void:
	$UI/Button/HouverExitSound.play()

func play_button_press() -> void:
	$UI/Button/Press.play()

func play_laughs() -> void:
	$UI/Laughs.play()

func stop_laughs() -> void:
	$UI/Laughs.stop()

func play_ghost_eaten() -> void:
	$Ghosts/GhostEaten.play()
