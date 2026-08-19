extends Control

# Drag your gameplay level file (.tscn) into this inspector slot later
@export_file("*.tscn") var start_level_path: String = ""

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	# Connect the button click signals to code
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	if start_level_path != "":
		get_tree().change_scene_to_file("res://World.tscn")
	else:
		print("No level scene assigned in start_level_path!")

func _on_quit_pressed() -> void:
	get_tree().quit()
