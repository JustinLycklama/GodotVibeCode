extends CharacterBody2D

@export var speed: float = 300.0
@export var gravity: float = 800.0

func _physics_process(delta: float) -> void:
	# Apply gravity
	velocity.y += gravity * delta

	# Horizontal movement
	var direction := 0.0
	if Input.is_action_pressed("ui_right"):
		direction += 1
	if Input.is_action_pressed("ui_left"):
		direction -= 1

	velocity.x = direction * speed

	move_and_slide()
