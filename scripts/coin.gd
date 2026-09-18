extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collected_sound: AudioStreamPlayer2D = $CollectedSound

var is_collected: bool = false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	# Prevent triggering multiple times if touched twice quickly
	if is_collected:
		return
		
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		is_collected = true
		
		# Hide the animated sprite immediately so it vanishes from screen
		animated_sprite_2d.visible = false
		
		# Play pickup audio
		collected_sound.play()
		
		# Wait for the audio clip to finish before destroying the node completely
		await collected_sound.finished
		queue_free()
