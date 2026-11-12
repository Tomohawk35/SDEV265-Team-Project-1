@tool
extends EditorScript


enum TileType {
	WALL,
	FLOOR,
	START,
	EXIT,
	DOOR,
	KEY,
	MONSTER
}

const DIRS = [
	Vector2i(0,-1),
	Vector2i(0,1),
	Vector2i(-1,0),
	Vector2i(1,0)
]

var difficulty : int = 1
var guaranteed_keys_per_zone : int = 1

var rng : RandomNumberGenerator = RandomNumberGenerator.new()


#@export var width : int = 12
#@export var height : int = 7

func _run() -> void:
	var width : int = 8 + randi_range(1, 3) * difficulty
	var height : int = 7 + randi_range(1, 3) * difficulty
	var extra_key_chance : float = 0.1 * difficulty
	var monster_density : float = 0.08
	var monster_near_keys_weight : float = 2.0
	var monster_near_exit_weight : float = 0.5
	var safe_start_radius : int = 5
	
	
	print("\nGenerating grid wall...")
	print("==============================\n")
	var grid : Array[Array] = _create_grid(width, height)
	print_grid(grid)
	
	print("\nCarving maze...")
	print("==============================\n")
	_carve_maze(grid)
	print_grid(grid)
	
	print("\nAdding branches...")
	print("==============================\n")
	_add_extra_branches(grid, 2)
	print_grid(grid)
	
	#1. Generate maze
	#2. Find start and exit
	#3. Find main path
	#4. Place doors on main path
	#5. Segment path into zones
	#6. Guarantee enough keys in each zone
	#7. Place bonus keys
	#8. Place monsters


func _create_grid(grid_width: int, grid_height: int) -> Array[Array]:
	var grid : Array[Array] = []
	for y in grid_height:
		var row : Array = []
		for x in grid_width:
			row.append(TileType.WALL)
		grid.append(row)
	return grid


func _carve_maze(grid: Array[Array]) -> void:
	var stack : Array = []
	var start : Vector2i = Vector2i(1, 1)
	grid[1][1] = TileType.FLOOR
	stack.push_back(start)
	var carve_dirs : Array[Vector2i] = [
		Vector2i(0,-2),
		Vector2i(0,2),
		Vector2i(-2,0),
		Vector2i(2,0)
	]
	while not stack.is_empty():
		var current : Vector2i = stack.back()
		var neighbors : Array[Vector2i] = []
		for d in carve_dirs:
			var next : Vector2i = current + d
			if next.x < 1:
				continue
			if next.y < 1:
				continue
			if next.x >= grid[0].size() - 1:
				continue
			if next.y >= grid.size() - 1:
				continue
			if grid[next.y][next.x] == TileType.WALL:
				neighbors.append(next)
		if neighbors.is_empty():
			stack.pop_back()
			continue
		var chosen : Vector2i = neighbors[randi_range(0, neighbors.size() - 1)]
		var wall : Vector2i = current + ((chosen - current) / 2)
		grid[wall.y][wall.x] = TileType.FLOOR
		grid[chosen.y][chosen.x] = TileType.FLOOR
		stack.push_back(chosen)


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


func find_furthest_floor(grid: Array[Array], start: Vector2i) -> Vector2i:
	var queue : Array[Vector2i] = [start]
	var visited : Dictionary[Vector2i, bool] = { start: true }
	var furthest : Vector2i = start
	
	while not queue.is_empty():
		var current = queue.pop_front()
		furthest = current
		
		for d in DIRS:
			var next = current + d
			if visited.has(next):
				continue
			
			if not walkable(grid,next):
				continue
			
			visited[next] = true
			queue.push_back(next)
	
	return furthest





func print_grid(grid: Array[Array]) -> void:
	for row in grid:
		print(row)


func place_doors(grid: Array[Array], path: Array[Vector2i], min_doors: int, max_doors: int, min_door_spacing: int) -> Array:
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




func walkable(grid: Array[Array], pos: Vector2i) -> bool:
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
					output += "#"
				TileType.FLOOR:
					output += "."
				TileType.START:
					output += "S"
				TileType.EXIT:
					output += "E"
				TileType.DOOR:
					output += "D"
				TileType.KEY:
					output += "K"
				TileType.MONSTER:
					output += "M"
		output += "\n"
	return output


