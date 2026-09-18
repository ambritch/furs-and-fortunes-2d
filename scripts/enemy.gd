extends CharacterBody2D
class_name FrogEnemy

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# Ensure this path matches the exact location of your floating number scene in your FileSystem
const FLOATING_NUMBER_SCENE = preload("res://scenes/floating_number.tscn")

@export var max_health: int = 100
var health: int = 100
var health_min: int = 0

@export var damage_to_deal: int = 1

var dead: bool = false
var taking_damage: bool = false

func _ready() -> void:
	health = max_health

func _physics_process(_delta: float) -> void:
	if not dead:
		check_physics_collisions()

# Deals contact damage to player on touch instead of instant death
func hit_player(target: Node2D) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage_to_deal)
	elif target.has_method("die"):
		target.die()

# Checks physics collisions every frame to hit player when touched
func check_physics_collisions() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and (collider.is_in_group("player") or collider.has_method("take_damage")):
			if "is_invincible" in collider and collider.is_invincible:
				continue
			hit_player(collider)

# Function called when hit by player attacks or stomps
func take_damage(amount: int = 40) -> void:
	if dead or taking_damage:
		return
		
	health -= amount
	taking_damage = true
	
	# Spawn floating minus HP label above enemy
	spawn_floating_number(amount)
	
	if animated_sprite_2d and animated_sprite_2d.sprite_frames.has_animation("hurt"):
		animated_sprite_2d.play("hurt")
	
	if health <= health_min:
		die()
	else:
		await get_tree().create_timer(0.4).timeout
		taking_damage = false

# Spawns floating HP label in world space
func spawn_floating_number(amount: int) -> void:
	if FLOATING_NUMBER_SCENE:
		var number_instance = FLOATING_NUMBER_SCENE.instantiate()
		
		# Position slightly above the enemy
		number_instance.global_position = global_position + Vector2(-10, -30)
		
		# Attach to main scene tree so it moves independently of enemy velocity
		get_tree().current_scene.add_child(number_instance)
		
		# Call setup on the floating number label
		if number_instance.has_method("setup"):
			number_instance.setup(amount)

# Handles squishy death effect & scene removal
func die() -> void:
	dead = true
	velocity = Vector2.ZERO
	
	if animated_sprite_2d and animated_sprite_2d.sprite_frames.has_animation("dying"):
		animated_sprite_2d.play("dying")
		await animated_sprite_2d.animation_finished
	
	queue_free()

# Handles stomp detection if you connected a StompArea Area2D
func _on_stomp_area_body_entered(body: Node2D) -> void:
	if (body.is_in_group("player") or body.has_method("take_damage")) and not dead:
		if body.has_method("bounce"):
			body.bounce()
		
		take_damage(max_health)

# Optional: Connect Area2D detection areas if using trigger zones for contact
func _on_detection_area_entered(body: Node2D) -> void:
	if (body.is_in_group("player") or body.has_method("take_damage")) and not dead:
		if "is_invincible" in body and body.is_invincible:
			return
		hit_player(body)
