class_name Sortija
extends CanvasLayer

signal termino(sacadas: Array[int])

const PERIODOS:= [2.4, 1.8, 1.3]
const VENTANA :=0.12
const VUELTAS:= 3
const PAUSA :=0.8
const GRACIA:= 0.25
const CENTRO:= Vector2(128, 118)
const RADIO :=Vector2(62, 12)
const ARO:= Vector2(128, 96)
const ROJO :=Color("c8384a")
const BLANCO:= Color("f0ece0")
const ORO :=Color("f2c230")
const MADERA:= Color("8a5a36")
const CIELO :=Color("141c34")

var ronda:= 0
var t :=0.0
var jugando:= false
var pausa_hasta :=-1.0
var sacadas: Array[int]= []
var lienzo: Control
var titulo: Label
var ayuda: Label
var resultado: Label

static func paso(periodo_ronda: float) -> float:
	return periodo_ronda* 0.5

static func dentro(tiempo: float, periodo_ronda: float) -> bool:
	var d:= fposmod(tiempo- paso(periodo_ronda), periodo_ronda)
	return minf(d, periodo_ronda- d)<= VENTANA

func periodo() -> float:
	return float(PERIODOS[clampi(ronda, 0, PERIODOS.size()- 1)])

func _ready() -> void:
	layer= 106
	add_to_group("sortija")
	var fondo:= ColorRect.new()
	fondo.color =CIELO
	fondo.size= Vector2(256, 192)
	add_child(fondo)
	lienzo= Control.new()
	lienzo.size =Vector2(256, 192)
	lienzo.draw.connect(_dibujar)
	add_child(lienzo)
	titulo= EstiloUI.nuevo_label("", 8, Vector2(6, 2))
	add_child(titulo)
	resultado =EstiloUI.nuevo_label("", 8, Vector2(0, 136), ORO)
	resultado.size= Vector2(256, 14)
	resultado.horizontal_alignment= HORIZONTAL_ALIGNMENT_CENTER
	add_child(resultado)
	var caja:= Panel.new()
	caja.add_theme_stylebox_override("panel", EstiloUI.panel())
	caja.position =Vector2(4, 156)
	caja.size= Vector2(248, 32)
	add_child(caja)
	ayuda= Label.new()
	EstiloUI.fuente_batalla(ayuda)
	ayuda.add_theme_color_override("font_color", EstiloUI.TEXTO)
	ayuda.position= Vector2(10, 159)
	ayuda.size =Vector2(236, 26)
	ayuda.autowrap_mode= TextServer.AUTOWRAP_WORD_SMART
	ayuda.text= "Apretá A cuando tu caballito dorado pase justo debajo de la sortija."
	add_child(ayuda)
	_empezar(0)

func _empezar(k: int) -> void:
	ronda= k
	t =0.0
	jugando= true
	pausa_hasta= -1.0
	titulo.text= "LA SORTIJA - Ronda %d/%d" % [k+ 1, PERIODOS.size()]
	resultado.text =""

func _process(delta: float) -> void:
	t+= delta
	lienzo.queue_redraw()
	if pausa_hasta>= 0.0:
		if t>= pausa_hasta:
			if ronda+ 1< PERIODOS.size():
				_empezar(ronda+ 1)
			else:
				_terminar()
		return
	if not jugando:
		return
	if Input.is_action_just_pressed("aceptar") and t>= GRACIA:
		_resolver(dentro(t, periodo()))
	elif t> paso(periodo())+ periodo()* (VUELTAS- 1)+ VENTANA* 2.0:
		_resolver(false)

func _resolver(ok: bool) -> void:
	jugando= false
	if ok:
		sacadas.append(ronda)
		Sonido.efecto("confirmar")
		resultado.text= "¡Sacaste la sortija!"
	else:
		Sonido.efecto("menu_cerrar")
		resultado.text ="¡Uy! Se te escapó."
	var p:= periodo()
	pausa_hasta= ceilf((t+ PAUSA)/ p)* p

