extends Node2D

@export var spawn_interval: float = 2.0
@export var game_block_scene: PackedScene
@export var columns: int = 5
@export var column_spacing: float = 60.0

var symbols: Array[String] = ["#", "$", "%", "!"]

func _ready() -> void:
	$Timer.wait_time = spawn_interval
	$Timer.start()
	# Spawn one immediately
	spawn_block()

func spawn_block() -> void:
	if game_block_scene:
		var block = game_block_scene.instantiate()

		# Pick a random column (0 to columns-1)
		var column := randi() % columns

		# Calculate x position centered around spawner position
		var grid_width := (columns - 1) * column_spacing
		var start_x := position.x - grid_width / 2.0
		var spawn_x := start_x + column * column_spacing

		block.position = Vector2(spawn_x, position.y)
		block.symbol = symbols.pick_random()
		get_parent().add_child(block)

func _on_timer_timeout() -> void:
	spawn_block()
