extends Resource
class_name MazeConfig

@export var difficulty : int

@export var width : int
@export var height : int

@export var maze_seed : int = 0
@export var randomize_seed : bool = true

#@export_group("Doors")
#@export var min_doors : int = 2
#@export var max_doors : int = 5
#@export var min_door_spacing : int = 8

@export_group("Keys")
@export var guaranteed_keys_per_zone : int = 1
@export var bonus_keys : int = 2

@export_group("Dead Ends")
@export var extra_dead_end_branches : int = 10

@export_group("Monsters")
@export var monster_density := 0.08
@export var safe_start_radius : int = 5

@export_group("Validation")
@export var minimum_solution_length : int = 20

@export_group("Maze Data")
@export var start_position : Vector2i
@export var exit_position : Vector2i
@export var num_doors : int
@export var regions : Array[MazeRegion] = []
@export var maze_grid : Array[Array] = []


func _init(_difficulty: int = 1) -> void:
	difficulty = _difficulty
	width = 25 + randi_range(2, 5) * difficulty
	height = 25 + randi_range(2, 5) * difficulty
	num_doors = (difficulty - 1)

	#const MIN_DIST_BETWEEN_START_AND_EXIT : int = 4
#const MIN_PATH_LENGTH : int = 15
#const MOVE_TOWARDS_EXIT_PROBABILITY : float = 0.55
