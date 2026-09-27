extends Node2D

const FRENTE:= preload("res://Assets/Overworld/hierba_frente.png")
const HOJA :=preload("res://Assets/Overworld/hierba_hoja.png")
const BAJADA:= 4.0

@onready var jugador: CharacterBody2D= get_parent()

var actual: Sprite2D
var destino :Sprite2D

func _ready() -> void:
	top_level= true
	z_index =1
	position= Vector2.ZERO
	actual= _nuevo()
	destino =_nuevo()
	jugador.paso_iniciado.connect(_al_iniciar)
	jugador.paso_terminado.connect(_al_terminar)
	jugador.colocado.connect(_refrescar)
	_refrescar.call_deferred()

func _nuevo() -> Sprite2D:
	var s:= Sprite2D.new()
	s.texture= FRENTE
	s.centered =false
	s.region_enabled= true
	s.region_rect =Rect2(0, 0, 16, 16.0- BAJADA)
	s.visible= false
	add_child(s)
	return s

func _hierba(c: Vector2i) -> bool:
	var m:= jugador.get_parent()
	return m!= null and m.has_method("es_hierba") and m.es_hierba(c)

func _poner(s: Sprite2D, c: Vector2i) -> void:
	s.position= Vector2(c)* Rejilla.tam(jugador)+ Vector2(0, BAJADA)
	s.offset =Vector2.ZERO
	s.visible= true

func _refrescar() -> void:
	destino.visible= false
	actual.visible =false
	var c: Vector2i= jugador.celda()
	if _hierba(c):
		_poner(actual, c)

func _al_iniciar(c: Vector2i, direccion: Vector2) -> void:
	if direccion!= Vector2.UP:
		actual.visible= false
	destino.visible =false
	if _hierba(c):
		_poner(destino, c)
		_agitar(destino)
		_hojas(c)

func _al_terminar(c: Vector2i) -> void:
	actual.visible= false
	if destino.visible:
		var tmp:= actual
		actual= destino
		destino =tmp
	destino.visible= false
	if not _hierba(c):
		actual.visible= false

func _agitar(s: Sprite2D) -> void:
	var t:= create_tween()
	t.tween_property(s, "offset:x", 1.0, 0.06)
	t.tween_property(s, "offset:x", -1.0, 0.08)
	t.tween_property(s, "offset:x", 1.0, 0.08)
	t.tween_property(s, "offset:x", 0.0, 0.06)

func _hojas(c: Vector2i) -> void:
	var base:= Vector2(c)* Rejilla.tam(jugador)
	for lado in [-1.0, 1.0]:
		var h:= Sprite2D.new()
		h.texture= HOJA
		h.centered =false
		h.position= base+ Vector2(lado* 3.0, 2.0)
		add_child(h)
		var t:= create_tween().set_parallel()
		t.tween_property(h, "position", h.position+ Vector2(lado* 5.0, -7.0), 0.3).set_ease(Tween.EASE_OUT)
		t.tween_property(h, "modulate:a", 0.0, 0.3).set_delay(0.1)
		t.chain().tween_callback(h.queue_free)