#func generate_maze() -> Array[Array]:
	#var width : int = 8 + randi_range(1, 3) * difficulty
	#var height : int = 7 + randi_range(1, 3) * difficulty
	#var extra_key_chance : float = 0.1 * difficulty
	#var monster_density : float = 0.08
	#var monster_near_keys_weight : float = 2.0
	#var monster_near_exit_weight : float = 0.5
	#var safe_start_radius : int = 5
	#
	#var layout : Array[Array] = []
	#for i in range(height):
		#var row : Array = []
		#for j in range(width):
			#row.append("#")
		#print(row)
		#layout.append(row)
	##print_rich(layout)
	#return [[]]


#func validate_progression(path:Array,doors:Array,keys:Array) -> bool:
	#for door_index in range(doors.size()):
		#var door_path_index = doors[door_index]["path_index"]
		#var available_keys := 0
		#for key_pos in keys:
			#var key_idx = _closest_path_index(path,key_pos)
			#if key_idx < door_path_index:
				#available_keys += 1
		#if available_keys < door_index + 1:
			#return false
	#return true


func _walkable(grid: Array, pos: Vector2i) -> bool:
	if pos.x < 0:
		return false

	if pos.y < 0:
		return false

	if pos.y >= grid.size():
		return false

	if pos.x >= grid[0].size():
		return false

	return grid[pos.y][pos.x] != TileType.WALL





func _find_dead_ends(grid: Array) -> Array[Vector2i]:
	var results : Array[Vector2i] = []
	for y in range(1, grid.size() - 1):
		for x in range(1, grid[0].size() - 1):
			var pos : Vector2i = Vector2i(x, y)
			if not _walkable(grid, pos):
				continue
			var exits : int = 0
			for dir in DIRS:
				if _walkable(grid, pos + dir):
					exits += 1
			if exits == 1:
				results.append(pos)
	return results


func _find_furthest_floor(grid: Array, start: Vector2i) -> Vector2i:
	var queue := [start]
	var visited := {}
	visited[start] = true
	var furthest := start
	while not queue.is_empty():
		var current : Vector2i = queue.pop_front()
		furthest = current
		for dir in DIRS:
			var next : Vector2i = current + dir
			if visited.has(next):
				continue
			if not _walkable(grid, next):
				continue
			visited[next] = true
			queue.push_back(next)
	return furthest


