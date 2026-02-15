extends Node2D

@onready var tilemap = $Tilemap
@onready var background_layer = $Tilemap/Background
@onready var road_layer = $Tilemap/Road
@onready var apple_layer = $Tilemap/Apples
@onready var top_snake = $TopSnake
@onready var bottom_snake = $BottomSnake
@onready var camera = $Camera2D

# Tile configuration
var tile_size: int = 16
var snake_length: int = 4
var original_width: int = 0
var original_height: int = 0
var current_text: String = ""
var text_length: int = 0
var is_ready: bool = false

# Apple start positions (cell coordinates)
var top_apple_start_cell: Vector2i = Vector2i(6, 14)
var bottom_apple_start_cell: Vector2i = Vector2i(6, 20)

# Snake world positions (from your coordinates)
var top_snake_y: int = 230
var bottom_snake_y: int = 327

# Camera settings
var camera_follow_speed: float = 5.0
var camera_offset: Vector2 = Vector2(600, 0)  # Increased offset to keep player on right side

# Letter to tile mapping (based on your tileset layout)
var letter_to_tile = {
	"q": Vector2i(0, 0), "w": Vector2i(1, 0), "e": Vector2i(2, 0), "r": Vector2i(3, 0), "t": Vector2i(4, 0), "y": Vector2i(5, 0),
	"u": Vector2i(0, 1), "i": Vector2i(1, 1), "o": Vector2i(2, 1), "p": Vector2i(3, 1), "a": Vector2i(4, 1), "s": Vector2i(5, 1),
	"d": Vector2i(0, 2), "f": Vector2i(1, 2), "g": Vector2i(2, 2), "h": Vector2i(3, 2), "j": Vector2i(4, 2), "k": Vector2i(5, 2),
	"l": Vector2i(0, 3), "z": Vector2i(1, 3), "x": Vector2i(2, 3), "c": Vector2i(3, 3), "v": Vector2i(4, 3), "b": Vector2i(5, 3),
	"n": Vector2i(0, 4), "m": Vector2i(1, 4), " ": Vector2i(2, 4)  # Space at (2,4)
}

# Apple tracking
var apple_positions_top: Array = []  # Array of {cell: Vector2i, letter: String, eaten: bool}
var apple_positions_bottom: Array = []

func _ready():
	calculate_original_dimensions()
	setup_camera()
	# Set snake positions
	if top_snake:
		top_snake.position = Vector2(0, top_snake_y)
	if bottom_snake:
		bottom_snake.position = Vector2(0, bottom_snake_y)
	
	is_ready = true

func _process(delta):
	# Camera follows bottom snake (player)
	if bottom_snake and camera:
		var head_pos = bottom_snake.get_head_position()
		# Position camera so player is closer to right edge
		var target_x = head_pos.x - camera_offset.x
		var current_pos = camera.position
		var new_x = lerp(current_pos.x, target_x, camera_follow_speed * delta)
		camera.position = Vector2(new_x, current_pos.y)

func calculate_original_dimensions():
	var max_x = 0
	var max_y = 0
	
	for layer in [background_layer, road_layer, apple_layer]:
		if layer:
			for cell in layer.get_used_cells():
				max_x = max(max_x, cell.x)
				max_y = max(max_y, cell.y)
	
	original_width = max_x + 1
	original_height = max_y + 1
	
	print("Original map size: ", original_width, " x ", original_height)

func setup_camera():
	if not camera:
		return
	
	# Set camera limits
	camera.limit_left = 0
	camera.limit_right = 5000  # Large initial limit
	camera.limit_top = 0
	camera.limit_bottom = original_height * tile_size
	
	# Center camera initially with player on right side
	camera.position = Vector2(400, bottom_snake_y)