func _terminar() -> void:
	pausa_hasta =-1.0
	titulo.text= "LA SORTIJA"
	resultado.text= "Sacaste %d de %d" % [sacadas.size(), PERIODOS.size()]
	set_process(false)
	await get_tree().create_timer(1.0).timeout
	termino.emit(sacadas)
	queue_free()

func angulo() -> float:
	return -PI/ 2.0+ TAU* t/ periodo()

func _caballo(k: int) -> Dictionary:
	var a:= angulo()+ k* TAU/ 8.0
	var bob:= 3.0+ 2.0* sin(2.0* a+ k)
	var p:= CENTRO+ Vector2(RADIO.x* cos(a), RADIO.y* sin(a)- bob)
	return {"pos": p.round(), "frente": sin(a)> 0.0, "mira": -1 if sin(a)> 0.0 else 1}

func _dibujar_caballo(c: Dictionary, k: int) -> void:
	var p: Vector2= c["pos"]
	lienzo.draw_line(Vector2(p.x, 56), p+ Vector2(0, -6), ORO if k== 0 else Color("c8a060"), 1.0)
	var cuerpo:= ORO if k== 0 else (BLANCO if k% 2 else Color("a8c0e0"))
	lienzo.draw_rect(Rect2(p+ Vector2(-6, -5), Vector2(12, 5)), cuerpo)
	lienzo.draw_rect(Rect2(p+ Vector2(-6 if c["mira"]< 0 else 3, -9), Vector2(3, 5)), cuerpo)
	lienzo.draw_rect(Rect2(p+ Vector2(-5, 0), Vector2(1, 3)), cuerpo.darkened(0.3))
	lienzo.draw_rect(Rect2(p+ Vector2(4, 0), Vector2(1, 3)), cuerpo.darkened(0.3))
	if k== 0:
		lienzo.draw_colored_polygon(PackedVector2Array([p+ Vector2(-3, -15), p+ Vector2(3, -15), p+ Vector2(0, -11)]), ORO)

func _dibujar() -> void:
	var piso:= PackedVector2Array()
	var borde :=PackedVector2Array()
	for i in 32:
		var a:= TAU* i/ 32.0
		piso.append(CENTRO+ Vector2((RADIO.x+ 12)* cos(a), (RADIO.y+ 6)* sin(a)))
		borde.append(CENTRO+ Vector2((RADIO.x+ 12)* cos(a), (RADIO.y+ 6)* sin(a)+ 4))
	lienzo.draw_colored_polygon(borde, MADERA.darkened(0.4))
	lienzo.draw_colored_polygon(piso, MADERA)
	var caballos:= []
	for k in 8:
		caballos.append(_caballo(k))
	for k in 8:
		if not caballos[k]["frente"]:
			_dibujar_caballo(caballos[k], k)
	lienzo.draw_rect(Rect2(126, 56, 4, 62), Color("b04040"))
	lienzo.draw_rect(Rect2(127, 56, 1, 62), Color("e8a0a0"))
	for i in 8:
		var x0:= 52.0+ i* 19.0
		lienzo.draw_colored_polygon(PackedVector2Array([Vector2(128, 18), Vector2(x0, 52), Vector2(x0+ 19.0, 52)]), ROJO if i% 2== 0 else BLANCO)
		lienzo.draw_rect(Rect2(x0, 52, 19, 4), BLANCO if i% 2== 0 else ROJO)
	for k in 8:
		if caballos[k]["frente"]:
			_dibujar_caballo(caballos[k], k)
	lienzo.draw_rect(Rect2(232, 40, 3, 116), MADERA.darkened(0.2))
	lienzo.draw_rect(Rect2(128, 40, 106, 2), MADERA.darkened(0.2))
	lienzo.draw_line(Vector2(128, 42), ARO+ Vector2(0, -4), Color("d8d0c0"), 1.0)
	lienzo.draw_arc(ARO, 3.5, 0.0, TAU, 16, ORO, 2.0)
