extends Camera2D

@export var random_strength: float = 8.0
@export var shake_decay: float = 15.0

var shake_strength: float = 0.0

func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		offset = get_random_offset()
	else:
		offset = Vector2.ZERO

func apply_shake(strength: float = -1.0) -> void:
	if strength <= 0:
		shake_strength = random_strength
	else:
		shake_strength = strength

func get_random_offset() -> Vector2:
	return Vector2(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength)
	)