func _find_path(grid: Array[Array], start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var queue : Array[Vector2i] = [start]
	var came_from : Dictionary[Vector2i, Vector2i] = {}
	came_from[start] = start
	while not queue.is_empty():
		var current : Vector2i = queue.pop_front()
		if current == goal:
			break
		for d in DIRS:
			var next : Vector2i = current + d
			if came_from.has(next):
				continue
			if not _walkable(grid, next):
				continue
			came_from[next] = current
			queue.push_back(next)
	var path : Array[Vector2i] = []
	var cell : Vector2i = goal
	while cell != start:
		path.push_front(cell)
		cell = came_from[cell]
	path.push_front(start)
	return path





func _closest_path_index(
	path: Array[Vector2i],
	pos: Vector2i
) -> int:

	var best_index := 0
	var best_distance := INF

	for i in range(path.size()):

		var distance = path[i].distance_squared_to(pos)

		if distance < best_distance:

			best_distance = distance
			best_index = i

	return best_index

func _place_monsters(
	grid: Array[Array],
	start: Vector2i,
	exit: Vector2i,
	#safe_start_radius: int,
	#monster_density: float
	config: MazeConfig
):
	var monsters : Array = []
	for y in range(grid.size()):
		for x in range(grid[0].size()):
			var pos : Vector2i = Vector2i(x,y)
			if grid[y][x] != TileType.FLOOR:
				continue
			if pos.distance_to(start) < config.safe_start_radius:
				continue
			if pos == exit:
				continue
			if randf() < config.monster_density:
				grid[y][x] = TileType.MONSTER
				monsters.append(pos)

	return monsters


func generate(config: MazeConfig) -> Dictionary:
	if config.randomize_seed:
		config.seed = Time.get_unix_time_from_system()

	rng.seed = config.seed

	var grid = _create_grid(
		config.width,
		config.height
	)

	_carve_maze(grid)

	_add_extra_branches(
		grid,
		config.extra_dead_end_branches
	)

	var start = _find_furthest_floor(
		grid,
		Vector2i(1,1)
	)

	var exit = _find_furthest_floor(
		grid,
		start
	)

	var main_path = _find_path(
		grid,
		start,
		exit
	)

	if main_path.size() < config.minimum_solution_length:
		return generate(config)

	var doors = _place_doors(
		grid,
		main_path,
		config
	)

	var dead_ends = _find_dead_ends(grid)

	var keys = _place_keys(
		grid,
		start,
		main_path,
		doors,
		dead_ends,
		config
	)

	_place_monsters(grid,start,exit,config)

	grid[start.y][start.x] = TileType.START
	grid[exit.y][exit.x] = TileType.EXIT

	if not _validate_progression(
		main_path,
		doors,
		keys
	):
		return generate(config)

	return {
		"seed": config.seed,
		"grid": grid,
		"text": export_text(grid),
		"start": start,
		"exit": exit,
		"doors": doors,
		"keys": keys
	}


func _place_doors(
	grid:Array,
	path:Array,
	config:MazeConfig
) -> Array:

	var doors := []

	var count = rng.randi_range(
		config.min_doors,
		config.max_doors
	)

	for i in range(count):

		var fraction = float(i + 1) / float(count + 1)

		var index = int(
			fraction * path.size()
		)

		index = clamp(
			index,
			1,
			path.size() - 2
		)

		var pos = path[index]

		grid[pos.y][pos.x] = TileType.DOOR

		doors.append({
			"path_index": index,
			"position": pos
		})

	return doors


func _calculate_zone_cells(grid:Array,main_path:Array, doors:Array) -> Array:

	var zones := []

	var previous_path_index := 0

	for door_index in range(doors.size()):

		var current_index = doors[
			door_index
		]["path_index"]

		var zone := []

		for path_idx in range(
			previous_path_index,
			current_index
		):

			var path_cell = main_path[path_idx]

			var reachable = _flood_fill_side_area(
				grid,
				main_path,
				path_idx
			)

			zone.append_array(reachable)

		zones.append(zone)

		previous_path_index = current_index

	return zones


func _flood_fill_side_area(grid,main_path,path_index):
	var origin = main_path[path_index]
	var result := []
	var queue := [origin]
	var visited := {}
	visited[origin] = true

	while not queue.is_empty():

		var current = queue.pop_front()

		result.append(current)

		for dir in DIRS:

			var next = current + dir

			if visited.has(next):
				continue

			if not _walkable(grid,next):
				continue

			visited[next] = true
			queue.push_back(next)

	return result


func _place_keys(grid:Array, start:Vector2i, main_path:Array, doors:Array, dead_ends:Array, config:MazeConfig) -> Array:

	var keys := []

	var used := {}

	var zones = _calculate_zone_cells(
		grid,
		main_path,
		doors
	)

	for zone in zones:

		var candidates := []

		for dead_end in dead_ends:

			if used.has(dead_end):
				continue

			if zone.has(dead_end):
				candidates.append(dead_end)

		candidates.shuffle()

		var count = min(
			config.guaranteed_keys_per_zone,
			candidates.size()
		)

		for i in range(count):

			var tile = candidates[i]

			grid[tile.y][tile.x] = TileType.KEY

			used[tile] = true

			keys.append(tile)

	# Bonus keys

	var remaining := []

	for dead_end in dead_ends:

		if not used.has(dead_end):
			remaining.append(dead_end)

	remaining.shuffle()

	for i in range(
		min(
			config.bonus_keys,
			remaining.size()
		)
	):

		var pos = remaining[i]

		grid[pos.y][pos.x] = TileType.KEY

		keys.append(pos)

	return keys


func _validate_progression(path:Array, doors:Array, keys:Array) -> bool:

	for door_number in range(doors.size()):

		var door_index = doors[
			door_number
		]["path_index"]

		var keys_before := 0

		for key in keys:

			var best := _closest_path_index(
				path,
				key
			)

			if best < door_index:
				keys_before += 1

		if keys_before < door_number + 1:
			return false

	return true
