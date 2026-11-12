extends Resource
class_name MazeRegion

@export var index : int
@export var path_tiles : Array[Vector2i] = []
@export var branch_tiles : Array[Vector2i] = []
@export var all_tiles : Array[Vector2i] = []
@export var ending_door : Vector2i
