extends Area2D

func take_damage(amount: float) -> void:
	get_parent().take_damage(amount)
