extends "res://Scripts/mapa.gd"

func _ready() -> void:
	var mapa_suelo: TileMapLayer = $Suelo
	for y in range(12):
		for x in range(16):
			mapa_suelo.set_cell(Vector2i(x, y), 2, Vector2i.ZERO)
	mapa_suelo.visible = false
	super._ready()
