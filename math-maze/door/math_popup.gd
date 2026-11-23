extends Control

@onready var question_label = $QuestionLabel
@onready var answer_input = $AnswerInput
@onready var submit_button = $SubmitButton

var correct_answer = 0

# Change this later when you hook it into level selection
var difficulty = 1

func _ready() -> void:
	answer_input.call_deferred("grab_focus")

	generate_problem(difficulty)

	submit_button.pressed.connect(_on_submit)

func generate_problem(level):
	var num1
	var num2

	match level:
		1:
			# Addition
			num1 = randi() % 10 + 1
			num2 = randi() % 10 + 1
			correct_answer = num1 + num2
			question_label.text = "What is " + str(num1) + " + " + str(num2) + "?"

		2:
			# Subtraction
			num1 = randi() % 20 + 1
			num2 = randi() % num1 + 1
			correct_answer = num1 - num2
			question_label.text = "What is " + str(num1) + " - " + str(num2) + "?"

		3:
			# Multiplication
			num1 = randi() % 12 + 1
			num2 = randi() % 12 + 1
			correct_answer = num1 * num2
			question_label.text = "What is " + str(num1) + " × " + str(num2) + "?"

		4:
			# Division
			num2 = randi() % 12 + 1
			correct_answer = randi() % 12 + 1
			num1 = num2 * correct_answer
			question_label.text = "What is " + str(num1) + " ÷ " + str(num2) + "?"

		5:
			# Mixed Multiplication and Division
			if randf() < 0.5:
				num1 = randi() % 12 + 1
				num2 = randi() % 12 + 1
				correct_answer = num1 * num2
				question_label.text = "What is " + str(num1) + " × " + str(num2) + "?"
			else:
				num2 = randi() % 12 + 1
				correct_answer = randi() % 12 + 1
				num1 = num2 * correct_answer
				question_label.text = "What is " + str(num1) + " ÷ " + str(num2) + "?"

		6:
			# PEMDAS
			var a = randi() % 10 + 1
			var b = randi() % 10 + 1
			var c = randi() % 10 + 1
			correct_answer = a + (b * c)
			question_label.text = "What is " + str(a) + " + " + str(b) + " × " + str(c) + "?"

func _on_submit():
	var player_answer = int(answer_input.text)

	if player_answer == correct_answer:
		print("Correct!")
		
		# Later: defeat enemy

	else:
		print("Incorrect!")
		
		# Later: remove life and start invulnerability timer

	get_tree().paused = false
	queue_free()
