extends CharacterBody2D

var TILE_SIZE = 32

func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO

	if Input.is_action_just_pressed("ui_up"):
		direction = Vector2.UP
	elif Input.is_action_just_pressed("ui_down"):
		direction = Vector2.DOWN
	elif Input.is_action_just_pressed("ui_left"):
		direction = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_right"):
		direction = Vector2.RIGHT

	if direction != Vector2.ZERO:
		# Move one tile
		position += direction * TILE_SIZE
