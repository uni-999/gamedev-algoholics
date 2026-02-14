extends Button

signal key_pressed(key_char: String)

var key_label: String = ""
var is_shifted: bool = false

func _ready():
	# Connect the button's pressed signal
	pressed.connect(_on_key_pressed)
	
	# Set up button properties for keyboard appearance
	custom_minimum_size = Vector2(40, 40)
	
	# Optional: Add theme overrides for better keyboard appearance
	add_theme_color_override("font_color", Color(1, 1, 1))
	add_theme_color_override("font_hover_color", Color(1, 1, 0))
	add_theme_color_override("font_pressed_color", Color(0.8, 0.8, 0.8))
	add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	
	add_theme_stylebox_override("normal", get_key_style(Color(0.3, 0.3, 0.3)))
	add_theme_stylebox_override("hover", get_key_style(Color(0.4, 0.4, 0.4)))
	add_theme_stylebox_override("pressed", get_key_style(Color(0.2, 0.2, 0.2)))
	add_theme_stylebox_override("disabled", get_key_style(Color(0.15, 0.15, 0.15)))

func get_key_style(bg_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.5, 0.5)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _on_key_pressed():
	key_pressed.emit(key_label)

func set_key_label(label_text: String):
	key_label = label_text
	text = label_text  # Set the button text
	
	# Adjust button size based on text length
	var text_width = get_theme_font("font").get_string_size(label_text, get_theme_font_size("font_size")).x
	var new_width = max(40, text_width + 20)
	custom_minimum_size = Vector2(new_width, 40)

func get_key_label() -> String:
	return key_label

func set_shift_state(shifted: bool):
	is_shifted = shifted
	# Optionally change appearance when shifted
	if shifted:
		add_theme_color_override("font_color", Color(1, 1, 0.5))
	else:
		add_theme_color_override("font_color", Color(1, 1, 1))

func set_key_pressed(pressed_state: bool):
	button_pressed = pressed_state
