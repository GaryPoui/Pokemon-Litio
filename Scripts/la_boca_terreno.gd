extends Node2D

func _ready() -> void:
	var suelo:= get_parent().get_node("Suelo") as TileMapLayer
	if suelo== null:
		return

	for celda: Vector2i in suelo.get_used_cells():
		if suelo.get_cell_source_id(celda)!= 1:
			continue

		var datos: TileData= suelo.get_cell_tile_data(celda)
		if datos!= null and datos.get_custom_data("hierba_alta")== true:
			continue

		if celda.y== 10 or celda.y== 11:
			suelo.set_cell(celda, 1, Vector2i(0, 0))
		elif suelo.get_cell_atlas_coords(celda)== Vector2i(1, 0):
			var variante_x:= posmod(celda.x * 5 + celda.y * 3, 8)
			var variante_y:= posmod(celda.x * 2 + celda.y, 6)
			suelo.set_cell(celda, 0, Vector2i(variante_x, variante_y))

	for y: int in [10, 11]:
		for x: int in range(-6, 32):
			suelo.set_cell(Vector2i(x, y), 1, Vector2i(0, 0))

	for x: int in [5, 11]:
		for y: int in range(1, 11):
			suelo.set_cell(Vector2i(x, y), 1, Vector2i(0, 0))
