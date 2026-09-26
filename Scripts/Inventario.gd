extends Node

signal inventory_changed

const CATEGORIES:= [
	"MEDICINA",
	"POKÉ BALLS",
	"MT / MO",
	"BAYAS",
	"OBJETOS",
	"CLAVE"
]

const INICIAL :={
	"potion": 5,
	"super_potion": 2,
	"pokeball": 12,
	"greatball": 4,
	"tm01": 1,
	"oran": 7,
	"repel": 3,
	"bicycle": 1,
}

var objetos: Dictionary= {}
var cantidades: Dictionary ={}

func _ready() -> void:
	for id in BaseDatos.ids(BaseDatos.OBJETOS):
		objetos[id]= BaseDatos.objeto(id)
	cantidades =INICIAL.duplicate()

func reiniciar() -> void:
	cantidades= INICIAL.duplicate()
	inventory_changed.emit()

func get_categories() -> Array[String]:
	var result: Array[String]= []
	for category in CATEGORIES:
		result.append(category)
	return result

func get_objeto(item_id: String) -> Objeto:
	return objetos.get(item_id)

func cantidad_de(item_id: String) -> int:
	return int(cantidades.get(item_id, 0))

func get_items_for_category(category: String) -> Array[Dictionary]:
	var result: Array[Dictionary] =[]
	for id in objetos:
		var o: Objeto= objetos[id]
		if o.categoria== category and cantidad_de(id)> 0:
			result.append(_como_diccionario(o))
	return result

func _como_diccionario(o: Objeto) -> Dictionary:
	return {
		"id": o.id,
		"name": o.nombre,
		"category": o.categoria,
		"quantity": cantidad_de(o.id),
		"description": o.descripcion,
		"usable": o.usable,
		"can_toss": o.se_puede_tirar,
	}

func use_item(item_id: String) -> bool:
	var o:= get_objeto(item_id)
	if o== null or not o.usable or cantidad_de(item_id)<= 0:
		return false
	if o.categoria!= "CLAVE" and o.categoria !="MT / MO":
		cantidades[item_id]= cantidad_de(item_id)- 1
		inventory_changed.emit()
	return true

func toss_item(item_id: String) -> bool:
	var o:= get_objeto(item_id)
	if o ==null or not o.se_puede_tirar or cantidad_de(item_id) <=0:
		return false
	cantidades[item_id] =cantidad_de(item_id)- 1
	inventory_changed.emit()
	return true

func add_item(item_id: String, cantidad: int= 1) -> bool:
	if not objetos.has(item_id):
		return false
	cantidades[item_id]= cantidad_de(item_id)+ cantidad
	inventory_changed.emit()
	return true

func consumir(item_id: String) -> bool:
	if cantidad_de(item_id)<= 0:
		return false
	cantidades[item_id]= cantidad_de(item_id) -1
	inventory_changed.emit()
	return true

func get_item_name(item_id: String) -> String:
	var o:= get_objeto(item_id)
	return o.nombre if o!= null else item_id

func a_diccionario() -> Dictionary:
	return cantidades.duplicate()

func desde_diccionario(d: Dictionary) -> void:
	cantidades= {}
	for k in d:
		cantidades[k] =int(d[k])
	inventory_changed.emit()
