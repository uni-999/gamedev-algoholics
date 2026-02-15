extends Node2D

# Node references
@onready var tilemap = $Tilemap
@onready var background_layer = $Tilemap/Background
@onready var road_layer = $Tilemap/Road
@onready var snakes_layer = $Tilemap/Snakes

# Tile configuration
var tile_size: int = 16  # Assuming 16x16 tiles
var snake_length: int = 4  # Length of each snake

# Game state
var current_text: String = ""
var text_length: int = 0
var original_width: int = 0  # Width of originally painted area
var is_ready: bool = false  # Flag to track if road is ready

# Snake positions and tracking
var top_snake_head: Vector2i = Vector2i(-1, -1)
var bottom_snake_head: Vector2i = Vector2i(-1, -1)
var top_snake_cells: Array = []  # All cells occupied by top snake
var bottom_snake_cells: Array = []  # All cells occupied by bottom snake

# Text tracking
var top_text_cells: Array = []  # Cells where top snake's text is placed
var bottom_text_cells: Array = []  # Cells where bottom snake's text is placed
var top_text_eaten: Array = []  # Track which characters are eaten
var bottom_text_eaten: Array = []  # Track which characters are eaten

# Apple tile
var apple_tile: Vector2i = Vector2i(0, 21)

# Snake tile IDs - different for top and bottom snakes
var top_snake_head_tile: Vector2i = Vector2i(8, 13)
var top_snake_body_tile: Vector2i = Vector2i(1, 9)
var top_snake_tail_tile: Vector2i = Vector2i(9, 9)

var bottom_snake_head_tile: Vector2i = Vector2i(8, 20)
var bottom_snake_body_tile: Vector2i = Vector2i(1, 16)
var bottom_snake_tail_tile: Vector2i = Vector2i(9, 16)

func _ready():
	# Store the original width of your painted map
	calculate_original_width()
	# Find initial snake positions
	find_snake_heads()
	is_ready = true

func calculate_original_width():
	var max_x = 0
	var found_cells = false
	
	for layer in [background_layer, road_layer, snakes_layer]:
		if layer:
			var used_cells = layer.get_used_cells()
			if used_cells.size() > 0:
				found_cells = true
			for cell in used_cells:
				if cell.x > max_x:
					max_x = cell.x
	
	if found_cells:
		original_width = max_x + 1
	else:
		original_width = 20

func find_snake_heads():
	if snakes_layer:
		for x in range(original_width):
			var cell = Vector2i(x, 14)
			var atlas_coords = snakes_layer.get_cell_atlas_coords(cell)
			if atlas_coords != Vector2i(-1, -1):
				if atlas_coords == top_snake_head_tile:
					top_snake_head = cell
					break
		
		for x in range(original_width):
			var cell = Vector2i(x, 20)
			var atlas_coords = snakes_layer.get_cell_atlas_coords(cell)
			if atlas_coords != Vector2i(-1, -1):
				if atlas_coords == bottom_snake_head_tile:
					bottom_snake_head = cell
					break
	
	if top_snake_head == Vector2i(-1, -1):
		top_snake_head = Vector2i(snake_length - 1, 14)
	if bottom_snake_head == Vector2i(-1, -1):
		bottom_snake_head = Vector2i(snake_length - 1, 20)
	
	build_snake_cells()

func build_snake_cells():
	if snakes_layer and top_snake_head != Vector2i(-1, -1):
		top_snake_cells.clear()
		var current_pos = top_snake_head
		var found_segments = 0
		
		while found_segments < snake_length and current_pos.x >= 0:
			var atlas_coords = snakes_layer.get_cell_atlas_coords(current_pos)
			if atlas_coords != Vector2i(-1, -1):
				top_snake_cells.insert(0, current_pos)
				found_segments += 1
			current_pos = Vector2i(current_pos.x - 1, current_pos.y)
	
	if snakes_layer and bottom_snake_head != Vector2i(-1, -1):
		bottom_snake_cells.clear()
		var current_pos = bottom_snake_head
		var found_segments = 0
		
		while found_segments < snake_length and current_pos.x >= 0:
			var atlas_coords = snakes_layer.get_cell_atlas_coords(current_pos)
			if atlas_coords != Vector2i(-1, -1):
				bottom_snake_cells.insert(0, current_pos)
				found_segments += 1
			current_pos = Vector2i(current_pos.x - 1, current_pos.y)

