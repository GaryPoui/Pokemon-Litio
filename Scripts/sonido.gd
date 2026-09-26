extends Node

signal sonado(tipo: String, nombre: String)
signal jingle_terminado

const MUSICA:= "res://Assets/Audio/Musica/"
const EFECTOS :="res://Assets/Audio/Efectos/"
const GRITOS:= "res://Assets/Audio/Gritos/"
const CONFIG :="user://config.cfg"
const BUSES:= ["Musica", "Efectos", "Gritos"]
const VOCES :=8
const BUCLES:= {
	"titulo": 0.0,
	"pueblo": 13.35345,
	"ruta_1": 37.30719,
	"batalla_salvaje": 35.91646,
	"victoria_salvaje": 9.50558,
	"mirada_joven": 3.98909,
	"batalla_entrenador": 92.65206,
	"victoria_entrenador": 2.93503,
	"ps_bajo": 0.0,
}

var musica_actual :=""
var historial: Array[String]= []
var volumenes:= {"Musica": 0.8, "Efectos": 0.8, "Gritos": 0.8}
var posiciones :={}
var cache:= {}
var faltantes :={}
var reproductor: AudioStreamPlayer
var saliente: AudioStreamPlayer
var jingle_actual: AudioStreamPlayer
var grito_actual: AudioStreamPlayer
var voces: Array[AudioStreamPlayer]= []
var siguiente_voz :=0
var tween_musica: Tween
var tween_salida: Tween
var tween_jingle: Tween

func _ready() -> void:
	process_mode= Node.PROCESS_MODE_ALWAYS
	for b in BUSES:
		if AudioServer.get_bus_index(b)== -1:
			AudioServer.add_bus()
			var i:= AudioServer.bus_count- 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	reproductor= _nuevo("Musica")
	saliente =_nuevo("Musica")
	jingle_actual= _nuevo("Musica")
	grito_actual =_nuevo("Gritos")
	for i in VOCES:
		voces.append(_nuevo("Efectos"))
	jingle_actual.finished.connect(_fin_jingle)
	cargar_config()

func _nuevo(bus: String) -> AudioStreamPlayer:
	var p:= AudioStreamPlayer.new()
	p.bus= bus
	add_child(p)
	return p

func _cargar(ruta: String) -> AudioStream:
	if cache.has(ruta):
		return cache[ruta]
	var s: AudioStream= null
	if ResourceLoader.exists(ruta):
		s= load(ruta)
	elif not faltantes.has(ruta):
		faltantes[ruta]= true
		push_warning("Sonido: falta %s" % ruta)
	cache[ruta]= s
	return s

func _anotar(tipo: String, nombre: String) -> void:
	historial.append("%s:%s" % [tipo, nombre])
	if historial.size()> 400:
		historial= historial.slice(historial.size()- 300)
	sonado.emit(tipo, nombre)

func musica(nombre: String, fundido: float= 0.5, reanudar: bool= false) -> void:
	if nombre== musica_actual and reproductor.playing:
		return
	if nombre== "":
		detener_musica(fundido)
		return
	var s:= _cargar(MUSICA+ nombre+ ".ogg")
	_anotar("musica", nombre)
	if musica_actual!= "" and reproductor.playing:
		posiciones[musica_actual]= reproductor.get_playback_position()
	var viejo:= reproductor
	reproductor= saliente
	saliente =viejo
	if tween_salida and tween_salida.is_valid():
		tween_salida.kill()
	if saliente.playing:
		tween_salida= create_tween()
		tween_salida.tween_property(saliente, "volume_db", -60.0, maxf(0.05, fundido))
		tween_salida.tween_callback(saliente.stop)
	musica_actual= nombre
	_apagar_jingle(maxf(0.05, fundido))
	if s== null:
		reproductor.stop()
		return
	if s is AudioStreamOggVorbis:
		s.loop= BUCLES.has(nombre)
		s.loop_offset= float(BUCLES.get(nombre, 0.0))
	reproductor.stream= s
	reproductor.stream_paused =false
	reproductor.volume_db= -60.0 if fundido> 0.0 else 0.0
	reproductor.play(float(posiciones.get(nombre, 0.0)) if reanudar else 0.0)
	if tween_musica and tween_musica.is_valid():
		tween_musica.kill()
	if fundido> 0.0:
		tween_musica= create_tween()
		tween_musica.tween_property(reproductor, "volume_db", 0.0, fundido)

