extends Label

func setup(amount: int, custom_text: String = "") -> void:
	if custom_text != "":
		text = custom_text
	else:
		text = "-" + str(amount)
	

	position.x += randf_range(-10.0, 10.0)
	
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(self, "position:y", position.y - 30.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	tween.finished.connect(queue_free)
