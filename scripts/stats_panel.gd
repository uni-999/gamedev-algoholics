extends Control

@onready var wpm_label = $MainContainer/TopRow/WPMContainer
@onready var mistakes_label = $MainContainer/TopRow/MistakesContainer
@onready var progress_bar = $MainContainer/ProgressBar

func _ready():
	update_wpm(0)
	update_mistakes(0)
	progress_bar.value = 0
	progress_bar.max_value = 100
	
	# Debug: Print node paths to verify they're correct
	print("StatsPanel - WPM Label: ", wpm_label)
	print("StatsPanel - Mistakes Label: ", mistakes_label)

func update_wpm(wpm: int):
	if wpm_label:
		if wpm_label is Label:
			wpm_label.text = "WPM: " + str(wpm)
		else:
			# If it's not a Label, try to find a Label child
			var label = find_label_child(wpm_label)
			if label:
				label.text = "WPM: " + str(wpm)
			else:
				print("Warning: Could not find WPM Label")
	else:
		print("Warning: wpm_label is null")

func update_mistakes(count: int):
	if mistakes_label:
		if mistakes_label is Label:
			mistakes_label.text = "MISTAKES: " + str(count)
		else:
			# If it's not a Label, try to find a Label child
			var label = find_label_child(mistakes_label)
			if label:
				label.text = "MISTAKES: " + str(count)
			else:
				print("Warning: Could not find Mistakes Label")
	else:
		print("Warning: mistakes_label is null")

func find_label_child(node: Node) -> Label:
	for child in node.get_children():
		if child is Label:
			return child
	return null

func update_progress(percent: float):
	if progress_bar:
		progress_bar.value = percent

func reset_progress():
	if progress_bar:
		progress_bar.value = 0
