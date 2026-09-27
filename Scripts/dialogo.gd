extends CanvasLayer

signal terminado
signal elegido(indice: int)

@export var letras_por_segundo: float= 45.0

@onready var caja: Panel =$Caja
@onready var texto: Label= $Caja/Texto
@onready var flecha: Label =$Caja/Flecha
@onready var caja_opciones: Panel= $Opciones
@onready var lista: ListaOpciones =$Opciones/Lista

var esta_abierto:= false
var paginas: PackedStringArray =[]
var pagina:= 0
var escribiendo :=false
var avance: float= 0.0
var eligiendo:= false
var preguntando :=false
var lineas: Array[String]= []
var arriba:= 0
var esperando_scroll :=false
var desplazando:= false
var base_y :=0.0

const LINEAS_VISIBLES:= 2

func _ready() -> void:
	layer= 110
	caja.visible =false
	var estilo:= StyleBoxFlat.new()
	estilo.bg_color =Color("f8f8f8")
	estilo.set_border_width_all(2)
	estilo.border_color= Color("3a4a6a")
	estilo.set_corner_radius_all(3)
	caja.add_theme_stylebox_override("panel", estilo)
	caja_opciones.add_theme_stylebox_override("panel", EstiloUI.panel())
	caja_opciones.visible= false
	EstiloUI.label(texto, 9)
	var zona:= texto.get_rect()
	var ventana:= Control.new()
	ventana.name= "Ventana"
	ventana.clip_contents =true
	ventana.mouse_filter= Control.MOUSE_FILTER_IGNORE
	caja.add_child(ventana)
	ventana.position= zona.position
	ventana.size =zona.size
	texto.reparent(ventana, false)
	texto.anchor_right= 0.0
	texto.anchor_bottom =0.0
	texto.position= Vector2.ZERO
	texto.size =zona.size
	base_y= 0.0
	EstiloUI.fuente_batalla(flecha)
	flecha.add_theme_color_override("font_color", Color("d04030"))

func mostrar(contenido: String) -> void:
	paginas =contenido.split("\n\n", false)
	if paginas.is_empty():
		return
	pagina= 0
	esta_abierto =true
	caja.visible= true
	_empezar_pagina()
	await terminado

func preguntar(contenido: String, opciones: Array= ["SÍ", "NO"]) -> int:
	preguntando= true
	paginas= PackedStringArray([contenido])
	pagina =0
	esta_abierto= true
	caja.visible =true
	_empezar_pagina()
	while escribiendo:
		await get_tree().process_frame
	flecha.visible= false
	caja_opciones.size.y =10+ opciones.size()* 12
	caja_opciones.position.y= 142- caja_opciones.size.y
	var ancho:= 56.0
	for o in opciones:
		ancho= maxf(ancho, texto.get_theme_font("font").get_string_size(str(o), HORIZONTAL_ALIGNMENT_LEFT, -1, texto.get_theme_font_size("font_size")).x+ 24.0)
	caja_opciones.size.x =ancho
	caja_opciones.position.x= 252.0- ancho
	lista.size.x= ancho- 8.0
	lista.poner(opciones)
	caja_opciones.visible= true
	eligiendo =true
	var r: int= await elegido
	eligiendo= false
	preguntando =false
	caja_opciones.visible =false
	_cerrar()
	return r

func _empezar_pagina() -> void:
	lineas= EstiloUI.envolver(paginas[pagina], texto, texto.size.x)
	arriba =0
	texto.position.y= base_y
	_mostrar_lineas()
	texto.visible_characters =0
	avance= 0.0
	escribiendo= true
	esperando_scroll =false
	flecha.visible =false

func _mostrar_lineas() -> void:
	texto.text= "\n".join(lineas.slice(arriba, arriba+ LINEAS_VISIBLES))

func _quedan_lineas() -> bool:
	return arriba+ LINEAS_VISIBLES< lineas.size()

func _terminar_visible() -> void:
	texto.visible_characters= -1
	if _quedan_lineas():
		esperando_scroll =true
	else:
		escribiendo= false

func _process(delta: float) -> void:
	if desplazando:
		return
	if esperando_scroll or not escribiendo:
		if esta_abierto and not eligiendo:
			flecha.visible= fmod(Time.get_ticks_msec()/ 400.0, 2.0) <1.0
		return
	avance+= delta *letras_por_segundo
	texto.visible_characters =int(avance)
	if texto.visible_characters>= texto.get_total_character_count():
		_terminar_visible()

func _desplazar() -> void:
	esperando_scroll= false
	desplazando =true
	flecha.visible= false
	var t:= create_tween()
	t.tween_property(texto, "position:y", base_y- EstiloUI.alto_linea(texto), 0.12)
	await t.finished
	arriba+= 1
	_mostrar_lineas()
	texto.position.y= base_y
	avance =float(lineas[arriba].length())
	texto.visible_characters= int(avance)
	desplazando =false

func _unhandled_input(event: InputEvent) -> void:
	if not esta_abierto:
		return
	if eligiendo:
		if event.is_action_pressed("aceptar"):
			Sonido.efecto("confirmar")
			elegido.emit(lista.cursor)
		elif event.is_action_pressed("cancelar"):
			Sonido.efecto("cancelar")
			elegido.emit(-1)
		elif not lista.mover_con_evento(event):
			return
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("aceptar") or event.is_action_pressed("cancelar"):
		get_viewport().set_input_as_handled()
		if desplazando:
			return
		if esperando_scroll:
			_desplazar()
			return
		if escribiendo:
			_terminar_visible()
			return
		if preguntando:
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
