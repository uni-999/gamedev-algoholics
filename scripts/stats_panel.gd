extends Control

@onready var wpm_label = $MainContainer/TopRow/WPMContainer
@onready var mistakes_label = $MainContainer/TopRow/MistakesContainer
@onready var progress_bar = $MainContainer/ProgressBar

func _ready():
	update_wpm(0)
	update_mistakes(0)
	progress_bar.value = 0
	progress_bar.max_value = 100

func update_wpm(wpm: int):
	if wpm_label is Label:
		wpm_label.text = "WPM: " + str(wpm)

func update_mistakes(count: int):
	if mistakes_label is Label:
		mistakes_label.text = "Mistakes: " + str(count)

func update_progress(percent: float):
	progress_bar.value = percent

func reset_progress():
	progress_bar.value = 0
