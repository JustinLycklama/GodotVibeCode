extends CharacterBody2D

@export var speed: float = 300.0
@export var gravity: float = 2000.0

# Spider movement system
var surface_normal: Vector2 = Vector2.UP  # Direction away from surface (player's "up")
var is_attached: bool = true              # Currently on a surface?
var target_rotation: float = 0.0          # For smooth rotation lerping
var input_direction: float = 0.0          # Current movement input (-1, 0, or 1)

# Raycast constants
const WALL_DETECT_DISTANCE := 30.0   # How far ahead to look for walls
const FLOOR_DETECT_DISTANCE := 35.0  # How far down to check for floor
const CORNER_DETECT_DISTANCE := 45.0 # Diagonal check for corners
const STICK_FORCE := 100.0           # Force pulling toward surface

# Dual raycast constants
const RAY_OFFSET := 15.0             # Distance from center to ray origin
const RAY_LENGTH := 50.0             # How far to cast surface detection rays
const RAY_INWARD_TILT := 0.15        # Slight tilt toward center (radians, ~8.5°)
const PLAYER_HALF_HEIGHT := 23.0     # Half player height for positioning
const MAX_ROTATION_SPEED := 8.0      # Radians/sec (~460°/sec) for constant-speed rotation

# Block pickup system
var held_block: StaticBody2D = null
const HELD_BLOCK_OFFSET := Vector2(0, -50)  # Block appears above player's head (in local space)

# Debug visualization
const DEBUG_DRAW_RAYS := true
var _debug_rays: Array = []  # Array of {from, to, color, hit}


func _ready() -> void:
	add_to_group("player")


func _draw() -> void:
	if not DEBUG_DRAW_RAYS:
		return
	for ray in _debug_rays:
		# Convert global positions to local for drawing
		var from_local := to_local(ray.from)
		var to_local_pos := to_local(ray.to)
		var color: Color = ray.color
		if ray.hit:
			color = Color.GREEN  # Hit = green
		draw_line(from_local, to_local_pos, color, 2.0)


func _process(delta: float) -> void:
	# Constant-speed rotation (not lerp which slows at the end)
	var angle_diff := wrapf(target_rotation - rotation, -PI, PI)
	var max_step := MAX_ROTATION_SPEED * delta
	rotation += clampf(angle_diff, -max_step, max_step)

	# Update held block position to follow player (using rotated offset)
	if held_block and is_instance_valid(held_block):
		var rotated_offset := HELD_BLOCK_OFFSET.rotated(rotation)
		held_block.global_position = global_position + rotated_offset


func _physics_process(delta: float) -> void:
	# Clear debug rays for this frame
	if DEBUG_DRAW_RAYS:
		_debug_rays.clear()

	# Get input
	input_direction = 0.0
	if Input.is_action_pressed("ui_right"):
		input_direction += 1
	if Input.is_action_pressed("ui_left"):
		input_direction -= 1

	if is_attached:
		_attached_movement(delta)
	else:
		_falling_movement(delta)

	move_and_slide()

	# Trigger redraw for debug visualization
	if DEBUG_DRAW_RAYS:
		queue_redraw()

	# Push any overlapping falling blocks up out of the way
	_push_overlapping_blocks_up()


func _attached_movement(delta: float) -> void:
	# Move along surface (perpendicular to surface_normal)
	# Positive input = clockwise around surface (right on floor, up on right wall, etc.)
	var move_dir := surface_normal.rotated(PI / 2) * input_direction
	velocity = move_dir * speed

	# Check for surface transitions
	_check_surface_transitions()

	# Apply small force toward surface to maintain contact
	velocity += -surface_normal * STICK_FORCE

	# Use dual-ray surface info for continuous surface tracking
	var info := _get_surface_info()
	if info.is_empty():
		is_attached = false
	else:
		# Continuously update normal from averaged rays
		surface_normal = info.normal
		target_rotation = surface_normal.angle() + PI / 2


func _falling_movement(delta: float) -> void:
	# Apply world gravity (always down)
	velocity.y += gravity * delta

	# Allow some air control
	var air_move := input_direction * speed * 0.3
	velocity.x = move_toward(velocity.x, air_move, speed * delta)

	# Check for surface to attach to
	var down_ray := _cast_ray(Vector2.DOWN, FLOOR_DETECT_DISTANCE, Color.WHITE)
	if not down_ray.is_empty():
		_attach_to_surface(down_ray.normal)


