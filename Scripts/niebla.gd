class_name Niebla
extends Node2D

const SHADER :=preload("res://Recursos/niebla.gdshader")
const BORDE :=6.0

@export var area: Rect2 = Rect2(0, 0, 0, 0)
@export var color :Color = Color(0.78, 0.8, 0.86)

var capa: CanvasLayer
var velo: ColorRect
var material_niebla: ShaderMaterial
var nivel := 0.0
var radio_px:= 0.0
var tiempo := 0.0

func _ready() -> void:
	add_to_group("niebla")
	capa = CanvasLayer.new()
	capa.layer =30
	add_child(capa)
	velo =ColorRect.new()
	velo.mouse_filter =Control.MOUSE_FILTER_IGNORE
	velo.position =Vector2.ZERO
	velo.size =Vector2(256, 192)
	material_niebla = ShaderMaterial.new()
	material_niebla.shader =SHADER
	material_niebla.set_shader_parameter("tono", color)
	velo.material = material_niebla
	capa.add_child(velo)
	radio_px= _radio_objetivo()
	nivel = 1.0 if _adentro() else 0.0
	_actualizar(0.0)

func _jugador() -> Node:
	var m:= get_parent()
	return m.get_node_or_null("Jugador") if m != null else null

func radio_celdas() -> int:
	return 4 if Seguidor.en(get_parent()) != null else 2

func densidad() -> float:
	return nivel

func _radio_objetivo() -> float:
	return radio_celdas()* Rejilla.tam(self).x+ BORDE

func _adentro() -> bool:
	var j := _jugador()
	if j == null:
		return false
	var c: Vector2i = j.celda()
	return area.has_point(Vector2(c)+ Vector2(0.5, 0.5))

func _process(delta: float) -> void:
	_actualizar(delta)

func _actualizar(delta: float) -> void:
	tiempo+= delta
	var objetivo :=1.0 if _adentro() else 0.0
	nivel = move_toward(nivel, objetivo, delta/ 0.6)
	radio_px =move_toward(radio_px, _radio_objetivo(), delta * 2.0 * 2.0 * Rejilla.tam(self).x)
	velo.visible= nivel >0.0
	var j :=_jugador()
	var centro :=Vector2(128, 96)
	if j !=null:
		var cam: Camera2D =j.get_node_or_null("Camara")
		var foco: Vector2 = cam.get_screen_center_position() if cam != null else j.global_position
		centro= (j.global_position- foco+ Vector2(128, 96)).floor()
	material_niebla.set_shader_parameter("centro", centro)
	material_niebla.set_shader_parameter("radio", radio_px)
	material_niebla.set_shader_parameter("densidad", nivel)
	material_niebla.set_shader_parameter("tiempo", tiempo)
