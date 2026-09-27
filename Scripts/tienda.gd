extends "res://Scripts/npc.gd"

const ESCENA_TIENDA:= "res://Escenas/UI/TiendaTrinkets.tscn"

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	await Dialogo.mostrar(texto if texto!= "" else "¡Bienvenido! Aquí vendemos Trinkets. El surtido cambia cada vez que alguien supera la Torre Desafío.")
	var t= load(ESCENA_TIENDA).instantiate()
	await GestorEscenas.fundido(func(): get_tree().current_scene.add_child(t))
	await t.cerrado
	await GestorEscenas.fundido(func(): t.queue_free())
