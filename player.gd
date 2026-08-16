extends CharacterBody2D

# --- Movement Variables ---
@export var speed: float = 50
@export var dodge_speed: float = 280.0
@export var dodge_duration: float = 0.2
@export var dodge_cooldown: float = 0.6

# --- State Flags ---
var is_dodging: bool = false
var can_dodge: bool = true
var dodge_direction: Vector2 = Vector2.ZERO

# 1. Update the node reference to target your AnimatedSprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	if is_dodging:
		# During dodge, maintain the burst velocity
		velocity = dodge_direction * dodge_speed
		move_and_slide()
		return

	# Read 8-directional input vector
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Apply regular movement
	velocity = input_vector * speed

	# 2. Evaluate state for Animation and Sprite Flipping
	if input_vector != Vector2.ZERO:
		# If the vector is not 0, the player is actively pressing a movement key
		animated_sprite.play("run")
		
		# Flip the sprite horizontally based on move direction
		if input_vector.x != 0:
			animated_sprite.flip_h = input_vector.x < 0
	else:
		# If the vector is exactly 0, the player has let go of the keys
		animated_sprite.play("idle")

	# Trigger dodge roll on Spacebar 
	if Input.is_action_just_pressed("dodge") and can_dodge and input_vector != Vector2.ZERO:
		start_dodge(input_vector)

	move_and_slide()

func start_dodge(direction: Vector2) -> void:
	is_dodging = true
	can_dodge = false
	dodge_direction = direction

	# Visual indicator (ghostly blue dodge tint)
	modulate = Color(0.6, 0.8, 1.0, 0.6)

	# 0.2-second dodge burst duration
	await get_tree().create_timer(dodge_duration).timeout
	is_dodging = false
	modulate = Color(1.0, 1.0, 1.0, 1.0) # Reset tint

	# Dodge cooldown timer
	await get_tree().create_timer(dodge_cooldown).timeout
	can_dodge = true
