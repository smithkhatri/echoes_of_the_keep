extends Area2D

@export var max_hp: float = 100.0
var current_hp: float

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# Initialize health when the enemy spawns
	current_hp = max_hp

func take_damage(amount: float) -> void:
	current_hp -= amount
	print("Enemy took damage! HP left: ", current_hp)
	
	if current_hp <= 0:
		die()

func die() -> void:
	# Turn the sprite red
	sprite.modulate = Color(1.0, 0.0, 0.0, 1.0)
	
	# Wait for 0.2 seconds so the player registers the visual feedback
	await get_tree().create_timer(0.5).timeout
	
	# queue_free() completely deletes the node from the game's memory
	queue_free()
