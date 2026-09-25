class_name Tipos
extends RefCounted

const RUTA:= "res://Datos/tipos.json"

static var _datos: Dictionary= {}

static func _cargar() -> void:
	if _datos.is_empty():
		_datos =JSON.parse_string(FileAccess.get_file_as_string(RUTA))

static func nombre(tipo: String) -> String:
	_cargar()
	return str(_datos["nombres"].get(tipo, tipo))

static func multiplicador(ataque: String, defensor: String) -> float:
	_cargar()
	return float(_datos["tabla"].get(ataque, {}).get(defensor, 1.0))

static func efectividad(ataque: String, tipos_defensor: PackedStringArray) -> float:
	var total:= 1.0
	for t in tipos_defensor:
		total*= multiplicador(ataque, t)
	return total
