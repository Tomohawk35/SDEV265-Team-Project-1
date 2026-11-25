
extends CanvasLayer

@onready var green_key_count: Label = $PanelContainer/MarginContainer/VBoxContainer/GreenKeyContainer/GreenKeyCount

var green_keys: int = 0


func _ready():
	add_to_group("key_overlay")
	update_display()


func add_key():
	green_keys += 1
	update_display()


func use_key() -> bool:
	if green_keys <= 0:
		return false

	green_keys -= 1
	update_display()
	return true


func get_key_count() -> int:
	return green_keys


func update_display():
	green_key_count.text = "x " + str(green_keys)


func reset_keys():
	green_keys = 0
	update_display()
