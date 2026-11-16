class_name Tango
extends Node2D

const ORDEN:= [2, 0, 3, 1]
const FIGURAS :=["sube", "baja", "ondula", "salta"]
const NOCHE:= Color(0.55, 0.55, 0.8)
const ICONOS:= preload("res://Assets/UI/figuras_tango.png")

@export var clave:= "tango_completo"
@export_multiline var texto_completo :String= "El último acorde quedó flotando en el aire… y a lo lejos sonaron las campanadas de medianoche. El Abasto se llenó de sombras."

var progreso:= 0
var capa: CanvasLayer
var marco: Panel
var casillas: Array= []

static func figura(frase: int) -> AtlasTexture:
	var a:= AtlasTexture.new()
	a.atlas= ICONOS
	a.region =Rect2(12* frase, 0, 12, 8)
	return a

func _ready() -> void:
	_armar()
	if Estado.tiene(clave):
		progreso= ORDEN.size()
		_noche(false)

func _armar() -> void:
	capa= CanvasLayer.new()
	capa.layer= 40
	add_child(capa)
	marco =Panel.new()
	marco.add_theme_stylebox_override("panel", EstiloUI.pastilla())
	marco.position= Vector2(4, 4)
	marco.size =Vector2(4+ ORDEN.size()* 16, 14)
	marco.visible= false
	capa.add_child(marco)
	for i in ORDEN.size():
		var t:= TextureRect.new()
		t.position= Vector2(4+ i* 16, 3)
		t.size= Vector2(12, 8)
		marco.add_child(t)
		casillas.append(t)

func tocar(frase: int) -> void:
	if Estado.tiene(clave):
		return
	if frase== ORDEN[progreso]:
		casillas[progreso].texture= figura(frase)
		progreso+= 1
		marco.visible =true
		if progreso== ORDEN.size():
			await _completar()
		return
	Sonido.efecto("tango_error")
	progreso= 0
	for c in casillas:
		c.texture= null
	marco.visible= false

func _completar() -> void:
	Estado.marcar(clave)
	var j= get_parent().get_node_or_null("Jugador")
	if j!= null:
		j.en_evento= true
	await Sonido.jingle("tango_completo")
	Sonido.efecto("campanadas")
	var t= _noche(true)
	if t!= null:
		await t.finished
	await Dialogo.mostrar(texto_completo)
	marco.visible= false
	if j!= null and is_instance_valid(j):
		j.en_evento =false

func _noche(fundido: bool) -> Tween:
	var m:= CanvasModulate.new()
	m.name= "Noche"
	get_parent().add_child.call_deferred(m)
	if not fundido:
		m.color= NOCHE
		return null
	m.color= Color.WHITE
	var t:= create_tween()
	t.tween_property(m, "color", NOCHE, 1.5)
	return t
