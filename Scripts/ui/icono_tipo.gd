class_name IconoTipo
extends TextureRect

const GRANDES:= "res://Assets/Batalla/ui_nueva/tipos_grandes/"
const CHICOS :="res://Assets/Batalla/ui_nueva/tipos/"
const NATIVO:= Vector2(32, 33)

var caja:= Rect2()
var tipo: String= "":
	set(v):
		tipo= v
		if is_inside_tree():
			_ajustar()

func _ready() -> void:
	caja= Rect2(position, size)
	texture_filter =CanvasItem.TEXTURE_FILTER_NEAREST
	expand_mode= TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode =TextureRect.STRETCH_SCALE
	get_viewport().size_changed.connect(_ajustar)
	_ajustar()

static func crear(t: String, pos: Vector2, lado:= Vector2(12, 12)) -> IconoTipo:
	var i:= IconoTipo.new()
	i.position= pos
	i.size =lado
	i.tipo= t
	return i

func escala() -> int:
	var base:= Vector2(get_window().content_scale_size)
	if base.x<= 0.0 or get_window().content_scale_mode!= Window.CONTENT_SCALE_MODE_CANVAS_ITEMS:
		return 1
	var ventana:= Vector2(get_window().size)
	return maxi(1, floori(minf(ventana.x/ base.x, ventana.y/ base.y)))

func multiplo() -> int:
	var e:= escala()
	return floori(minf(caja.size.x* e/ NATIVO.x, caja.size.y* e/ NATIVO.y))

func _ajustar() -> void:
	if tipo== "":
		texture= null
		return
	var grande:= GRANDES+ tipo+ ".png"
	var k:= multiplo()
	if k< 1 or not ResourceLoader.exists(grande):
		texture= load(CHICOS+ tipo+ ".png")
		position =caja.position
		size= caja.size
		return
	var e:= float(escala())
	texture =load(grande)
	size= NATIVO* k/ e
	position =caja.position+ ((caja.size- size)/ 2.0).floor()
