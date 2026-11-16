extends "res://Scripts/npc.gd"

@export_group("Puesto")
@export var producto: String= "ramo_flores"
@export var clave_anima :String= "anima_flores"
@export_multiline var texto_tiene: String= "Ya llevás un ramo. Dejalo en la tumba que te pidieron antes de que se marchite."
@export_multiline var texto_listo :String= "Vi flores frescas en la bóveda de los Santángelo. Qué lindo gesto."
@export_multiline var texto_chau: String= "Cuando quieras. Las flores no se van a ningún lado."

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	if Estado.tiene(clave_anima):
		await Dialogo.mostrar(texto_listo)
		return
	if Inventario.cantidad_de(producto)> 0:
		await Dialogo.mostrar(texto_tiene)
		return
	var o:= BaseDatos.objeto(producto)
	await Dialogo.mostrar(texto)
	var r: int= await Dialogo.preguntar("Un %s sale $%d. Tenés $%d. ¿Lo llevás?" % [o.nombre, o.precio, Estado.dinero])
	if r!= 0:
		await Dialogo.mostrar(texto_chau)
		return
	if Estado.dinero< o.precio:
		Sonido.efecto("error")
		await Dialogo.mostrar("Uy, no te alcanza la plata.")
		return
	Estado.sumar_dinero(-o.precio)
	Inventario.add_item(producto, 1)
	Sonido.jingle("objeto")
	await Dialogo.mostrar("¡Recibiste %s!" % o.nombre)
	Sonido.cortar_jingle()
