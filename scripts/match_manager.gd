extends Node

signal resources_changed(resources: Dictionary)

# Grid constants (synced with spawner)
const COLUMN_COUNT := 5
const COLUMN_SPACING := 50.0  # Same as block size - no gaps
const CENTER_X := 900.0
const GROUND_TOP_Y := 600.0
const BLOCK_SIZE := 50.0

# First column X position (CENTER_X - 2 * COLUMN_SPACING = 900 - 100 = 800)
const FIRST_COLUMN_X := 800.0

# Resources per match
const RESOURCES_PER_MATCH := 10

# Grid storage: maps Vector2i(col, row) -> block
var grid: Dictionary = {}

# All registered blocks
var blocks: Array = []

# Resource tracking
var resources: Dictionary = {
	"#": 0,
	"$": 0,
	"%": 0,
	"!": 0
}

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


func world_to_grid(world_pos: Vector2) -> Vector2i:
	# Convert world position to grid coordinates
	var col := roundi((world_pos.x - FIRST_COLUMN_X) / COLUMN_SPACING)
	col = clampi(col, 0, COLUMN_COUNT - 1)
	# Row calculation: block at row 0 has center at y = 575, row 1 at y = 525, etc.
	var row := roundi((GROUND_TOP_Y - (BLOCK_SIZE / 2.0) - world_pos.y) / BLOCK_SIZE)
	row = maxi(row, 0)
	return Vector2i(col, row)


func get_block_at(col: int, row: int) -> StaticBody2D:
	var grid_pos := Vector2i(col, row)
	if grid.has(grid_pos):
		return grid[grid_pos]
	return null


func remove_block_from_grid(block: StaticBody2D) -> void:
	# Remove block from grid without destroying it
	for grid_pos in grid.keys():
		if grid[grid_pos] == block:
			grid.erase(grid_pos)
			break


func add_resource(symbol: String, amount: int) -> void:
	if symbol in resources:
		resources[symbol] += amount
		resources_changed.emit(resources)


func get_resources() -> Dictionary:
	return resources


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

	if matched_blocks.is_empty():
		return

	# Track which columns had blocks removed
	var affected_columns := {}

	# Group matched blocks by symbol and remove them
	var symbols_matched := {}
	for block in matched_blocks.keys():
		if is_instance_valid(block):
			var symbol: String = block.symbol
			if symbol not in symbols_matched:
				symbols_matched[symbol] = 0
			symbols_matched[symbol] += 1
			# Track the column
			affected_columns[block.grid_col] = true
			# Remove from grid and destroy
			_remove_block(block)

	# Add resources for each symbol matched
	for symbol in symbols_matched.keys():
		add_resource(symbol, symbols_matched[symbol] * RESOURCES_PER_MATCH)

	# Apply gravity to blocks in affected columns
	_apply_gravity(affected_columns.keys())


func _remove_block(block: StaticBody2D) -> void:
	# Remove from blocks array
	blocks.erase(block)
	# Remove from grid
	for grid_pos in grid.keys():
		if grid[grid_pos] == block:
			grid.erase(grid_pos)
			break
	# Destroy the block
	block.queue_free()


func _apply_gravity(columns: Array) -> void:
	# For each affected column, find blocks that are floating and make them fall
	for col in columns:
		# Get all blocks in this column, sorted by row (bottom to top)
		var column_blocks := []
		for grid_pos in grid.keys():
			if grid_pos.x == col:
				column_blocks.append({"pos": grid_pos, "block": grid[grid_pos]})

		# Sort by row (y) ascending
		column_blocks.sort_custom(func(a, b): return a.pos.y < b.pos.y)

		# Check for gaps and make floating blocks fall
		for entry in column_blocks:
			var block = entry.block
			var current_row: int = entry.pos.y

			# Check if there's a gap below this block
			var expected_row := get_landing_row(col)
			if expected_row < current_row:
				# This block is floating - remove from grid and make it fall
				grid.erase(entry.pos)
				if is_instance_valid(block) and block.has_method("start_falling"):
					block.start_falling()


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