func set_text(new_text: String):
	if not is_ready:
		await ready
	
	current_text = new_text.to_lower()
	text_length = new_text.length()
	
	# Initialize eaten arrays
	top_text_eaten = []
	bottom_text_eaten = []
	for i in range(text_length):
		top_text_eaten.append(false)
		bottom_text_eaten.append(false)
	
	# Extend the map to the right
	extend_map_to_right()
	
	# Place apples on both snakes
	place_apples_on_snakes()

func extend_map_to_right():
	var needed_width = original_width + text_length + 10
	var repeats_needed = ceil(float(needed_width) / float(original_width))
	
	for rep in range(1, int(repeats_needed)):
		var start_x = rep * original_width
		duplicate_pattern_to_right(start_x)

func duplicate_pattern_to_right(start_x: int):
	if background_layer:
		duplicate_layer(background_layer, start_x)
	
	if road_layer:
		duplicate_layer(road_layer, start_x)
	
	if snakes_layer:
		duplicate_layer_excluding_snakes(snakes_layer, start_x)

func duplicate_layer(layer: TileMapLayer, start_x: int):
	var original_cells = []
	for cell in layer.get_used_cells():
		if cell.x < original_width:
			original_cells.append(cell)
	
	for cell in original_cells:
		var source_id = layer.get_cell_source_id(cell)
		var atlas_coords = layer.get_cell_atlas_coords(cell)
		var alternative_tile = layer.get_cell_alternative_tile(cell)
		
		if source_id != -1:
			var new_cell = Vector2i(cell.x + start_x, cell.y)
			layer.set_cell(new_cell, source_id, atlas_coords, alternative_tile)

func duplicate_layer_excluding_snakes(layer: TileMapLayer, start_x: int):
	var original_cells = []
	for cell in layer.get_used_cells():
		if cell.x < original_width:
			var atlas_coords = layer.get_cell_atlas_coords(cell)
			
			if atlas_coords != Vector2i(-1, -1):
				if atlas_coords != top_snake_head_tile and \
				   atlas_coords != top_snake_body_tile and \
				   atlas_coords != top_snake_tail_tile and \
				   atlas_coords != bottom_snake_head_tile and \
				   atlas_coords != bottom_snake_body_tile and \
				   atlas_coords != bottom_snake_tail_tile and \
				   atlas_coords != apple_tile:
					original_cells.append(cell)
	
	for cell in original_cells:
		var source_id = layer.get_cell_source_id(cell)
		var atlas_coords = layer.get_cell_atlas_coords(cell)
		var alternative_tile = layer.get_cell_alternative_tile(cell)
		
		if source_id != -1:
			var new_cell = Vector2i(cell.x + start_x, cell.y)
			layer.set_cell(new_cell, source_id, atlas_coords, alternative_tile)

func place_apples_on_snakes():
	if not snakes_layer or current_text.is_empty():
		return
	
	clear_apple_area()
	
	top_text_cells.clear()
	bottom_text_cells.clear()
	
	find_snake_heads()
	
	var top_y = top_snake_head.y
	var top_start_x = top_snake_head.x + 1
	
	for i in range(text_length):
		var cell_x = top_start_x + i
		var cell = Vector2i(cell_x, top_y)
		
		if not top_text_eaten[i]:
			snakes_layer.set_cell(cell, 0, apple_tile)
			top_text_cells.append(cell)
	
	var bottom_y = bottom_snake_head.y
	var bottom_start_x = bottom_snake_head.x + 1
	
	for i in range(text_length):
		var cell_x = bottom_start_x + i
		var cell = Vector2i(cell_x, bottom_y)
		
		if not bottom_text_eaten[i]:
			snakes_layer.set_cell(cell, 0, apple_tile)
			bottom_text_cells.append(cell)

