extends StaticBody2D

@export var symbol: String = "#"
@export var block_color: Color = Color(0.2, 0.7, 0.3, 1)

# Grid position
var grid_col: int = 0
var grid_row: int = -1  # -1 means not yet placed

# Fall settings
const FALL_SPEED := 200.0  # pixels per second

var _settled := false
var _matched := false


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
	else:
		# Continue falling
		position.y += FALL_SPEED * delta


func _settle() -> void:
	_settled = true
	# Register in the grid
	MatchManager.place_block(self, grid_col, grid_row)
	# Request match check
	MatchManager.request_match_check()


func is_settled() -> bool:
	return _settled


func set_matched() -> void:
	if _matched:
		return
	_matched = true
	block_color = Color.YELLOW
	$ColorRect.color = block_color
