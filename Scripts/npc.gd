extends StaticBody2D

@export_multiline var texto: String =""
@export var mirando: Vector2= Vector2.DOWN

@export_group("Regalo")
@export var regalo: EspeciePokemon
@export var regalo_nivel: int= 5
@export var clave_regalo: String =""
@export_multiline var texto_regalo: String= ""

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
	if regalo!= null and clave_regalo!= "" and not Estado.tiene(clave_regalo):
		await Dialogo.mostrar(texto_regalo)
		if Equipo.agregar(PokemonInstancia.crear(regalo, regalo_nivel)):
			Estado.marcar(clave_regalo)
			Sonido.jingle("captura")
			await Dialogo.mostrar("¡Recibiste a %s!" % regalo.nombre)
			Sonido.cortar_jingle()
		else:
			await Dialogo.mostrar("Tu equipo está lleno.")
		return
	await Dialogo.mostrar(texto)

func _mirar(direccion: Vector2) -> void:
	if ANIMS.has(direccion):
		sprite.play(ANIMS[direccion])
