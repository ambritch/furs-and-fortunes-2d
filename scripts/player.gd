extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound

# Reference to HUD node
@onready var hud: CanvasLayer = get_node_or_null("HUD") 

# Attack references
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

@export var max_hearts: int = 9
var hearts: int = 9

@export var invincibility_duration: float = 1.0
var is_invincible: bool = false
var is_taking_damage: bool = false

@export var sleep_time: float = 7.0
var idle_timer: float = 0.0

var default_scale: Vector2
var spawn_position: Vector2

const COYOTE_TIME: float = 0.15
var coyote: float = 0.0

const SPEED = 480.0
const ACCEL = 1800.0 # Acceleration for movement weight
const JUMP_VELOCITY = -850.0

const WALL_SLIDE_SPEED = 50.0
const WALL_CLIMB_SPEED = 240.0
var is_wall_climbing: bool = false

var is_dying: bool = false
var is_attacking: bool = false

func _ready() -> void:
	default_scale = animated_sprite_2d.scale
	spawn_position = global_position
	hearts = max_hearts
	update_hearts_ui()
	if attack_shape:
		attack_shape.disabled = true

func _physics_process(delta: float) -> void:
	if is_dying:
		return

	if Input.is_action_just_pressed("attack") and not is_attacking and not is_taking_damage:
		perform_attack()

	var direction := Input.get_axis("left", "right")

	# Wall Stick & Climb Logic
	if is_on_wall() and not is_on_floor() and velocity.y >= 0:
		if not is_wall_climbing:
			is_wall_climbing = true
			trigger_camera_shake(4.0) # Shake effect when first clinging to wall
	else:
		is_wall_climbing = false

	if is_wall_climbing:
		var climb_direction := Input.get_axis("ui_up", "ui_down")
		if climb_direction != 0:
			velocity.y = climb_direction * WALL_CLIMB_SPEED
			if not is_taking_damage and animated_sprite_2d.sprite_frames.has_animation("against_wall"):
				animated_sprite_2d.play("against_wall")
		else:
			velocity.y = WALL_SLIDE_SPEED
			if not is_taking_damage and animated_sprite_2d.sprite_frames.has_animation("against_wall"):
				animated_sprite_2d.play("against_wall")
				animated_sprite_2d.pause()
		if Input.is_action_just_pressed("jump"):
			var wall_normal = get_wall_normal()
			velocity.x = wall_normal.x * SPEED
			velocity.y = JUMP_VELOCITY
			jump_sound.play()
			_on_jump()
			is_wall_climbing = false
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta
			if not is_attacking and not is_taking_damage:
				if velocity.y < 0:
					if animated_sprite_2d.sprite_frames.has_animation("jumping"):
						animated_sprite_2d.play("jumping")
				else:
					if animated_sprite_2d.sprite_frames.has_animation("falling"):
						animated_sprite_2d.play("falling")

		if is_on_floor():
			coyote = COYOTE_TIME
		else:
			coyote -= delta

		if Input.is_action_just_pressed("jump") and coyote > 0.0:
			velocity.y = JUMP_VELOCITY
			jump_sound.play()
			_on_jump()
			coyote = 0.0

		# Movement Weight: Eases into speed and decelerates instead of instant snapping
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)

	if direction == 1.0:
		animated_sprite_2d.flip_h = false
		if attack_area:
			attack_area.scale.x = 1.0
	elif direction == -1.0:
		animated_sprite_2d.flip_h = true
		if attack_area:
			attack_area.scale.x = -1.0

	var was_on_floor = is_on_floor()
	move_and_slide()

	if not was_on_floor and is_on_floor():
		_on_land()

	if is_on_floor() and not is_attacking and not is_taking_damage:
		if velocity.x > 1 or velocity.x < -1:
			idle_timer = 0.0 
			if animated_sprite_2d.sprite_frames.has_animation("running"):
				animated_sprite_2d.play("running")
		else:
			idle_timer += delta
			if idle_timer >= sleep_time:
				if animated_sprite_2d.animation != "sleeping" and animated_sprite_2d.sprite_frames.has_animation("sleeping"):
					animated_sprite_2d.play("sleeping")
			else:
				if animated_sprite_2d.sprite_frames.has_animation("idle"):
					animated_sprite_2d.play("idle")
	elif not is_on_floor() and not is_wall_climbing:
		idle_timer = 0.0

