extends Control

@onready var question_label = $QuestionLabel
@onready var answer_input = $AnswerInput
@onready var submit_button = $SubmitButton

var correct_answer = 0

func _ready() -> void:
	# Generate a simple math problem
	var a = randi() % 10 + 1  # random number 1-10
	var b = randi() % 10 + 1  # random number 1-10
	correct_answer = a * b

	# Set the label text (like Python's label.text = "...")
	question_label.text = "What is " + str(a) + " × " + str(b) + "?"

	# Connect the button's "pressed" signal to our check function
	submit_button.pressed.connect(_on_submit)

func _on_submit():
	# Get the text the player typed, convert to integer
	var player_answer = int(answer_input.text)

	if player_answer == correct_answer:
		# Correct! Close the popup and let the player through
		print("Correct! Door opens.")
		queue_free()  # Removes this node from the scene (like Python's del)
	else:
		# Wrong answer
		print("Incorrect. Try again.")
		answer_input.text = ""  # Clear the input field
