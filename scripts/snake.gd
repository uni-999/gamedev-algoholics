extends Node2D

signal apple_eaten(position_index)

enum SnakeType { PLAYER, BOT }

@export var snake_type: SnakeType = SnakeType.PLAYER
@export var snake_color: Color = Color(1, 1, 1)
@export var move_speed: float = 0.3  # Seconds per move (for bot)

var snake_length: int = 4
var current_index: int = 0  # Current apple index
var segment_positions: Array = []  # Store positions of each segment
var is_moving: bool = true  # Changed to true by default for bot
var move_timer: float = 0.0

@onready var segments = [
	$Head,
	$Body1,
	$Body2,
	$Body3,
	$Tail
]

func _ready():
	# Set initial positions (head at 0,0, body extending left)
	for i in range(segments.size()):
		segments[i].position.x = -i * 16  # Each segment 16px left of previous
		segment_positions.append(segments[i].position)
	
	# Apply color tint
	for segment in segments:
		if segment is Sprite2D:
			segment.modulate = snake_color

func _process(delta):
	if snake_type == SnakeType.BOT:
		move_timer += delta
		while move_timer >= move_speed and current_index < get_parent().get_text_length():
			move_timer -= move_speed
			# Emit signal for bot eating apple
			$"..".eat_apple("top", current_index)
			apple_eaten.emit("top", current_index - 1)

func move_forward():
	if current_index >= get_parent().get_text_length():
		return
	
	# Move all segments forward (right)
	for i in range(segments.size() - 1, 0, -1):
		segments[i].position = segments[i - 1].position
		segment_positions[i] = segments[i].position
	
		
	# Move head forward
	segments[0].position.x += 16
	
	segment_positions[0] = segments[0].position
	
#	if snake_type == SnakeType.PLAYER:
#		print(get_head_position())
	current_index += 1
	
	#print("Bot moved to index: ", current_index)

func reset_position(start_x: float):
	# Reset snake with head at start_x, body extending left
	for i in range(segments.size()):
		segments[i].position = Vector2(start_x - (i * 16), 0)
		segment_positions[i] = segments[i].position
	
	current_index = 0
	move_timer = 0.0

func eat_apple():
	# Visual feedback
	modulate = Color(1, 1, 0.5)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.2)
	move_forward()
	apple_eaten.emit(current_index - 1)

func get_head_position() -> Vector2:
	return segments[0].position

func get_head_cell() -> Vector2i:
	var head_pos = segments[0].position
	return Vector2i(floor(head_pos.x / 16), floor(head_pos.y / 16))

func set_bot_speed(speed: float):
	move_speed = speed
