extends Control

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options: Panel = $options
@onready var controls: Control = $controls  # Refers to your 'controls' node

func _ready():
	main_buttons.visible = true
	options.visible = false
	if controls:
		controls.visible = false
	
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	print("settings pressed")
	main_buttons.visible = false
	options.visible = true

func _on_back_options_pressed() -> void:
	_ready()

func _on_controls_pressed() -> void:
	main_buttons.visible = false
	if controls:
		controls.visible = true

# Signal function for the 'back' button under controls
func _on_back_controls_pressed() -> void:
	_ready()
