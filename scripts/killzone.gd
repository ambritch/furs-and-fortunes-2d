extends Area2D

@onready var timer: Timer = $Timer

func _on_body_entered(body: Node2D) -> void:
	# Check if the object entering the killzone is the player/has die()
	if body.has_method("die"):
		print("You fell into the killzone!")
		body.die() # Triggers Mochi's death animation, glitch effect, and resurrection
		timer.start()

func _on_timer_timeout() -> void:
	# Optional: You can keep this empty or use it to trigger audio/events
	pass
