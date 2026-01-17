extends Node

# Grid constants (synced with spawner)
const COLUMN_COUNT := 5
const COLUMN_SPACING := 50.0  # Same as block size - no gaps
const CENTER_X := 900.0
const GROUND_TOP_Y := 600.0
const BLOCK_SIZE := 50.0

# First column X position (CENTER_X - 2 * COLUMN_SPACING = 900 - 100 = 800)
const FIRST_COLUMN_X := 800.0

# Grid storage: maps Vector2i(col, row) -> block
var grid: Dictionary = {}

# All registered blocks
var blocks: Array = []

# Pending match check
var _check_pending := false


func register_block(block: StaticBody2D) -> void:
	if block not in blocks:
		blocks.append(block)


func unregister_block(block: StaticBody2D) -> void:
	blocks.erase(block)
	# Remove from grid if present
	for grid_pos in grid.keys():
		if grid[grid_pos] == block:
			grid.erase(grid_pos)
			break


func is_cell_occupied(col: int, row: int) -> bool:
	return grid.has(Vector2i(col, row))


func place_block(block: StaticBody2D, col: int, row: int) -> void:
	var grid_pos := Vector2i(col, row)
	grid[grid_pos] = block


func get_landing_row(col: int) -> int:
	# Find the lowest empty row in this column (row 0 is at bottom)
	var row := 0
	while is_cell_occupied(col, row):
		row += 1
	return row


func grid_to_world(col: int, row: int) -> Vector2:
	var x := FIRST_COLUMN_X + col * COLUMN_SPACING
	# Row 0 is at bottom, block center is half block above ground
	var y := GROUND_TOP_Y - (row * BLOCK_SIZE) - (BLOCK_SIZE / 2.0)
	return Vector2(x, y)


func request_match_check() -> void:
	# Defer check to next frame to batch multiple settlement events
	if not _check_pending:
		_check_pending = true
		call_deferred("_do_match_check")


func _do_match_check() -> void:
	_check_pending = false

	# Find all matches using the grid directly
	var matched_blocks := {}  # Use dict as set

	# Check horizontal matches (rows)
	matched_blocks.merge(_find_horizontal_matches(grid))

	# Check vertical matches (columns)
	matched_blocks.merge(_find_vertical_matches(grid))

	# Mark matched blocks yellow
	for block in matched_blocks.keys():
		if is_instance_valid(block) and block.has_method("set_matched"):
			block.set_matched()


func _find_horizontal_matches(check_grid: Dictionary) -> Dictionary:
	var matched := {}

	# Group blocks by row
	var rows := {}  # Dictionary[int, Array[Vector2i]]
	for grid_pos in check_grid.keys():
		var row: int = grid_pos.y
		if row not in rows:
			rows[row] = []
		rows[row].append(grid_pos)

	# Check each row for consecutive columns with matching symbols
	for row in rows.keys():
		var positions: Array = rows[row]
		positions.sort_custom(func(a, b): return a.x < b.x)

		if positions.size() < 3:
			continue

		var run_start := 0
		var run_symbol: String = check_grid[positions[0]].symbol if positions.size() > 0 else ""

		for i in range(1, positions.size() + 1):
			var current_symbol: String = check_grid[positions[i]].symbol if i < positions.size() else ""
			var is_consecutive: bool = i < positions.size() and positions[i].x == positions[i - 1].x + 1
			var is_same_symbol: bool = current_symbol == run_symbol

			if not is_consecutive or not is_same_symbol:
				var run_length := i - run_start
				if run_length >= 3:
					for j in range(run_start, i):
						matched[check_grid[positions[j]]] = true
				run_start = i
				run_symbol = current_symbol

	return matched


func _find_vertical_matches(check_grid: Dictionary) -> Dictionary:
	var matched := {}

	# Group blocks by column
	var cols := {}  # Dictionary[int, Array[Vector2i]]
	for grid_pos in check_grid.keys():
		var col: int = grid_pos.x
		if col not in cols:
			cols[col] = []
		cols[col].append(grid_pos)

	# Check each column for consecutive rows with matching symbols
	for col in cols.keys():
		var positions: Array = cols[col]
		positions.sort_custom(func(a, b): return a.y < b.y)

		if positions.size() < 3:
			continue

		var run_start := 0
		var run_symbol: String = check_grid[positions[0]].symbol if positions.size() > 0 else ""

		for i in range(1, positions.size() + 1):
			var current_symbol: String = check_grid[positions[i]].symbol if i < positions.size() else ""
			var is_consecutive: bool = i < positions.size() and positions[i].y == positions[i - 1].y + 1
			var is_same_symbol: bool = current_symbol == run_symbol

			if not is_consecutive or not is_same_symbol:
				var run_length := i - run_start
				if run_length >= 3:
					for j in range(run_start, i):
						matched[check_grid[positions[j]]] = true
				run_start = i
				run_symbol = current_symbol

	return matched
