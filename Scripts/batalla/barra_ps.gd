extends Control

@export var es_exp: bool= false
@export var estilo_bw :=false

const VERDE:= [Color("009200"), Color("18c320")]
const AMARILLO :=[Color("b26908"), Color("fbb200")]
const ROJO:= [Color("aa3038"), Color("fb5928")]
const AZUL :=[Color("3061db"), Color("4992fb")]
const BW_VERDE:= [Color(0.388, 1.0, 0.388), Color(0.094, 0.776, 0.129)]
const BW_AMARILLO :=[Color(1.0, 0.871, 0.0), Color(0.937, 0.678, 0.0)]
const BW_ROJO:= [Color(1.0, 0.612, 0.612), Color(1.0, 0.29, 0.224)]

var valor: float= 1.0

func poner(v: float) -> void:
	valor =clampf(v, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var colores: Array
	if es_exp:
		colores= AZUL
	elif valor> 0.5:
		colores =BW_VERDE if estilo_bw else VERDE
	elif valor> 0.2:
		colores= BW_AMARILLO if estilo_bw else AMARILLO
	else:
		colores =BW_ROJO if estilo_bw else ROJO
	var ancho:= roundi(size.x* valor)
	if valor> 0.0 and ancho== 0:
		ancho= 1
	if ancho<= 0:
		return
	draw_rect(Rect2(0, 0, ancho, 1), colores[0])
	draw_rect(Rect2(0, 1, ancho, size.y- 1), colores[1])
