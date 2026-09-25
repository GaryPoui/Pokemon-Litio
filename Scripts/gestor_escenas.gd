extends CanvasLayer

var en_transicion:= false
var llegada :=""
var direccion_llegada: Vector2= Vector2.DOWN
var posicion_llegada: Variant =null

@onready var velo: ColorRect =$Velo

func _ready() -> void:
	layer =120
	velo.color= Color.BLACK
	velo.modulate.a =0.0
	velo.mouse_filter= Control.MOUSE_FILTER_IGNORE

func cambiar_mapa_a(ruta: String, posicion: Vector2, direccion: Vector2) -> void:
	if en_transicion:
		return
	posicion_llegada= posicion
	await cambiar_mapa(ruta, "", direccion)

func cambiar_mapa(ruta: String, punto: String, direccion: Vector2) -> void:
	if en_transicion:
		return
	en_transicion= true
	llegada =punto
	direccion_llegada= direccion
	var salida:= create_tween()
	salida.tween_property(velo, "modulate:a", 1.0, 0.25)
	await salida.finished
	get_tree().change_scene_to_file(ruta)
	await get_tree().process_frame
	await get_tree().process_frame
	var entrada :=create_tween()
	entrada.tween_property(velo, "modulate:a", 0.0, 0.25)
	await entrada.finished
	en_transicion =false
