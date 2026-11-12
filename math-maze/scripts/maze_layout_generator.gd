#@tool
#extends EditorScript
extends Node


enum TileType {
	WALL,
	FLOOR,
	START,
	EXIT,
	DOOR,
	KEY,
	MONSTER
}

const DIRS : Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT
]

const SURROUNDING_DIRS : Array[Vector2i] = [
		Vector2i(0, -1),
		Vector2i(1, -1),
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(0, 1),
		Vector2i(-1, 1),
		Vector2i(-1, 0),
		Vector2i(-1, -1)
	]

const MIN_DIST_BETWEEN_START_AND_EXIT : int = 15
const MIN_PATH_LENGTH : int = 15
const MOVE_TOWARDS_EXIT_PROBABILITY : float = 0.55


var difficulty : int = 1
var guaranteed_keys_per_zone : int = 1

@onready var generate_button: Button = %GenerateButton
@onready var difficulty_label: Label = %DifficultyLabel
@onready var up_difficulty_button: Button = %UpDifficultyButton
@onready var down_difficulty_button: Button = %DownDifficultyButton
@onready var grid_layout_display: RichTextLabel = %GridLayoutDisplay

func _ready() -> void:
	difficulty_label.text = str(difficulty)
	generate_button.pressed.connect(_on_generate_button_pressed)
	up_difficulty_button.pressed.connect(_on_up_difficulty_button_pressed)
	down_difficulty_button.pressed.connect(_on_down_difficulty_button_pressed)


func _on_generate_button_pressed() -> void:
	_run()


func _on_up_difficulty_button_pressed() -> void:
	difficulty += 1
	difficulty_label.text = str(difficulty)


func _on_down_difficulty_button_pressed() -> void:
	difficulty -= 1
	difficulty_label.text = str(difficulty)


func _update_display(grid: Array[Array]) -> void:
	grid_layout_display.text = export_text(grid)


func _run() -> void:
	var maze_config : MazeConfig = MazeConfig.new(difficulty)
	if maze_config.randomize_seed:
		maze_config.maze_seed = roundi(Time.get_unix_time_from_system())

	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = maze_config.maze_seed

	print("\nDetermining start and exit...")
	print("==============================\n")
	var start_and_end_points : Dictionary[String, Vector2i] = choose_start_and_exit(maze_config.width, maze_config.height, MIN_DIST_BETWEEN_START_AND_EXIT, rng)
	# print(start_and_end_points)
	maze_config.start_position = start_and_end_points["start"]
	maze_config.exit_position = start_and_end_points["exit"]
	
	print("\nGenerating grid wall...")
	print("==============================\n")
	var grid : Array[Array] = _create_grid(maze_config.width, maze_config.height)
	
	grid[maze_config.start_position.y][maze_config.start_position.x] = TileType.START
	grid[maze_config.exit_position.y][maze_config.exit_position.x] = TileType.EXIT
	# print_grid(grid)
	_update_display(grid)
	
	
	print("\nCarving main path...")
	print("==============================\n")
	var path_array : Array[Vector2i] = _carve_main_path(grid, maze_config.start_position, maze_config.exit_position, maze_config.minimum_solution_length, rng)
	if path_array.is_empty():
		print("Generation failed. Exiting.")
		_update_display(grid)
		grid_layout_display.text = "Layout generation failed.\n" + grid_layout_display.text
		return
	else:
		print("Path generated...\n")
	
	for pos in path_array:
		grid[pos.y][pos.x] = TileType.FLOOR
		grid[maze_config.start_position.y][maze_config.start_position.x] = TileType.START
		grid[maze_config.exit_position.y][maze_config.exit_position.x] = TileType.EXIT
	
	# print_grid(grid)
	_update_display(grid)
	
	
	#print("\nDetermining door positions...")
	#print("==============================\n")
	#var door_indices : Array[int] = _calculate_door_positions(grid, path_array, maze_config.num_doors)
	#var door_positions : Array[Vector2i] = []
	#for idx in door_indices:
		#var door_pos : Vector2i = path_array[idx]
		#door_positions.append(door_pos)
		#grid[door_pos.y][door_pos.x] = TileType.DOOR
	#print("Door indices: ", str(door_indices))
	#print("Door positions: ", str(door_positions))
	#print_grid(grid)


	#print("\nAdding branches...")
	#print("==============================\n")
	#_add_extra_branches(grid, 2)
	#print_grid(grid)
	