func set_text(new_text: String):
	if not is_ready:
		await ready
	
	# Keep spaces in the text
	current_text = new_text.to_lower()
	text_length = current_text.length()
	
	# Clear existing apples
	clear_apples()
	
	# Initialize apple positions
	apple_positions_top.clear()
	apple_positions_bottom.clear()
	
	print("Setting text with spaces: '", current_text, "' length: ", text_length)
	
	# First, duplicate the background and road to the right to cover text length
	duplicate_for_text_length()
	
	# Place apples for top snake
	for i in range(text_length):
		var letter = current_text[i]
		if letter in letter_to_tile:
			var tile_coords = letter_to_tile[letter]
			
			# Top snake apples - start at (6, 14) and go right
			var top_cell = Vector2i(top_apple_start_cell.x + i, top_apple_start_cell.y)
			apple_layer.set_cell(top_cell, 0, tile_coords)
			apple_positions_top.append({"cell": top_cell, "letter": letter, "eaten": false})
	
	# Place apples for bottom snake
	for i in range(text_length):
		var letter = current_text[i]
		if letter in letter_to_tile:
			var tile_coords = letter_to_tile[letter]
			
			# Bottom snake apples - start at (6, 20) and go right
			var bottom_cell = Vector2i(bottom_apple_start_cell.x + i, bottom_apple_start_cell.y)
			apple_layer.set_cell(bottom_cell, 0, tile_coords)
			apple_positions_bottom.append({"cell": bottom_cell, "letter": letter, "eaten": false})
	
	# Extend camera limits generously
	var needed_width = (bottom_apple_start_cell.x + text_length + 30) * tile_size  # Extra padding
	if camera and camera.limit_right < needed_width:
		camera.limit_right = needed_width
	
	print("Placed ", text_length, " apples for each snake")

func duplicate_for_text_length():
	# Calculate how many times we need to repeat the pattern
	var needed_width = bottom_apple_start_cell.x + text_length + 20
	var repeats_needed = ceil(float(needed_width) / float(original_width))
	
	print("Original width: ", original_width, ", needed width: ", needed_width)
	print("Repeating pattern ", repeats_needed, " times")
	
	# For each repetition, duplicate the existing tiles
	for rep in range(1, int(repeats_needed) + 2):  # +2 for extra safety
		var start_x = rep * original_width
		duplicate_pattern_to_right(start_x)

func duplicate_pattern_to_right(start_x: int):
	# Duplicate background layer
	if background_layer:
		duplicate_layer(background_layer, start_x)
	
	# Duplicate road layer
	if road_layer:
		duplicate_layer(road_layer, start_x)

func duplicate_layer(layer: TileMapLayer, start_x: int):
	# Get all used cells in the original pattern
	var original_cells = []
	for cell in layer.get_used_cells():
		if cell.x < original_width:
			original_cells.append(cell)
	
	# Duplicate each cell to the new position
	for cell in original_cells:
		var source_id = layer.get_cell_source_id(cell)
		var atlas_coords = layer.get_cell_atlas_coords(cell)
		var alternative_tile = layer.get_cell_alternative_tile(cell)
		
		if source_id != -1:
			var new_cell = Vector2i(cell.x + start_x, cell.y)
			layer.set_cell(new_cell, source_id, atlas_coords, alternative_tile)

func clear_apples():
	if apple_layer:
		for cell in apple_layer.get_used_cells():
			apple_layer.set_cell(cell, -1, Vector2i(-1, -1))

func eat_apple(snake: String, position_index: int) -> bool:
	if position_index >= text_length:
		return false
	
	var apple_array = apple_positions_top if snake == "top" else apple_positions_bottom
	
	if position_index >= apple_array.size():
		return false
	
	if apple_array[position_index]["eaten"]:
		return false
	
	# Mark as eaten
	apple_array[position_index]["eaten"] = true
	
	# Remove the apple tile
	var apple_cell = apple_array[position_index]["cell"]
	apple_layer.set_cell(apple_cell, -1, Vector2i(-1, -1))
	
	# Animate the appropriate snake
	if snake == "top" and top_snake:
		top_snake.eat_apple()
	elif snake == "bottom" and bottom_snake:
		bottom_snake.eat_apple()
	
	return true

func get_text_length() -> int:
	return text_length

func get_current_text() -> String:
	return current_text

func get_snake_head_positions() -> Dictionary:
	return {
		"top": top_snake.get_head_position() if top_snake else Vector2.ZERO,
		"bottom": bottom_snake.get_head_position() if bottom_snake else Vector2.ZERO
	}

func reset_game():
	# Reset apple eaten states
	for apple in apple_positions_top:
		apple["eaten"] = false
	for apple in apple_positions_bottom:
		apple["eaten"] = false
	
	# Redraw apples
	clear_apples()
	for apple in apple_positions_top:
		if not apple["eaten"]:
			apple_layer.set_cell(apple["cell"], 0, letter_to_tile[apple["letter"]])
	for apple in apple_positions_bottom:
		if not apple["eaten"]:
			apple_layer.set_cell(apple["cell"], 0, letter_to_tile[apple["letter"]])
	
	# Reset snake positions
	if top_snake:
		top_snake.reset_position(3 * tile_size)
	if bottom_snake:
		bottom_snake.reset_position(3 * tile_size)
	
	# Reset camera
	if camera:
		camera.position = Vector2(400, bottom_snake_y)
	
	print("Game reset")
