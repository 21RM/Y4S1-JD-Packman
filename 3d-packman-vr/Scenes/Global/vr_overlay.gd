extends CanvasLayer

func _ready() -> void:
	$ColorRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$ColorRect.focus_mode = Control.FOCUS_NONE
