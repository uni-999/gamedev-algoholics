extends Control

signal key_pressed(key_char: String, is_shifted: bool)

@onready var keyboard_rows = $KeyboardRows

# Simple keyboard layout with only lowercase letters, space, and backspace
var key_rows = [
	["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "Backspace"],
	["a", "s", "d", "f", "g", "h", "j", "k", "l"],
	["z", "x", "c", "v", "b", "n", "m"],
	["Space"]
]

var keyboard_enabled: bool = false
var key_nodes = []  # Store references to all key buttons for highlighting
var highlight_timers = []  # Store timers to prevent garbage collection

func _ready():
	build_keyboard()

func build_keyboard():
	# Clear existing rows
	for child in keyboard_rows.get_children():
		child.queue_free()
	
	key_nodes.clear()
	highlight_timers.clear()
	
	# Build each row
	for row_index in range(key_rows.size()):
		var hbox = HBoxContainer.new()
		hbox.name = "Row" + str(row_index + 1)
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Add keys to row
		for key_text in key_rows[row_index]:
			var key = Button.new()
			key.text = key_text
			key.custom_minimum_size = Vector2(40, 40)
			key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			# Store reference for highlighting
			key_nodes.append({"button": key, "text": key_text})
			
			# Connect the signal
			key.pressed.connect(_on_key_button_pressed.bind(key_text))
			
			# Style the button
			style_key_button(key)
			
			hbox.add_child(key)
		
		keyboard_rows.add_child(hbox)

func style_key_button(button: Button):
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.3, 0.3, 0.3)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.5, 0.5, 0.5)
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.4, 0.4, 0.4)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.2, 0.2, 0.2)
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)

func _on_key_button_pressed(key_text: String):
	if not keyboard_enabled:
		return
	
	# Handle special keys
	if key_text == "Backspace":
		key_pressed.emit("Backspace", false)
	elif key_text == "Space":
		key_pressed.emit(" ", false)
	else:
		# Regular letter keys
		key_pressed.emit(key_text, false)
	
	# Highlight the pressed key
	highlight_key(key_text)

func highlight_key(key: String):
	# First, reset any existing highlights
	reset_all_highlights()
	
	# Find and highlight the matching key
	for key_data in key_nodes:
		if key_data["text"] == key:
			var button = key_data["button"]
			# Change the button's appearance to show it's pressed
			button.modulate = Color(0.8, 0.8, 0.3)  # Highlight color
			
			# Create a timer to reset this specific highlight
			var timer = Timer.new()
			timer.one_shot = true
			timer.wait_time = 0.15  # Slightly longer for better visibility
			timer.timeout.connect(_reset_single_highlight.bind(button))
			add_child(timer)
			highlight_timers.append(timer)  # Store reference to prevent garbage collection
			timer.start()
			break

func _reset_single_highlight(button: Button):
	# Only reset this specific button if it's still highlighted
	if button.modulate == Color(0.8, 0.8, 0.3):
		button.modulate = Color(1, 1, 1)

func reset_all_highlights():
	# Reset all keys to normal color
	for key_data in key_nodes:
		key_data["button"].modulate = Color(1, 1, 1)
	
	# Clean up old timers
	for timer in highlight_timers:
		if timer and timer.is_inside_tree():
			timer.queue_free()
	highlight_timers.clear()

func enable_keyboard(enabled: bool):
	keyboard_enabled = enabled
	modulate = Color(1, 1, 1, 1.0 if enabled else 0.5)
	
	# Reset highlights when disabling
	if not enabled:
		reset_all_highlights()
