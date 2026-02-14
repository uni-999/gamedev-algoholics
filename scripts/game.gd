extends Control

# Node references
@onready var stats_panel = $GameContainer/StatsPanel
@onready var typing_display = $GameContainer/TypingDisplay
@onready var virtual_keyboard = $GameContainer/VirtualKeyboard
@onready var text_selector = $ControlButtons/TextSelector
@onready var start_button = $ControlButtons/StartButton
@onready var control_buttons = $ControlButtons
@onready var control_buttons_bg = $ControlButtonsBackground

# Game state
var current_text: String = ""
var current_input: String = ""
var current_position: int = 0
var mistakes: int = 0
var start_time: int = 0
var is_typing: bool = false
var timer_running: bool = false

# Sample texts for typing practice (lowercase only, no punctuation)
var sample_texts = [
	"the quick brown fox jumps over the lazy dog",
	"programming is the art of telling another human what one wants the computer to do",
	"practice makes perfect but perfect practice makes perfect permanent",
	"learning to type quickly is an essential skill in the digital age",
	"the only way to learn a new programming language is by writing programs in it",
	"a quick movement of the enemy will jeopardize six gunboats",
	"all questions asked by five watched experts amaze the judge",
	"the five boxing wizards jump quickly",
	"pack my box with five dozen liquor jugs",
	"how vexingly quick daft zebras jump"
]

func _ready():
	# Connect signals
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	
	if text_selector:
		text_selector.item_selected.connect(_on_text_selected)
		
		# Populate text selector
		for i in range(sample_texts.size()):
			text_selector.add_item("Text " + str(i + 1), i)
		# Select first item by default
		text_selector.select(0)
		_on_text_selected(0)
	
	# Connect keyboard signals
	if virtual_keyboard:
		if virtual_keyboard.has_signal("key_pressed"):
			virtual_keyboard.key_pressed.connect(_on_key_pressed)
	
	# Connect physical keyboard
	set_process_input(true)
	
	# Make sure control buttons are visible at start
	show_control_buttons()
	
	# Initialize display
	update_display()

func _input(event):
	if not is_typing or not event is InputEventKey:
		return
	
	if event.pressed and not event.echo:
		var key_unicode = event.unicode
		
		# Handle backspace
		if event.keycode == KEY_BACKSPACE:
			_on_key_pressed("Backspace", false)
			highlight_virtual_key("Backspace")
		# Handle space
		elif event.keycode == KEY_SPACE:
			_on_key_pressed(" ", false)
			highlight_virtual_key("Space")
		# Handle lowercase letters (a-z)
		elif key_unicode >= 97 and key_unicode <= 122:  # a-z in ASCII
			var character = char(key_unicode)
			_on_key_pressed(character, false)
			highlight_virtual_key(character)
		# Handle uppercase letters (convert to lowercase)
		elif key_unicode >= 65 and key_unicode <= 90:  # A-Z in ASCII
			var character = char(key_unicode + 32)  # Convert to lowercase
			_on_key_pressed(character, false)
			highlight_virtual_key(character)

func highlight_virtual_key(key: String):
	if virtual_keyboard and virtual_keyboard.has_method("highlight_key"):
		virtual_keyboard.highlight_key(key)

func _process(_delta):
	if is_typing and timer_running and start_time > 0:
		update_wpm()

func _on_start_pressed():
	# Hide control buttons
	hide_control_buttons()
	
	# Reset and start game
	reset_game()
	start_time = Time.get_ticks_msec()
	timer_running = true
	is_typing = true
	current_input = ""
	current_position = 0
	mistakes = 0
	
	if virtual_keyboard and virtual_keyboard.has_method("enable_keyboard"):
		virtual_keyboard.enable_keyboard(true)
		
	# Make sure the current text is displayed
	update_display()

func _on_text_selected(index: int):
	if index >= 0 and index < sample_texts.size():
		current_text = sample_texts[index]
		update_display()

func _on_key_pressed(key_char: String, _is_shifted):
	if not is_typing:
		return
	
	# Handle backspace
	if key_char == "Backspace":
		if current_position > 0:
			current_position -= 1
			current_input = current_input.substr(0, current_position)
	# Handle space
	elif key_char == " ":
		process_character(" ")
	# Handle regular keys (should be lowercase letters)
	elif key_char.length() == 1 and key_char >= "a" and key_char <= "z":
		process_character(key_char)
	
	update_display()
	check_completion()

func process_character(character: String):
	if current_position < current_text.length():
		var expected_char = current_text[current_position]
		current_input += character
		
		if character != expected_char:
			mistakes += 1
			if stats_panel and stats_panel.has_method("update_mistakes"):
				stats_panel.update_mistakes(mistakes)
		
		current_position += 1

func update_display():
	if typing_display and typing_display.has_method("update_text"):
		typing_display.update_text(current_text, current_input, current_position)
	
	# Update progress bar if available
	if stats_panel and stats_panel.has_method("update_progress") and current_text.length() > 0:
		var progress = (float(current_position) / float(current_text.length())) * 100
		stats_panel.update_progress(progress)

func update_wpm():
	if start_time == 0:
		return
		
	var elapsed_minutes = (Time.get_ticks_msec() - start_time) / 60000.0
	if elapsed_minutes > 0:
		var words_typed = current_input.split(" ").size()
		var wpm = int(words_typed / elapsed_minutes)
		if stats_panel and stats_panel.has_method("update_wpm"):
			stats_panel.update_wpm(wpm)

func check_completion():
	if current_position >= current_text.length() and current_text.length() > 0:
		complete_typing()

func complete_typing():
	is_typing = false
	timer_running = false
	
	if virtual_keyboard and virtual_keyboard.has_method("enable_keyboard"):
		virtual_keyboard.enable_keyboard(false)
	
	# Show control buttons again
	show_control_buttons()
	
	print("Typing completed!")

func reset_game():
	current_input = ""
	current_position = 0
	mistakes = 0
	start_time = 0
	
	if stats_panel:
		if stats_panel.has_method("update_wpm"):
			stats_panel.update_wpm(0)
		if stats_panel.has_method("update_mistakes"):
			stats_panel.update_mistakes(0)
		if stats_panel.has_method("reset_progress"):
			stats_panel.reset_progress()
	
	if typing_display and typing_display.has_method("reset_display"):
		typing_display.reset_display()

func hide_control_buttons():
	if control_buttons:
		control_buttons.visible = false
		control_buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if control_buttons_bg:
		control_buttons_bg.visible = false
		control_buttons_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_control_buttons():
	if control_buttons:
		control_buttons.visible = true
		control_buttons.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if control_buttons_bg:
		control_buttons_bg.visible = true
		control_buttons_bg.mouse_filter = Control.MOUSE_FILTER_STOP
