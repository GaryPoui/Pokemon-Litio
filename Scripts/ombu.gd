extends "res://Scripts/npc.gd"

const SPRITE:= preload("res://Scripts/batalla/sprite_pokemon.gd")
const TIPOS :={"snivy": "Planta", "charmander": "Fuego", "mudkip": "Agua"}

@export_group("Ombú")
@export var facu: String= "../FacuUsina"
const CONSEJOS:= [
	"En el Almacén hay una señora que vende Trinkets. Si te sobra plata, date una vuelta.",
	"Cada ciudad tiene su torre de desafío. Con las Fichas, tu Pokémon sube de nivel y se gana un Trinket.",
	"Los guardaparques anotan cada Pokémon que atrapás en su ruta. Si completás el registro, te dan un premio.",
]

var jugador: Node
var ocupado:= false
var negado_hasta :=0

func _ready() -> void:
	super._ready()
	add_to_group("ombu")
	add_to_group("guardia_salida")
	_conectar.call_deferred()

func _conectar() -> void:
	var m:= get_tree().current_scene
	if m== null or not "jugador" in m or m.jugador== null:
		return
	jugador= m.jugador
	var menu= jugador.get("menu_pausa")
	if menu!= null and not menu.cerrado.is_connected(_al_cerrar_menu):
		menu.cerrado.connect(_al_cerrar_menu)
	if Estado.en_tutorial() and not Estado.tiene("tut_llego"):
		_llegada()
	elif _listo_para_cierre():
		_cierre.call_deferred()

func _listo_para_cierre() -> bool:
	return Estado.en_tutorial() and Estado.tiene("tut_trinkets") and not Estado.tiene("tut_usina") and _tiene_prestados()

func _facu() -> Node:
	return get_node_or_null(facu)

func _bola_de(id: String) -> Node:
	for b in get_tree().get_nodes_in_group("bola_inicial"):
		if b.especie== id:
			return b
	return null

func _nombre_inicial() -> String:
	for p in Equipo.miembros:
		if p.especie.id== Estado.inicial():
			return p.nombre()
	return BaseDatos.especie(Estado.inicial()).nombre if Estado.inicial()!= "" else ""

func _empezar() -> void:
	ocupado= true
	if is_instance_valid(jugador):
		jugador.en_evento= true

func _terminar() -> void:
	ocupado =false
	if is_instance_valid(jugador):
		jugador.en_evento= false

func _llegada() -> void:
	_empezar()
	while GestorEscenas.en_transicion:
		await get_tree().process_frame
	var f:= _facu()
	if f!= null:
		f._mirar(Vector2.RIGHT)
	await Dialogo.mostrar("¡Por fin! ¡Profe, ya llegó!")
	await Dialogo.mostrar("¡Ah, llegaste! Él es Facu, vive acá a la vuelta. Quiero que cada uno se lleve un Pokémon y lo cuide.")
	await Dialogo.mostrar("En esa mesa hay tres Poké Balls. Elegí la que quieras. Facu, vos esperá tu turno.")
	Estado.marcar("tut_llego")
	_terminar()

func interactuar(j: Node) -> void:
	_mirar(-j.last_direction)
	if ocupado:
		return
	if _listo_para_cierre():
		await _cierre()
		return
	if Estado.en_tutorial() and not Estado.tiene("tut_usina"):
		if Estado.inicial()== "":
			await Dialogo.mostrar("Elegí la Poké Ball que quieras de la mesa.")
		else:
			await Dialogo.mostrar("Ponéselos vos: abrí el menú, entrá a POKéMON, elegí a %s y andá a TRINKETS." % _nombre_inicial())
		return
	await Dialogo.mostrar(CONSEJOS[randi()% CONSEJOS.size()])

func al_tocar_bola(bola: Node, j: Node) -> void:
	if ocupado:
		return
	jugador= j
	if Estado.inicial()!= "":
		if bola.especie== Estado.CONTRA.get(Estado.inicial(), ""):
			await Dialogo.mostrar("Esa es la de Facu.")
		else:
			await Dialogo.mostrar("Esa me la quedo yo.")
		return
	var e: EspeciePokemon= BaseDatos.especie(bola.especie)
	var capa:= _mostrar_pokemon(e)
	var r: int= await Dialogo.preguntar("¿Elegís a %s, el Pokémon de tipo %s?" % [e.nombre, TIPOS.get(bola.especie, "")])
	capa.queue_free()
	if r!= 0:
		return
	_empezar()
	await _dar_inicial(bola, e)
	_terminar()

func _mostrar_pokemon(e: EspeciePokemon) -> CanvasLayer:
	var capa:= CanvasLayer.new()
	capa.layer= 106
	var caja:= Panel.new()
	caja.position= Vector2(84, 30)
	caja.size =Vector2(88, 84)
	caja.add_theme_stylebox_override("panel", EstiloUI.panel())
	capa.add_child(caja)
	var spr: Sprite2D= SPRITE.new()
	capa.add_child(spr)
	spr.mostrar(e, false)
	spr.encajar_en(Rect2(88, 34, 80, 76))
	get_tree().current_scene.add_child(capa)
	Sonido.grito(e.numero)
	return capa

