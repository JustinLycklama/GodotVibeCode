extends CharacterBody2D

@export var speed: float = 300.0
@export var fall_speed: float = 400.0

# Surface states for spider-style movement
enum Surface { FLOOR, WALL_LEFT, WALL_RIGHT, FALLING }
var current_surface: Surface = Surface.FALLING
var move_direction: int = 0  # -1, 0, or 1

# Constants for collision detection
const PLAYER_HALF := 23.0
const BLOCK_HALF := 25.0

# Block pickup system
var held_block: StaticBody2D = null
const HELD_BLOCK_OFFSET := Vector2(0, -50)  # Block appears above player's head


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	# Get input direction
	move_direction = 0
	if Input.is_action_pressed("ui_right"):
		move_direction += 1
	if Input.is_action_pressed("ui_left"):
		move_direction -= 1

	# Process movement based on current surface
	match current_surface:
		Surface.FLOOR:
			_move_on_floor()
		Surface.WALL_RIGHT:
			_move_on_wall_right()
		Surface.WALL_LEFT:
			_move_on_wall_left()
		Surface.FALLING:
			_fall()

	move_and_slide()

	# Check for surface transitions after movement
	_check_surface_transitions()

	# Update visual rotation
	_update_rotation()

	# Push any overlapping falling blocks up out of the way
	_push_overlapping_blocks_up()

	# Update held block position to follow player
	if held_block and is_instance_valid(held_block):
		held_block.global_position = global_position + HELD_BLOCK_OFFSET


func _move_on_floor() -> void:
	velocity = Vector2(move_direction * speed, 0)


func _move_on_wall_right() -> void:
	# On right wall: right arrow = climb up (-Y), left arrow = climb down (+Y)
	velocity = Vector2(0, -move_direction * speed)


func _move_on_wall_left() -> void:
	# On left wall: right arrow = climb down (+Y), left arrow = climb up (-Y)
	velocity = Vector2(0, move_direction * speed)


func _fall() -> void:
	velocity = Vector2(0, fall_speed)


func _check_surface_transitions() -> void:
	match current_surface:
		Surface.FLOOR:
			_check_floor_transitions()
		Surface.WALL_RIGHT:
			_check_wall_right_transitions()
		Surface.WALL_LEFT:
			_check_wall_left_transitions()
		Surface.FALLING:
			_check_falling_transitions()


func _check_floor_transitions() -> void:
	# Hit a wall while moving? Only transition if pressing toward the wall
	if is_on_wall() and move_direction != 0:
		var collision := get_last_slide_collision()
		if collision:
			var normal := collision.get_normal()
			# Only climb right wall if pressing right
			if normal.x < -0.5 and move_direction > 0:
				current_surface = Surface.WALL_RIGHT
				return
			# Only climb left wall if pressing left
			elif normal.x > 0.5 and move_direction < 0:
				current_surface = Surface.WALL_LEFT
				return

	# Floor disappeared while moving? Check for corner wrap
	if not is_on_floor() and move_direction != 0:
		# Check if there's a wall to cling to in the direction we were moving
		if move_direction > 0:
			# Moving right - check for wall on right side to climb down
			if _is_wall_at_direction(1):
				current_surface = Surface.WALL_RIGHT
				return
		else:
			# Moving left - check for wall on left side to climb down
			if _is_wall_at_direction(-1):
				current_surface = Surface.WALL_LEFT
				return
		# No wall to cling to - fall
		current_surface = Surface.FALLING


