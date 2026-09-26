extends CanvasLayer

signal cerrado

const BUSES:= ["Musica", "Efectos", "Gritos"]
const FILA_PANTALLA :=3
const FILA_PRUEBA:= 4
const GRITO_PRUEBA :=495

@onready var caja: Panel= $Caja
@onready var cursor_lbl: Label =$Caja/Cursor

var fila:= 0
var prueba :=0
var efectos: Array[String]= []

func _ready() -> void:
	layer= 106
	caja.add_theme_stylebox_override("panel", EstiloUI.panel())
	EstiloUI.label($Caja/Titulo, 9)
	EstiloUI.label($Caja/Ayuda, 6)
	EstiloUI.label(cursor_lbl, 6)
	$Caja/Ayuda.text= "izq/der: cambiar     X: volver"
	for i in 5:
		EstiloUI.label(caja.get_node("F%d/Nombre" % i), 9)
		EstiloUI.label(caja.get_node("F%d/Valor" % i), 9)
	for f in DirAccess.get_files_at(Sonido.EFECTOS):
		var n:= f.trim_suffix(".import").trim_suffix(".remap")
		if n.ends_with(".wav") and not efectos.has(n.get_basename()):
			efectos.append(n.get_basename())
	efectos.sort()
	_pintar()

func abrir() -> void:
	_pintar()

func _pintar() -> void:
	for i in BUSES.size():
		var v: float= Sonido.volumen(BUSES[i])
		caja.get_node("F%d/Barra" % i).poner(v)
		(caja.get_node("F%d/Valor" % i) as Label).text= str(roundi(v* 10))
	(caja.get_node("F%d/Valor" % FILA_PANTALLA) as Label).text ="SÍ" if GestorEscenas.es_pantalla_completa() else "NO"
	(caja.get_node("F%d/Valor" % FILA_PRUEBA) as Label).text= "◀ %s ▶" % (efectos[prueba] if not efectos.is_empty() else "-")
	var f: Control= caja.get_node("F%d" % fila)
	cursor_lbl.position.y =f.position.y+ 3

func _unhandled_input(event: InputEvent) -> void:
	if GestorEscenas.en_transicion:
		return
	if event.is_action_pressed("cancelar") or event.is_action_pressed("menu"):
		Sonido.guardar_config()
		Sonido.efecto("cancelar")
		cerrado.emit()
	elif event.is_action_pressed("arriba"):
		fila= wrapi(fila- 1, 0, 5)
		Sonido.efecto("cursor")
	elif event.is_action_pressed("abajo"):
		fila =wrapi(fila+ 1, 0, 5)
		Sonido.efecto("cursor")
	elif event.is_action_pressed("izquierda"):
		_cambiar(-1)
	elif event.is_action_pressed("derecha"):
		_cambiar(1)
	elif event.is_action_pressed("aceptar"):
		if fila== FILA_PANTALLA:
			_cambiar(1)
		elif fila== FILA_PRUEBA and not efectos.is_empty():
			Sonido.efecto(efectos[prueba])
	else:
		return
	_pintar()
	get_viewport().set_input_as_handled()

func _cambiar(d: int) -> void:
	if fila< BUSES.size():
		var bus: String= BUSES[fila]
		Sonido.poner_volumen(bus, Sonido.volumen(bus)+ 0.1* d)
		if bus== "Gritos":
			Sonido.grito(GRITO_PRUEBA)
		else:
			Sonido.efecto("cursor")
	elif fila== FILA_PANTALLA:
		GestorEscenas.alternar_pantalla_completa()
		Sonido.efecto("confirmar")
	elif not efectos.is_empty():
		prueba= wrapi(prueba+ d, 0, efectos.size())
		Sonido.efecto(efectos[prueba])