func _dar_inicial(bola: Node, e: EspeciePokemon) -> void:
	var id: String= bola.especie
	var p:= PokemonInstancia.crear(e, 5)
	var destino:= Equipo.recibir(p)
	Estado.marcar("inicial_" +id)
	bola.quitar()
	Sonido.jingle("captura")
	await Dialogo.mostrar("¡Recibiste a %s!" % e.nombre+ ("" if destino== "equipo" else " Como tu equipo está lleno, fue enviado a la Caja del PC."))
	Sonido.cortar_jingle()
	await Combate.pedir_mote(p)
	var f:= _facu()
	var suya:= _bola_de(Estado.CONTRA[id])
	if f!= null and suya!= null:
		await f.tomar_bola(suya)
	await Dialogo.mostrar("¡Entonces yo me quedo con este! Le gana al tuyo.")
	_mirar(Vector2(_hacia(jugador)))
	await Dialogo.mostrar("Je, siempre el mismo. El que queda me lo quedo yo.")
	await _amistoso()
	await _prestar()

func _hacia(n: Node) -> Vector2i:
	var v:= Rejilla.celda(n)- celda()
	if absi(v.x)>= absi(v.y):
		return Vector2i(signi(v.x), 0) if v.x!= 0 else Vector2i.DOWN
	return Vector2i(0, signi(v.y))

func _amistoso() -> void:
	await Dialogo.mostrar(Estado.con_nombre("A ver, %s, ¿probamos cómo se llevan? Un combate amistoso, sin apuestas.", "A ver, ¿probamos cómo se llevan? Un combate amistoso, sin apuestas."))
	var suyo: Array[PokemonInstancia]= [PokemonInstancia.crear(BaseDatos.especie(Estado.SOBRA[Estado.inicial()]), 5)]
	var res: String= await Combate.iniciar_entrenador("Profesor Ombú", suyo, 0, {"sin_derrota": true})
	Estado.marcar("tut_amistoso")
	if not is_inside_tree():
		return
	await Dialogo.mostrar("¡Muy bien! Se nota que ya se entienden." if res== "victoria" else "Tranqui, es el primero. Dejame curarlo.")
	Equipo.curar_todo()
	Sonido.jingle("curacion")
	await Dialogo.mostrar("Tu equipo recuperó toda su energía.")
	Sonido.cortar_jingle()

func _prestar() -> void:
	await Dialogo.mostrar("Ahora te muestro algo que en otras regiones no tienen: los Trinkets. Son amuletos que los Pokémon llevan encima; cada uno puede llevar hasta cinco distintos.")
	for id in Estado.PRESTADOS:
		Inventario.agregar_trinket(id)
	await Dialogo.mostrar("Te presto tres para que pruebes: el Bombo de la Hinchada, los Botines de Potrero y el Mate Compartido.")
	await Dialogo.mostrar("Ponéselos vos: abrí el menú, entrá a POKéMON, elegí a %s y andá a TRINKETS." % _nombre_inicial())
	Estado.marcar("tut_trinkets")

func _tiene_prestados() -> bool:
	for p in Equipo.miembros:
		if Estado.PRESTADOS.all(func(id): return p.trinkets.has(id)):
			return true
	return false

func _al_cerrar_menu() -> void:
	if ocupado or not Estado.en_tutorial() or not Estado.tiene("tut_trinkets") or Estado.tiene("tut_usina"):
		return
	if _tiene_prestados():
		_cierre.call_deferred()

func _cierre() -> void:
	if ocupado or not _listo_para_cierre():
		return
	_empezar()
	while GestorEscenas.en_transicion:
		await get_tree().process_frame
	if is_instance_valid(jugador):
		_mirar(Vector2(_hacia(jugador)))
	await Dialogo.mostrar("¡Eso! Ahora %s los lleva puestos. En combate vas a ver lo que hacen." % _nombre_inicial())
	await Dialogo.mostrar("Eso de allá es el Desafío de la Usina. Cada ciudad tiene una torre así: ganás un combate uno contra uno, gastás una Ficha, y tu Pokémon sube un nivel y se lleva un Trinket.")
	Estado.dar_fichas_ciudad("la_boca")
	await Dialogo.mostrar("Tomá, cinco Fichas de La Boca. Cada ciudad nueva te da cinco más la primera vez que llegás.")
	await Dialogo.mostrar("Otra cosa: en las rutas de acá no se pelea con los Pokémon salvajes; se los atrapa al estilo Safari. Los guardaparques te explican el resto.")
	Estado.marcar("pokedex")
	Inventario.add_item("potion", 5)
	Sonido.jingle("captura")
	await Dialogo.mostrar("Por último, tomá: una Pokédex, para anotar cada Pokémon que veas, y cinco Pociones.")
	Sonido.cortar_jingle()
	var f:= _facu()
	if f!= null:
		f._mirar(Vector2.RIGHT)
		await Dialogo.mostrar(Estado.con_nombre("¡Profe, me voy! %s, te espero afuera.", "¡Profe, me voy! Te espero afuera."))
		await f.salir_por(_puerta())
	await Dialogo.mostrar("Andá, andá. Y cuidá mucho a %s." % _nombre_inicial())
	Estado.marcar("tut_usina")
	_terminar()

func _puerta() -> Vector2i:
	for w in get_tree().get_nodes_in_group("warp"):
		if w.salir_empujando:
			return w.celda()+ Vector2i.UP
	return celda()

func deja_salir(_w: Node) -> bool:
	if not Estado.en_tutorial() or Estado.tiene("tut_usina"):
		return true
	if not ocupado and _listo_para_cierre():
		_cierre.call_deferred()
	elif not ocupado and Time.get_ticks_msec()>= negado_hasta:
		_negar.call_deferred()
	return false

func _negar() -> void:
	_empezar()
	if Estado.inicial()== "":
		await Dialogo.mostrar("¡Esperá! Primero elegí un Pokémon.")
	else:
		await Dialogo.mostrar("¡Esperá! Primero ponele los tres Trinkets a %s." % _nombre_inicial())
	negado_hasta= Time.get_ticks_msec()+ 700
	_terminar()
