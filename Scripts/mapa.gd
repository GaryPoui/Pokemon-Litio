extends Node2D

@export var encuentros: TablaEncuentros
@export var fondo_batalla: Texture2D
@export var musica: String= ""
@export var tam_celda :Vector2i= Vector2i(16, 16)

@export_group("Zona")
@export var zona_id: String= ""
@export var zona_nombre: String= ""
@export var zona_subtitulo: String= ""
@export_enum("Ciudad", "Pueblo", "Ruta", "Interior", "Zona especial") var tipo_zona: int= 2
@export var anunciar_al_entrar: bool= true

@export_group("Reserva")
@export var safari:= false
@export var encuentros_raros :TablaEncuentros
@export_range(0.0, 1.0, 0.005) var prob_hierba_rara: float= 0.04

const HIERBA_RARA:= preload("res://Scripts/hierba_rara.gd")
const DIST_RARA :=Vector2i(2, 5)
const PASOS_RARA:= 40

var rng:= RandomNumberGenerator.new()
var hierba_rara: Node2D
var celda_rara :=Vector2i.ZERO
var pasos_rara:= 0

@onready var suelo: TileMapLayer= $Suelo
@onready var jugador =$Jugador
@onready var camara: Camera2D =$Jugador/Camara

func _ready() -> void:
	rng.randomize()
	if musica!= "":
		Sonido.musica(musica)
	_ajustar_camara()
	var de_partida:= GestorEscenas.posicion_llegada!= null
	var por_cambio :=GestorEscenas.consumir_cambio()
	if GestorEscenas.posicion_llegada!= null:
		jugador.colocar(GestorEscenas.posicion_llegada, GestorEscenas.direccion_llegada)
		GestorEscenas.posicion_llegada =null
	elif GestorEscenas.llegada!= "":
		var marca:= get_node_or_null("Llegadas/" +GestorEscenas.llegada)
		if marca!= null:
			jugador.colocar(marca.global_position, GestorEscenas.direccion_llegada)
		GestorEscenas.llegada= ""
	jugador.paso_terminado.connect(_al_terminar_paso)
	GestorEscenas.registrar_zona(zona_id, zona_nombre, zona_subtitulo, tipo_zona, anunciar_al_entrar)
	if tipo_zona== 0 and por_cambio and not de_partida and Estado.dar_fichas_ciudad(zona_id)> 0:
		_avisar_fichas.call_deferred()
	if safari and not de_partida:
		for g in get_tree().get_nodes_in_group("guardaparque"):
			if g.cerca_de(jugador):
				g.al_llegar.call_deferred(jugador)
				break

func _avisar_fichas() -> void:
	while GestorEscenas.en_transicion or Dialogo.esta_abierto:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	if not is_inside_tree():
		return
	jugador.en_evento= true
	Sonido.jingle("objeto")
	await Dialogo.mostrar("¡Bienvenido a %s! Recibiste %d Fichas de Desafío. Cada victoria en la torre de desafíos de la ciudad le sube un nivel al Pokémon que pelea. Ya tenés %d." % [zona_nombre, Estado.FICHAS_POR_CIUDAD, Estado.fichas])
	Sonido.cortar_jingle()
	if is_instance_valid(jugador):
		jugador.en_evento =false

func _ajustar_camara() -> void:
	var zona: Rect2i= suelo.get_used_rect()
	var tam: Vector2i =suelo.tile_set.tile_size
	var izq: int= zona.position.x* tam.x
	var arr: int =zona.position.y *tam.y
	var der: int= zona.end.x* tam.x
	var aba: int =zona.end.y* tam.y
	var vista:= get_viewport_rect().size
	if der- izq< vista.x:
		var extra: float= (vista.x -(der- izq))/ 2.0
		izq-= int(floor(extra))
		der +=int(ceil(extra))
	if aba -arr< vista.y:
		var extra: float =(vista.y- (aba -arr))/ 2.0
		arr -=int(floor(extra))
		aba+= int(ceil(extra))
	camara.limit_left= izq
	camara.limit_top =arr
	camara.limit_right= der
	camara.limit_bottom =aba

