extends CharacterBody2D

signal paso_terminado(celda: Vector2i)

@export var tile_size: float= 16.0
@export var move_speed: float =4.0
@export var run_multiplier: float= 2.0
@export var turn_delay: float =0.08
@export_range(0, 3, 1) var idle_frame: int= 1

@onready var animated_sprite: AnimatedSprite2D =$AnimatedSprite2D
@onready var mochila= get_node_or_null("Mochila")

var is_moving: bool =false
var is_running: bool= false
var target_position: Vector2 =Vector2.ZERO
var last_direction: Vector2= Vector2.DOWN
var turn_timer: float =0.0

const WALK_ANIMS:= {
	Vector2.DOWN: &"caminar_abajo",
	Vector2.UP: &"caminar_arriba",
	Vector2.LEFT: &"caminar_izquierda",
	Vector2.RIGHT: &"caminar_derecha",
}
const RUN_ANIMS :={
	Vector2.DOWN: &"correr_abajo",
	Vector2.UP: &"correr_arriba",
	Vector2.LEFT: &"correr_izquierda",
	Vector2.RIGHT: &"correr_derecha",
}

func _ready() -> void:
	target_position= position
	_set_animation_speeds()
	_set_idle()

func _bloqueado() -> bool:
	return (mochila!= null and mochila.is_open) or Dialogo.esta_abierto or GestorEscenas.en_transicion

func celda() -> Vector2i:
	return Vector2i((position/ tile_size).floor())

func colocar(pos: Vector2, direccion: Vector2) -> void:
	position =pos
	target_position= pos
	is_moving =false
	turn_timer= 0.0
	last_direction =direccion
	_set_idle()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("aceptar") or is_moving or _bloqueado():
		return
	var objetivo:= celda()+ Vector2i(last_direction)
	for n in get_tree().get_nodes_in_group("interactuable"):
		if n.celda()== objetivo:
			get_viewport().set_input_as_handled()
			n.interactuar(self)
			return

func _physics_process(delta: float) -> void:
	if _bloqueado():
		if is_moving:
			position =target_position
			is_moving= false
		turn_timer= 0.0
		_set_idle()
		return

	if is_moving:
		_move_towards_target(delta)
	else:
		_try_start_move(delta, false)

func _get_input_direction() -> Vector2:
	if Input.is_action_pressed("derecha"):
		return Vector2.RIGHT
	if Input.is_action_pressed("izquierda"):
		return Vector2.LEFT
	if Input.is_action_pressed("arriba"):
		return Vector2.UP
	if Input.is_action_pressed("abajo"):
		return Vector2.DOWN
	return Vector2.ZERO

func _try_start_move(delta: float, chained: bool) -> void:
	var direction: Vector2= _get_input_direction()

	if direction== Vector2.ZERO:
		turn_timer =0.0
		_set_idle()
		return

	if direction!= last_direction and not chained:
		last_direction= direction
		turn_timer =turn_delay
		_set_idle()
		return

	if turn_timer> 0.0:
		turn_timer-= delta
		return

	last_direction =direction
	is_running= Input.is_action_pressed("correr")
	var motion: Vector2 =direction* tile_size

	if test_move(transform, motion):
		_set_idle()
		return

	target_position= position +motion
	is_moving =true
	_play_move_animation(direction)

func _move_towards_target(delta: float) -> void:
	var speed: float= move_speed* tile_size *(run_multiplier if is_running else 1.0)
	var restante: float =speed* delta
	var distancia:= position.distance_to(target_position)

	if restante< distancia:
		position =position.move_toward(target_position, restante)
		return

	position= target_position
	restante-= distancia
	is_moving= false
	paso_terminado.emit(celda())
	if _bloqueado():
		_set_idle()
		return
	_try_start_move(delta, true)
	if is_moving and restante> 0.0:
		position= position.move_toward(target_position, restante)

func _play_move_animation(direction: Vector2) -> void:
	var anims: Dictionary= RUN_ANIMS if is_running else WALK_ANIMS
	var animation_name: StringName =anims[direction]

	if animated_sprite.animation== animation_name and animated_sprite.is_playing():
		return

	var seguir:= animated_sprite.is_playing()
	var cuadro:= animated_sprite.frame
	var avance:= animated_sprite.frame_progress
	animated_sprite.play(animation_name)
	if seguir:
		animated_sprite.set_frame_and_progress(cuadro, avance)

func _set_idle() -> void:
	var animation_name: StringName= WALK_ANIMS[last_direction]

	if animated_sprite.animation!= animation_name:
		animated_sprite.animation =animation_name

	animated_sprite.stop()
	animated_sprite.frame= idle_frame

func _set_animation_speeds() -> void:
	var walk_fps: float =move_speed* 2.0
	for d in WALK_ANIMS:
		animated_sprite.sprite_frames.set_animation_speed(WALK_ANIMS[d], walk_fps)
		animated_sprite.sprite_frames.set_animation_speed(RUN_ANIMS[d], walk_fps *run_multiplier)
