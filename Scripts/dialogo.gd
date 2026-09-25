extends CanvasLayer

signal terminado

@export var letras_por_segundo: float= 45.0

@onready var caja: Panel =$Caja
@onready var texto: Label= $Caja/Texto
@onready var flecha: Label =$Caja/Flecha

var esta_abierto:= false
var paginas: PackedStringArray =[]
var pagina:= 0
var escribiendo :=false
var avance: float= 0.0

func _ready() -> void:
	layer= 110
	caja.visible =false
	var estilo:= StyleBoxFlat.new()
	estilo.bg_color =Color("f8f8f8")
	estilo.set_border_width_all(2)
	estilo.border_color= Color("3a4a6a")
	estilo.set_corner_radius_all(3)
	caja.add_theme_stylebox_override("panel", estilo)
	texto.add_theme_color_override("font_color", Color("303030"))
	texto.add_theme_font_size_override("font_size", 9)
	flecha.add_theme_color_override("font_color", Color("d04030"))
	flecha.add_theme_font_size_override("font_size", 7)

func mostrar(contenido: String) -> void:
	paginas =contenido.split("\n\n", false)
	if paginas.is_empty():
		return
	pagina= 0
	esta_abierto =true
	caja.visible= true
	_empezar_pagina()
	await terminado

func _empezar_pagina() -> void:
	texto.text= paginas[pagina]
	texto.visible_characters =0
	avance= 0.0
	escribiendo= true
	flecha.visible =false

func _process(delta: float) -> void:
	if not escribiendo:
		if esta_abierto:
			flecha.visible= fmod(Time.get_ticks_msec()/ 400.0, 2.0) <1.0
		return
	avance+= delta *letras_por_segundo
	texto.visible_characters =int(avance)
	if texto.visible_characters>= texto.get_total_character_count():
		texto.visible_characters= -1
		escribiendo =false

func _unhandled_input(event: InputEvent) -> void:
	if not esta_abierto:
		return
	if event.is_action_pressed("aceptar") or event.is_action_pressed("cancelar"):
		get_viewport().set_input_as_handled()
		if escribiendo:
			texto.visible_characters =-1
			escribiendo= false
			return
		pagina +=1
		if pagina< paginas.size():
			_empezar_pagina()
		else:
			_cerrar()

func _cerrar() -> void:
	caja.visible= false
	flecha.visible =false
	esta_abierto= false
	terminado.emit()
