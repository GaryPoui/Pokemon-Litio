extends CanvasLayer

const CONFIG:= "user://config.cfg"
const FUNDIDO_MENU :=0.15
const NUM_BARRAS:= 16

var en_transicion:= false
var barras: Array[ColorRect] =[]
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
		alternar_pantalla_completa()
		get_viewport().set_input_as_handled()

func alternar_pantalla_completa() -> void:
	poner_pantalla_completa(not es_pantalla_completa())
	var c:= ConfigFile.new()
	c.load(CONFIG)
	c.set_value("pantalla", "completa", es_pantalla_completa())
	c.save(CONFIG)

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

func _preparar_barras() -> void:
	if not barras.is_empty():
		return
	var alto:= 192.0/ NUM_BARRAS
	for i in NUM_BARRAS:
		var b:= ColorRect.new()
		b.color= Color.BLACK
		b.size =Vector2(256, alto)
		b.position= Vector2(-256, i* alto)
		b.mouse_filter =Control.MOUSE_FILTER_IGNORE
		b.visible= false
		add_child(b)
		barras.append(b)

func barras_cubrir() -> void:
	en_transicion= true
	_preparar_barras()
	var tw:= create_tween().set_parallel()
	for i in NUM_BARRAS:
		var b:= barras[i]
		b.position.x= -256.0 if i% 2== 0 else 256.0
		b.visible =true
		tw.tween_property(b, "position:x", 0.0, 0.2).set_delay(i* 0.02).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished
	await get_tree().create_timer(0.15).timeout

func barras_descubrir() -> void:
	_preparar_barras()
	var rng:= RandomNumberGenerator.new()
	rng.randomize()
	var tw:= create_tween().set_parallel()
	for i in NUM_BARRAS:
		var hacia:= 256.0 if rng.randi_range(0, 1)== 0 else -256.0
		tw.tween_property(barras[i], "position:x", hacia, 0.28).set_delay(rng.randf_range(0.0, 0.4)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	for b in barras:
		b.visible= false
	en_transicion =false
