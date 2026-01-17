extends CharacterBody2D

@export var speed: float = 300.0
@export var gravity: float = 800.0
@export var jump_velocity: float = -400.0

# Block pickup system
var held_block: StaticBody2D = null
const HELD_BLOCK_OFFSET := Vector2(0, -50)  # Block appears above player's head


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	# Apply gravity
	velocity.y += gravity * delta

	# Jump when on floor
	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = jump_velocity

	# Horizontal movement
	var direction := 0.0
	if Input.is_action_pressed("ui_right"):
		direction += 1
	if Input.is_action_pressed("ui_left"):
		direction -= 1

	velocity.x = direction * speed

	move_and_slide()

	# Push any overlapping falling blocks up out of the way
	_push_overlapping_blocks_up()

	# Update held block position to follow player
	if held_block and is_instance_valid(held_block):
		held_block.global_position = global_position + HELD_BLOCK_OFFSET


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
