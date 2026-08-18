extends CharacterBody2D

enum EnemyState {IDLE, CHASE, ATTACK, HURT, DEAD}
var current_state: EnemyState = EnemyState.IDLE

# Movement
@export var move_speed: float = 30
@export var acceleration: float = 10.0   # how quickly it reaches max speed

# Combat
@export var max_health: float = 50
var health: float
@export var attack_damage: float = 5
@export var attack_cooldown: float = 1.0
var can_attack: bool = true

# Ranges
@export var detection_range: float = 200
@export var attack_range: float = 10

# References
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea

# Target (player)
var player: CharacterBody2D = null


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	health = max_health
	# Connect the detection area's signal so we know when player enters/leaves
	#detection_area.body_entered.connect(_on_detection_area_body_entered)
	#detection_area.body_exited.connect(_on_detection_area_body_exited)
	# Set the attack area to monitor but we'll use it manually
	attack_area.monitoring = false


func _physics_process(delta: float) -> void:
	# Check if dead first
	if current_state == EnemyState.DEAD:
		return

	# Check if health depleted
	if health <= 0:
		_change_state(EnemyState.DEAD)
		return

	# Update based on current state
	match current_state:
		EnemyState.IDLE:
			_state_idle(delta)
		EnemyState.CHASE:
			_state_chase(delta)
		EnemyState.ATTACK:
			_state_attack(delta)
		EnemyState.HURT:
			_state_hurt(delta)


func _state_idle(delta: float) -> void:
	sprite.play("idle")
	# Look for player
	if _can_see_player():
		_change_state(EnemyState.CHASE)
	else:
		# Play idle animation, do nothing
		sprite.play("idle")
		velocity = Vector2.ZERO
		move_and_slide()


func _state_chase(delta: float) -> void:
	sprite.play("run")
	if not _can_see_player():
		_change_state(EnemyState.IDLE)
		return

	# Move toward player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	# Flip sprite based on direction
	if direction.x != 0:
		sprite.flip_h = direction.x < 0

	# If within attack range, switch to attack
	if global_position.distance_to(player.global_position) <= attack_range:
		_change_state(EnemyState.ATTACK)


func _state_attack(delta: float) -> void:
	# Stop moving
	velocity = Vector2.ZERO
	move_and_slide()

	# Face the player
	if player:
		var direction = player.global_position - global_position
		if direction.x != 0:
			sprite.flip_h = direction.x < 0

	# If player moves out of attack range, go back to chase
	if not _can_see_player() or global_position.distance_to(player.global_position) > attack_range:
		_change_state(EnemyState.CHASE)
		return

	# Attack if cooldown ready
	if can_attack and player.current_health > 0: # and player not dead
		_perform_attack()


func _state_hurt(delta: float) -> void:
	# Stop movement
	velocity = Vector2.ZERO
	move_and_slide()
	# Wait for a short time then go back to chase/idle
	await get_tree().create_timer(0.3).timeout
	if health <= 0:
		_change_state(EnemyState.DEAD)
	elif _can_see_player():
		_change_state(EnemyState.CHASE)
	else:
		_change_state(EnemyState.IDLE)


func _state_dead(delta: float) -> void:
	# Play death animation (or just queue_free)
	sprite.modulate = Color(1,0,0)
	await get_tree().create_timer(0.2).timeout
	queue_free()


func _can_see_player() -> bool:
	#return player != null and is_instance_valid(player)
	if player == null or not is_instance_valid(player):
		return false
	return global_position.distance_to(player.global_position) <= detection_range

func _perform_attack() -> void:
	can_attack = false
	sprite.play("attack_1")
	# Here you would enable attack_area and check for player overlap
	# For now, just print and damage if player is within attack_area
	# We'll implement the actual hit detection later.
	print("Enemy attacks!")
	# Simple distance check to damage player
	if _can_see_player() and global_position.distance_to(player.global_position) <= attack_range:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
	# Cooldown

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func take_damage(amount: float) -> void:
	health -= amount
	print("Enemy took damage! HP left: ", health)
	if health <= 0:
		_change_state(EnemyState.DEAD)
	else:
		_change_state(EnemyState.HURT)


func _change_state(new_state: EnemyState) -> void:
	current_state = new_state
	# Optionally reset timers, animations, etc.


func _on_animated_sprite_2d_animation_finished() -> void:
	# If the first swing just finished, open the 0.5-second window
	if sprite.animation == "attack_1":
		sprite.play("idle")



#
#@export var max_hp: float = 100.0
#var current_hp: float
#
#
#
#func _ready() -> void:
	## Initialize health when the enemy spawns
	#current_hp = max_hp
#
#func take_damage(amount: float) -> void:
	#current_hp -= amount
	#print("Enemy took damage! HP left: ", current_hp)
	#
	#if current_hp <= 0:
		#die()
#
#func die() -> void:
	## Turn the sprite red
	#sprite.modulate = Color(1.0, 0.0, 0.0, 1.0)
	#
	## Wait for 0.2 seconds so the player registers the visual feedback
	#await get_tree().create_timer(0.5).timeout
	#
	## queue_free() completely deletes the node from the game's memory
	#queue_free()
