extends Node

var banderas: Dictionary= {}

func marcar(clave: String) -> void:
	banderas[clave] =true

func tiene(clave: String) -> bool:
	return banderas.get(clave, false)
