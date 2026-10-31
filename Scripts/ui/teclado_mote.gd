extends CanvasLayer

signal listo(texto: String)

const FONDO:= preload("res://Assets/Fondos/opciones.png")
const MAX:= 10
const JUEGOS :=[
	["ABCDEFGHIJ", "KLMNÑOPQRS", "TUVWXYZ .,", "ÁÉÍÓÚÜ-!?♂"],
	["abcdefghij", "klmnñopqrs", "tuvwxyz .,", "áéíóúü-!?♀"],
	["0123456789", "!?¡¿.,-'&/", "♂♀()+:;% ", "          "],
]
const BOTONES:= ["ABC/abc/123", "BORRAR", "OK"]
const X0:= 24
const Y0 :=78
const PASO_X:= 21
const PASO_Y :=17
const ANCHO_LETRA:= 13

var texto:= ""
var juego :=0
var fila:= 0
var col :=0
var celdas: Array= []
var botones: Array[Label]= []
var campo: Label
var cursor: Panel
var activo:= false

func _ready() -> void:
	layer= 108

func armar(p: PokemonInstancia) -> void:
	var fondo:= TextureRect.new()
	fondo.texture= FONDO
	add_child(fondo)
	var cab:= Panel.new()
	cab.position= Vector2(6, 6)
	cab.size =Vector2(244, 54)
	cab.add_theme_stylebox_override("panel", EstiloUI.madera())
	add_child(cab)
	var hoja:= Panel.new()
	hoja.position= Vector2(4, 4)
	hoja.size =Vector2(236, 46)
	hoja.add_theme_stylebox_override("panel", EstiloUI.hoja())
	cab.add_child(hoja)
	var ruta:= "res://Assets/Pokemones/iconos/%s.png" % p.especie.id
	if ResourceLoader.exists(ruta):
		var at:= AtlasTexture.new()
		at.atlas= load(ruta)
		at.region =Rect2(0, 0, 32, 32)
		var ic:= TextureRect.new()
		ic.name= "Icono"
		ic.texture= at
		ic.position =EstiloUI.posicion_icono(at.atlas, 2, Vector2(20, 23), false)
		ic.texture_filter= CanvasItem.TEXTURE_FILTER_NEAREST
		hoja.add_child(ic)
	hoja.add_child(EstiloUI.nuevo_label("Mote de %s" % p.especie.nombre, 8, Vector2(42, 4), EstiloUI.TENUE))
	campo= EstiloUI.nuevo_label("", 9, Vector2(42, 20))
	campo.name= "Campo"
	hoja.add_child(campo)
	var abajo:= Panel.new()
	abajo.position= Vector2(6, 64)
	abajo.size =Vector2(244, 122)
	abajo.add_theme_stylebox_override("panel", EstiloUI.panel())
	add_child(abajo)
	cursor= Panel.new()
	cursor.add_theme_stylebox_override("panel", EstiloUI.panel(Color(1, 0.85, 0.3, 0.25), Color("ffd84a")))
	cursor.mouse_filter =Control.MOUSE_FILTER_IGNORE
	add_child(cursor)
	for f in 4:
		var linea: Array[Label]= []
		for c in 10:
			var l:= EstiloUI.nuevo_label("", 9, Vector2(X0+ c* PASO_X- 3, Y0+ f* PASO_Y))
			l.size.x= ANCHO_LETRA
			l.horizontal_alignment= HORIZONTAL_ALIGNMENT_CENTER
			add_child(l)
			linea.append(l)
		celdas.append(linea)
	for k in BOTONES.size():
		var b:= EstiloUI.nuevo_label(BOTONES[k], 8, Vector2(X0+ [0, 96, 176][k], Y0+ 4* PASO_Y+ 4))
		b.name= "Boton%d" % k
		add_child(b)
		botones.append(b)
	add_child(EstiloUI.nuevo_label("B: borrar   MENÚ: listo", 6, Vector2(10, 176), EstiloUI.TENUE))
	_pintar()

func esperar() -> String:
	activo= true
	var r: String= await listo
	activo =false
	return r.strip_edges()

func _pintar() -> void:
	var j: Array= JUEGOS[juego]
	for f in 4:
		for c in 10:
			var ch: String= j[f][c] if c< j[f].length() else " "
			celdas[f][c].text= ch
	var vacios:= MAX- texto.length()
	campo.text= texto+ "_".repeat(vacios)
	if fila< 4:
		cursor.position= Vector2(X0+ col* PASO_X- 3+ (ANCHO_LETRA- 17)/ 2.0, Y0+ fila* PASO_Y- 1).round()
		cursor.size =Vector2(17, 16)
	else:
		var b:= botones[col]
		cursor.position= b.position- Vector2(4, 1)
		cursor.size= Vector2(b.get_combined_minimum_size().x+ 8, 16)

func _unhandled_input(event: InputEvent) -> void:
	if not activo:
		return
	if event.is_action_pressed("derecha"):
		col= wrapi(col+ 1, 0, 10 if fila< 4 else BOTONES.size())
	elif event.is_action_pressed("izquierda"):
		col =wrapi(col- 1, 0, 10 if fila< 4 else BOTONES.size())
	elif event.is_action_pressed("abajo"):
		_mover_fila(1)
	elif event.is_action_pressed("arriba"):
		_mover_fila(-1)
	elif event.is_action_pressed("aceptar"):
		_aceptar()
	elif event.is_action_pressed("cancelar"):
		_borrar()
	elif event.is_action_pressed("menu"):
		Sonido.efecto("confirmar")
		listo.emit(texto)
	else:
		return
	get_viewport().set_input_as_handled()
	Sonido.efecto("cursor")
	_pintar()

func _mover_fila(d: int) -> void:
	var antes:= fila
	fila= wrapi(fila+ d, 0, 5)
	if antes< 4 and fila== 4:
		col= mini(floori(col/ 4.0), BOTONES.size()- 1)
	elif antes== 4 and fila< 4:
		col =[0, 4, 8][col]

func escribir(t: String) -> void:
	for ch in t:
		if texto.length()< MAX:
			texto+= ch
	_pintar()

func _aceptar() -> void:
	if fila== 4:
		match col:
			0:
				juego= (juego+ 1)% JUEGOS.size()
			1:
				_borrar()
			2:
				Sonido.efecto("confirmar")
				listo.emit(texto)
		return
	var ch: String= celdas[fila][col].text
	if texto.length()< MAX:
		texto+= ch
	if texto.length()== MAX:
		fila= 4
		col =2

func _borrar() -> void:
	if texto.length()> 0:
		texto= texto.substr(0, texto.length()- 1)
