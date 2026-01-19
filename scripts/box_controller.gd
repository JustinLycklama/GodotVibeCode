extends CharacterBody2D

@export var speed: float = 300.0
@export var surface_follow_speed: float = 25.0  # Smoothing for position
@export var rotation_speed: float = 25.0  # Smoothing for rotation
@export var snap_angle_threshold: float = 0.3  # Snap instantly if angle difference > this (radians, ~17 degrees)
@export var debug_draw: bool = true  # Toggle debug visualization

# Raycast references
@onready var left_ray: RayCast2D = $LeftRay
@onready var right_ray: RayCast2D = $RightRay
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Player size (computed from collision shape)
var player_half_size: Vector2
var hover_height: float  # Distance from surface to player center

# Block pickup system
var held_block: StaticBody2D = null
var held_block_offset: Vector2  # Computed based on player size


func _ready() -> void:
	add_to_group("player")

	# Get player size from collision shape
	var shape = collision_shape.shape as RectangleShape2D
	player_half_size = shape.size / 2.0
	hover_height = player_half_size.y
	held_block_offset = Vector2(0, -(player_half_size.y + 30))  # Block above player's head


func _draw() -> void:
	if not debug_draw:
		return

	# Draw left ray
	var left_start = left_ray.position
	var left_end = left_ray.position + left_ray.target_position
	var left_color = Color.GREEN if left_ray.is_colliding() else Color.RED
	draw_line(left_start, left_end, left_color, 2.0)

	# Draw hit point for left ray
	if left_ray.is_colliding():
		var hit_local = to_local(left_ray.get_collision_point())
		draw_circle(hit_local, 5, Color.YELLOW)
		# Draw normal
		var normal = left_ray.get_collision_normal() * 20
		draw_line(hit_local, hit_local + normal.rotated(-rotation), Color.CYAN, 2.0)

	# Draw right ray
	var right_start = right_ray.position
	var right_end = right_ray.position + right_ray.target_position
	var right_color = Color.GREEN if right_ray.is_colliding() else Color.RED
	draw_line(right_start, right_end, right_color, 2.0)

	# Draw hit point for right ray
	if right_ray.is_colliding():
		var hit_local = to_local(right_ray.get_collision_point())
		draw_circle(hit_local, 5, Color.YELLOW)
		# Draw normal
		var normal = right_ray.get_collision_normal() * 20
		draw_line(hit_local, hit_local + normal.rotated(-rotation), Color.CYAN, 2.0)


func _process(_delta: float) -> void:
	if debug_draw:
		queue_redraw()


