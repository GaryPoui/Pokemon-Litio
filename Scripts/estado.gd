extends Node

var banderas: Dictionary= {}
var vistos: Dictionary ={}
var capturados: Dictionary= {}
var pasos_repelente: int =0
var dinero:= DINERO_INICIAL
var stock_tienda: Array[String]= []

const DINERO_INICIAL :=3000
const DINERO_MAX:= 999999

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

func reiniciar() -> void:
	banderas= {}
	vistos ={}
	capturados= {}
	pasos_repelente =0
	dinero= DINERO_INICIAL
	stock_tienda.clear()
