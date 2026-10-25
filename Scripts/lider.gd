extends "res://Scripts/entrenador.gd"

@export_group("Líder")
@export var medalla: String= ""
@export var nombre_medalla :String= ""
@export var requiere_medalla: String =""
@export_multiline var texto_requisito: String= ""
@export var mt_premio :String= ""
@export var trinket_premio: String= ""
@export_multiline var texto_premio :String= ""

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	if medalla!= "" and Estado.tiene_medalla(medalla):
		await Dialogo.mostrar(texto_despues)
		return
	if requiere_medalla!= "" and not Estado.tiene_medalla(requiere_medalla):
		await Dialogo.mostrar(texto_requisito)
		return
	if Equipo.primero_util()== null:
		await Dialogo.mostrar("¡Volvé cuando tengas un Pokémon!")
		return
	Sonido.musica("mirada_joven", 0.0)
	await Dialogo.mostrar(texto)
	if datos== null:
		return
	var res: String= await Combate.iniciar_entrenador(datos.nombre_completo(), datos.crear_equipo(), datos.pago_base, {"objetos": datos.objetos, "lider": true})
	if res!= "victoria":
		return
	if clave!= "":
		Estado.marcar(clave)
	await Dialogo.mostrar(texto_derrota)
	Estado.dar_medalla(medalla)
	Sonido.jingle("medalla")
	await Dialogo.mostrar("¡Recibiste la %s de %s!" % [nombre_medalla, datos.nombre])
	Sonido.cortar_jingle()
	if texto_premio!= "":
		await Dialogo.mostrar(texto_premio)
	if mt_premio!= "":
		Inventario.add_item(mt_premio)
		Sonido.jingle("objeto")
		await Dialogo.mostrar("¡Recibiste %s!" % Inventario.get_item_name(mt_premio))
		Sonido.cortar_jingle()
	if trinket_premio!= "":
		Inventario.agregar_trinket(trinket_premio)
		Sonido.jingle("objeto_clave")
		var t:= BaseDatos.trinket(trinket_premio)
		await Dialogo.mostrar("¡Recibiste el Trinket %s!" % (t.nombre if t!= null else trinket_premio))
		Sonido.cortar_jingle()
