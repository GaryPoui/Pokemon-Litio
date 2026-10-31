class_name ListaOpciones
extends Control

@export var tam_fuente: int= 9
@export var alto_fila: float =14.0
@export var columnas: int= 1
@export var max_visibles :int= 0
@export var sangria: float= 0.0

const ANCHO_CURSOR:= 10
const ANCHO_FLECHAS :=8

var opciones: Array =[]
var cursor:= 0
var arriba :=0
var etiquetas: Array[Label]= []
var flecha: Label
var flecha_arriba: Label
var flecha_abajo :Label
var color :Color= EstiloUI.TEXTO

func poner(lista: Array, inicio: int= 0) -> void:
	for l in etiquetas:
		l.queue_free()
	etiquetas.clear()
	if flecha== null:
		flecha= EstiloUI.nuevo_label("▶", 6, Vector2.ZERO, color)
		add_child(flecha)
		flecha_arriba =EstiloUI.nuevo_label("▲", 8, Vector2.ZERO, color)
		flecha_abajo= EstiloUI.nuevo_label("▼", 8, Vector2.ZERO, color)
		for f in [flecha_arriba, flecha_abajo]:
			EstiloUI.fuente_batalla(f)
			add_child(f)
	opciones= lista
	for i in lista.size():
		var l:= EstiloUI.nuevo_label(str(lista[i]), tam_fuente, Vector2.ZERO, color)
		add_child(l)
		etiquetas.append(l)
	cursor =clampi(inicio, 0, maxi(0, lista.size()- 1))
	arriba= 0
	_ajustar_ventana()
	_pintar()

func refrescar() -> void:
	_ajustar_ventana()
	_pintar()

func filas_visibles() -> int:
	var filas:= ceili(opciones.size()/ float(columnas))
	return filas if max_visibles<= 0 or columnas> 1 else mini(max_visibles, filas)

func desplaza() -> bool:
	return columnas== 1 and max_visibles> 0 and opciones.size()> max_visibles

func ancho_necesario() -> float:
	var mx:= 0.0
	for l in etiquetas:
		mx= maxf(mx, l.get_combined_minimum_size().x)
	return 2.0+ ANCHO_CURSOR+ sangria+ mx+ (ANCHO_FLECHAS+ 2.0 if desplaza() else 0.0)

func alto_necesario() -> float:
	return filas_visibles()* alto_fila

func _pos_fila(i: int, ancho: float) -> Vector2:
	return Vector2(2+ (i% columnas)* ancho, floori(i/ float(columnas))* alto_fila)

func _ajustar_ventana() -> void:
	var ancho:= size.x/ columnas
	var v:= filas_visibles()
	if desplaza():
		if cursor< arriba:
			arriba= cursor
		elif cursor>= arriba+ v:
			arriba =cursor- v+ 1
	else:
		arriba= 0
	for i in etiquetas.size():
		var dentro:= i>= arriba and i< arriba+ v if desplaza() else true
		etiquetas[i].visible= dentro
		etiquetas[i].position =_pos_fila(i- arriba, ancho)+ Vector2(ANCHO_CURSOR+ sangria, 0)
	if flecha_arriba== null:
		return
	flecha_arriba.visible= desplaza() and arriba> 0
	flecha_abajo.visible =desplaza() and arriba+ v< opciones.size()
	var alto_flecha:= flecha_arriba.get_combined_minimum_size()
	flecha_arriba.position= Vector2(size.x- alto_flecha.x, 0)
	flecha_abajo.position =Vector2(size.x- alto_flecha.x, (v- 1)* alto_fila+ alto_fila- alto_flecha.y)

func mover(d: int) -> bool:
	var n:= cursor+ d
	if n< 0 or n>= opciones.size():
		return false
	cursor= n
	_ajustar_ventana()
	_pintar()
	Sonido.efecto("cursor")
	return true

func mover_con_evento(event: InputEvent) -> bool:
	if event.is_action_pressed("arriba"):
		mover(-columnas)
	elif event.is_action_pressed("abajo"):
		mover(columnas)
	elif columnas> 1 and event.is_action_pressed("izquierda"):
		mover(-1)
	elif columnas> 1 and event.is_action_pressed("derecha"):
		mover(1)
	else:
		return false
	return true

func _pintar() -> void:
	flecha.visible= not etiquetas.is_empty()
	if etiquetas.is_empty():
		return
	var fila:= etiquetas[cursor]
	var alto_texto:= fila.get_combined_minimum_size().y
	var alto_flecha :=flecha.get_combined_minimum_size().y
	flecha.position= Vector2(fila.position.x- ANCHO_CURSOR- sangria, fila.position.y+ roundi((alto_texto- alto_flecha)/ 2.0))
