extends Resource
class_name MazeConfig

@export var width := 31
@export var height := 31

@export var seed : int = 0
@export var randomize_seed := true

@export_group("Doors")
@export var min_doors := 2
@export var max_doors := 5
@export var min_door_spacing := 8

@export_group("Keys")
@export var guaranteed_keys_per_zone := 1
@export var bonus_keys := 2

@export_group("Dead Ends")
@export var extra_dead_end_branches := 10

@export_group("Monsters")
@export var monster_density := 0.08
@export var safe_start_radius := 5

@export_group("Validation")
@export var minimum_solution_length := 40
