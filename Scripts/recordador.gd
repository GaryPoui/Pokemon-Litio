extends "res://Scripts/npc.gd"

const ESCENA_EQUIPO:= "res://Escenas/UI/PantallaEquipo.tscn"
const POR_PAGINA :=6

@export_group("Recordador")
@export var objeto_pago: String= "alfajor"
@export_multiline var texto_sin_pago :String= ""

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	await Dialogo.mostrar(texto)
	var nombre_pago:= Inventario.get_item_name(objeto_pago)
	if Inventario.cantidad_de(objeto_pago)<= 0:
		await Dialogo.mostrar(texto_sin_pago if texto_sin_pago!= "" else "Traeme un %s y le hago recordar un movimiento a tu Pokémon." % nombre_pago)
		return
	var r: int= await Dialogo.preguntar("¿Querés que uno de tus Pokémon recuerde un movimiento? Me alcanza con un %s." % nombre_pago)
	if r!= 0:
		return
	var p:= await _elegir()
	if p== null:
		return
	var lista:= olvidados(p)
	if lista.is_empty():
		await Dialogo.mostrar("Hmm... %s no tiene ningún movimiento para recordar." % p.nombre())
		return
	var m:= await _elegir_movimiento(p, lista)
	if m== null:
		return
	var antes:= p.movimientos.duplicate()
	if p.movimientos.size()< PokemonInstancia.MAX_MOVIMIENTOS:
		p.aprender(m)
		Sonido.jingle("aprender")
		await Dialogo.mostrar("¡%s recordó %s!" % [p.nombre(), m.nombre])
	else:
		await Combate._aprender_fuera(p, m)
	if p.movimientos!= antes:
		Inventario.consumir(objeto_pago)
		await Dialogo.mostrar("¡Mmm, qué rico! Gracias por el %s." % nombre_pago)

static func olvidados(p: PokemonInstancia) -> Array[Movimiento]:
	var sabe:= {}
	for m in p.movimientos:
		sabe[m.id]= true
	var lista: Array[Movimiento] =[]
	for m in p.especie.movimientos_hasta(p.nivel):
		if not sabe.has(m.id):
			lista.append(m)
			sabe[m.id] =true
	return lista

func _elegir_movimiento(p: PokemonInstancia, lista: Array[Movimiento]) -> Movimiento:
	var pagina:= 0
	while true:
		var desde: int= pagina* POR_PAGINA
		var hasta :int= mini(desde+ POR_PAGINA, lista.size())
		var opciones: Array= []
		for i in range(desde, hasta):
			opciones.append(lista[i].nombre)
		var hay_mas:= lista.size()> POR_PAGINA
		if hay_mas:
			opciones.append("MÁS...")
		opciones.append("SALIR")
		var r: int= await Dialogo.preguntar("¿Qué movimiento querés que recuerde %s?" % p.nombre(), opciones)
		if r>= 0 and r< hasta- desde:
			return lista[desde+ r]
		if hay_mas and r== hasta -desde:
			pagina= (pagina+ 1)% ceili(lista.size()/ float(POR_PAGINA))
			continue
		return null
	return null

func _elegir() -> PokemonInstancia:
	var pe= load(ESCENA_EQUIPO).instantiate()
	await GestorEscenas.fundido(func():
		get_tree().current_scene.add_child(pe)
		pe.abrir("elegir", "¿Qué Pokémon tiene que recordar?"))
	await pe.cerrado
	var i: int= pe.resultado
	await GestorEscenas.fundido(func(): pe.queue_free())
	return Equipo.miembros[i] if i>= 0 else null
