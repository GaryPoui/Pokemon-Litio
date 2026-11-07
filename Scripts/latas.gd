extends Node2D

@export var latas: Array = []
@export var orilla_este :Array= []
@export var orilla_oeste: Array = []
@export var premiador: String= ""
@export var rescatador :String= ""
@export var clave_premio: String= "r7_latas_perfecto"
@export var tile_lata: Array= []
@export var tile_hundida :Array= []

const DIRS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var celdas: Array[Vector2i] =[]
var este :Array[Vector2i] =[]
var oeste: Array[Vector2i] =[]
var hundidas_ahora: Dictionary= {}
var origen :Array[Vector2i]= []
var jugador: Node

func _ready() -> void:
	celdas = _celdas(latas)
	este = _celdas(orilla_este)
	oeste = _celdas(orilla_oeste)
	jugador =get_parent().get_node_or_null("Jugador")
	if jugador !=null:
		jugador.paso_iniciado.connect(_al_salir)
		jugador.paso_terminado.connect(_al_llegar)

func _celdas(lista: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] =[]
	for c in lista:
		out.append(Vector2i(int(c[0]), int(c[1])))
	return out

func hundidas() -> int:
	return hundidas_ahora.size()

func _poner(c: Vector2i, t: Array) -> void:
	get_parent().cambiar_celdas([[c.x, c.y, int(t[0]), int(t[1]), int(t[2])]])

func reiniciar() -> void:
	for c in hundidas_ahora:
		_poner(c, tile_lata)
	hundidas_ahora.clear()

func _orilla(c: Vector2i) -> bool:
	return este.has(c) or oeste.has(c)

func _al_salir(destino: Vector2i, _dir: Vector2) -> void:
	var desde: Vector2i = jugador.celda()
	if celdas.has(desde) and not hundidas_ahora.has(desde):
		hundidas_ahora[desde]= true
		_poner(desde, tile_hundida)
		Sonido.efecto("chapoteo")
	elif _orilla(desde) and celdas.has(destino):
		origen= este if este.has(desde) else oeste

func _al_llegar(c: Vector2i) -> void:
	if _orilla(c):
		var cruzo:= not origen.is_empty() and not origen.has(c)
		if cruzo and oeste.has(c) and hundidas() == celdas.size() and not Estado.tiene(clave_premio):
			_premiar.call_deferred()
		reiniciar()
		origen =[]
		return
	if celdas.has(c) and not _hay_salida(c):
		_rescatar.call_deferred()

func _hay_salida(c: Vector2i) -> bool:
	for d: Vector2i in DIRS:
		var n: Vector2i= c +d
		if _orilla(n) or (celdas.has(n) and not hundidas_ahora.has(n)):
			return true
	return false

func _hablar(nombre: String, texto: String) -> void:
	var npc := get_parent().get_node_or_null(nombre)
	if npc!= null and npc.has_method("_mirar"):
		npc._mirar(Vector2(jugador.celda() -Rejilla.celda(npc)).sign())
	await Dialogo.mostrar(texto)

func _rescatar() -> void:
	jugador.en_evento= true
	await get_tree().create_timer(0.6).timeout
	await _hablar(rescatador, "¡Uy, te quedaste varado! Agarrate de la caña que te saco.")
	var destino: Vector2i =origen[0] if not origen.is_empty() else este[0]
	var mirar :=Vector2.LEFT if este.has(destino) else Vector2.RIGHT
	await GestorEscenas.fundido(func():
		jugador.colocar(Rejilla.centro(jugador, destino), mirar)
		reiniciar())
	origen =[]
	await Dialogo.mostrar("Las latas volvieron a flotar.")
	if is_instance_valid(jugador):
		jugador.en_evento= false

func _premiar() -> void:
	jugador.en_evento = true
	await _hablar(premiador, "¡Cruzaste hundiendo todas las latas, sin dejar ninguna! Eso es ser un vecino de Parque Patricios. Tomá, me lo dejó un Croagunk en la orilla.")
	Estado.marcar(clave_premio)
	Inventario.agregar_trinket("colmillo_afilado")
	Sonido.jingle("objeto_clave")
	var t:= BaseDatos.trinket("colmillo_afilado")
	await Dialogo.mostrar("¡Recibiste el Trinket %s!" % (t.nombre if t != null else "Colmillo Afilado"))
	Sonido.cortar_jingle()
	if is_instance_valid(jugador):
		jugador.en_evento =false
