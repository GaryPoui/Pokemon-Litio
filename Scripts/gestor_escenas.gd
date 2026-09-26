extends CanvasLayer

const CONFIG:= "user://config.cfg"
const FUNDIDO_MENU :=0.15

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
	var c:= ConfigFile.new()
	if c.load(CONFIG)== OK and c.has_section_key("pantalla", "completa"):
		poner_pantalla_completa(bool(c.get_value("pantalla", "completa")))

func _input(event: InputEvent) -> void:
	var k:= event as InputEventKey
	if k== null or not k.pressed or k.echo:
		return
	if k.keycode== KEY_F11 or (k.alt_pressed and (k.keycode== KEY_ENTER or k.keycode== KEY_KP_ENTER)):
		poner_pantalla_completa(not es_pantalla_completa())
		var c:= ConfigFile.new()
		c.load(CONFIG)
		c.set_value("pantalla", "completa", es_pantalla_completa())
		c.save(CONFIG)
		get_viewport().set_input_as_handled()

func es_pantalla_completa() -> bool:
	var m:= DisplayServer.window_get_mode()
	return m== DisplayServer.WINDOW_MODE_FULLSCREEN or m ==DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func poner_pantalla_completa(si: bool) -> void:
	if si== es_pantalla_completa():
		return
	if si:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1024, 768))
		var pantalla:= DisplayServer.window_get_current_screen()
		var centro:= DisplayServer.screen_get_position(pantalla)+ DisplayServer.screen_get_size(pantalla)/ 2
		DisplayServer.window_set_position(centro- Vector2i(512, 384))

func cubrir(t: float= FUNDIDO_MENU) -> void:
	en_transicion= true
	var tw:= create_tween()
	tw.tween_property(velo, "modulate:a", 1.0, t)
	await tw.finished

func descubrir(t: float =FUNDIDO_MENU) -> void:
	var tw:= create_tween()
	tw.tween_property(velo, "modulate:a", 0.0, t)
	await tw.finished
	en_transicion =false

func fundido(cambio: Callable, t: float= FUNDIDO_MENU) -> void:
	await cubrir(t)
	await cambio.call()
	await descubrir(t)

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
