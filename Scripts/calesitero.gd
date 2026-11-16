extends "res://Scripts/npc.gd"

const SORTIJA:= preload("res://Scripts/ui/sortija.gd")
const PREMIOS :=[["greatball", 3], ["revive", 1], ["dusk_stone", 1]]

@export_multiline var texto_pregunta: String= "¡Pase, pase! ¿Una vuelta en la calesita? Si sacás la sortija, hay premio."
@export_multiline var texto_no :String= "¡Cuando quieras! La calesita gira hasta tarde."
@export_multiline var texto_nada: String= "¡Uy, esta vez no! La sortija es mañosa. ¡Probá otra vuelta!"
@export_multiline var texto_repetido :String= "¡Muy bien! Pero esos premios ya te los di. ¡Sos un campeón de la sortija!"

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	var r: int= await Dialogo.preguntar(texto_pregunta)
	if r!= 0:
		await Dialogo.mostrar(texto_no)
		return
	var s= SORTIJA.new()
	get_tree().root.add_child(s)
	var sacadas: Array= await s.termino
	if sacadas.is_empty():
		await Dialogo.mostrar(texto_nada)
		return
	var nuevas:= 0
	for k in sacadas:
		var clave:= "sortija_%d" % (int(k)+ 1)
		if Estado.tiene(clave):
			continue
		Estado.marcar(clave)
		var premio: Array= PREMIOS[int(k)]
		Inventario.add_item(premio[0], premio[1])
		nuevas+= 1
		Sonido.jingle("objeto")
		var nombre:= Inventario.get_item_name(premio[0])
		await Dialogo.mostrar("¡Premio por la sortija %d! ¡Recibiste %s!" % [int(k)+ 1, nombre] if premio[1]== 1 else "¡Premio por la sortija %d! ¡Recibiste %s x%d!" % [int(k)+ 1, nombre, premio[1]])
		Sonido.cortar_jingle()
	if nuevas== 0:
		await Dialogo.mostrar(texto_repetido)
