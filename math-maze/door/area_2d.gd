extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect to the built-in "area_entered" signal
	area_entered.connect(_on_area_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass  # We don't need this for now, so leave it empty

# This function runs automatically when another Area2D overlaps with this one
func _on_area_entered(area):
	print("Detected collision with:", area.name)
	print("In player group:", area.is_in_group("player"))

	show_math_popup()

func show_math_popup():
	print("show_math_popup called")
	var popup_scene = preload("res://door/math_popup.tscn")
	var popup = popup_scene.instantiate()
	print("popup instantiated")
	get_tree().current_scene.add_child(popup)
	get_tree().paused = true
	print("popup added")
