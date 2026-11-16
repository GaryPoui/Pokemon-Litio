extends Node2D

@export var sotanos: Array= []
@export var salida :Array= []
@export var clave:= "r8_galeria"

func _ready() -> void:
	_preparar.call_deferred()

func _preparar() -> void:
	if Estado.tiene(clave):
		_despejar()
	var j= get_parent().get_node_or_null("Jugador")
	if j!= null:
		j.paso_terminado.connect(_al_paso)

func _al_paso(c: Vector2i) -> void:
	if Estado.tiene(clave) or salida.size()< 2:
		return
	if c== Vector2i(int(salida[0]), int(salida[1])):
		Estado.marcar(clave)

func _despejar() -> void:
	var mapa:= get_parent()
	if mapa.has_method("cambiar_celdas"):
		mapa.cambiar_celdas(sotanos)
	for n in get_tree().get_nodes_in_group("empujable"):
		if n.get_parent()== mapa and "tile_tapado" in n:
			n.remove_from_group("empujable")
			n.queue_free()
