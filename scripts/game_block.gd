extends RigidBody2D

@export var symbol: String = "#"
@export var block_color: Color = Color(0.2, 0.7, 0.3, 1)

# Settlement detection
const SETTLE_VELOCITY_THRESHOLD := 5.0  # pixels/second
const SETTLE_TIME_REQUIRED := 0.3  # seconds

var _settled := false
var _settle_timer := 0.0
var _matched := false


func _ready() -> void:
	$Label.text = symbol
	$ColorRect.color = block_color
	if MatchManager:
		MatchManager.register_block(self)


func _exit_tree() -> void:
	if MatchManager:
		MatchManager.unregister_block(self)


func _physics_process(delta: float) -> void:
	if _settled:
		return

	var speed := linear_velocity.length()

	if speed < SETTLE_VELOCITY_THRESHOLD:
		_settle_timer += delta
		if _settle_timer >= SETTLE_TIME_REQUIRED:
			_settled = true
			if MatchManager:
				MatchManager.request_match_check()
	else:
		_settle_timer = 0.0


func is_settled() -> bool:
	return _settled


func set_matched() -> void:
	if _matched:
		return
	_matched = true
	block_color = Color.YELLOW
	$ColorRect.color = block_color
