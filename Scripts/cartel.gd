extends Node2D

@export_multiline var texto: String= ""

func _ready() -> void:
	add_to_group("interactuable")

func celda() -> Vector2i:
	return Vector2i((global_position/ 16.0).floor())

func interactuar(_jugador: Node) -> void:
	await Dialogo.mostrar(texto)
