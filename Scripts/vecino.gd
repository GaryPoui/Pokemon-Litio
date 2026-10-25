extends "res://Scripts/npc.gd"

@export_group("Regalo de objeto")
@export var objeto_regalo: String= ""
@export var cantidad_regalo :int= 1
@export var trinket_regalo: String =""
@export var clave_objeto: String= ""
@export_multiline var texto_antes :String= ""
@export_multiline var texto_despues: String =""
@export var requiere_tipos: Array[String]= []
@export_multiline var texto_falta :String= ""

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	var tiene_regalo:= (objeto_regalo!= "" or trinket_regalo!= "") and clave_objeto!= ""
	if not tiene_regalo or Estado.tiene(clave_objeto):
		await Dialogo.mostrar(texto_despues if tiene_regalo and texto_despues!= "" else texto)
		return
	if not requiere_tipos.is_empty() and mostrar_tipo()== null:
		await Dialogo.mostrar(texto_falta if texto_falta!= "" else texto)
		return
	await Dialogo.mostrar(texto_antes if texto_antes!= "" else texto)
	Estado.marcar(clave_objeto)
	if objeto_regalo!= "":
		Inventario.add_item(objeto_regalo, cantidad_regalo)
		Sonido.jingle("objeto")
		var nombre:= Inventario.get_item_name(objeto_regalo)
		await Dialogo.mostrar("¡Recibiste %s!" % nombre if cantidad_regalo== 1 else "¡Recibiste %s x%d!" % [nombre, cantidad_regalo])
		Sonido.cortar_jingle()
	if trinket_regalo!= "":
		Inventario.agregar_trinket(trinket_regalo)
		Sonido.jingle("objeto_clave")
		var t:= BaseDatos.trinket(trinket_regalo)
		await Dialogo.mostrar("¡Recibiste el Trinket %s!" % (t.nombre if t!= null else trinket_regalo))
		Sonido.cortar_jingle()
	if texto_despues!= "":
		await Dialogo.mostrar(texto_despues)

func mostrar_tipo() -> PokemonInstancia:
	for p in Equipo.miembros:
		for t in p.especie.tipos:
			if requiere_tipos.has(str(t)):
				return p
	return null
