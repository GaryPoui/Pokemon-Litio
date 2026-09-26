extends Node

var banderas: Dictionary= {}
var vistos: Dictionary ={}
var capturados: Dictionary= {}
var pasos_repelente: int =0

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