func _check_wall_right_transitions() -> void:
	# Climbing up (move_direction > 0) - check if we reached the top
	if move_direction > 0:
		# If no longer on wall, try to step onto the block we were climbing
		if not is_on_wall():
			# Find the block we were climbing (to our RIGHT, below our current position)
			var block_x := global_position.x + PLAYER_HALF + BLOCK_HALF
			var block_y := global_position.y + PLAYER_HALF + BLOCK_HALF  # Check one block below feet
			var grid_pos := MatchManager.world_to_grid(Vector2(block_x, block_y))
			print("Checking at world: ", block_x, ", ", block_y, " -> grid: ", grid_pos)
			_spawn_debug_marker(Vector2(block_x, block_y), Color.ORANGE)

			if MatchManager.is_cell_occupied(grid_pos.x, grid_pos.y):
				print("Cell is occupied")
				# Step onto the top of this block
				var block_world := MatchManager.grid_to_world(grid_pos.x, grid_pos.y)
				# Nudge X left to stand on the block (block is to our right)
				global_position.x += 4
				global_position.y = block_world.y - BLOCK_HALF - PLAYER_HALF + 1
				velocity.y = 10  # Small downward velocity to register floor contact
				current_surface = Surface.FLOOR
				return
			# No block to step onto - fall
			current_surface = Surface.FALLING
			return

	# Climbing down (move_direction < 0) - check if we hit floor
	if move_direction < 0:
		if is_on_floor():
			current_surface = Surface.FLOOR
			return

	# Check if wall disappeared
	if not is_on_wall() and move_direction == 0:
		if is_on_floor():
			current_surface = Surface.FLOOR
		else:
			current_surface = Surface.FALLING


func _check_wall_left_transitions() -> void:
	# Climbing up (move_direction < 0) - check if we reached the top
	if move_direction < 0:
		# If no longer on wall, try to step onto the block we were climbing
		if not is_on_wall():
			# Find the block we were climbing (to our LEFT, below our current position)
			var block_x := global_position.x - PLAYER_HALF - BLOCK_HALF
			var block_y := global_position.y + PLAYER_HALF + BLOCK_HALF  # Check one block below feet
			var grid_pos := MatchManager.world_to_grid(Vector2(block_x, block_y))

			if MatchManager.is_cell_occupied(grid_pos.x, grid_pos.y):
				# Step onto the top of this block
				var block_world := MatchManager.grid_to_world(grid_pos.x, grid_pos.y)
				# Nudge X right to stand on the block (block is to our left)
				global_position.x -= 4
				global_position.y = block_world.y - BLOCK_HALF - PLAYER_HALF + 1
				velocity.y = 10  # Small downward velocity to register floor contact
				current_surface = Surface.FLOOR
				return
			# No block to step onto - fall
			current_surface = Surface.FALLING
			return

	# Climbing down (move_direction > 0) - check if we hit floor
	if move_direction > 0:
		if is_on_floor():
			current_surface = Surface.FLOOR
			return

	# Check if wall disappeared
	if not is_on_wall() and move_direction == 0:
		if is_on_floor():
			current_surface = Surface.FLOOR
		else:
			current_surface = Surface.FALLING


func _check_falling_transitions() -> void:
	# Landed on floor?
	if is_on_floor():
		current_surface = Surface.FLOOR
		return

	# Hit a wall while falling?
	if is_on_wall():
		var collision := get_last_slide_collision()
		if collision:
			var normal := collision.get_normal()
			if normal.x < -0.5:  # Hit wall on right side
				current_surface = Surface.WALL_RIGHT
				return
			elif normal.x > 0.5:  # Hit wall on left side
				current_surface = Surface.WALL_LEFT
				return


func _is_wall_at_direction(direction: int) -> bool:
	# Check if there's a block in the given direction using the grid
	var check_x := global_position.x + direction * (PLAYER_HALF + 5)
	var check_y := global_position.y + PLAYER_HALF + 5  # Check slightly below feet
	var grid_pos := MatchManager.world_to_grid(Vector2(check_x, check_y))
	return MatchManager.is_cell_occupied(grid_pos.x, grid_pos.y)


func _update_rotation() -> void:
	match current_surface:
		Surface.FLOOR, Surface.FALLING:
			rotation_degrees = 0
		Surface.WALL_RIGHT:
			rotation_degrees = -90
		Surface.WALL_LEFT:
			rotation_degrees = 90


