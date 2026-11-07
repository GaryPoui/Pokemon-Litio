extends "res://Scripts/npc.gd"

@export var medalla: String= "anden"
@export_multiline var texto_abierto :String= ""
@export var celda_libre: Array= []

func _ready() -> void:
	super._ready()
	if abierta() and celda_libre.size() >=2:
		position =Rejilla.centro(self, Vector2i(int(celda_libre[0]), int(celda_libre[1])))

func abierta() -> bool:
	return medalla!= "" and Estado.tiene_medalla(medalla)

func interactuar(jugador: Node) -> void:
	if not abierta() or texto_abierto== "":
		await super.interactuar(jugador)
		return
	_mirar(-jugador.last_direction)
	await Dialogo.mostrar(texto_abierto)
