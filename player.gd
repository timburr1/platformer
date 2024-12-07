extends CharacterBody2D

@export var movement_data : PlayerMovementData

var air_jump = false
var just_wall_jumped = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_jump_timer: Timer = $CoyoteJumpTimer
@onready var start_position = global_position

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_wall_jump()
	handle_jump()
	var input_axis := Input.get_axis("ui_left", "ui_right")
	handle_acceleration(input_axis, delta)
	apply_friction(input_axis, delta)
	apply_air_resistance(input_axis, delta)
	update_animations(input_axis)
	var was_on_floor = is_on_floor()
	move_and_slide()
	var just_left_ledge = was_on_floor and not is_on_floor() and velocity.y >= 0.0
	if just_left_ledge:
		coyote_jump_timer.start()
	just_wall_jumped = false
	
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * movement_data.gravity_scale * delta

func handle_wall_jump() -> void:
	if not is_on_wall_only():
		return
	var wall_normal = get_wall_normal()
	if Input.is_action_just_pressed("ui_accept"):
		velocity.x = wall_normal.x * movement_data.speed
		velocity.y = movement_data.jump_velocity
		just_wall_jumped = true
	
func handle_jump() -> void:
	if is_on_floor():
		air_jump = true
		
	if is_on_floor() or coyote_jump_timer.time_left > 0.0:
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = movement_data.jump_velocity
	elif not is_on_floor():
		if Input.is_action_just_released("ui_accept") and velocity.y < movement_data.jump_velocity / 2:
			velocity.y = movement_data.jump_velocity / 2
			
		if Input.is_action_just_pressed("ui_accept") and air_jump and not just_wall_jumped:
			velocity.y = movement_data.jump_velocity * 0.8
			air_jump = false

func apply_friction(input_axis:float, delta: float) -> void:
	if input_axis == 0.0 and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.friction * delta)
		
func apply_air_resistance(input_axis:float, delta: float) -> void:
	if  input_axis == 0.0 and not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.air_resistance * delta)
	
func handle_acceleration(input_axis:float, delta: float) -> void:
	if input_axis != 0.0: 
		if is_on_floor():
			velocity.x = move_toward(velocity.x, input_axis * movement_data.speed, movement_data.acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, input_axis * movement_data.speed, movement_data.air_acceleration * delta)
	
func update_animations(input_axis: float) -> void:
	if input_axis != 0.0:
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")
		
	if not is_on_floor():
		animated_sprite_2d.play("jump")
		
	if input_axis < 0.0:
		animated_sprite_2d.flip_h = true
	elif input_axis > 0.0: 
		animated_sprite_2d.flip_h = false

func _on_hazard_detector_area_entered(area: Area2D) -> void:
	global_position = start_position
