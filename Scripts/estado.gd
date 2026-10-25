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

const DINERO_INICIAL :=3000
const DINERO_MAX:= 999999
const FICHAS_POR_CIUDAD :=5

func sumar_dinero(cantidad: int) -> void:
	dinero= clampi(dinero+ cantidad, 0, DINERO_MAX)

func marcar(clave: String) -> void:
	banderas[clave] =true

func tiene(clave: String) -> bool:
	return banderas.get(clave, false)

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
