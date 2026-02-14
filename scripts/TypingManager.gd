extends Node

signal text_completed
signal mistake_made(mistake_count)
signal progress_updated(current_pos, total_length)

var target_text: String = ""
var current_position: int = 0
var mistakes: int = 0
var start_time: float = 0.0
var is_typing: bool = false

# Stats tracking
var total_keystrokes: int = 0
var correct_keystrokes: int = 0
var wpm: float = 0.0

func _ready():
	reset()

func set_text(text: String):
	target_text = text
	reset()

func reset():
	current_position = 0
	mistakes = 0
	start_time = 0.0
	is_typing = false
	total_keystrokes = 0
	correct_keystrokes = 0
	wpm = 0.0

func start_typing():
	start_time = Time.get_ticks_msec() / 1000.0
	is_typing = true

func process_input(event: InputEventKey) -> bool:
	if not is_typing or current_position >= target_text.length():
		return false
	
	if event.pressed and not event.echo:
		var key_unicode = event.unicode
		if key_unicode == 0:
			return false
		
		var expected_char = target_text[current_position]
		var pressed_char = char(key_unicode)
		
		total_keystrokes += 1
		
		if pressed_char == expected_char:
			# Correct input
			correct_keystrokes += 1
			current_position += 1
			progress_updated.emit(current_position, target_text.length())
			
			if current_position >= target_text.length():
				text_completed.emit()
		else:
			# Mistake
			mistakes += 1
			mistake_made.emit(mistakes)
		
		return true
	
	return false

func calculate_wpm():
	if start_time > 0 and current_position > 0:
		var time_elapsed = (Time.get_ticks_msec() / 1000.0) - start_time
		var minutes = time_elapsed / 60.0
		# Standard: 5 characters = 1 word
		var words_typed = correct_keystrokes / 5.0
		wpm = words_typed / max(minutes, 0.001)
	return wpm

func get_accuracy() -> float:
	if total_keystrokes == 0:
		return 100.0
	return (float(correct_keystrokes) / total_keystrokes) * 100.0
