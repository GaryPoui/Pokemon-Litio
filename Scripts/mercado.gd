extends "res://Scripts/npc.gd"

const TIENDA:= preload("res://Scripts/ui/tienda_objetos.gd")
const STOCK_POR_MEDALLAS :=[
	["pokeball", "potion", "antidote", "paralyze_heal", "awakening", "repel"],
	["greatball", "super_potion", "burn_heal", "ice_heal", "super_repel", "fire_stone", "water_stone", "thunder_stone", "leaf_stone", "moon_stone"],
	["revive", "full_heal", "sun_stone", "shiny_stone", "dusk_stone", "dawn_stone", "ice_stone", "oval_stone", "linking_cord"],
	["kings_rock", "metal_coat", "dragon_scale", "up_grade", "dubious_disc", "protector", "electirizer", "magmarizer", "reaper_cloth", "deep_sea_tooth", "deep_sea_scale", "prism_scale", "razor_fang", "razor_claw", "ability_patch"],
]

@export_group("Almacén")
@export var titulo: String= "ALMACÉN POKéMON"
@export var extra :Array[String]= []

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	await Dialogo.mostrar(texto if texto!= "" else "¡Hola! Bienvenido al almacén. ¿Qué andás buscando?")
	while true:
		var r: int= await Dialogo.preguntar("¿Qué vas a hacer?", ["COMPRAR", "VENDER", "NADA"])
		if r!= 0 and r!= 1:
			break
		await _tienda(r== 1)
	await Dialogo.mostrar("¡Gracias, volvé pronto!")

func stock() -> Array:
	var ids: Array= []
	for k in mini(Estado.medallas.size()+ 1, STOCK_POR_MEDALLAS.size()):
		ids.append_array(STOCK_POR_MEDALLAS[k])
	for id in extra:
		if not ids.has(id):
			ids.append(id)
	return ids

func _tienda(vender: bool) -> void:
	var t= TIENDA.new()
	await GestorEscenas.fundido(func():
		get_tree().current_scene.add_child(t)
		t.abrir(titulo, stock(), vender))
	await t.cerrado
	await GestorEscenas.fundido(func(): t.queue_free())
