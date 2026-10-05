extends Node2D

const TEXTURA_ADOQUIN:= preload("res://Assets/Overworld/LaBoca/suelo_adoquin_vereda_transiciones_gen4.png")
const TEXTURA_CAMINITO:= preload("res://Assets/Overworld/LaBoca/suelo_caminito_multicolor_tileset_gen4.png")
const COLUMNAS:= 8
const PITCH:= 181
const ORIGEN_X:= 40
const ORIGEN_Y:= 34
const TAM_REGION:= 160
const ESCALA_CELDA:= 16.0 / TAM_REGION

func _ready() -> void:
	var suelo:= get_parent().get_node("Suelo") as TileMapLayer
	if suelo== null:
		return
	var celdas_calle: Array[Vector2i] = []
	for celda: Vector2i in suelo.get_used_cells():
		var es_agua:= suelo.get_cell_atlas_coords(celda)== Vector2i(2, 0)
		if suelo.get_cell_source_id(celda)== 1 and not es_agua:
			celdas_calle.append(celda)
	celdas_calle.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	for celda: Vector2i in celdas_calle:
		var atlas:= AtlasTexture.new()
		var clave: int = (celda.x * 73856093) ^ (celda.y * 19349663)
		var variante: int = posmod(clave, COLUMNAS * 2)
		var region:= Vector2i(40 + (variante % COLUMNAS) * PITCH, 34 + (variante / COLUMNAS) * PITCH)
		if celda.y== 10 or celda.y== 11:
			atlas.atlas= TEXTURA_CAMINITO
			atlas.region= Rect2(region, Vector2i(TAM_REGION, TAM_REGION))
		elif celda.x>= 26 and celda.y<= 3:
			var variante_ladrillo:= posmod(celda.x * 7 + celda.y * 11, 4)
			atlas.atlas= TEXTURA_ADOQUIN
			atlas.region= Rect2(40 + variante_ladrillo * PITCH, 34 + 2 * PITCH, TAM_REGION, TAM_REGION)
		else:
			var variante_adoquin:= posmod(celda.x * 13 + celda.y * 19, 8)
			var fila_adoquin:= 0 if posmod(celda.x + celda.y, 3)!= 0 else 1
			atlas.atlas= TEXTURA_ADOQUIN
			atlas.region= Rect2(40 + variante_adoquin * PITCH, 34 + fila_adoquin * PITCH, TAM_REGION, TAM_REGION)
		var baldosa:= Sprite2D.new()
		baldosa.texture= atlas
		baldosa.texture_filter= CanvasItem.TEXTURE_FILTER_NEAREST
		baldosa.scale= Vector2.ONE * ESCALA_CELDA
		baldosa.position= suelo.map_to_local(celda)
		add_child(baldosa)
