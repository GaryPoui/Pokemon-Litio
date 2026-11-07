extends Node2D

@export var objetivo: String= ""
@export var radio :float= 10.0

const CELESTE :=Color(0.62, 0.9, 1.0)
const BRILLO := Color(0.92, 1.0, 1.0)

var blanco: Node2D
var centro := Vector2.ZERO
var capa: CanvasLayer
var punto: Node2D
var tiempo :=0.0

func _ready() -> void:
	blanco= get_parent().get_node_or_null(objetivo)
	if blanco ==null:
		queue_free()
		return
	centro =blanco.position
	tiempo = randf() * TAU
	capa = CanvasLayer.new()
	capa.layer= 31
	add_child(capa)
	punto = Node2D.new()
	punto.draw.connect(_dibujar)
	capa.add_child(punto)
	_mover(0.0)

func _process(delta: float) -> void:
	if not is_instance_valid(blanco) or blanco.is_queued_for_deletion():
		queue_free()
		return
	_mover(delta)
	punto.queue_redraw()

func _mover(delta: float) -> void:
	tiempo +=delta *1.4
	position =(centro + Vector2(cos(tiempo)* radio, sin(tiempo* 2.0) *radio *0.35- 6.0)).floor()

func _dibujar() -> void:
	var j: Node = get_parent().get_node_or_null("Jugador")
	var cam: Camera2D = j.get_node_or_null("Camara") if j !=null else null
	if cam == null:
		return
	var p:= (global_position -cam.get_screen_center_position() + Vector2(128, 96)).floor()
	var grande:= fmod(tiempo, 1.2) <0.6
	punto.draw_rect(Rect2(p- Vector2(1, 1), Vector2(3, 3)), CELESTE)
	punto.draw_rect(Rect2(p, Vector2(1, 1)), BRILLO)
	if grande:
		for d in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
			punto.draw_rect(Rect2(p +d, Vector2(1, 1)), CELESTE)
