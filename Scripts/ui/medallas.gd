extends CanvasLayer

signal cerrado

const ICONOS:= preload("res://Assets/UI/medallas.png")
const FONDO :=preload("res://Assets/Fondos/opciones.png")
const LISTA:= [
	["bombonera", "Medalla Bombonera", "Líder Riquelme · La Boca"],
	["terraza", "Medalla Terraza", "Líder La Gata · Villa 31"],
	["anden", "Medalla Andén", "Líder La Guarda · Constitución"],
]
const VACIA:= 3
const HUECOS :=8
const TAM:= 24

var cursor:= 0
var marco: Panel
var titulo: Label
var detalle :Label
var fichas: Label
var iconos: Array[TextureRect]= []

func _ready() -> void:
	layer= 106
	var fondo:= TextureRect.new()
	fondo.texture= FONDO
	add_child(fondo)
	var caja:= Panel.new()
	caja.position= Vector2(16, 12)
	caja.size =Vector2(224, 108)
	caja.add_theme_stylebox_override("panel", EstiloUI.madera())
	add_child(caja)
	var hoja:= Panel.new()
	hoja.position= Vector2(8, 18)
	hoja.size= Vector2(208, 82)
	hoja.add_theme_stylebox_override("panel", EstiloUI.hoja())
	caja.add_child(hoja)
	caja.add_child(EstiloUI.nuevo_label("MEDALLAS", 9, Vector2(10, 4)))
	marco= Panel.new()
	marco.size =Vector2(TAM+ 6, TAM+ 6)
	marco.add_theme_stylebox_override("panel", EstiloUI.panel(Color(0, 0, 0, 0), Color("ffd84a")))
	hoja.add_child(marco)
	for i in HUECOS:
		var r:= TextureRect.new()
		var a:= AtlasTexture.new()
		a.atlas= ICONOS
		r.texture =a
		r.position= Vector2(14+ (i% 4)* 50, 8+ floori(i/ 4.0)* 38)
		hoja.add_child(r)
		iconos.append(r)
	var info:= Panel.new()
	info.position= Vector2(16, 124)
	info.size =Vector2(224, 58)
	info.add_theme_stylebox_override("panel", EstiloUI.panel())
	add_child(info)
	titulo= EstiloUI.nuevo_label("", 9, Vector2(8, 4))
	detalle =EstiloUI.nuevo_label("", 9, Vector2(8, 18), EstiloUI.TENUE)
	fichas= EstiloUI.nuevo_label("", 6, Vector2(8, 38))
	for l in [titulo, detalle, fichas]:
		info.add_child(l)
	_pintar()

func abrir() -> void:
	_pintar()

func tiene(i: int) -> bool:
	return i< LISTA.size() and Estado.tiene_medalla(LISTA[i][0])

func _pintar() -> void:
	for i in HUECOS:
		var a: AtlasTexture= iconos[i].texture
		var k:= i if tiene(i) else VACIA
		a.region= Rect2(k* TAM, 0, TAM, TAM)
	marco.position= iconos[cursor].position- Vector2(3, 3)
	if tiene(cursor):
		titulo.text= LISTA[cursor][1]
		detalle.text =LISTA[cursor][2]
	else:
		titulo.text= "???"
		detalle.text ="Todavía no la ganaste."
	fichas.text= "Medallas: %d    Fichas de Desafío: %d" % [Estado.medallas.size(), Estado.fichas]

func _unhandled_input(event: InputEvent) -> void:
	if GestorEscenas.en_transicion:
		return
	if event.is_action_pressed("cancelar") or event.is_action_pressed("menu"):
		Sonido.efecto("cancelar")
		cerrado.emit()
	elif event.is_action_pressed("izquierda"):
		cursor= wrapi(cursor- 1, 0, HUECOS)
		Sonido.efecto("cursor")
	elif event.is_action_pressed("derecha"):
		cursor =wrapi(cursor+ 1, 0, HUECOS)
		Sonido.efecto("cursor")
	elif event.is_action_pressed("arriba") or event.is_action_pressed("abajo"):
		cursor= (cursor+ 4)% HUECOS
		Sonido.efecto("cursor")
	else:
		return
	get_viewport().set_input_as_handled()
	_pintar()