func get_random_edge_cell(width: int, height: int, rng: RandomNumberGenerator) -> Vector2i:
	var side = rng.randi_range(0, 3)
	match side:
		0: # top
			return Vector2i(rng.randi_range(1, width - 2), 0)

		1: # bottom
			return Vector2i(rng.randi_range(1, width - 2), height - 1)

		2: # left
			return Vector2i(0, rng.randi_range(1, height - 2))

		_: # right
			return Vector2i(width - 1, rng.randi_range(1, height - 2))


func choose_start_and_exit(width: int, height: int, min_edge_distance: int, rng: RandomNumberGenerator) -> Dictionary[String, Vector2i]:
	var start : Vector2i = get_random_edge_cell(width, height, rng)
	var exit: Vector2i
	while true:
		exit = get_random_edge_cell(width, height, rng)
		if (absi(start.x - exit.x) + absi(start.y - exit.y)) >= min_edge_distance:
			break
	return {
		"start": start,
		"exit": exit
	}


func _create_grid(width: int, height: int) -> Array[Array]:
	var grid : Array[Array] = []
	for y in height:
		var row : Array = []
		for x in width:
			row.append(TileType.WALL)
		grid.append(row)
	return grid


func _carve_main_path(grid: Array[Array], start: Vector2i, exit: Vector2i, min_path_length: int, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var path : Array[Vector2i] = [start]
	var current_pos : Vector2i = start
	var bad_pos : Vector2i
	var iterations : int = 0

	while iterations < 100:
		#print("Current Position: ", str(current_pos))
		# iterations += 1

		if current_pos == exit:
			if path.size() >= min_path_length:
				break
			elif path.size() > 3:
				path.pop_back()
				bad_pos = path.pop_back()
				current_pos = path.back()
				continue
			else:
				path = [start]
				current_pos = start
				continue
		
		
		var candidates : Array[Vector2i] = []
		
		for dir in DIRS:
			var next_pos : Vector2i = current_pos + dir

			# Check if the next position is within the grid boundaries
			if next_pos.x < 0 or next_pos.y < 0 or next_pos.x >= grid[0].size() or next_pos.y >= grid.size():
				continue
			
			# Check if the next position is an edge cell
			if next_pos.x == 0 or next_pos.y == 0 or next_pos.x == grid[0].size() - 1 or next_pos.y == grid.size() - 1:
				if next_pos == exit and path.size() >= min_path_length:
					path.append(next_pos)
					break
				continue
			
			candidates.append(next_pos)
		
		if path.back() == exit:
			break
		
		# Remove candidates that are already in the path
		for candidate in candidates.duplicate():
			if candidate in path or (bad_pos != null and candidate == bad_pos):
				candidates.erase(candidate)
		
		if candidates.size() == 0:
			bad_pos = path.pop_back()
			if path.is_empty():
				push_error("Cannot calculate path")
				break
			current_pos = path.back()
			continue
		
		candidates.sort_custom(
			func(a, b):
				return a.distance_to(exit) < b.distance_to(exit)
		)
		
		var next : Vector2i
		
		# Move towards exit 70% of the time
		if candidates.size() == 1:
			next = candidates[0]
		elif path.size() >= min_path_length:
			if rng.randf() < MOVE_TOWARDS_EXIT_PROBABILITY:
				next = candidates[0]
			else:
				next = candidates[rng.randi_range(0, candidates.size() - 1)]
		elif rng.randf() < MOVE_TOWARDS_EXIT_PROBABILITY:
			next = candidates[rng.randi_range(0, candidates.size() - 1)]
		else:
			next = candidates[0]
		
		
		current_pos = next
		path.append(current_pos)

		iterations += 1
	
	if iterations == 100:
		for pos in path:
			grid[pos.y][pos.x] = TileType.FLOOR
		grid[start.y][start.x] = TileType.START
		grid[exit.y][exit.x] = TileType.EXIT
		path = []
	
	return path



func _calculate_door_positions(grid: Array[Array], path: Array[Vector2i], door_count: int) -> Array[int]:
	var door_indices : Array[int] = []
	if door_count <= 0 or path.size() < 3 or grid.is_empty():
		return door_indices

	for i in range(door_count):
		var t : float = float(i + 1) / float(door_count + 1)
		var target_idx : int = clampi(int(t * path.size()), 1, path.size() - 2)
		var selected_idx : int = -1

		for distance in range(path.size()):
			var candidates : Array[int] = []
			if distance == 0:
				candidates.append(target_idx)
			else:
				candidates.append(target_idx - distance)
				candidates.append(target_idx + distance)

			for candidate_idx in candidates:
				if candidate_idx <= 0 or candidate_idx >= path.size() - 1:
					continue
				if candidate_idx in door_indices:
					continue
				if not _has_two_wall_segments_around(grid, path[candidate_idx]):
					continue

				selected_idx = candidate_idx
				break

			if selected_idx >= 0:
				break

		if selected_idx >= 0:
			door_indices.append(selected_idx)

	door_indices.sort()
	return door_indices


func _has_two_wall_segments_around(grid: Array[Array], pos: Vector2i) -> bool:
	if grid.is_empty() or grid[0].is_empty():
		return false

	var wall_neighbors : Array[bool] = []
	for dir in SURROUNDING_DIRS:
		wall_neighbors.append(_is_wall_at(grid, pos + dir))

	var wall_segments : int = 0
	for i in range(wall_neighbors.size()):
		var previous_idx : int = (i - 1 + wall_neighbors.size()) % wall_neighbors.size()
		if wall_neighbors[i] and not wall_neighbors[previous_idx]:
			wall_segments += 1

	if wall_segments == 0 and wall_neighbors.has(true):
		wall_segments = 1

	return wall_segments >= 2


func _is_wall_at(grid: Array[Array], pos: Vector2i) -> bool:
	if pos.x < 0 or pos.y < 0:
		return false
	if pos.y >= grid.size() or pos.x >= grid[pos.y].size():
		return false
	return grid[pos.y][pos.x] == TileType.WALL


func _build_regions(path: Array[Vector2i], door_indices: Array[int]) -> Array:
	var regions : Array[MazeRegion] = []
	var start_idx : int = 0
	for i in range(door_indices.size()):
		var region : MazeRegion = MazeRegion.new()
		region.index = i
		var end_idx : int = door_indices[i]
		for p in range(start_idx, end_idx):
			region.path_tiles.append(path[p])
		region.ending_door = path[end_idx]
		regions.append(region)
		start_idx = end_idx
	var final_region : MazeRegion = MazeRegion.new()
	final_region.index = regions.size()
	for p in range(start_idx, path.size()):
		final_region.path_tiles.append(path[p])
	regions.append(final_region)
	return regions


func _grow_region_branches(grid: Array[Array], region: MazeRegion, rng: RandomNumberGenerator, branch_count: int, max_branch_length: int) -> void:
	for i in branch_count:
		var root : Vector2i = region.path_tiles.pick_random()
		_grow_branch(grid, root, region, rng, max_branch_length)


func _grow_branch(grid: Array[Array], root: Vector2i, region: MazeRegion, rng: RandomNumberGenerator, max_length: int) -> void:
	var directions : Array[Vector2i] = DIRS.duplicate()
	directions.shuffle()
	var current : Vector2i = root
	var length : int = rng.randi_range(2, max_length)
	for i in length:
		var candidates : Array[Vector2i] = []
		for dir in directions:
			var next : Vector2i = current + dir
			if next.x < 0 or next.y < 0:
				continue
			if next.x >= grid[0].size() or next.y >= grid.size():
				continue
			if grid[next.y][next.x] != TileType.WALL:
				continue
			candidates.append(next)
		if candidates.is_empty():
			break
		var chosen : Vector2i = candidates.pick_random()
		region.branch_tiles.append(chosen)
		region.all_tiles.append(chosen)
		current = chosen



func _add_extra_branches(grid: Array[Array], branch_count: int) -> void:
	for i in branch_count:
		var candidates : Array[Vector2i] = []
		for y in range(1, grid.size() - 1):
			for x in range(1, grid[0].size() - 1):
				if grid[y][x] == TileType.FLOOR:
					candidates.append(Vector2i(x, y))
		
		if candidates.is_empty():
			return
		
		var cell : Vector2i = candidates.pick_random()
		
		for d in DIRS:
			var target : Vector2i = cell + d
			
			if target.x <= 0:
				continue
			
			if target.y <= 0:
				continue
			
			if target.x >= grid[0].size() - 1:
				continue
			
			if target.y >= grid.size() - 1:
				continue
			
			grid[target.y][target.x] = TileType.FLOOR
		
		#var direction = DIRS.pick_random()
		#var target : Vector2i = start_cell + direction * 2
		#if target.x <= 0:
			#continue
		#if target.y <= 0:
			#continue
		#if target.x >= grid[0].size() - 1:
			#continue
		#if target.y >= grid.size() - 1:
			#continue
		#if grid[target.y][target.x] != TileType.WALL:
			#continue
		#var wall : Vector2i = start_cell + direction
		#grid[wall.y][wall.x] = TileType.FLOOR
		#grid[target.y][target.x] = TileType.FLOOR








func print_grid(grid: Array[Array]) -> void:
	print(export_text(grid))


func place_doors(grid: Array[Array], path: Array[Vector2i], min_doors: int, max_doors: int, _min_door_spacing: int) -> Array:
	var doors : Array[Dictionary] = []
	var count = randi_range(min_doors, max_doors)
	for i in range(count):
		var fraction : float = float(i + 1) / float(count + 1)
		var path_index : int = int(fraction * path.size())
		var pos : Vector2i = path[path_index]
		grid[pos.y][pos.x] = "D"
		doors.append({
			"position": pos,
			"path_index": path_index
		})
	return doors









func _walkable(grid: Array[Array], pos: Vector2i) -> bool:
	if pos.x < 0:
		return false
	if pos.y < 0:
		return false
	if pos.y >= grid.size():
		return false
	if pos.x >= grid[0].size():
		return false
	return grid[pos.y][pos.x] != TileType.WALL


func export_text(grid: Array[Array]) -> String:
	var output : String = ""
	for row in grid:
		for tile in row:
			match tile:
				TileType.WALL:
					output += "[color=black]■[/color]"
				TileType.FLOOR:
					output += "[color=white]■[/color]"
				TileType.START:
					output += "[color=green]■[/color]"
				TileType.EXIT:
					output += "[color=red]■[/color]"
				TileType.DOOR:
					output += "[color=blue]■[/color]"
				TileType.KEY:
					output += "[color=yellow]■[/color]"
				TileType.MONSTER:
					output += "[color=purple]■[/color]"
		output += "\n"
	return output







#func _find_dead_ends(grid: Array) -> Array[Vector2i]:
	#var results : Array[Vector2i] = []
	#for y in range(1, grid.size() - 1):
		#for x in range(1, grid[0].size() - 1):
			#var pos : Vector2i = Vector2i(x, y)
			#if not _walkable(grid, pos):
				#continue
			#var exits : int = 0
			#for dir in DIRS:
				#if _walkable(grid, pos + dir):
					#exits += 1
			#if exits == 1:
				#results.append(pos)
	#return results
#
#
#
#func find_furthest_floor(grid: Array[Array], start: Vector2i) -> Vector2i:
	#var queue : Array[Vector2i] = [start]
	#var visited : Dictionary[Vector2i, bool] = { start: true }
	#var furthest : Vector2i = start
	#
	#while not queue.is_empty():
		#var current = queue.pop_front()
		#furthest = current
		#
		#for d in DIRS:
			#var next = current + d
			#if visited.has(next):
				#continue
			#
			#if not _walkable(grid,next):
				#continue
			#
			#visited[next] = true
			#queue.push_back(next)
	#
	#return furthest
#
#
#func _find_furthest_floor(grid: Array, start: Vector2i) -> Vector2i:
	#var queue := [start]
	#var visited := {}
	#visited[start] = true
	#var furthest := start
	#while not queue.is_empty():
		#var current : Vector2i = queue.pop_front()
		#furthest = current
		#for dir in DIRS:
			#var next : Vector2i = current + dir
			#if visited.has(next):
				#continue
			#if not _walkable(grid, next):
				#continue
			#visited[next] = true
			#queue.push_back(next)
	#return furthest
#
#
#func _find_path(grid: Array[Array], start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	#var queue : Array[Vector2i] = [start]
	#var came_from : Dictionary[Vector2i, Vector2i] = {}
	#came_from[start] = start
	#while not queue.is_empty():
		#var current : Vector2i = queue.pop_front()
		#if current == goal:
			#break
		#for d in DIRS:
			#var next : Vector2i = current + d
			#if came_from.has(next):
				#continue
			#if not _walkable(grid, next):
				#continue
			#came_from[next] = current
			#queue.push_back(next)
	#var path : Array[Vector2i] = []
	#var cell : Vector2i = goal
	#while cell != start:
		#path.push_front(cell)
		#cell = came_from[cell]
	#path.push_front(start)
	#return path
#
#
#
#
#
#func _closest_path_index(
	#path: Array[Vector2i],
	#pos: Vector2i
#) -> int:
#
	#var best_index := 0
	#var best_distance := INF
#
	#for i in range(path.size()):
#
		#var distance = path[i].distance_squared_to(pos)
#
		#if distance < best_distance:
#
			#best_distance = distance
			#best_index = i
#
	#return best_index
#
#func _place_monsters(
	#grid: Array[Array],
	#start: Vector2i,
	#exit: Vector2i,
	##safe_start_radius: int,
	##monster_density: float
	#config: MazeConfig
#):
	#var monsters : Array = []
	#for y in range(grid.size()):
		#for x in range(grid[0].size()):
			#var pos : Vector2i = Vector2i(x,y)
			#if grid[y][x] != TileType.FLOOR:
				#continue
			#if pos.distance_to(start) < config.safe_start_radius:
				#continue
			#if pos == exit:
				#continue
			#if randf() < config.monster_density:
				#grid[y][x] = TileType.MONSTER
				#monsters.append(pos)
#
	#return monsters


#func generate(config: MazeConfig) -> Dictionary:
	#if config.randomize_seed:
		#config.maze_seed = Time.get_unix_time_from_system()
#
	#var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	#rng.seed = config.seed
	#var grid = _create_grid(config.width, config.height)
#
	##_carve_maze(grid)
#
	#_add_extra_branches(grid, config.extra_dead_end_branches)
#
	#var start = _find_furthest_floor(grid, Vector2i(1,1))
#
	#var exit = _find_furthest_floor(
		#grid,
		#start
	#)
#
	#var main_path = _find_path(
		#grid,
		#start,
		#exit
	#)
#
	#if main_path.size() < config.minimum_solution_length:
		#return generate(config)
#
	#var doors = _place_doors(grid, main_path, config, rng)
#
	#var dead_ends = _find_dead_ends(grid)
#
	#var keys = _place_keys(
		#grid,
		#start,
		#main_path,
		#doors,
		#dead_ends,
		#config
	#)
#
	#_place_monsters(grid,start,exit,config)
#
	#grid[start.y][start.x] = TileType.START
	#grid[exit.y][exit.x] = TileType.EXIT
#
	#if not _validate_progression(
		#main_path,
		#doors,
		#keys
	#):
		#return generate(config)
#
	#return {
		#"seed": config.seed,
		#"grid": grid,
		#"text": export_text(grid),
		#"start": start,
		#"exit": exit,
		#"doors": doors,
		#"keys": keys
	#}
#
#
#func _place_doors(
	#grid:Array,
	#path:Array,
	#config:MazeConfig,
	#rng: RandomNumberGenerator
#) -> Array:
#
	#var doors := []
#
	#var count = rng.randi_range(
		#config.min_doors,
		#config.max_doors
	#)
#
	#for i in range(count):
#
		#var fraction = float(i + 1) / float(count + 1)
#
		#var index = int(
			#fraction * path.size()
		#)
#
		#index = clamp(
			#index,
			#1,
			#path.size() - 2
		#)
#
		#var pos = path[index]
#
		#grid[pos.y][pos.x] = TileType.DOOR
#
		#doors.append({
			#"path_index": index,
			#"position": pos
		#})
#
	#return doors
#
#
#func _calculate_zone_cells(grid:Array,main_path: Array[Vector2i], doors:Array) -> Array:
	#var zones := []
	#var previous_path_index := 0
	#for door_index in range(doors.size()):
		#var current_index = doors[
			#door_index
		#]["path_index"]
		#var zone := []
		#for path_idx in range(
			#previous_path_index,
			#current_index
		#):
			##var path_cell : Vector2i = main_path[path_idx]
			#var reachable = _flood_fill_side_area(
				#grid,
				#main_path,
				#path_idx
			#)
			#zone.append_array(reachable)
		#zones.append(zone)
		#previous_path_index = current_index
	#return zones
#
#
#func _flood_fill_side_area(grid,main_path,path_index):
	#var origin = main_path[path_index]
	#var result := []
	#var queue := [origin]
	#var visited := {}
	#visited[origin] = true
#
	#while not queue.is_empty():
#
		#var current = queue.pop_front()
#
		#result.append(current)
#
		#for dir in DIRS:
#
			#var next = current + dir
#
			#if visited.has(next):
				#continue
#
			#if not _walkable(grid,next):
				#continue
#
			#visited[next] = true
			#queue.push_back(next)
#
	#return result
#


#func place_keys(grid: Array[Array], path: Array[Vector2i], doors: Array[Dictionary], dead_ends: Array[Vector2i], bonus_keys: int) -> Array:
	#var keys := []
	#var used := {}
	#for door_index in range(doors.size()):
		#var zone_start := 0
		#if door_index > 0:
			#zone_start = doors[door_index - 1]["path_index"]
		#var zone_end = doors[door_index]["path_index"]
		#var candidates := []
		#for dead_end in dead_ends:
			#if used.has(dead_end):
				#continue
			#var path_idx = _closest_path_index(path, dead_end)
			#if path_idx <= zone_start:
				#continue
			#if path_idx >= zone_end:
				#continue
			#candidates.append(dead_end)
		#if candidates.is_empty():
			#for idx in range(zone_start + 1, zone_end):
				#var pos = path[idx]
				#if grid[pos.y][pos.x] == TileType.FLOOR:
					#candidates.append(pos)
		#if candidates.is_empty():
			#continue
		#var key_pos = candidates[randi_range(0, candidates.size() - 1)]
		#grid[key_pos.y][key_pos.x] = "K"
		#used[key_pos] = true
		#keys.append(key_pos)
	## Bonus keys
	#var remaining := []
	#for dead_end in dead_ends:
		#if not used.has(dead_end):
			#remaining.append(dead_end)
	#remaining.shuffle()
	#for i in range(min(bonus_keys, remaining.size())):
		#var pos = remaining[i]
		#grid[pos.y][pos.x] = "K"
		#keys.append(pos)
	#return keys


#func place_progression_keys(
	#grid: Array[Array],
	#start: Vector2i,
	#doors: Array[Vector2i],
	#dead_ends: Array[Vector2i]
#):
	#var used_dead_ends : Dictionary = {}
	#var keys : Array[Vector2i] = []
	#for door_index in doors.size():
		#var door = doors[door_index]
		#var candidates : Array[Vector2i] = _find_dead_ends_before_door(
			#grid: Array[Array],
			#start: Vector2i,
			#door.position: Vector2i,
			#dead_ends: Array[Vector2i],
			#used_dead_ends
		#)
		#if candidates.is_empty():
			#return []
		#var key_pos = candidates[
			#randi_range(
				#0,
				#candidates.size() - 1
			#)
		#]
		#used_dead_ends[key_pos] = true
		#grid[key_pos.y][key_pos.x] = TileType.KEY
		#keys.append({
			#"id": door_index,
			#"position": key_pos
		#})
	#return keys


#func _place_keys(grid:Array, _start:Vector2i, main_path:Array, doors:Array, dead_ends:Array, config:MazeConfig) -> Array:
	#var keys := []
	#var used := {}
	#var zones = _calculate_zone_cells(
		#grid,
		#main_path,
		#doors
	#)
	#for zone in zones:
		#var candidates := []
		#for dead_end in dead_ends:
			#if used.has(dead_end):
				#continue
			#if zone.has(dead_end):
				#candidates.append(dead_end)
		#candidates.shuffle()
		#var count = min(
			#config.guaranteed_keys_per_zone,
			#candidates.size()
		#)
		#for i in range(count):
			#var tile = candidates[i]
			#grid[tile.y][tile.x] = TileType.KEY
			#used[tile] = true
			#keys.append(tile)
#
	## Bonus keys
	#var remaining := []
	#for dead_end in dead_ends:
		#if not used.has(dead_end):
			#remaining.append(dead_end)
	#remaining.shuffle()
	#for i in range(
		#min(
			#config.bonus_keys,
			#remaining.size()
		#)
	#):
		#var pos = remaining[i]
		#grid[pos.y][pos.x] = TileType.KEY
		#keys.append(pos)
	#return keys
#
#
#func _validate_progression(path:Array, doors:Array, keys:Array) -> bool:
	#for door_number in range(doors.size()):
		#var door_index = doors[door_number]["path_index"]
		#var keys_before := 0
		#for key in keys:
			#var best := _closest_path_index(
				#path,
				#key
			#)
			#if best < door_index:
				#keys_before += 1
		#if keys_before < door_number + 1:
			#return false
	#return true
