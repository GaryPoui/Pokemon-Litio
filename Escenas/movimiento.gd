extends CharacterBody2D
 
@export var tile_size: int = 16
@export var move_speed: float  = 4.0
 
var is_moving: bool = false
var target_position: Vector2
var input_direction: Vector2 = Vector2.ZERO
 
func _ready() -> void:
	target_position = position
 
func _physics_process(delta: float) -> void:
	if is_moving:
		move_towards_target(delta)
	else:
		check_input()
 
func check_input() -> void:
	input_direction = Vector2.ZERO
 
	if Input.is_action_pressed("ui_right"):
		input_direction = Vector2.RIGHT
	elif Input.is_action_pressed("ui_left"):
		input_direction  = Vector2.LEFT
	elif Input.is_action_pressed("ui_up"):
		input_direction = Vector2.UP
	elif Input.is_action_pressed("ui_down"):
		input_direction = Vector2.DOWN
 
	if input_direction != Vector2.ZERO:
		start_move()
 
func start_move() -> void:
	var next_position: Vector2 = position + (input_direction * tile_size)
 
	# Acá después podés chequear colisiones antes de mover
	target_position = next_position
	is_moving  = true
 
func move_towards_target(delta: float) -> void:
	var direction: Vector2 = (target_position - position).normalized()
	var distance: float = move_speed * tile_size * delta
 
	position += direction * distance
 
	if position.distance_to(target_position) < 1.0:
		position = target_position
		is_moving = false
