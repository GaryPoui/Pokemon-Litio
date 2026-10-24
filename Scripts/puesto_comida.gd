extends "res://Scripts/npc.gd"

const CANTIDADES:= [1, 5, 10]

@export var productos: Array[String]= ["alfajor", "barro"]
@export_multiline var texto_saludo :String= "¡Buenas! ¿Qué te sirvo?"
@export_multiline var texto_chau: String= "¡Gracias, volvé pronto!"

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	await Dialogo.mostrar(texto_saludo)
	while true:
		var opciones :Array= []
		for id in productos:
			var o:= BaseDatos.objeto(id)
			opciones.append("%s $%d" % [o.nombre.to_upper(), o.precio])
		opciones.append("NADA")
		var r: int= await Dialogo.preguntar("¿Qué vas a llevar? Tenés $%d." % Estado.dinero, opciones)
		if r< 0 or r>= productos.size():
			break
		var elegido :=BaseDatos.objeto(productos[r])
		var etiquetas: Array= CANTIDADES.map(func(n): return "x%d" % n)
		etiquetas.append("NINGUNO")
		var c: int= await Dialogo.preguntar("¿Cuántos? Cada uno sale $%d." % elegido.precio, etiquetas)
		if c< 0 or c>= CANTIDADES.size():
			continue
		var n: int =CANTIDADES[c]
		var total :=elegido.precio* n
		if Estado.dinero< total:
			Sonido.efecto("error")
			await Dialogo.mostrar("Uy, no te alcanza la plata.")
			continue
		Estado.sumar_dinero(-total)
		Inventario.add_item(elegido.id, n)
		Sonido.jingle("objeto")
		await Dialogo.mostrar("¡Ahí tenés! %s x%d." % [elegido.nombre, n])
		Sonido.cortar_jingle()
	await Dialogo.mostrar(texto_chau)
