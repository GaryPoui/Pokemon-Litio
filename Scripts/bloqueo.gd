extends Node2D

@export var celdas: Array= []
@export var quien :String= ""
@export_multiline var texto: String =""

var jugador: Node
var ocupado:= false

func _ready() -> void:
	_conectar.call_deferred()

func _conectar() -> void:
	var m:= get_tree().current_scene
	if m== null or not "jugador" in m or m.jugador== null:
		return
	jugador= m.jugador
	if not jugador.paso_terminado.is_connected(_al_paso):
		jugador.paso_terminado.connect(_al_paso)

func es_mia(c: Vector2i) -> bool:
	for k in celdas:
		if Vector2i(int(k[0]), int(k[1]))== c:
			return true
	return false

func _al_paso(c: Vector2i) -> void:
	if ocupado or not Estado.en_tutorial() or not es_mia(c):
		return
	ocupado= true
	jugador.en_evento =true
	var dir: Vector2= jugador.last_direction
	var n:= get_node_or_null(quien)
	if n!= null and n.has_method("_mirar"):
		var v:= c- Rejilla.celda(n)
		n._mirar(Vector2(signi(v.x), 0) if absi(v.x)>= absi(v.y) else Vector2(0, signi(v.y)))
	await Dialogo.mostrar(texto)
	var destino:= Rejilla.centro(jugador, c- Vector2i(dir))
	var tw:= create_tween()
	tw.tween_property(jugador, "position", destino, 0.2)
	await tw.finished
	if is_instance_valid(jugador):
		jugador.colocar(destino, dir)
		jugador.en_evento= false
	ocupado =false