func clear_apple_area():
	if snakes_layer:
		var cells_to_clear = []
		
		for cell in top_text_cells + bottom_text_cells:
			cells_to_clear.append(cell)
		
		for cell in snakes_layer.get_used_cells():
			if cell.x >= original_width:
				var atlas_coords = snakes_layer.get_cell_atlas_coords(cell)
				if atlas_coords == apple_tile:
					cells_to_clear.append(cell)
		
		var unique_cells = []
		for cell in cells_to_clear:
			if cell not in unique_cells:
				unique_cells.append(cell)
		
		for cell in unique_cells:
			snakes_layer.set_cell(cell, -1, Vector2i(-1, -1))

func eat_apple(snake: String, position_index: int):
	if position_index >= text_length:
		return
	
	var head_pos = top_snake_head if snake == "top" else bottom_snake_head
	var y = head_pos.y
	
	if snake == "top":
		top_text_eaten[position_index] = true
	else:
		bottom_text_eaten[position_index] = true
	
	var apple_cell_x = head_pos.x + 1 + position_index
	var apple_cell = Vector2i(apple_cell_x, y)
	
	snakes_layer.set_cell(apple_cell, -1, Vector2i(-1, -1))
	
	move_snake_forward(snake)

func move_snake_forward(snake: String):
	var head_pos = top_snake_head if snake == "top" else bottom_snake_head
	var y = head_pos.y
	
	var new_head_x = head_pos.x + 1
	var new_head = Vector2i(new_head_x, y)
	
	var head_tile = top_snake_head_tile if snake == "top" else bottom_snake_head_tile
	var body_tile = top_snake_body_tile if snake == "top" else bottom_snake_body_tile
	var tail_tile = top_snake_tail_tile if snake == "top" else bottom_snake_tail_tile
	
	snakes_layer.set_cell(new_head, 0, head_tile)
	snakes_layer.set_cell(head_pos, 0, body_tile)
	
	if snake == "top":
		top_snake_head = new_head
		if top_snake_cells.size() > 0:
			top_snake_cells.append(new_head)
			if top_snake_cells.size() > snake_length:
				var old_tail = top_snake_cells[0]
				snakes_layer.set_cell(old_tail, -1, Vector2i(-1, -1))
				top_snake_cells.remove_at(0)
				if top_snake_cells.size() > 0:
					var new_tail = top_snake_cells[0]
					snakes_layer.set_cell(new_tail, 0, tail_tile)
	else:
		bottom_snake_head = new_head
		if bottom_snake_cells.size() > 0:
			bottom_snake_cells.append(new_head)
			if bottom_snake_cells.size() > snake_length:
				var old_tail = bottom_snake_cells[0]
				snakes_layer.set_cell(old_tail, -1, Vector2i(-1, -1))
				bottom_snake_cells.remove_at(0)
				if bottom_snake_cells.size() > 0:
					var new_tail = bottom_snake_cells[0]
					snakes_layer.set_cell(new_tail, 0, tail_tile)

func is_apple_eaten(snake: String, position_index: int) -> bool:
	if snake == "top":
		return position_index < top_text_eaten.size() and top_text_eaten[position_index]
	else:
		return position_index < bottom_text_eaten.size() and bottom_text_eaten[position_index]

func get_current_text() -> String:
	return current_text

func get_text_length() -> int:
	return text_length

func reset_game():
	top_text_eaten = []
	bottom_text_eaten = []
	for i in range(text_length):
		top_text_eaten.append(false)
		bottom_text_eaten.append(false)
	
	clear_apple_area()
	place_apples_on_snakes()
	
	find_snake_heads()
