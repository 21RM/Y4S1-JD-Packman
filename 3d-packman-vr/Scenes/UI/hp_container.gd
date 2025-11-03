extends MarginContainer

var heart_texture: CompressedTexture2D = preload("res://Assets/UI/Hearts/heart.png")

func set_lives(lives_n: int) -> void:
	for child in $HBoxContainer.get_children():
		child.queue_free()
	for n in range(lives_n):
		var mc: MarginContainer = MarginContainer.new()
		mc.add_theme_constant_override("margin_left", 10)
		mc.add_theme_constant_override("margin_right", 10)
		var tex_rect: TextureRect = TextureRect.new()
		tex_rect.texture = heart_texture
		mc.add_child(tex_rect)
		$HBoxContainer.add_child(mc)
