extends CanvasLayer

const DURACION_VISIBLE:= 2.5
const DESPLAZAMIENTO:= 8
const POSICION_Y:= 6
const ANCHO:= 136
const MARGEN_DERECHO:= 6

@onready var panel: PanelContainer= $Panel
@onready var nombre: Label= $Panel/Contenido/Nombre
@onready var subtitulo: Label= $Panel/Contenido/Subtitulo

var _generacion:= 0
var _animacion: Tween

func _ready() -> void:
	# Encima del mundo y debajo de combates, diálogos y menús.
	layer= 45
	panel.mouse_filter= Control.MOUSE_FILTER_IGNORE
	nombre.mouse_filter= Control.MOUSE_FILTER_IGNORE
	subtitulo.mouse_filter= Control.MOUSE_FILTER_IGNORE
	EstiloUI.label(nombre, 9)
	EstiloUI.fuente_batalla(subtitulo)
	subtitulo.add_theme_color_override("font_color", EstiloUI.TENUE)
	nombre.horizontal_alignment= HORIZONTAL_ALIGNMENT_RIGHT
	subtitulo.horizontal_alignment= HORIZONTAL_ALIGNMENT_RIGHT
	nombre.text_overrun_behavior= TextServer.OVERRUN_TRIM_ELLIPSIS
	subtitulo.text_overrun_behavior= TextServer.OVERRUN_TRIM_ELLIPSIS
	panel.size= Vector2(ANCHO, 38)
	panel.custom_minimum_size= Vector2(ANCHO, 38)
	panel.visible= false
	panel.position= _posicion_final()
	var estilo:= EstiloUI.panel(Color(0.06, 0.08, 0.12, 0.96), Color("e0c068"))
	estilo.set_content_margin_all(4.0)
	panel.add_theme_stylebox_override("panel", estilo)
	$Panel/Contenido.add_theme_constant_override("separation", 1)

func mostrar_zona(titulo: String, detalle: String= "") -> void:
	_generacion+= 1
	var solicitud:= _generacion
	if _animacion != null and _animacion.is_running():
		_animacion.kill()
	nombre.text= titulo
	subtitulo.text= detalle
	subtitulo.visible= not detalle.strip_edges().is_empty()
	panel.visible= true
	panel.modulate.a= 0.0
	panel.position= _posicion_final()+ Vector2(DESPLAZAMIENTO, 0)
	_animacion= create_tween().set_parallel(true)
	_animacion.tween_property(panel, "modulate:a", 1.0, 0.14)
	_animacion.tween_method(_desplazar, DESPLAZAMIENTO, 0, 0.14)
	await get_tree().create_timer(DURACION_VISIBLE+ 0.14).timeout
	if solicitud!= _generacion or not is_instance_valid(panel):
		return
	_animacion= create_tween().set_parallel(true)
	_animacion.tween_property(panel, "modulate:a", 0.0, 0.14)
	_animacion.tween_method(_desplazar, 0, DESPLAZAMIENTO, 0.14)
	await get_tree().create_timer(0.14).timeout
	if solicitud== _generacion:
		panel.visible= false

func _posicion_final() -> Vector2:
	var ancho_visible:= get_viewport().get_visible_rect().size.x
	return Vector2(ancho_visible- ANCHO- MARGEN_DERECHO, POSICION_Y)

func _desplazar(valor: float) -> void:
	panel.position.x= _posicion_final().x+ roundi(valor)
