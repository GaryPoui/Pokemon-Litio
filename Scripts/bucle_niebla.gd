extends Node2D

@export var celdas: Array =[]
@export var destino :Array =[]
@export_multiline var texto: String= "Te perdiste en la niebla y volviste al monumento."

var jugador: Node
var lista: Array[Vector2i] =[]

func _ready() -> void:
	for c in celdas:
		lista.append(Vector2i(int(c[0]), int(c[1])))
	jugador = get_parent().get_node_or_null("Jugador")
	if jugador!= null:
		jugador.paso_terminado.connect(_al_paso)

func _al_paso(c: Vector2i) -> void:
	if Seguidor.activo() or not lista.has(c) or destino.size()< 2:
		return
	_devolver.call_deferred()

func _devolver() -> void:
	jugador.en_evento =true
	var llegada :=Rejilla.centro(jugador, Vector2i(int(destino[0]), int(destino[1])))
	await GestorEscenas.fundido(func(): jugador.colocar(llegada, Vector2.DOWN))
	await Dialogo.mostrar(texto)
	if is_instance_valid(jugador):
		jugador.en_evento =false
