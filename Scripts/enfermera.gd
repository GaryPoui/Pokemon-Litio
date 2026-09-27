extends "res://Scripts/npc.gd"

@export_group("Curación")
@export_multiline var texto_pregunta: String= "¡Hola! Cuido a los Pokémon que entrenan en esta zona. ¿Quieres que cure a tu equipo?"
@export_multiline var texto_espera :String= "De acuerdo, déjame tus Pokémon un momento..."
@export_multiline var texto_listo: String= "¡Listo! Tus Pokémon están como nuevos. ¡Mucha suerte con el entrenamiento!"
@export_multiline var texto_no :String= "¡Vuelve cuando quieras!"
@export var mirar_al_curar: Vector2= Vector2.UP
@export var maquina :String= ""

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	if Equipo.miembros.is_empty():
		await Dialogo.mostrar(texto)
		return
	var r: int= await Dialogo.preguntar(texto_pregunta)
	if r!= 0:
		await Dialogo.mostrar(texto_no)
		return
	await Dialogo.mostrar(texto_espera)
	_mirar(mirar_al_curar)
	var m:= get_node_or_null(maquina) if maquina!= "" else null
	if m!= null:
		await m.colocar(Equipo.miembros)
		m.parpadear(2.6)
	await Sonido.jingle("curacion")
	Equipo.curar_todo()
	if m!= null:
		m.limpiar()
	_mirar(-jugador.last_direction)
	await Dialogo.mostrar(texto_listo)
