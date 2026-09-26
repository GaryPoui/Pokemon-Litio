extends "res://Scripts/npc.gd"

@export_group("Combate")
@export var datos: EquipoEntrenador
@export var clave: String= ""
@export_multiline var texto_derrota: String =""
@export_multiline var texto_despues: String= ""

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	if clave!= "" and Estado.tiene(clave):
		await Dialogo.mostrar(texto_despues)
		return
	if Equipo.primero_util()== null:
		await Dialogo.mostrar("¡Vuelve cuando tengas un Pokémon!")
		return
	await Dialogo.mostrar(texto)
	if datos== null:
		return
	var res: String= await Combate.iniciar_entrenador(datos.nombre_completo(), datos.crear_equipo())
	if res== "victoria":
		if clave!= "":
			Estado.marcar(clave)
		await Dialogo.mostrar(texto_derrota)
