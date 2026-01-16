extends Node

# Grid constants (synced with spawner)
const COLUMN_COUNT := 5
const COLUMN_SPACING := 60.0
const CENTER_X := 900.0
const GROUND_TOP_Y := 600.0
const BLOCK_SIZE := 50.0

# First column X position (CENTER_X - 2 * COLUMN_SPACING = 900 - 120 = 780)
const FIRST_COLUMN_X := 780.0

# All registered blocks
var blocks: Array[RigidBody2D] = []

# Pending match check
var _check_pending := false


func register_block(block: RigidBody2D) -> void:
	if block not in blocks:
		blocks.append(block)


func unregister_block(block: RigidBody2D) -> void:
	blocks.erase(block)


func request_match_check() -> void:
	# Defer check to next frame to batch multiple settlement events
	if not _check_pending:
		_check_pending = true
		call_deferred("_do_match_check")


func _do_match_check() -> void:
	_check_pending = false

	# Build grid from settled blocks only
	var grid := {}  # Dictionary[Vector2i, RigidBody2D]

	for block in blocks:
		if not is_instance_valid(block):
			continue
		if not block.has_method("is_settled") or not block.is_settled():
			continue

		var grid_pos := _world_to_grid(block.global_position)
		grid[grid_pos] = block

	# Find all matches
	var matched_blocks := {}  # Use dict as set

	# Check horizontal matches (rows)
	matched_blocks.merge(_find_horizontal_matches(grid))

	# Check vertical matches (columns)
	matched_blocks.merge(_find_vertical_matches(grid))

	# Mark matched blocks yellow
	for block in matched_blocks.keys():
		if is_instance_valid(block) and block.has_method("set_matched"):
			block.set_matched()


func _world_to_grid(world_pos: Vector2) -> Vector2i:
	# Column: based on x position
	var col := roundi((world_pos.x - FIRST_COLUMN_X) / COLUMN_SPACING)
	col = clampi(col, 0, COLUMN_COUNT - 1)

	# Row: based on y position (row 0 at bottom)
	var row := floori((GROUND_TOP_Y - world_pos.y) / BLOCK_SIZE)
	row = maxi(row, 0)

	return Vector2i(col, row)


func _find_horizontal_matches(grid: Dictionary) -> Dictionary:
	var matched := {}

	# Group blocks by row
	var rows := {}  # Dictionary[int, Array[Vector2i]]
	for grid_pos in grid.keys():
		var row: int = grid_pos.y
		if row not in rows:
			rows[row] = []
		rows[row].append(grid_pos)

	# Check each row for consecutive columns with matching symbols
	for row in rows.keys():
		var positions: Array = rows[row]
		positions.sort_custom(func(a, b): return a.x < b.x)

		var run_start := 0
		var run_symbol: String = grid[positions[0]].symbol if positions.size() > 0 else ""

		for i in range(1, positions.size() + 1):
			var current_symbol: String = grid[positions[i]].symbol if i < positions.size() else ""
			var is_consecutive: bool = i < positions.size() and positions[i].x == positions[i - 1].x + 1
			var is_same_symbol: bool = current_symbol == run_symbol

			if not is_consecutive or not is_same_symbol:
				var run_length := i - run_start
				if run_length >= 3:
					for j in range(run_start, i):
						matched[grid[positions[j]]] = true
				run_start = i
				run_symbol = current_symbol

	return matched


func _find_vertical_matches(grid: Dictionary) -> Dictionary:
	var matched := {}

	# Group blocks by column
	var cols := {}  # Dictionary[int, Array[Vector2i]]
	for grid_pos in grid.keys():
		var col: int = grid_pos.x
		if col not in cols:
			cols[col] = []
		cols[col].append(grid_pos)

	# Check each column for consecutive rows with matching symbols
	for col in cols.keys():
		var positions: Array = cols[col]
		positions.sort_custom(func(a, b): return a.y < b.y)

		var run_start := 0
		var run_symbol: String = grid[positions[0]].symbol if positions.size() > 0 else ""

		for i in range(1, positions.size() + 1):
			var current_symbol: String = grid[positions[i]].symbol if i < positions.size() else ""
			var is_consecutive: bool = i < positions.size() and positions[i].y == positions[i - 1].y + 1
			var is_same_symbol: bool = current_symbol == run_symbol

			if not is_consecutive or not is_same_symbol:
				var run_length := i - run_start
				if run_length >= 3:
					for j in range(run_start, i):
						matched[grid[positions[j]]] = true
				run_start = i
				run_symbol = current_symbol

	return matched
