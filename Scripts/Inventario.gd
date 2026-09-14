extends Node

signal inventory_changed

const CATEGORIES := [
	"MEDICINA",
	"POKÉ BALLS",
	"MT / MO",
	"BAYAS",
	"OBJETOS",
	"CLAVE"
]

var items: Array[Dictionary] = [
	{
		"id": "potion",
		"name": "Poción",
		"category": "MEDICINA",
		"quantity": 5,
		"description": "Restaura 20 PS a un Pokémon.",
		"usable": true,
		"can_toss": true
	},
	{
		"id": "super_potion",
		"name": "Superpoción",
		"category": "MEDICINA",
		"quantity": 2,
		"description": "Restaura una buena cantidad de PS a un Pokémon.",
		"usable": true,
		"can_toss": true
	},
	{
		"id": "pokeball",
		"name": "Poké Ball",
		"category": "POKÉ BALLS",
		"quantity": 12,
		"description": "Dispositivo para capturar Pokémon salvajes.",
		"usable": false,
		"can_toss": true
	},
	{
		"id": "greatball",
		"name": "Super Ball",
		"category": "POKÉ BALLS",
		"quantity": 4,
		"description": "Poké Ball con un rendimiento superior al modelo normal.",
		"usable": false,
		"can_toss": true
	},
	{
		"id": "tm01",
		"name": "MT01",
		"category": "MT / MO",
		"quantity": 1,
		"description": "Disco técnico que enseña un movimiento a un Pokémon compatible.",
		"usable": true,
		"can_toss": false
	},
	{
		"id": "oran",
		"name": "Baya Aranja",
		"category": "BAYAS",
		"quantity": 7,
		"description": "Una baya que restaura algunos PS cuando la lleva un Pokémon.",
		"usable": true,
		"can_toss": true
	},
	{
		"id": "repel",
		"name": "Repelente",
		"category": "OBJETOS",
		"quantity": 3,
		"description": "Mantiene alejados a los Pokémon salvajes débiles durante un tiempo.",
		"usable": true,
		"can_toss": true
	},
	{
		"id": "bicycle",
		"name": "Bici",
		"category": "CLAVE",
		"quantity": 1,
		"description": "Una bicicleta plegable para desplazarse más rápido.",
		"usable": true,
		"can_toss": false
	}
]

func get_categories() -> Array[String]:
	var result: Array[String] = []
	for category in CATEGORIES:
		result.append(category)
	return result

func get_items_for_category(category: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in items:
		if item.get("category", "") == category and int(item.get("quantity", 0)) > 0:
			result.append(item)
	return result

func use_item(item_id: String) -> bool:
	for item in items:
		if item.get("id", "") == item_id:
			if not bool(item.get("usable", false)):
				return false
			if int(item.get("quantity", 0)) <= 0:
				return false

			# Por ahora simula el uso consumiendo una unidad.
			# Más adelante esto se conecta con el equipo Pokémon.
			if item.get("category", "") != "CLAVE" and item.get("category", "") != "MT / MO":
				item["quantity"] = int(item.get("quantity", 0)) - 1
				inventory_changed.emit()
			return true
	return false

func toss_item(item_id: String) -> bool:
	for item in items:
		if item.get("id", "") == item_id:
			if not bool(item.get("can_toss", true)):
				return false
			if int(item.get("quantity", 0)) <= 0:
				return false
			item["quantity"] = int(item.get("quantity", 0)) - 1
			inventory_changed.emit()
			return true
	return false
