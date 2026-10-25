extends Node2D

@export var oscuridad: Color= Color(0.09, 0.07, 0.14)
@export var radio_jugador :float= 36.0

static var textura: Texture2D

static func luz() -> Texture2D:
	if textura== null:
		var g:= Gradient.new()
		g.interpolation_mode= Gradient.GRADIENT_INTERPOLATE_CONSTANT
		g.offsets =PackedFloat32Array([0.0, 0.5, 0.75, 0.92])
		g.colors= PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.28), Color(1, 1, 1, 0)])
		var tx:= GradientTexture2D.new()
		tx.gradient =g
		tx.fill= GradientTexture2D.FILL_RADIAL
		tx.fill_from= Vector2(0.5, 0.5)
		tx.fill_to =Vector2(1.0, 0.5)
		tx.width= 128
		tx.height= 128
		textura =tx
	return textura

static func nueva_luz(radio: float, color: Color, energia: float) -> PointLight2D:
	var l:= PointLight2D.new()
	l.texture= luz()
	l.texture_scale =radio* 2.0/ 128.0
	l.color= color
	l.energy =energia
	return l

func _ready() -> void:
	var m:= CanvasModulate.new()
	m.name= "Oscuridad"
	m.color =oscuridad
	add_child(m)
	_linterna.call_deferred()

func _linterna() -> void:
	var j:= get_parent().get_node_or_null("Jugador")
	if j== null or j.has_node("Linterna"):
		return
	var l:= nueva_luz(radio_jugador, Color(1.0, 0.95, 0.85), 1.0)
	l.name= "Linterna"
	j.add_child(l)