func detener_musica(fundido: float= 0.5) -> void:
	if musica_actual!= "" and reproductor.playing:
		posiciones[musica_actual]= reproductor.get_playback_position()
	_anotar("musica", "")
	musica_actual =""
	if tween_musica and tween_musica.is_valid():
		tween_musica.kill()
	if fundido<= 0.0:
		reproductor.stop()
		return
	tween_musica= create_tween()
	tween_musica.tween_property(reproductor, "volume_db", -60.0, fundido)
	tween_musica.tween_callback(reproductor.stop)

func jingle(nombre: String) -> void:
	var s:= _cargar(MUSICA+ nombre+ ".ogg")
	_anotar("jingle", nombre)
	if s== null:
		return
	if s is AudioStreamOggVorbis:
		s.loop= false
	reproductor.stream_paused =true
	if tween_jingle and tween_jingle.is_valid():
		tween_jingle.kill()
	jingle_actual.volume_db= 0.0
	jingle_actual.stream= s
	jingle_actual.play()
	await jingle_terminado

func sonando_jingle() -> bool:
	return jingle_actual.playing and jingle_actual.volume_db> -59.0

func cortar_jingle(fundido: float= 0.35) -> void:
	if not sonando_jingle():
		return
	_anotar("corte", "jingle")
	_apagar_jingle(fundido)
	_reanudar_musica(0.5)

func _apagar_jingle(fundido: float) -> void:
	if not jingle_actual.playing:
		return
	if tween_jingle and tween_jingle.is_valid():
		tween_jingle.kill()
	tween_jingle= create_tween()
	tween_jingle.tween_property(jingle_actual, "volume_db", -60.0, fundido)
	tween_jingle.tween_callback(jingle_actual.stop)
	tween_jingle.tween_callback(jingle_terminado.emit)

func _fin_jingle() -> void:
	jingle_terminado.emit()
	_reanudar_musica(0.4)

func _reanudar_musica(fundido: float) -> void:
	if musica_actual== "" or not reproductor.stream_paused:
		return
	reproductor.stream_paused= false
	reproductor.volume_db =-60.0
	if tween_musica and tween_musica.is_valid():
		tween_musica.kill()
	tween_musica= create_tween()
	tween_musica.tween_property(reproductor, "volume_db", 0.0, fundido)

func efecto(nombre: String, tono: float= 1.0) -> void:
	var s:= _cargar(EFECTOS+ nombre+ ".wav")
	_anotar("efecto", nombre)
	if s== null:
		return
	var v:= voces[siguiente_voz]
	siguiente_voz= (siguiente_voz+ 1) % voces.size()
	v.stream =s
	v.pitch_scale= tono
	v.play()

func grito(numero: int, tono: float= 1.0) -> float:
	var s:= _cargar(GRITOS+ "%03d.wav" % numero)
	_anotar("grito", str(numero))
	if s== null:
		return 0.0
	grito_actual.stream= s
	grito_actual.pitch_scale =tono
	grito_actual.play()
	return s.get_length()/ tono

func volumen(bus: String) -> float:
	return float(volumenes.get(bus, 1.0))

func poner_volumen(bus: String, valor: float) -> void:
	valor= clampf(snappedf(valor, 0.1), 0.0, 1.0)
	volumenes[bus]= valor
	var i:= AudioServer.get_bus_index(bus)
	if i< 0:
		return
	AudioServer.set_bus_mute(i, valor<= 0.0)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(valor, 0.0001)))

func cargar_config() -> void:
	var c:= ConfigFile.new()
	c.load(CONFIG)
	for b in BUSES:
		poner_volumen(b, float(c.get_value("audio", b, volumenes[b])))

func guardar_config() -> void:
	var c:= ConfigFile.new()
	c.load(CONFIG)
	for b in BUSES:
		c.set_value("audio", b, volumenes[b])
	c.save(CONFIG)