func _al_terminar_paso(celda: Vector2i) -> void:
	for w in get_tree().get_nodes_in_group("warp"):
		if w.celda()== celda and w.destino!= "" and not w.salir_empujando:
			if w.sonido!= "":
				Sonido.efecto(w.sonido)
			GestorEscenas.usar_warp(w)
			return
	if hierba_rara!= null and celda== celda_rara:
		_quitar_rara()
		var raro:= encuentros_raros.elegir(rng) if encuentros_raros!= null else null
		if raro!= null:
			_encuentro(raro)
			return

	if Estado.pasos_repelente> 0:
		Estado.pasos_repelente -=1
		if Estado.pasos_repelente== 0:
			Dialogo.mostrar("El efecto del Repelente se ha terminado.")
			return
	var tasa:= encuentros.tasa* (1.0+ EfectosTrinket.total("encuentros", null, Equipo.miembros)) if encuentros!= null else 0.0
	if encuentros!= null and es_hierba(celda) and (safari or Equipo.primero_util()!= null) and rng.randf()< tasa:
		var e:= encuentros.elegir(rng, EfectosTrinket.total("rareza", null, Equipo.miembros))
		if e!= null:
			_encuentro(e)
			return
	_avanzar_rara(celda)

func salir_empujando(celda: Vector2i, dir: Vector2) -> bool:
	for w in get_tree().get_nodes_in_group("warp"):
		if w.celda()== celda and w.destino!= "" and w.salir_empujando and Vector2(w.direccion)== dir:
			if w.sonido!= "":
				Sonido.efecto(w.sonido)
			GestorEscenas.usar_warp(w)
			return true
	return false

func _encuentro(e: EncuentroEntrada) -> void:
	var nivel:= rng.randi_range(e.nivel_min, e.nivel_max)
	var guia:= Equipo.primero_util()
	if Estado.pasos_repelente> 0 and guia!= null and nivel< guia.nivel:
		return
	if safari:
		Combate.iniciar_safari(e.especie, nivel, zona_id)
	else:
		Combate.iniciar_salvaje(e.especie, nivel)

func _avanzar_rara(celda: Vector2i) -> void:
	if not safari or encuentros_raros== null:
		return
	if hierba_rara!= null:
		pasos_rara+= 1
		var d:= (celda_rara- celda).abs()
		if pasos_rara> PASOS_RARA or maxi(d.x, d.y)> DIST_RARA.y* 2:
			_quitar_rara()
		return
	if rng.randf()>= prob_hierba_rara:
		return
	var opciones: Array[Vector2i]= []
	for dy in range(-DIST_RARA.y, DIST_RARA.y+ 1):
		for dx in range(-DIST_RARA.y, DIST_RARA.y+ 1):
			var c:= celda+ Vector2i(dx, dy)
			if absi(dx)+ absi(dy)>= DIST_RARA.x and es_hierba(c):
				opciones.append(c)
	if opciones.is_empty():
		return
	poner_rara(opciones[rng.randi_range(0, opciones.size()- 1)])

func poner_rara(c: Vector2i) -> void:
	_quitar_rara()
	celda_rara= c
	pasos_rara =0
	hierba_rara= HIERBA_RARA.new()
	hierba_rara.position= Vector2(c* tam_celda)
	add_child(hierba_rara)

func _quitar_rara() -> void:
	if hierba_rara!= null:
		hierba_rara.queue_free()
	hierba_rara= null

func es_hierba(celda: Vector2i) -> bool:
	var capa:= get_node_or_null("Decoracion") as TileMapLayer
	if capa== null:
		return false
	var td:= capa.get_cell_tile_data(celda)
	return td!= null and td.get_custom_data("hierba_alta")== true
