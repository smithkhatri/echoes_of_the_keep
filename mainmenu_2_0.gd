extends Control

@export_file("*.tscn") var start_level_path: String = "res://map.tscn"

@onready var splash_logo: Control = $SplashLogo
@onready var made_by_label: Label = $MadeByLabel
@onready var buttons_container: VBoxContainer = $MenuUI/ButtonsContainer

@onready var start_button: Button = $MenuUI/ButtonsContainer/StartButton
@onready var quit_button: Button = $MenuUI/ButtonsContainer/QuitButton

var is_intro_finished: bool = false

func _ready() -> void:
	# 1. Start everything completely invisible (alpha = 0.0)
	buttons_container.modulate.a = 0.0
	buttons_container.visible = false
	
	splash_logo.modulate.a = 0.0
	splash_logo.visible = true
	
	made_by_label.modulate.a = 0.0
	made_by_label.visible = true
	
	# 2. Connect button events
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# 3. Start intro sequence
	run_intro_sequence()

func _input(event: InputEvent) -> void:
	if not is_intro_finished and (event is InputEventKey or event is InputEventMouseButton):
		if event.is_pressed():
			skip_intro()

func run_intro_sequence() -> void:
	# Step A: Fade IN the Logo first (over 1.0 second)
	var logo_tween = create_tween()
	logo_tween.tween_property(splash_logo, "modulate:a", 1.0, 1.0)
	await logo_tween.finished
	if is_intro_finished: return
	
	# Step B: Fade IN "Made by" text right after (over 0.8 seconds)
	var label_tween = create_tween()
	label_tween.tween_property(made_by_label, "modulate:a", 1.0, 0.8)
	await label_tween.finished
	if is_intro_finished: return
	
	# Step C: Hold both on screen briefly
	await get_tree().create_timer(1.2).timeout
	if is_intro_finished: return
	
	# Step D: Transition to Main Menu
	transition_to_main_menu()

func transition_to_main_menu() -> void:
	if is_intro_finished: return
	is_intro_finished = true
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Fade out logo and credits together
	tween.tween_property(splash_logo, "modulate:a", 0.0, 0.8)
	tween.tween_property(made_by_label, "modulate:a", 0.0, 0.8)
	
	# Fade in menu buttons
	buttons_container.visible = true
	tween.tween_property(buttons_container, "modulate:a", 1.0, 0.8).set_delay(0.3)
	
	await tween.finished
	splash_logo.visible = false
	made_by_label.visible = false

func skip_intro() -> void:
	is_intro_finished = true
	splash_logo.visible = false
	splash_logo.modulate.a = 0.0
	made_by_label.visible = false
	made_by_label.modulate.a = 0.0
	
	buttons_container.visible = true
	buttons_container.modulate.a = 1.0

func _on_start_pressed() -> void:
	if start_level_path != "":
		get_tree().change_scene_to_file(start_level_path)

func _on_quit_pressed() -> void:
	get_tree().quit()
