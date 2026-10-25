class_name BaseDatos
extends RefCounted

const ESPECIES:= "res://Datos/Especies/"
const MOVIMIENTOS :="res://Datos/Movimientos/"
const OBJETOS:= "res://Datos/Objetos/"
const TRINKETS :="res://Datos/Trinkets/"
const PESOS:= "res://Datos/pesos.json"

static var _pesos :={}
static var _maquinas:= {}
const MAQUINAS :="res://Datos/maquinas.json"

static func peso(id: String) -> float:
	if _pesos.is_empty():
		_pesos= JSON.parse_string(FileAccess.get_file_as_string(PESOS))
	return float(_pesos.get(id, 50.0))

static func puede_aprender_mt(especie_id: String, mov_id: String) -> bool:
	if _maquinas.is_empty():
		_maquinas= JSON.parse_string(FileAccess.get_file_as_string(MAQUINAS))
	return mov_id in _maquinas.get(especie_id, [])

static func especie(id: String) -> EspeciePokemon:
	return _cargar(ESPECIES, id) as EspeciePokemon

static func movimiento(id: String) -> Movimiento:
	return _cargar(MOVIMIENTOS, id) as Movimiento

static func objeto(id: String) -> Objeto:
	return _cargar(OBJETOS, id) as Objeto

static func trinket(id: String) -> Trinket:
	return _cargar(TRINKETS, id) as Trinket

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
