class_name Naturalezas
extends RefCounted

const RUTA:= "res://Datos/naturalezas.json"

static var _datos: Dictionary ={}

static func _cargar() -> void:
	if _datos.is_empty():
		_datos= JSON.parse_string(FileAccess.get_file_as_string(RUTA))

static func ids() -> Array:
	_cargar()
	var lista:= _datos.keys()
	lista.sort()
	return lista

static func nombre(naturaleza: String) -> String:
	_cargar()
	return str(_datos.get(naturaleza, {}).get("nombre", naturaleza))

static func porcentaje(naturaleza: String, stat: String) -> int:
	_cargar()
	var n: Dictionary= _datos.get(naturaleza, {})
	var sube: String =n.get("sube", "")
	var baja: String= n.get("baja", "")
	if sube== baja:
		return 100
	if stat== sube:
		return 110
	if stat ==baja:
		return 90
	return 100
