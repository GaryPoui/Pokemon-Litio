class_name BaseDatos
extends RefCounted

const ESPECIES:= "res://Datos/Especies/"
const MOVIMIENTOS :="res://Datos/Movimientos/"
const OBJETOS:= "res://Datos/Objetos/"

static func especie(id: String) -> EspeciePokemon:
	return _cargar(ESPECIES, id) as EspeciePokemon

static func movimiento(id: String) -> Movimiento:
	return _cargar(MOVIMIENTOS, id) as Movimiento

static func objeto(id: String) -> Objeto:
	return _cargar(OBJETOS, id) as Objeto

static func ids(carpeta: String) -> PackedStringArray:
	var lista: PackedStringArray= []
	for f in ResourceLoader.list_directory(carpeta):
		if f.ends_with(".tres"):
			lista.append(f.get_basename())
	lista.sort()
	return lista

static func _cargar(carpeta: String, id: String) -> Resource:
	var ruta:= carpeta+ id +".tres"
	if not ResourceLoader.exists(ruta):
		return null
	return load(ruta)
