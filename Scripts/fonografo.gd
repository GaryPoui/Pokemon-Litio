extends Node2D

const TANGO:= preload("res://Scripts/tango.gd")

@export_multiline var texto: String= "Un fonógrafo viejo con un disco de pasta. Al darle cuerda suena un tango… y en la etiqueta del disco hay cuatro dibujitos, uno detrás del otro."

var figuras_mostradas: Array= []

func _ready() -> void:
	add_to_group("interactuable")

func celda() -> Vector2i:
	return Rejilla.celda(self)

func interactuar(_jugador: Node) -> void:
	var capa:= CanvasLayer.new()
	capa.layer= 41
	add_child(capa)
	var marco:= Panel.new()
	marco.add_theme_stylebox_override("panel", EstiloUI.pastilla())
	marco.size= Vector2(4+ TANGO.ORDEN.size()* 16, 14)
	marco.position =Vector2((256- marco.size.x)/ 2.0, 40)
	capa.add_child(marco)
	figuras_mostradas.clear()
	for i in TANGO.ORDEN.size():
		var t:= TextureRect.new()
		t.texture= TANGO.figura(TANGO.ORDEN[i])
		t.position =Vector2(4+ i* 16, 3)
		t.size= Vector2(12, 8)
		marco.add_child(t)
		figuras_mostradas.append(TANGO.ORDEN[i])
	Sonido.jingle("tango_completo")
	await Dialogo.mostrar(texto)
	if Sonido.sonando_jingle():
		await Sonido.jingle_terminado
	capa.queue_free()
