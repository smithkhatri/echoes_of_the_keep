extends CharacterBody2D

# --- Movement Variables ---
@export var speed: float = 50
@export var dodge_speed: float = 150
@export var dodge_duration: float = 0.2
@export var dodge_cooldown: float = 0.6

# --- Combat Variables ---
@export var base_damage: float = 10.0
var attack_state: String = "idle" # States: "idle", "swinging", "combo_window"
var combo_locked: bool = false

@onready var sword_hitbox: Area2D = $SwordHitbox

# --- State Flags ---
var is_dodging: bool = false
var can_dodge: bool = true
var dodge_direction: Vector2 = Vector2.ZERO

# 1. Update the node reference to target your AnimatedSprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


signal health_changed(current_health, max_health)

var max_health: float = 100.0
var current_health: float




func _ready() -> void:
	add_to_group("player")
	current_health = max_health

func _physics_process(_delta: float) -> void:
	if (Input.is_action_just_pressed("rewind")):
		TimeManager.rewind()

	# --- Combat Input Logic ---
	if Input.is_action_just_pressed("attack"):
		if attack_state == "idle":
			perform_swing_1()
		elif attack_state == "combo_window":
			perform_swing_2()
		elif attack_state == 'swinging':
			combo_locked = true

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
	if attack_state == "idle":
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


func perform_swing_1() -> void:
	attack_state = "swinging"
	combo_locked = false
	animated_sprite.play("swing_1")
	
	check_hitbox(base_damage)


func perform_swing_2() -> void:
	attack_state = "swinging"
	combo_locked = false
	animated_sprite.play("swing_2")
	
	# Check for enemies and apply 1.2x multiplier
	check_hitbox(base_damage * 1.5)


func check_hitbox(damage_amount: float) -> void:
	# Get an array of all Area2D nodes currently touching our sword box
	var overlapping_areas = sword_hitbox.get_overlapping_areas()
	
	for area in overlapping_areas:
		# Check if the object we hit is actually an enemy
		if area.is_in_group("enemy"):
			area.take_damage(damage_amount)


func _on_animated_sprite_2d_animation_finished() -> void:
	# If the first swing just finished, open the 0.5-second window
	if animated_sprite.animation == "swing_1":
		if combo_locked:
			attack_state = "idle"
			animated_sprite.play("idle")
		else:
			attack_state = "combo_window"
			animated_sprite.play("idle_after_swing_1") # Return to a resting pose while waiting
		
		# Start the strict 0.5 second countdown
			await get_tree().create_timer(0.2).timeout
		
			if attack_state == "combo_window":
				attack_state = "idle"
		
	elif animated_sprite.animation == "swing_2":
		attack_state = "idle"
		animated_sprite.play("idle")


func take_damage(amount: float) -> void:
	current_health -= amount
	print("Player took damage! HP left: ", current_health)
	emit_signal("health_changed", current_health, max_health)
	if current_health <= 0:
		die()

func die() -> void:
	print("Player died!")
	# For now, just reload the scene or reset
	get_tree().reload_current_scene()


func get_rewind_state() -> Dictionary:
	return {
		"position": global_position,
		"health": current_health
	}

func set_rewind_state(state: Dictionary) -> void:
	# Restore position and health
	global_position = state["position"]
	current_health = state["health"]
	
	# Force idle state
	attack_state = "idle"
	combo_locked = false
	is_dodging = false
	can_dodge = true
	velocity = Vector2.ZERO
	animated_sprite.play("idle")
	# Reset any active modifiers (e.g., dodge tint)
	modulate = Color(1, 1, 1, 1)
