extends Control

# Node references
@onready var stats_panel = $CanvasLayer/GameContainer/StatsPanel
@onready var typing_display = $CanvasLayer/GameContainer/TypingDisplay
@onready var road = $Road
@onready var virtual_keyboard = $CanvasLayer/GameContainer/VirtualKeyboard
@onready var text_selector = $CanvasLayer/ControlButtons/TextSelector
@onready var start_button = $CanvasLayer/ControlButtons/StartButton
@onready var control_buttons = $CanvasLayer/ControlButtons
@onready var control_buttons_bg = $CanvasLayer/ControlButtonsBackground
@onready var finished_buttons = $CanvasLayer/FinishedButtons
@onready var score_label = $CanvasLayer/FinishedButtons/ScoreLabel
@onready var restart_button = $CanvasLayer/FinishedButtons/RestartButton
@onready var music = $Music
@onready var finish_sound = $Finish
# Game state
var current_text: String = ""
var current_text_with_spaces: String = ""  # Keep spaces for display
var current_position: int = 0
var bot_position: int = 0
var mistakes: int = 0
var start_time: int = 0
var is_typing: bool = false
var timer_running: bool = false
var game_completed: bool = false

# Bot settings
var bot_typing_speed: float = 0.3
var bot_timer: float = 0.0

# Sample texts with spaces
var sample_texts = [
	"the quick brown fox jumps over the lazy dog",
	"programming is the art of telling another human what one wants the computer to do",
	"practice makes perfect but perfect practice makes perfect permanent",
	"learning to type quickly is an essential skill in the digital age",
	"the only way to learn a new programming language is by writing programs in it"
]

func _ready():
	# Connect signals
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	
	if text_selector:
		text_selector.item_selected.connect(_on_text_selected)
		for i in range(sample_texts.size()):
			text_selector.add_item("Text " + str(i + 1), i)
		text_selector.select(0)
		_on_text_selected(0)
	
	if virtual_keyboard and virtual_keyboard.has_signal("key_pressed"):
		virtual_keyboard.key_pressed.connect(_on_key_pressed)
	
	# Set bot speed
	if road and road.has_node("TopSnake"):
		var bot_snake = road.get_node("TopSnake")
		bot_snake.set_bot_speed(bot_typing_speed)
		bot_snake.snake_type = 1  # BOT type
		print("Bot snake configured with speed: ", bot_typing_speed)
	
	set_process_input(true)
	show_control_buttons()
	
	if typing_display:
		typing_display.visible = false
	
	hide_finished_buttons()

func _input(event):
	if not is_typing or not event is InputEventKey:
		return
	
	if event.pressed and not event.echo:
		var key_unicode = event.unicode
		
		if event.keycode == KEY_SPACE:
			_on_key_pressed(" ", false)
			highlight_virtual_key("Space")
		elif key_unicode >= 97 and key_unicode <= 122:
			var character = char(key_unicode)
			_on_key_pressed(character, false)
			highlight_virtual_key(character)
		elif key_unicode >= 65 and key_unicode <= 90:
			var character = char(key_unicode + 32)
			_on_key_pressed(character, false)
			highlight_virtual_key(character)

func highlight_virtual_key(key: String):
	if virtual_keyboard and virtual_keyboard.has_method("highlight_key"):
		virtual_keyboard.highlight_key(key)

func _process(delta):
	if not is_typing or game_completed:
		music.stop()
		return
	
	if timer_running and start_time > 0:
		update_wpm()

func _on_start_pressed():
	hide_control_buttons()
	hide_finished_buttons()
	show_road_layers()
	music.play()
	reset_game()
	start_time = Time.get_ticks_msec()
	timer_running = true
	is_typing = true
	game_completed = false
	current_position = 0
	bot_position = 0
	mistakes = 0
	bot_timer = 0.0
	
	# Set the text on the road (with spaces)
	if road and road.has_method("set_text") and current_text_with_spaces != "":
		road.set_text(current_text_with_spaces)
	
	if virtual_keyboard and virtual_keyboard.has_method("enable_keyboard"):
		virtual_keyboard.enable_keyboard(true)
	
	update_display()

func _on_restart_pressed():
	_on_start_pressed()

func show_road_layers():
	if not road:
		return
	road.visible = true

