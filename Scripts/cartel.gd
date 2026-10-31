extends Node2D

const PANEL:= preload("res://Scripts/ui/panel_encuentros.gd")

@export_multiline var texto: String= ""
@export var mostrar_encuentros:= false

func _ready() -> void:
	add_to_group("interactuable")

func celda() -> Vector2i:
	return Rejilla.celda(self)

func interactuar(_jugador: Node) -> void:
	await Dialogo.mostrar(texto)
	if not mostrar_encuentros:
		return
	var r: int= await Dialogo.preguntar("¿Querés ver qué Pokémon viven en esta zona?")
	if r!= 0:
		return
	await abrir_panel()

func abrir_panel() -> void:
	var p= PANEL.new()
	await GestorEscenas.fundido(func():
		get_tree().root.add_child(p)
		p.armar(get_tree().current_scene))
	await p.esperar()
	await GestorEscenas.fundido(func(): p.queue_free())
