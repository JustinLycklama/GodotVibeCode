extends CharacterBody2D

@export var speed: float = 300.0
@export var gravity: float = 800.0
@export var jump_velocity: float = -400.0

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
