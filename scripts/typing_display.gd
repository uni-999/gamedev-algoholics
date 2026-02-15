extends Control

@onready var target_text = $TextPanel/MarginContainer/TargetText

var correct_color = Color(0.2, 0.8, 0.2)  # Green
var incorrect_color = Color(0.8, 0.2, 0.2)  # Red
var neutral_color = Color(1, 1, 1)  # White
var current_color = Color(1, 1, 0)  # Yellow for current character

func _ready():
	if target_text is RichTextLabel:
		target_text.bbcode_enabled = true
	else:
		print("Warning: TargetText is not a RichTextLabel")

func update_text(full_text: String, typed_text: String, current_pos: int):
	if not target_text is RichTextLabel:
		return
	
	var formatted_text = ""
	
	for i in range(full_text.length()):
		var character = full_text[i]
		
		if i < typed_text.length():
			# Character has been typed
			if typed_text[i] == character:
				formatted_text += "[color=#" + correct_color.to_html() + "]" + character + "[/color]"
			else:
				formatted_text += "[color=#" + incorrect_color.to_html() + "]" + character + "[/color]"
		elif i == current_pos:
			# Current character to type
			formatted_text += "[color=#" + current_color.to_html() + "]" + character + "[/color]"
		else:
			# Future characters
			formatted_text += "[color=#" + neutral_color.to_html() + "]" + character + "[/color]"
	
	target_text.text = formatted_text

func reset_display():
	if target_text is RichTextLabel:
		target_text.text = ""