func _push_overlapping_blocks_up() -> void:
	const PLAYER_HALF := 23.0
	const BLOCK_HALF := 25.0

	# Check all registered blocks for overlap
	for block in MatchManager.blocks:
		if not is_instance_valid(block):
			continue
		# Skip settled blocks (they have physics collision) and held block
		if block._settled or block == held_block:
			continue

		# Check for overlap using AABB
		var player_left: float = global_position.x - PLAYER_HALF
		var player_right: float = global_position.x + PLAYER_HALF
		var player_top: float = global_position.y - PLAYER_HALF
		var player_bottom: float = global_position.y + PLAYER_HALF

		var block_left: float = block.global_position.x - BLOCK_HALF
		var block_right: float = block.global_position.x + BLOCK_HALF
		var block_top: float = block.global_position.y - BLOCK_HALF
		var block_bottom: float = block.global_position.y + BLOCK_HALF

		var x_overlap: bool = player_left < block_right and player_right > block_left
		var y_overlap: bool = player_top < block_bottom and player_bottom > block_top

		if x_overlap and y_overlap:
			# Push the block up so its bottom is at player's top
			block.global_position.y = player_top - BLOCK_HALF


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # Spacebar
		if held_block:
			_put_down_block()
		else:
			_pick_up_block()


func _pick_up_block() -> void:
	# Find which column we're in
	var grid_pos := MatchManager.world_to_grid(global_position)
	var col: int = grid_pos.x

	# Find the topmost block in this column that's at or below our feet
	# Player's feet are at global_position.y + 25 (half player height)
	var feet_y := global_position.y + 25
	var feet_grid_pos := MatchManager.world_to_grid(Vector2(global_position.x, feet_y))
	var target_row: int = feet_grid_pos.y

	# Look for a block at this position or below
	var block: StaticBody2D = null
	for row in range(target_row, -1, -1):
		block = MatchManager.get_block_at(col, row)
		if block:
			target_row = row
			break

	if not block:
		return

	# Pick up the block
	held_block = block

	# Remove from grid (but don't destroy)
	MatchManager.remove_block_from_grid(block)

	# Disable collision while held
	var collision_shape = block.get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.disabled = true

	# Mark as not settled so it can be placed again
	block._settled = false
	block.grid_row = -1

	# Stop the block's own processing while held (prevents it from trying to fall)
	block.set_process(false)

	# Apply gravity to any blocks that were above this one
	MatchManager._apply_gravity([col])


func _put_down_block() -> void:
	if not held_block or not is_instance_valid(held_block):
		held_block = null
		return

	# Find which column we're in
	var grid_pos := MatchManager.world_to_grid(global_position)
	var col: int = grid_pos.x

	# Find the landing row for this column
	var landing_row := MatchManager.get_landing_row(col)

	# Place the block at the landing position
	var landing_pos := MatchManager.grid_to_world(col, landing_row)
	held_block.global_position = landing_pos
	held_block.grid_col = col
	held_block.grid_row = landing_row
	held_block._settled = true

	# Re-enable collision and processing
	var collision_shape = held_block.get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.disabled = false
	held_block.set_process(true)

	# Register in grid
	MatchManager.place_block(held_block, col, landing_row)

	# Move player on top of the placed block
	var player_y := landing_pos.y - MatchManager.BLOCK_SIZE  # One block height above
	global_position = Vector2(landing_pos.x, player_y)
	velocity = Vector2.ZERO  # Stop any movement

	# Clear held block reference
	held_block = null

	# Check for matches
	MatchManager.request_match_check()


func _spawn_debug_marker(pos: Vector2, color: Color) -> void:
	var marker := ColorRect.new()
	marker.size = Vector2(10, 10)
	marker.color = color
	marker.position = pos - Vector2(5, 5)  # Center the marker
	get_tree().current_scene.add_child(marker)
	# Auto-remove after 2 seconds
	get_tree().create_timer(2.0).timeout.connect(marker.queue_free)
