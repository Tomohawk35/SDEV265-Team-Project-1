extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect to the built-in "area_entered" signal
	area_entered.connect(_on_area_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass  # We don't need this for now, so leave it empty

# This function runs automatically when another Area2D overlaps with this one
func _on_area_entered(area):
	# Check if the thing that entered is the player
	# In Godot, "groups" are like Python tags or sets
	if area.is_in_group("player"):
		print("Player touched the door!")
		show_math_popup()

func show_math_popup():
	# Load the popup scene (like importing a module)
	var popup_scene = preload("res://door/math_popup.tscn")

	# Create an instance of it (like calling a constructor)
	var popup = popup_scene.instantiate()

	# Add it to the UI layer
	# CanvasLayer is where all UI lives in Godot
	var canvas = get_tree().root.get_node("CanvasLayer")
	canvas.add_child(popup)
