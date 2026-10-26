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

const DINERO_INICIAL :=3000
const DINERO_MAX:= 999999
const FICHAS_POR_CIUDAD :=5

static func estadisticas_nuevas() -> Dictionary:
	return {"tiempo": 0.0, "pasos": 0, "companero": ""}

func _process(delta: float) -> void:
	var escena:= get_tree().current_scene
	if escena!= null and escena.has_method("terreno_actual"):
		estadisticas["tiempo"]= float(estadisticas.get("tiempo", 0.0))+ delta

func contar_paso() -> void:
	estadisticas["pasos"] =int(estadisticas.get("pasos", 0))+ 1

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
	for id in ["snivy", "tepig", "oshawott"]:
		if tiene("inicial_" +id):
			return id
	return ""

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
