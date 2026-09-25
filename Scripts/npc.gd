extends StaticBody2D

@export_multiline var texto: String =""
@export var mirando: Vector2= Vector2.DOWN

@onready var sprite: AnimatedSprite2D= $AnimatedSprite2D

const ANIMS:= {
	Vector2.DOWN: &"abajo",
	Vector2.UP: &"arriba",
	Vector2.LEFT: &"izquierda",
	Vector2.RIGHT: &"derecha",
}

func _ready() -> void:
	add_to_group("interactuable")
	_mirar(mirando)

func celda() -> Vector2i:
	return Vector2i((global_position /16.0).floor())

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	await Dialogo.mostrar(texto)

func _mirar(direccion: Vector2) -> void:
	if ANIMS.has(direccion):
		sprite.play(ANIMS[direccion])