func hide_road_layers():
	if not road:
		return
	road.visible = false

func _on_text_selected(index: int):
	if index >= 0 and index < sample_texts.size():
		current_text_with_spaces = sample_texts[index]
		update_display()

func _on_key_pressed(key_char: String, _is_shifted):
	if not is_typing or game_completed:
		return
	
	if key_char == "Backspace":
		if current_position > 0:
			current_position -= 1
	elif key_char == " ":
		process_character(" ")
	elif key_char.length() == 1 and key_char >= "a" and key_char <= "z":
		process_character(key_char)
	
	update_display()
	check_completion()

func process_character(character: String):
	if current_position >= current_text_with_spaces.length():
		return
	
	var expected_char = current_text_with_spaces[current_position]
	
	if character == expected_char:
		# Correct - eat apple
		if road and road.has_method("eat_apple"):
			road.eat_apple("bottom", current_position)
		current_position += 1
	else:
		# Mistake
		mistakes += 1
		if stats_panel and stats_panel.has_method("update_mistakes"):
			stats_panel.update_mistakes(mistakes)

func update_display():
	if stats_panel and stats_panel.has_method("update_progress") and current_text_with_spaces.length() > 0:
		var progress = (float(current_position) / float(current_text_with_spaces.length())) * 100
		stats_panel.update_progress(progress)

func update_wpm():
	if start_time == 0 or current_position == 0:
		return
		
	var elapsed_seconds = (Time.get_ticks_msec() - start_time) / 1000.0
	if elapsed_seconds < 1.0:
		return
	
	var elapsed_minutes = elapsed_seconds / 60.0
	var words_typed = current_position / 5.0
	var wpm = int(words_typed / elapsed_minutes)
	wpm = max(0, wpm)
	
	if stats_panel and stats_panel.has_method("update_wpm"):
		stats_panel.update_wpm(wpm)

func check_completion():
	var total_length = current_text_with_spaces.length()
	if total_length == 0:
		return
		
	if current_position >= total_length and not game_completed:
		complete_typing()

func calculate_score() -> int:
	var total_length = current_text_with_spaces.length()
	var base_score = total_length * 100
	var mistake_penalty = mistakes * 50
	
	var elapsed_seconds = (Time.get_ticks_msec() - start_time) / 1000.0
	var elapsed_minutes = elapsed_seconds / 60.0
	var words_typed = current_position / 5.0
	var wpm = int(words_typed / elapsed_minutes) if elapsed_minutes > 0 else 0
	
	var wpm_bonus = wpm * 10
	var time_bonus = max(0, 300 - int(elapsed_seconds)) * 2
	
	return max(100, base_score - mistake_penalty + wpm_bonus + time_bonus)

func complete_typing():
	is_typing = false
	timer_running = false
	game_completed = true
	finish_sound.play()
	if virtual_keyboard and virtual_keyboard.has_method("enable_keyboard"):
		virtual_keyboard.enable_keyboard(false)
	
	var final_score = calculate_score()
	if score_label:
		score_label.text = "Score: " + str(final_score)
	
	show_finished_buttons()
	print("Game completed! Score: ", final_score, " Mistakes: ", mistakes)

func reset_game():
	current_position = 0
	bot_position = 0
	mistakes = 0
	start_time = 0
	bot_timer = 0.0
	game_completed = false
	
	if stats_panel:
		if stats_panel.has_method("update_wpm"):
			stats_panel.update_wpm(0)
		if stats_panel.has_method("update_mistakes"):
			stats_panel.update_mistakes(0)
		if stats_panel.has_method("reset_progress"):
			stats_panel.reset_progress()
	
	if road and road.has_method("reset_game"):
		road.reset_game()

func hide_control_buttons():
	if control_buttons:
		control_buttons.visible = false
	if control_buttons_bg:
		control_buttons_bg.visible = false

func show_control_buttons():
	if control_buttons:
		control_buttons.visible = true
	if control_buttons_bg:
		control_buttons_bg.visible = true
	
	hide_road_layers()
	hide_finished_buttons()

func show_finished_buttons():
	if finished_buttons:
		finished_buttons.visible = true

func hide_finished_buttons():
	if finished_buttons:
		finished_buttons.visible = false
