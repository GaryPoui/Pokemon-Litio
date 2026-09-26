extends Control

@export var es_exp: bool= false

const VERDE:= [Color("009200"), Color("18c320")]
const AMARILLO :=[Color("b26908"), Color("fbb200")]
const ROJO:= [Color("aa3038"), Color("fb5928")]
const AZUL :=[Color("3061db"), Color("4992fb")]

var valor: float= 1.0

func poner(v: float) -> void:
	valor =clampf(v, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var colores: Array
	if es_exp:
		colores= AZUL
	elif valor> 0.5:
		colores =VERDE
	elif valor> 0.2:
		colores= AMARILLO
	else:
		colores =ROJO
	var ancho:= roundi(size.x* valor)
	if valor> 0.0 and ancho== 0:
		ancho= 1
	if ancho<= 0:
		return
	draw_rect(Rect2(0, 0, ancho, 1), colores[0])
	draw_rect(Rect2(0, 1, ancho, size.y- 1), colores[1])
