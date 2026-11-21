extends Node

var banderas: Dictionary= {}
var vistos: Dictionary ={}
var capturados: Dictionary= {}
var pasos_repelente: int =0
var dinero:= DINERO_INICIAL
var stock_tienda: Array[String]= []
var safari :Dictionary= {}
var medallas: Array[String]= []
var fichas:= 0
var fichas_ciudades :Dictionary= {}
var estadisticas: Dictionary= estadisticas_nuevas()
var nombre_jugador :=""
var heroe:= HEROE_DEFECTO

const DINERO_INICIAL :=3000
const DINERO_MAX:= 999999
const FICHAS_POR_CIUDAD :=5
const INICIALES:= ["snivy", "charmander", "mudkip"]
const INICIALES_VIEJOS :=["tepig", "oshawott"]
const CONTRA:= {"snivy": "charmander", "charmander": "mudkip", "mudkip": "snivy"}
const SOBRA :={"snivy": "mudkip", "charmander": "snivy", "mudkip": "charmander"}
const PRESTADOS:= ["bombo_hinchada", "botines_potrero", "mate_compartido"]
const HEROES :=["ethan", "lyra", "lucas", "dawn", "hilbert", "hilda", "nate", "rosa"]
const FEMENINOS:= ["lyra", "dawn", "hilda", "rosa"]
const HEROE_DEFECTO :="hilbert"

static func estadisticas_nuevas() -> Dictionary:
	return {"tiempo": 0.0, "pasos": 0, "companero": ""}

func _process(delta: float) -> void:
	var escena:= get_tree().current_scene
	if escena!= null and escena.has_method("terreno_actual"):
		estadisticas["tiempo"]= float(estadisticas.get("tiempo", 0.0))+ delta

func contar_paso() -> void:
	estadisticas["pasos"] =int(estadisticas.get("pasos", 0))+ 1
	if int(estadisticas["pasos"])% 128== 0:
		var equipo:= get_tree().root.get_node_or_null("Equipo")
		if equipo!= null:
			for p in equipo.miembros:
				p.subir_amistad(1)

func anotar_companero(especie_id: String) -> void:
	if str(estadisticas.get("companero", ""))== "":
		estadisticas["companero"]= especie_id

func cambiar_companero(antes: String, despues: String) -> void:
	if str(estadisticas.get("companero", ""))== antes:
		estadisticas["companero"] =despues

func sumar_dinero(cantidad: int) -> void:
	dinero= clampi(dinero+ cantidad, 0, DINERO_MAX)

func marcar(clave: String) -> void:
	banderas[clave] =true

func tiene(clave: String) -> bool:
	return banderas.get(clave, false)

func inicial() -> String:
	for id in INICIALES+ INICIALES_VIEJOS:
		if tiene("inicial_" +id):
			return id
	return ""

func en_tutorial() -> bool:
	return tiene("tut_intro") and not tiene("tutorial_hecho")

func g(masc: String, fem: String) -> String:
	return fem if heroe in FEMENINOS else masc

func con_nombre(con: String, sin: String) -> String:
	return sin if nombre_jugador== "" else con % nombre_jugador

func ver(especie_id: String) -> void:
	vistos[especie_id]= true

func capturar(especie_id: String) -> void:
	vistos[especie_id] =true
	capturados[especie_id]= true

func registrar_safari(ruta: String, especie_id: String) -> void:
	if ruta== "":
		return
	if not safari.has(ruta):
		safari[ruta]= {}
	safari[ruta][especie_id] =true

func safari_de(ruta: String) -> Array:
	return safari.get(ruta, {}).keys()

func dar_medalla(id: String) -> void:
	if not medallas.has(id):
		medallas.append(id)

func tiene_medalla(id: String) -> bool:
	return medallas.has(id)

func dar_fichas_ciudad(zona_id: String) -> int:
	if zona_id== "" or fichas_ciudades.has(zona_id):
		return 0
	fichas_ciudades[zona_id]= true
	fichas+= FICHAS_POR_CIUDAD
	return FICHAS_POR_CIUDAD

func reiniciar() -> void:
	banderas= {}
	vistos ={}
	capturados= {}
	pasos_repelente =0
	dinero= DINERO_INICIAL
	stock_tienda.clear()
	safari ={}
	medallas.clear()
	fichas= 0
	fichas_ciudades ={}
	estadisticas= estadisticas_nuevas()
	nombre_jugador= ""
	heroe =HEROE_DEFECTO
