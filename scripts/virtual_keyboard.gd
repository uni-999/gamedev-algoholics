extends Control

signal key_pressed(key_char: String, is_shifted: bool)

@onready var keyboard_rows = $KeyboardRows

# Simple keyboard layout with only lowercase letters, space, and backspace
var key_rows = [
	["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
	["a", "s", "d", "f", "g", "h", "j", "k", "l"],
	["z", "x", "c", "v", "b", "n", "m"],
	["Space"]
]

var keyboard_enabled: bool = false
var key_nodes = []  # Store references to all key buttons for highlighting
var highlight_timers = []  # Store timers to prevent garbage collection

func _ready():
	# Load and set the pixel font
	var pixel_font = load("res://assets/m6x11.ttf")
	if pixel_font:
		# Set as default theme for all buttons
		var theme = Theme.new()
		var font_size = 16
		
		# Configure font for all button states
		theme.set_default_font(pixel_font)
		theme.set_default_font_size(font_size)
		
		# Apply theme to self
		self.theme = theme
	
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
		hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Add spacing between keys
		hbox.add_theme_constant_override("separation", 4)
		
		# Add keys to row
		for key_text in key_rows[row_index]:
			var key = Button.new()
			key.text = key_text
			key.custom_minimum_size = Vector2(32, 32)
			key.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			
			# Store reference for highlighting
			key_nodes.append({"button": key, "text": key_text})
			
			# Connect the signal
			key.pressed.connect(_on_key_button_pressed.bind(key_text))
			
			# Style the button
			style_key_button(key)
			
			hbox.add_child(key)
		
		keyboard_rows.add_child(hbox)

func style_key_button(button: Button):
	# Normal state - raised bevel look
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.25, 0.25, 0.3)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.45, 0.45, 0.5)
	normal_style.corner_radius_top_left = 2
	normal_style.corner_radius_top_right = 2
	normal_style.corner_radius_bottom_left = 2
	normal_style.corner_radius_bottom_right = 2
	normal_style.shadow_color = Color(0.1, 0.1, 0.1)
	normal_style.shadow_size = 1
	normal_style.shadow_offset = Vector2(1, 1)
	
	# Hover state - brighter
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.35, 0.35, 0.4)
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color(0.6, 0.6, 0.65)
	hover_style.corner_radius_top_left = 2
	hover_style.corner_radius_top_right = 2
	hover_style.corner_radius_bottom_left = 2
	hover_style.corner_radius_bottom_right = 2
	hover_style.shadow_color = Color(0.1, 0.1, 0.1)
	hover_style.shadow_size = 1
	hover_style.shadow_offset = Vector2(1, 1)
	
	# Pressed state - inset look
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.2, 0.2, 0.25)
	pressed_style.border_width_left = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_bottom = 2
	pressed_style.border_color = Color(0.3, 0.3, 0.35)
	pressed_style.corner_radius_top_left = 2
	pressed_style.corner_radius_top_right = 2
	pressed_style.corner_radius_bottom_left = 2
	pressed_style.corner_radius_bottom_right = 2
	pressed_style.shadow_color = Color(0.1, 0.1, 0.1)
	pressed_style.shadow_size = 1
	pressed_style.shadow_offset = Vector2(-1, -1)  # Reverse shadow for pressed effect
	
	# Disabled state - desaturated
	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.2, 0.2, 0.2)
	disabled_style.border_width_left = 2
	disabled_style.border_width_top = 2
	disabled_style.border_width_right = 2
	disabled_style.border_width_bottom = 2
	disabled_style.border_color = Color(0.3, 0.3, 0.3)
	disabled_style.corner_radius_top_left = 2
	disabled_style.corner_radius_top_right = 2
	disabled_style.corner_radius_bottom_left = 2
	disabled_style.corner_radius_bottom_right = 2
	disabled_style.shadow_color = Color(0.1, 0.1, 0.1)
	disabled_style.shadow_size = 1
	disabled_style.shadow_offset = Vector2(1, 1)
	
	# Apply the styles
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	# Text colors
	button.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 0.8))
	button.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.8))
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	
	# Text shadow for pixel art feel
	button.add_theme_color_override("font_shadow_color", Color(0.1, 0.1, 0.1))
	button.add_theme_constant_override("shadow_offset_x", 1)
	button.add_theme_constant_override("shadow_offset_y", 1)

func _on_key_button_pressed(key_text: String):
	if not keyboard_enabled:
		return
	
	# Handle special keys
	if key_text == "Bspace":
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
			
			# Create a highlight style
			var highlight_style = StyleBoxFlat.new()
			highlight_style.bg_color = Color(0.5, 0.4, 0.2)
			highlight_style.border_width_left = 2
			highlight_style.border_width_top = 2
			highlight_style.border_width_right = 2
			highlight_style.border_width_bottom = 2
			highlight_style.border_color = Color(0.8, 0.7, 0.3)
			highlight_style.corner_radius_top_left = 2
			highlight_style.corner_radius_top_right = 2
			highlight_style.corner_radius_bottom_left = 2
			highlight_style.corner_radius_bottom_right = 2
			highlight_style.shadow_color = Color(0.1, 0.1, 0.1)
			highlight_style.shadow_size = 1
			highlight_style.shadow_offset = Vector2(1, 1)
			
			# Temporarily override the normal style
			button.add_theme_stylebox_override("normal", highlight_style)
			button.add_theme_color_override("font_color", Color(1, 1, 0.8))
			
			# Timer to reset
			var timer = Timer.new()
			timer.one_shot = true
			timer.wait_time = 0.15
			timer.timeout.connect(_reset_single_highlight.bind(button))
			add_child(timer)
			highlight_timers.append(timer)
			timer.start()
			break

func _reset_single_highlight(button: Button):
	# Restore original styles
	style_key_button(button)

func reset_all_highlights():
	for key_data in key_nodes:
		style_key_button(key_data["button"])
	
	# Clean up timers
	for timer in highlight_timers:
		if timer and timer.is_inside_tree():
			timer.queue_free()
	highlight_timers.clear()

func enable_keyboard(enabled: bool):
	keyboard_enabled = enabled
	modulate = Color(1, 1, 1, 1.0 if enabled else 0.5)
	
	if not enabled:
		reset_all_highlights()
