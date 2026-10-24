extends "res://Scripts/npc.gd"

const BALL:= "safariball"
const CERCA :=6

@export_group("Reserva")
@export var balls:= 20
@export var kit_alfajores :=3
@export var kit_barro:= 3
@export var premio_trinket: String =""
@export_multiline var texto_bienvenida: String= "¡Bienvenido a la reserva! Acá los Pokémon están protegidos: no se pelea, solo se observa y se atrapa."
@export_multiline var texto_reglas :String= "Tirales Alfajores para que se queden comiendo, o Barro para enojarlos: enojados se atrapan más fácil, pero se van antes."

func _ready() -> void:
	super._ready()
	add_to_group("guardaparque")

func ruta() -> String:
	var m:= get_tree().current_scene
	return str(m.get("zona_id")) if m!= null and "zona_id" in m else ""

func especies() -> Array[String]:
	var lista: Array[String]= []
	var m:= get_tree().current_scene
	if m== null:
		return lista
	for campo in ["encuentros", "encuentros_raros"]:
		var t= m.get(campo) if campo in m else null
		if t== null:
			continue
		for e in t.entradas:
			if e.especie!= null and e.peso> 0 and not lista.has(e.especie.id):
				lista.append(e.especie.id)
	return lista

func cerca_de(jugador: Node) -> bool:
	var d: Vector2i= (jugador.celda()- celda()).abs()
	return maxi(d.x, d.y)<= CERCA

func al_llegar(jugador: Node) -> void:
	while is_inside_tree() and (GestorEscenas.en_transicion or Dialogo.esta_abierto):
		await get_tree().process_frame
	if not is_inside_tree() or not is_instance_valid(jugador):
		return
	var primera:= not Estado.tiene(_clave())
	if not primera and Inventario.cantidad_de(BALL)>= balls:
		return
	jugador.en_evento= true
	_mirar(_hacia(jugador))
	if primera:
		await _bienvenida()
	else:
		await Dialogo.mostrar("¡Hola de nuevo! Te recargo las Safari Balls.")
		await _recargar()
	if is_instance_valid(jugador):
		jugador.en_evento =false
	_mirar(mirando)

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	if not Estado.tiene(_clave()):
		await _bienvenida()
		return
	if Inventario.cantidad_de(BALL)< balls:
		await Dialogo.mostrar("Te recargo las Safari Balls.")
		await _recargar()
	await _registro()

func _clave() -> String:
	return "reserva_%s" % ruta()

func _hacia(jugador: Node) -> Vector2:
	var d: Vector2= Vector2(jugador.celda()- celda())
	if absf(d.x)>= absf(d.y):
		return Vector2.RIGHT if d.x> 0 else Vector2.LEFT
	return Vector2.DOWN if d.y> 0 else Vector2.UP

func _bienvenida() -> void:
	await Dialogo.mostrar(texto_bienvenida)
	await Dialogo.mostrar(texto_reglas)
	Estado.marcar(_clave())
	Inventario.add_item("alfajor", kit_alfajores)
	Inventario.add_item("barro", kit_barro)
	Sonido.jingle("objeto")
	await Dialogo.mostrar("¡Recibiste %d Alfajores y %d puñados de Barro!" % [kit_alfajores, kit_barro])
	Sonido.cortar_jingle()
	await _recargar()
	await Dialogo.mostrar("Si me traés registradas todas las especies de esta reserva, te doy un regalo. ¡Pasá cuando quieras a recargar!")

func _recargar() -> void:
	var faltan:= balls- Inventario.cantidad_de(BALL)
	if faltan<= 0:
		return
	Inventario.add_item(BALL, faltan)
	Sonido.jingle("objeto")
	await Dialogo.mostrar("¡Ahora tenés %d Safari Balls!" % balls)
	Sonido.cortar_jingle()

func _registro() -> void:
	var lista:= especies()
	var hechas:= Estado.safari_de(ruta())
	var faltan: Array[String]= []
	for id in lista:
		if not hechas.has(id):
			faltan.append(id)
	if lista.is_empty():
		await Dialogo.mostrar(texto)
		return
	if not faltan.is_empty():
		var pistas: Array[String]= []
		for id in faltan:
			pistas.append(BaseDatos.especie(id).nombre if Estado.vistos.has(id) else "???")
		await Dialogo.mostrar("Registro de la reserva: %d de %d especies." % [lista.size()- faltan.size(), lista.size()])
		await Dialogo.mostrar("Te faltan: %s." % ", ".join(pistas))
		return
	var clave_premio:= "premio_%s" % _clave()
	if premio_trinket!= "" and not Estado.tiene(clave_premio):
		await Dialogo.mostrar("¡Registraste las %d especies de la reserva! Tomá, te lo ganaste." % lista.size())
		Inventario.agregar_trinket(premio_trinket)
		Estado.marcar(clave_premio)
		Sonido.jingle("objeto_clave")
		var t:= BaseDatos.trinket(premio_trinket)
		await Dialogo.mostrar("¡Recibiste el Trinket %s!" % (t.nombre if t!= null else premio_trinket))
		Sonido.cortar_jingle()
		return
	await Dialogo.mostrar("¡Registro completo! Gracias por cuidar la reserva.")
