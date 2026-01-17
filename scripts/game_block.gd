extends StaticBody2D

@export var symbol: String = "#"
@export var block_color: Color = Color(0.2, 0.7, 0.3, 1)

# Grid position
var grid_col: int = 0
var grid_row: int = -1  # -1 means not yet placed

# Fall settings
const FALL_SPEED := 200.0  # pixels per second
const BLOCK_SIZE := 50.0

var _settled := false


func _ready() -> void:
	$Label.text = symbol
	$ColorRect.color = block_color
	if MatchManager:
		MatchManager.register_block(self)


func _exit_tree() -> void:
	if MatchManager:
		MatchManager.unregister_block(self)


func _process(delta: float) -> void:
	if _settled:
		return

	# Get the target landing row for this column
	var landing_row := MatchManager.get_landing_row(grid_col)
	var landing_pos := MatchManager.grid_to_world(grid_col, landing_row)

	# Check if we've reached or passed the landing position
	if position.y >= landing_pos.y:
		# Snap to grid position
		position = landing_pos
		grid_row = landing_row
		_settle()
		return

	# Calculate next position
	var next_y := position.y + FALL_SPEED * delta

	# Check for collision with player or held block before moving
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Check collision with player (player is 46x46, half = 23)
		if _would_collide_with(player.global_position, next_y, 23.0):
			# Hover above player - don't move down
			return

		# Check collision with held block (if any and not self) - held block is 50x50
		if player.held_block and player.held_block != self:
			if _would_collide_with(player.held_block.global_position, next_y, 25.0):
				# Hover above held block - don't move down
				return

	# Check collision with other falling (unsettled) blocks
	for other_block in MatchManager.blocks:
		if other_block == self or not is_instance_valid(other_block):
			continue
		# Only check against unsettled blocks that are below us (hovering)
		if not other_block._settled and other_block.global_position.y > position.y:
			if _would_collide_with(other_block.global_position, next_y, 25.0):
				# Hover above the other falling block
				return

	# No collision, continue falling
	position.y = next_y


func _would_collide_with(other_pos: Vector2, next_y: float, other_half_size: float = 25.0) -> bool:
	# Simple AABB collision check
	var my_half := BLOCK_SIZE / 2.0

	var my_left := position.x - my_half
	var my_right := position.x + my_half
	var my_top := next_y - my_half
	var my_bottom := next_y + my_half

	var other_left := other_pos.x - other_half_size
	var other_right := other_pos.x + other_half_size
	var other_top := other_pos.y - other_half_size
	var other_bottom := other_pos.y + other_half_size

	# Check for overlap
	var x_overlap := my_left < other_right and my_right > other_left
	var y_overlap := my_top < other_bottom and my_bottom > other_top

	return x_overlap and y_overlap


func _settle() -> void:
	_settled = true
	# Register in the grid
	MatchManager.place_block(self, grid_col, grid_row)
	# Request match check
	MatchManager.request_match_check()


func is_settled() -> bool:
	return _settled


func start_falling() -> void:
	# Called when block needs to fall again (e.g., block below was removed)
	_settled = false
	grid_row = -1
