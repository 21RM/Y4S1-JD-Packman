extends CanvasLayer


@export var empty_texture: Texture2D
@export var dot_texture: Texture2D
@export var energizer_texture: Texture2D
@export var packman_texture1: Texture2D
@export var packman_texture2: Texture2D
@export var packman_texture3: Texture2D


@onready var walls_grid: GridContainer = $ColorRect/VBoxContainer/HBoxContainer/MapContainer/AspectRatioContainer/WallsLayer
@onready var dots_grid : GridContainer = $ColorRect/VBoxContainer/HBoxContainer/MapContainer/AspectRatioContainer/DotsLayer
@onready var dots_node: Node3D = $"../Dots"
@onready var energizers_node: Node3D = $"../Energizers"

var wall_cells: Array[ColorRect] = []
var dot_cells : Array[TextureRect] = []
var dots_by_cell: Dictionary = {}
var packman: TextureRect = TextureRect.new()
var number: int = 0

func _ready() -> void:
	call_deferred("_late_ready")
	
	$ColorRect/VBoxContainer/HBoxContainer/MapContainer/AspectRatioContainer.ratio = float(UtilsGrid.grid_size_x) / float(UtilsGrid.grid_size_z)

	walls_grid.columns = UtilsGrid.grid_size_x
	dots_grid.columns  = UtilsGrid.grid_size_x

	var total := UtilsGrid.grid_size_x * UtilsGrid.grid_size_z
	wall_cells.resize(total)
	dot_cells.resize(total)

	for y in range(UtilsGrid.grid_size_z):
		for x in range(UtilsGrid.grid_size_x):
			var i := UtilsGrid.idx(x, y)

			var cr := ColorRect.new()
			# no custom_minimum_size — let it stretch
			cr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cr.size_flags_vertical = Control.SIZE_EXPAND_FILL
			cr.color =Color(0.0, 0.31, 1.0) if (UtilsGrid.grid[i] == 1) else Color(0, 0, 0)
			walls_grid.add_child(cr)
			wall_cells[i] = cr

			var tx_r := TextureRect.new()
			tx_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tx_r.size_flags_vertical = Control.SIZE_EXPAND_FILL
			tx_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tx_r.ignore_texture_size = true
			dots_grid.add_child(tx_r)
			dot_cells[i] = tx_r

	refresh_dots()
	
	make_packman_ui()


func make_packman_ui() -> void:
	packman.texture = packman_texture1
	packman.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	packman.size_flags_vertical = Control.SIZE_EXPAND_FILL
	packman.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	packman.ignore_texture_size = true
	add_child(packman)
	packman.resized.connect(func(): packman.pivot_offset = packman.size * 0.5)

func place_packman(cell: Vector2i, dir: Vector2i):
	var i: int = UtilsGrid.idx(cell.x, cell.y)
	var cell_ctrl: Control = dot_cells[i]
	if packman.get_parent() != cell_ctrl:
		packman.get_parent().remove_child(packman)
		cell_ctrl.add_child(packman)
	packman.anchor_left = 0.0
	packman.anchor_top = 0.0
	packman.anchor_right = 1.0
	packman.anchor_bottom = 1.0
	packman.offset_left = 0.0
	packman.offset_top = 0.0
	packman.offset_right = 0.0
	packman.offset_bottom = 0.0
	
	if dir != Vector2i.ZERO:
		var angle := atan2(float(-dir.y), float(-dir.x))
		packman.rotation = angle


func _late_ready() -> void:
	for d in dots_node.get_children():
		var cell: Vector2i = UtilsGrid.world_to_cell(d.global_position)
		dots_by_cell[cell] = d
	for e in energizers_node.get_children():
		var cell: Vector2i = UtilsGrid.world_to_cell(e.global_position)
		dots_by_cell[cell] = e

func refresh_dots() -> void:
	for y in range(UtilsGrid.grid_size_z):
		for x in range(UtilsGrid.grid_size_x):
			var i: int = UtilsGrid.idx(x, y)
			if has_energizer(x, y):
				dot_cells[i].texture = energizer_texture
			elif has_dot(x, y):
				dot_cells[i].texture = dot_texture
			else:
				dot_cells[i].texture = empty_texture

func _on_map_updater_timeout() -> void:
	refresh_dots()
	place_packman(UtilsPackman.packman.current_cell, UtilsPackman.packman.dir)
	number += 1
	number %= 3
	var p_tex: Array = [packman_texture1, packman_texture2, packman_texture3]
	packman.texture = p_tex[number]


func has_dot(x: int, y: int) -> bool:
	return dots_by_cell.has(Vector2i(x, y))

func has_energizer(x: int, y: int) -> bool:
	return dots_by_cell.has(Vector2i(x, y)) and UtilsGrid.is_corner_cells(Vector2i(x, y))

func remove_dot_at(cell: Vector2i) -> void:
	if dots_by_cell.has(cell):
		dots_by_cell.erase(cell)
