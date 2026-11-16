extends Node2D

const TRANVIA:= preload("res://Scripts/tranvia.gd")
const AVENIDA :=preload("res://Assets/Overworld/Rutas8/avenida_noche.png")

@export var duracion:= 4.0
@export var velocidad :=40.0
@export var ventana: Array= []

var fondo: Sprite2D
var desplazado:= 0.0

func _ready() -> void:
	_armar_fondo()
	_empezar.call_deferred()

func _armar_fondo() -> void:
	if ventana.size()< 4:
		return
	var tam:= Rejilla.tam(self)
	fondo= Sprite2D.new()
	fondo.texture =AVENIDA
	fondo.centered= false
	fondo.texture_repeat= CanvasItem.TEXTURE_REPEAT_ENABLED
	fondo.region_enabled =true
	var ancho:= (int(ventana[2])- int(ventana[0])+ 1)* tam.x
	fondo.region_rect= Rect2(0, 0, ancho, AVENIDA.get_height())
	fondo.position =Vector2(int(ventana[0])* tam.x, int(ventana[1])* tam.y- 14)
	fondo.z_index= -20
	get_parent().add_child.call_deferred(fondo)

func _process(delta: float) -> void:
	if fondo== null:
		return
	desplazado= fmod(desplazado+ velocidad* delta, float(AVENIDA.get_width()))
	var r:= fondo.region_rect
	r.position.x= desplazado
	fondo.region_rect= r

func _empezar() -> void:
	var mapa:= get_parent()
	var j= mapa.get_node_or_null("Jugador")
	if j!= null:
		j.en_evento= true
		var lit= mapa.get_node_or_null("Litwick")
		if lit!= null:
			lit.position= Rejilla.centro(lit, j.celda()+ Vector2i.RIGHT)
	if TRANVIA.pendiente.is_empty():
		return
	await get_tree().create_timer(duracion).timeout
	var p: Dictionary= TRANVIA.pendiente
	TRANVIA.pendiente= {}
	GestorEscenas.cambiar_mapa(str(p.get("destino", "")), str(p.get("llegada", "")), Vector2.DOWN)
