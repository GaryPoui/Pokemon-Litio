extends Node2D

const TEXTURA_CALLE:= preload("res://Assets/Overworld/LaBoca/terreno_calle_gen4_concepto.png")
const ORIGENES_ADOQUIN:= [30, 166, 302, 438, 574]
const TAM_REGION:= 118
const ESCALA_CELDA:= 16.0 / TAM_REGION

func _ready() -> void:
	var suelo:= get_parent().get_node("Suelo") as TileMapLayer
	if suelo== null:
		return
	var celdas_calle:= []
	for celda in suelo.get_used_cells():
		if suelo.get_cell_source_id(celda)== 1:
			celdas_calle.append(celda)
	celdas_calle.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	for celda in celdas_calle:
		var atlas:= AtlasTexture.new()
		var variante:= posmod(celda.x * 17 + celda.y * 31, ORIGENES_ADOQUIN.size())
		atlas.atlas= TEXTURA_CALLE
		atlas.region= Rect2(ORIGENES_ADOQUIN[variante], 32, TAM_REGION, TAM_REGION)
		var baldosa:= Sprite2D.new()
		baldosa.texture= atlas
		baldosa.texture_filter= CanvasItem.TEXTURE_FILTER_NEAREST
		baldosa.scale= Vector2.ONE * ESCALA_CELDA
		baldosa.position= suelo.map_to_local(celda)
		add_child(baldosa)
