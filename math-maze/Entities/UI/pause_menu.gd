extends CanvasLayer

@onready var menu = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer

@onready var resume_button = menu.get_node("ResumeButton")
@onready var settings_button = menu.get_node("SettingsButton")
@onready var new_game_button = menu.get_node("NewGameButton")
@onready var quit_button = menu.get_node("QuitButton")


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	resume_button.pressed.connect(resume_game)
	settings_button.pressed.connect(open_settings)
	new_game_button.pressed.connect(new_game)
	quit_button.pressed.connect(quit_game)


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if visible:
			resume_game()
		else:
			pause_game()

		get_viewport().set_input_as_handled()


func pause_game():
	get_tree().paused = true
	show()
	resume_button.grab_focus()


func resume_game():
	hide()
	get_tree().paused = false


func open_settings():
	print("Settings coming soon!")


func new_game():
	get_tree().paused = false
	get_tree().reload_current_scene()


func quit_game():
	get_tree().quit()