func _check_surface_transitions() -> void:
	if input_direction == 0:
		return

	# Movement direction along current surface
	var move_dir := surface_normal.rotated(PI / 2) * input_direction

	# 1. Check if we're about to hit a wall (climb up onto it)
	var forward_ray := _cast_ray(move_dir, WALL_DETECT_DISTANCE, Color.YELLOW)
	if not forward_ray.is_empty():
		_attach_to_surface(forward_ray.normal)
		return

	# 2. Check if floor disappeared (wrap around outer corner)
	var down_ray := _cast_ray(-surface_normal, FLOOR_DETECT_DISTANCE, Color.BLUE)
	if down_ray.is_empty():
		# Try to find corner to wrap around
		var corner_dir := (move_dir - surface_normal).normalized()
		var corner_ray := _cast_ray(corner_dir, CORNER_DETECT_DISTANCE, Color.MAGENTA)
		if not corner_ray.is_empty():
			_attach_to_surface(corner_ray.normal)
		else:
			is_attached = false  # Start falling


func _attach_to_surface(new_normal: Vector2) -> void:
	surface_normal = new_normal.normalized()
	is_attached = true
	# Convert normal to rotation: normal points "up" from player's perspective
	# When normal is UP (0, -1), rotation should be 0
	# When normal is RIGHT (1, 0), rotation should be -PI/2 (or 3PI/2)
	target_rotation = surface_normal.angle() + PI / 2
	_snap_to_surface()


func _cast_ray(direction: Vector2, distance: float, debug_color: Color = Color.RED) -> Dictionary:
	var from := global_position
	var to := global_position + direction.normalized() * distance
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [self]
	# Exclude held block from raycasts
	if held_block and is_instance_valid(held_block):
		query.exclude.append(held_block.get_rid())
	var result := space_state.intersect_ray(query)

	# Record for debug drawing
	if DEBUG_DRAW_RAYS:
		_debug_rays.append({"from": from, "to": to, "color": debug_color, "hit": not result.is_empty()})

	return result


func _cast_ray_from(origin: Vector2, direction: Vector2, distance: float, debug_color: Color = Color.CYAN) -> Dictionary:
	var to := origin + direction * distance
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(origin, to)
	query.exclude = [self]
	if held_block and is_instance_valid(held_block):
		query.exclude.append(held_block.get_rid())
	var result := space_state.intersect_ray(query)

	# Record for debug drawing
	if DEBUG_DRAW_RAYS:
		_debug_rays.append({"from": origin, "to": to, "color": debug_color, "hit": not result.is_empty()})

	return result


func _get_surface_info() -> Dictionary:
	var perpendicular := surface_normal.rotated(PI / 2)
	var down := -surface_normal

	# Left ray: starts left, tilts slightly right (toward center)
	var left_origin := global_position + perpendicular * -RAY_OFFSET
	var left_dir := down.rotated(-RAY_INWARD_TILT)  # Tilt toward center

	# Right ray: starts right, tilts slightly left (toward center)
	var right_origin := global_position + perpendicular * RAY_OFFSET
	var right_dir := down.rotated(RAY_INWARD_TILT)  # Tilt toward center

	var hit_left := _cast_ray_from(left_origin, left_dir, RAY_LENGTH, Color.ORANGE)
	var hit_right := _cast_ray_from(right_origin, right_dir, RAY_LENGTH, Color.CYAN)

	if hit_left.is_empty() and hit_right.is_empty():
		return {}

	# Average results
	var avg_normal: Vector2
	var avg_position: Vector2
	if not hit_left.is_empty() and not hit_right.is_empty():
		avg_normal = (hit_left.normal + hit_right.normal).normalized()
		avg_position = (hit_left.position + hit_right.position) / 2
	elif not hit_left.is_empty():
		avg_normal = hit_left.normal
		avg_position = hit_left.position
	else:
		avg_normal = hit_right.normal
		avg_position = hit_right.position

	return {"normal": avg_normal, "position": avg_position}


func _snap_to_surface() -> void:
	var info := _get_surface_info()
	if not info.is_empty():
		global_position = info.position + surface_normal * PLAYER_HALF_HEIGHT


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

	# Reset to floor orientation after placing block
	surface_normal = Vector2.UP
	target_rotation = 0.0
	is_attached = true

	# Clear held block reference
	held_block = null

	# Check for matches
	MatchManager.request_match_check()
