extends "res://Scripts/npc.gd"

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	if Equipo.miembros.is_empty():
		await Dialogo.mostrar(texto)
		return
	var r: int= await Dialogo.preguntar("¡Hola! Cuido a los Pokémon que entrenan en esta zona. ¿Quieres que cure a tu equipo?")
	if r!= 0:
		await Dialogo.mostrar("¡Vuelve cuando quieras!")
		return
	await Dialogo.mostrar("De acuerdo, déjame tus Pokémon un momento...")
	_mirar(Vector2.UP)
	await Sonido.jingle("curacion")
	Equipo.curar_todo()
	_mirar(-jugador.last_direction)
	await Dialogo.mostrar("¡Listo! Tus Pokémon están como nuevos. ¡Mucha suerte con el entrenamiento!")
