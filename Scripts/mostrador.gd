extends Node2D

@export var destino: String= ""

func _ready() -> void:
	add_to_group("interactuable")

func celda() -> Vector2i:
	return Rejilla.celda(self)

func interactuar(jugador: Node) -> void:
	var n:= get_node_or_null(destino)
	if n!= null:
		await n.interactuar(jugador)
