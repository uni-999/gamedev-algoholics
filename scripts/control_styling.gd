extends Control

func _ready():
	# Connect the button's pressed signal
	
	# Set up button properties for keyboard appearance	
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
	
	style.shadow_color = Color(0, 0, 0, 1)
	style.shadow_size = 1
	style.shadow_offset = Vector2(1, 1)
	return style