# Guaranteed HUD Finder & Life Subtraction Call
func update_hearts_ui() -> void:
	var target_hud = hud
	if not target_hud and get_tree() and get_tree().current_scene:
		target_hud = get_tree().current_scene.get_node_or_null("HUD")
	if not target_hud:
		target_hud = get_tree().get_first_node_in_group("hud")

	if target_hud and target_hud.has_method("update_hearts"):
		target_hud.update_hearts(hearts)

# Handles taking damage and updating HUD
func take_damage(amount: int = 1) -> void:
	if is_dying or is_invincible:
		return
	hearts -= amount
	update_hearts_ui()
	hit_stop(0.08)
	trigger_camera_shake(8.0) # Shake on taking damage
	if hearts <= 0:
		die()
		return

	play_hit_sequence()

func play_hit_sequence() -> void:
	is_invincible = true
	is_taking_damage = true
	if animated_sprite_2d.sprite_frames.has_animation("hit"):
		animated_sprite_2d.play("hit")
	elif animated_sprite_2d.sprite_frames.has_animation("hurt"):
		animated_sprite_2d.play("hurt")

	var sprite_material = animated_sprite_2d.material as ShaderMaterial
	if sprite_material:
		var flash_tween = create_tween()
		for i in range(3):
			flash_tween.tween_property(sprite_material, "shader_parameter/flash_amount", 1.0, 0.05)
			flash_tween.tween_property(sprite_material, "shader_parameter/flash_amount", 0.0, 0.05)

	await get_tree().create_timer(0.4).timeout
	is_taking_damage = false

	await get_tree().create_timer(max(0.0, invincibility_duration - 0.4)).timeout
	is_invincible = false

func perform_attack() -> void:
	if not attack_shape:
		return

	is_attacking = true
	if animated_sprite_2d.sprite_frames.has_animation("attack"):
		animated_sprite_2d.play("attack")
	attack_shape.disabled = false
	await get_tree().create_timer(0.15).timeout
	if attack_area:
		for body in attack_area.get_overlapping_bodies():
			if body.has_method("take_damage") and body != self:
				body.take_damage(40)
	await get_tree().create_timer(0.15).timeout
	if attack_shape:
		attack_shape.disabled = true
	is_attacking = false

# Squishy effect on jump (stretch vertically)
func _on_jump() -> void:
	animated_sprite_2d.scale = Vector2(default_scale.x * 0.7, default_scale.y * 1.3)
	var t = create_tween()
	t.tween_property(animated_sprite_2d, "scale", default_scale, 0.2).set_trans(Tween.TRANS_ELASTIC)

# Squishy effect on land (squash horizontally)
func _on_land() -> void:
	animated_sprite_2d.scale = Vector2(default_scale.x * 1.3, default_scale.y * 0.7)
	var t = create_tween()
	t.tween_property(animated_sprite_2d, "scale", default_scale, 0.2).set_trans(Tween.TRANS_ELASTIC)
	trigger_camera_shake(5.0) # Shake effect when landing

func trigger_camera_shake(strength: float = 5.0) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("apply_shake"):
		camera.apply_shake(strength)

func bounce(bounce_force: float = -600.0) -> void:
	velocity.y = bounce_force
	_on_jump()

func hit_stop(duration: float = 0.05) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func die() -> void:
	if is_dying:
		return
	is_dying = true
	velocity = Vector2.ZERO
	hit_stop(0.1)
	var sprite_material = animated_sprite_2d.material as ShaderMaterial
	if sprite_material:
		var flash_tween = create_tween()
		for i in range(4):
			flash_tween.tween_property(sprite_material, "shader_parameter/flash_amount", 1.0, 0.05)
			flash_tween.tween_property(sprite_material, "shader_parameter/flash_amount", 0.0, 0.05)

	if animated_sprite_2d.sprite_frames.has_animation("dying"):
		animated_sprite_2d.play("dying")
		await animated_sprite_2d.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout

	resurrect()

func resurrect() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	hearts = max_hearts
	update_hearts_ui()
	if animated_sprite_2d.sprite_frames.has_animation("idle"):
		animated_sprite_2d.play("idle")
	is_taking_damage = false
	is_invincible = false
	is_dying = false

func _on_enemy_hit_body_entered(body: Node2D) -> void:
	if body is FrogEnemy or body.is_in_group("enemy"):
		take_damage(1)
