extends CanvasLayer

@onready var heart_container: BoxContainer = $HeartsContainer

var last_hearts: int = -1

func update_hearts(current_hearts: int) -> void:
	if not heart_container:
		return

	var hearts = heart_container.get_children()

	# Game Start / First setup: initialize visibility
	if last_hearts == -1:
		last_hearts = current_hearts
		for i in range(hearts.size()):
			hearts[i].visible = (i < current_hearts)
			hearts[i].modulate.a = 1.0
		return

	# Handle life loss: trigger flicker on the exact lost heart
	if current_hearts < last_hearts:
		var lost_index = current_hearts # e.g. 9 -> 8 health means index 8 is removed
		if lost_index >= 0 and lost_index < hearts.size():
			flicker_and_remove(hearts[lost_index])

	# Update non-flickering hearts
	for i in range(hearts.size()):
		if i < current_hearts:
			hearts[i].visible = true
			hearts[i].modulate.a = 1.0
		elif i > current_hearts:
			hearts[i].visible = false

	last_hearts = current_hearts

# Flickers transparency 3 times over 0.36 seconds before hiding
func flicker_and_remove(heart: Node) -> void:
	heart.visible = true
	var tween = create_tween()
	
	for f in range(3):
		tween.tween_property(heart, "modulate:a", 0.1, 0.06)
		tween.tween_property(heart, "modulate:a", 1.0, 0.06)

	tween.tween_callback(func():
		heart.visible = false
		heart.modulate.a = 1.0
	)
	
