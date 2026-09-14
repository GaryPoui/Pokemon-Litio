extends CharacterBody2D

@export var tile_size: float = 16.0

@export var move_speed: float = 4.0

@export var animation_fps: float = 5.0

@export_range(0, 2, 1) var idle_frame: int = 1


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


var is_moving: bool = false
var target_position: Vector2 = Vector2.ZERO

var last_direction: Vector2 = Vector2.DOWN


const ANIM_DOWN: StringName = &"caminar_abajo"
const ANIM_UP: StringName = &"caminar_arriba"
const ANIM_LEFT: StringName = &"caminar_izquierda"
const ANIM_RIGHT: StringName = &"caminar_derecha"


func _ready() -> void:
	target_position = position

	_set_animation_speeds()

	_set_idle()


func _physics_process(delta: float) -> void:
	if is_moving:
		_move_towards_target(delta)
	else:
		_try_start_move()


func _get_input_direction() -> Vector2:

	if Input.is_action_pressed("ui_right"):
		return Vector2.RIGHT

	if Input.is_action_pressed("ui_left"):
		return Vector2.LEFT

	if Input.is_action_pressed("ui_up"):
		return Vector2.UP

	if Input.is_action_pressed("ui_down"):
		return Vector2.DOWN

	return Vector2.ZERO



func _try_start_move() -> void:
	var direction: Vector2 = _get_input_direction()

	if direction == Vector2.ZERO:
		_set_idle()
		return

	last_direction = direction

	var motion: Vector2 = direction * tile_size

	if test_move(transform, motion):
		_set_idle()
		return

	target_position = position + motion
	is_moving = true

	_play_walk_animation(direction)


func _move_towards_target(delta: float) -> void:
	var pixel_speed: float = move_speed * tile_size

	position = position.move_toward(
		target_position,
		pixel_speed * delta
	)

	if position == target_position:
		is_moving = false

		_try_start_move()



func _play_walk_animation(direction: Vector2) -> void:
	var animation_name: StringName = _get_animation_name(direction)

	if animation_name == &"":
		return

	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)

	elif not animated_sprite.is_playing():
		animated_sprite.play()


func _set_idle() -> void:
	var animation_name: StringName = _get_animation_name(last_direction)

	if animation_name == &"":
		return

	if animated_sprite.animation != animation_name:
		animated_sprite.animation = animation_name

	animated_sprite.stop()

	animated_sprite.frame = idle_frame


func _get_animation_name(direction: Vector2) -> StringName:
	match direction:
		Vector2.DOWN:
			return ANIM_DOWN

		Vector2.UP:
			return ANIM_UP

		Vector2.LEFT:
			return ANIM_LEFT

		Vector2.RIGHT:
			return ANIM_RIGHT

	return &""


func _set_animation_speeds() -> void:
	var animations: Array[StringName] = [
		ANIM_DOWN,
		ANIM_UP,
		ANIM_LEFT,
		ANIM_RIGHT
	]

	for animation_name: StringName in animations:
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.sprite_frames.set_animation_speed(
				animation_name,
				animation_fps
			)
