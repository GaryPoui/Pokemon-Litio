extends CanvasLayer

signal elegido(indice: int)

const UI:= "res://Assets/Batalla/ui_nueva/"
const BOTONES_TIPO :="res://Assets/Botones/tipos/"
const APAGADO:= Color(0.78, 0.78, 0.78)
const X_IZQ :=16.0
const EMPUJE:= 6.0
const SALIR:= 4

@onready var tablero: NinePatchRect= $Tablero
@onready var titulo: Label =$Tablero/Titulo
@onready var mano: TextureRect= $Tablero/Mano
@onready var flecha: Label =$Tablero/Flecha
@onready var salir: NinePatchRect= $Tablero/Salir
@onready var nuevo_btn: NinePatchRect =$Tablero/N
@onready var detalles: Panel= $Detalles
@onready var izq: Control =$Detalles/Izq
@onready var der: Control= $Detalles/Der

var pokemon: PokemonInstancia
var nuevo: Movimiento
var cursor:= 0
var ultimo_izq :=0
var activo:= false

func _ready() -> void:
	layer= 105
	detalles.add_theme_stylebox_override("panel", EstiloUI.panel())
	for l in [titulo, $Tablero/Nuevo, flecha]:
		EstiloUI.label(l, 9, Color.WHITE)
		EstiloUI.fuente_batalla(l)
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	$Tablero/Nuevo.add_theme_color_override("font_color", Color("f8e070"))
	for b in _botones()+ [nuevo_btn, salir]:
		var t: Label= b.get_node("Texto")
		EstiloUI.label(t, 9, Color.WHITE)
		EstiloUI.fuente_batalla(t)
		t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	for lado in [izq, der]:
		EstiloUI.label(lado.get_node("Nombre"), 9)
		EstiloUI.fuente_batalla(lado.get_node("Nombre"))
		EstiloUI.label(lado.get_node("Datos"), 8, Color("50607a"))
		EstiloUI.fuente_batalla(lado.get_node("Datos"))
		EstiloUI.label(lado.get_node("Desc"), 8)
		EstiloUI.fuente_batalla(lado.get_node("Desc"))
		lado.get_node("Desc").add_theme_constant_override("line_spacing", -3)
	$Detalles/Separador.color= Color("a8adc0")
	for n in _capas():
		n.modulate.a =0.0

func _capas() -> Array:
	return [$Oscuro, tablero, detalles]

func _botones() -> Array:
	return [$Tablero/M0, $Tablero/M1, $Tablero/M2, $Tablero/M3]

func elegir(p: PokemonInstancia, m: Movimiento) -> int:
	pokemon= p
	nuevo =m
	titulo.text= "¿Qué movimiento olvidará %s?" % p.nombre()
	for i in 4:
		var b: NinePatchRect= _botones()[i]
		b.visible= i< p.movimientos.size()
		if b.visible:
			_boton(b, p.movimientos[i])
	_boton(nuevo_btn, m)
	salir.get_node("Texto").text ="No aprender"
	cursor= 0
	ultimo_izq =0
	_pintar(false)
	var entrada:= create_tween().set_parallel()
	for n in _capas():
		entrada.tween_property(n, "modulate:a", 1.0, 0.18)
	await entrada.finished
	activo= true
	var r: int= await elegido
	activo =false
	var salida:= create_tween().set_parallel()
	for n in _capas():
		salida.tween_property(n, "modulate:a", 0.0, 0.15)
	await salida.finished
	return r

func _boton(b: NinePatchRect, m: Movimiento) -> void:
	b.texture= load(BOTONES_TIPO+ "%s.png" % m.tipo)
	b.get_node("Texto").text =m.nombre
	b.get_node("Tipo").texture= load(UI+ "tipos/%s.png" % m.tipo)

func _pintar(animar: bool) -> void:
	for i in 4:
		var b: NinePatchRect= _botones()[i]
		if not b.visible:
			continue
		var x:= X_IZQ+ (EMPUJE if i== cursor else 0.0)
		if animar:
			create_tween().tween_property(b, "position:x", x, 0.08)
		else:
			b.position.x =x
		b.self_modulate= Color.WHITE if i== cursor else APAGADO
	salir.self_modulate =Color.WHITE if cursor== SALIR else APAGADO
	flecha.visible= cursor!= SALIR
	if cursor== SALIR:
		mano.position= Vector2(salir.position.x- 11, salir.position.y+ 3)
		_vacio(izq)
	else:
		var bs: NinePatchRect= _botones()[cursor]
		mano.position =Vector2(X_IZQ+ EMPUJE- 11, bs.position.y+ 3)
		flecha.position.y= bs.position.y
		_detalle(izq, pokemon.movimientos[cursor], pokemon.pp[cursor] if cursor< pokemon.pp.size() else pokemon.movimientos[cursor].pp)
	_detalle(der, nuevo, nuevo.pp)

func _detalle(lado: Control, m: Movimiento, pp_actual: int) -> void:
	lado.get_node("Nombre").text= m.nombre
	lado.get_node("Tipo").texture =load(UI+ "tipos/%s.png" % m.tipo)
	lado.get_node("Cat").texture= load(UI+ "categoria_%s.png" % m.categoria)
	var pot:= str(m.poder) if m.categoria!= "estado" and m.poder> 0 else "-"
	var prec:= str(m.precision) if m.precision> 0 else "-"
	lado.get_node("Datos").text ="Pot %s Prec %s  PP %d/%d" % [pot, prec, pp_actual, m.pp]
	lado.get_node("Desc").text= m.descripcion

func _vacio(lado: Control) -> void:
	lado.get_node("Nombre").text= "No aprender"
	lado.get_node("Tipo").texture =null
	lado.get_node("Cat").texture= null
	lado.get_node("Datos").text =""
	lado.get_node("Desc").text= "%s conservará sus cuatro movimientos." % pokemon.nombre()

func _unhandled_input(event: InputEvent) -> void:
	if not activo:
		return
	var total:= pokemon.movimientos.size()
	if event.is_action_pressed("aceptar"):
		Sonido.efecto("confirmar")
		elegido.emit(cursor if cursor!= SALIR else -1)
	elif event.is_action_pressed("cancelar"):
		Sonido.efecto("cancelar")
		elegido.emit(-1)
	elif event.is_action_pressed("arriba") and cursor!= SALIR:
		cursor =maxi(0, cursor- 1)
		Sonido.efecto("cursor")
		_pintar(true)
	elif event.is_action_pressed("abajo") and cursor!= SALIR:
		cursor= mini(total- 1, cursor+ 1)
		Sonido.efecto("cursor")
		_pintar(true)
	elif event.is_action_pressed("derecha") and cursor!= SALIR:
		ultimo_izq= cursor
		cursor =SALIR
		Sonido.efecto("cursor")
		_pintar(true)
	elif event.is_action_pressed("izquierda") and cursor== SALIR:
		cursor= ultimo_izq
		Sonido.efecto("cursor")
		_pintar(true)
	else:
		return
	get_viewport().set_input_as_handled()