func _physics_process(delta: float) -> void:
	# Get horizontal input direction
	var direction := 0.0
	if Input.is_action_pressed("ui_right"):
		direction += 1
	if Input.is_action_pressed("ui_left"):
		direction -= 1

	# Check raycast collisions
	var left_hit := left_ray.is_colliding()
	var right_hit := right_ray.is_colliding()

	if left_hit and right_hit:
		# Both rays hit - follow surface (handles corners naturally via averaged normal)
		var left_normal = left_ray.get_collision_normal()
		var right_normal = right_ray.get_collision_normal()

		# Check if normals differ significantly (corner transition)
		var normal_dot = left_normal.dot(right_normal)
		var is_corner = normal_dot < 0.7  # ~45 degrees difference

		# For corners, weight toward the direction of movement
		var avg_normal: Vector2
		var avg_point: Vector2
		if is_corner and direction != 0:
			# Weight toward the leading ray (the one in direction of movement)
			var leading_ray = right_ray if direction > 0 else left_ray
			var trailing_ray = left_ray if direction > 0 else right_ray
			var leading_normal = leading_ray.get_collision_normal()
			var trailing_normal = trailing_ray.get_collision_normal()

			# Blend 70% toward leading surface for smoother corner transition
			avg_normal = (trailing_normal * 0.3 + leading_normal * 0.7).normalized()
			avg_point = trailing_ray.get_collision_point().lerp(leading_ray.get_collision_point(), 0.7)
		else:
			avg_point = (left_ray.get_collision_point() + right_ray.get_collision_point()) / 2
			avg_normal = (left_normal + right_normal).normalized()

		# Position player above the surface
		var target_pos = avg_point + avg_normal * hover_height

		# Use faster interpolation for corners, or snap if very different
		var pos_lerp_speed = surface_follow_speed * 2.0 if is_corner else surface_follow_speed
		var pos_distance = global_position.distance_to(target_pos)
		if is_corner and pos_distance > 10.0:
			# Snap position for large differences during corners
			global_position = target_pos
		else:
			global_position = global_position.lerp(target_pos, pos_lerp_speed * delta)

		# Rotate to match surface normal - snap for large angles
		var target_rotation = avg_normal.angle() + PI / 2
		var angle_diff = abs(angle_difference(rotation, target_rotation))
		if angle_diff > snap_angle_threshold:
			# Snap instantly for large angle changes (corners)
			rotation = target_rotation
		else:
			rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)

		# Apply movement along the surface tangent
		var tangent = Vector2(-avg_normal.y, avg_normal.x)
		velocity = tangent * direction * speed

	elif left_hit != right_hit:
		# One ray hit - determine if edge (block) or corner approach (allow)
		var hit_ray = left_ray if left_hit else right_ray
		var hit_normal = hit_ray.get_collision_normal()

		# Get player's current "up" direction
		var player_up = Vector2.UP.rotated(rotation)

		# Check if the hit surface is significantly different from current orientation
		# This indicates a corner transition rather than an edge
		var surface_alignment = hit_normal.dot(player_up)
		var is_corner_approach = surface_alignment < 0.7  # Surface is angled away from player up

		# Determine if this is the leading ray (in direction of movement) hitting
		var is_leading_ray_hit = (direction > 0 and right_hit) or (direction < 0 and left_hit)

		# Block movement only if leading ray misses (walking off edge)
		# Allow movement if trailing ray misses (transitioning onto new surface)
		if not is_leading_ray_hit and direction != 0:
			direction = 0  # Block - would walk off edge

		# Follow the hit surface - snap for corners
		var target_pos = hit_ray.get_collision_point() + hit_normal * hover_height
		var pos_distance = global_position.distance_to(target_pos)
		if is_corner_approach and pos_distance > 10.0:
			global_position = target_pos
		else:
			var lerp_speed = surface_follow_speed * 2.0 if is_corner_approach else surface_follow_speed
			global_position = global_position.lerp(target_pos, lerp_speed * delta)

		# Rotate toward the hit surface - snap for large angles
		var target_rotation = hit_normal.angle() + PI / 2
		var angle_diff = abs(angle_difference(rotation, target_rotation))
		if angle_diff > snap_angle_threshold:
			rotation = target_rotation
		else:
			rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)

		# Move along the surface tangent
		var tangent = Vector2(-hit_normal.y, hit_normal.x)
		velocity = tangent * direction * speed

	else:
		# No ground detected - stay in place, don't allow movement
		velocity = Vector2.ZERO

	move_and_slide()

	# Push any overlapping falling blocks up out of the way
	_push_overlapping_blocks_up()

	# Update held block position to follow player (accounting for rotation)
	if held_block and is_instance_valid(held_block):
		var rotated_offset = held_block_offset.rotated(rotation)
		held_block.global_position = global_position + rotated_offset


func _push_overlapping_blocks_up() -> void:
	var block_half := MatchManager.BLOCK_SIZE / 2.0

	# Check all registered blocks for overlap
	for block in MatchManager.blocks:
		if not is_instance_valid(block):
			continue
		# Skip settled blocks (they have physics collision) and held block
		if block._settled or block == held_block:
			continue

		# Check for overlap using AABB
		var player_left: float = global_position.x - player_half_size.x
		var player_right: float = global_position.x + player_half_size.x
		var player_top: float = global_position.y - player_half_size.y
		var player_bottom: float = global_position.y + player_half_size.y

		var block_left: float = block.global_position.x - block_half
		var block_right: float = block.global_position.x + block_half
		var block_top: float = block.global_position.y - block_half
		var block_bottom: float = block.global_position.y + block_half

		var x_overlap: bool = player_left < block_right and player_right > block_left
		var y_overlap: bool = player_top < block_bottom and player_bottom > block_top

		if x_overlap and y_overlap:
			# Push the block up so its bottom is at player's top
			block.global_position.y = player_top - block_half


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
	var feet_y := global_position.y + player_half_size.y
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
