extends "res://Scripts/npc.gd"

@export_multiline var texto_pregunta :String= "¿Querés que reacomode los rollos de la galería?"
@export_multiline var texto_si: String= "¡Listo! Todo en su lugar, como recién llegado."
@export var llegada:= "Galeria"
@export var clave_resuelto :String= ""
@export_multiline var texto_resuelto: String= "La galería quedó despejada: tapé los sótanos con los rollos que cayeron. Pasá tranquilo, para un lado o para el otro."

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	if clave_resuelto!= "" and Estado.tiene(clave_resuelto):
		await Dialogo.mostrar(texto_resuelto)
		return
	if texto!= "":
		await Dialogo.mostrar(texto)
	var r: int= await Dialogo.preguntar(texto_pregunta)
	if r!= 0:
		return
	await Dialogo.mostrar(texto_si)
	GestorEscenas.cambiar_mapa(get_tree().current_scene.scene_file_path, llegada, Vector2.UP)
