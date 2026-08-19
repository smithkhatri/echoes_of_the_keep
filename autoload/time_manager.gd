extends Node

# Time rewind settings
@export var rewind_duration: float = 5   # seconds to rewind
@export var record_interval: float = 0.1     # snapshot every 0.1 seconds

# Internal storage
var snapshots: Array[Dictionary] = []
var time_since_last_record: float = 0.0

func _physics_process(delta: float) -> void:
	# Record snapshots at fixed intervals
	time_since_last_record += delta
	if time_since_last_record >= record_interval:
		time_since_last_record = 0.0
		record_snapshot()

func record_snapshot() -> void:
	var snapshot := {
		"time": Time.get_ticks_msec(),   # milliseconds since game start
		"player": _get_player_state(),
		"enemies": _get_enemies_states()
	}
	snapshots.append(snapshot)

func _get_player_state() -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		return player.get_rewind_state()
	return {}

func _get_enemies_states() -> Array:
	var enemies := get_tree().get_nodes_in_group("enemy_rewind")
	var states := []
	for enemy in enemies:
		if is_instance_valid(enemy):
			states.append(enemy.get_rewind_state())
	return states

func rewind() -> void:
	if snapshots.is_empty():
		return

	var current_time = Time.get_ticks_msec()
	var target_time = current_time - int(rewind_duration * 1000)

	# Find the snapshot closest to target_time (older than or equal)
	var best_index = -1
	var best_time_diff = 1e9
	for i in range(snapshots.size()):
		var snap_time = snapshots[i]["time"]
		var diff = abs(snap_time - target_time)
		if diff < best_time_diff:
			best_time_diff = diff
			best_index = i

	if best_index == -1:
		return

	var target_snapshot = snapshots[best_index]

	# Restore player
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and target_snapshot.has("player"):
		player.set_rewind_state(target_snapshot["player"])

	# Restore enemies
	var enemies := get_tree().get_nodes_in_group("enemy_rewind")
	var enemy_states: Array = target_snapshot["enemies"]
	# Match enemies by index (simplistic; works if enemy count doesn't change)
	for i in range(min(enemies.size(), enemy_states.size())):
		if is_instance_valid(enemies[i]):
			enemies[i].set_rewind_state(enemy_states[i])

	# Optional: Clear snapshots after the rewind point to avoid weird future rewinds
	snapshots = snapshots.slice(0, best_index + 1)
