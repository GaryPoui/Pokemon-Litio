class_name ListaOpciones
extends Control

@export var tam_fuente: int= 9
@export var alto_fila: float =14.0
@export var columnas: int= 1

const ANCHO_CURSOR:= 10

var opciones: Array =[]
var cursor:= 0
var etiquetas: Array[Label]= []
var flecha: Label

func poner(lista: Array, inicio: int= 0) -> void:
	for l in etiquetas:
		l.queue_free()
	etiquetas.clear()
	if flecha== null:
		flecha= EstiloUI.nuevo_label("▶", 6, Vector2.ZERO)
		add_child(flecha)
	opciones= lista
	var ancho:= size.x/ columnas
	for i in lista.size():
		var l:= EstiloUI.nuevo_label(str(lista[i]), tam_fuente, _pos_fila(i, ancho)+ Vector2(ANCHO_CURSOR, 0))
		add_child(l)
		etiquetas.append(l)
	cursor =clampi(inicio, 0, maxi(0, lista.size()- 1))
	_pintar()

func _pos_fila(i: int, ancho: float) -> Vector2:
	return Vector2(2+ (i% columnas)* ancho, floori(i/ float(columnas))* alto_fila)

func mover(d: int) -> bool:
	var n:= cursor+ d
	if n< 0 or n>= opciones.size():
		return false
	cursor= n
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
	flecha.position= Vector2(fila.position.x- ANCHO_CURSOR, fila.position.y+ roundi((alto_texto- alto_flecha)/ 2.0))
