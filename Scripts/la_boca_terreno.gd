@tool
extends TileMapLayer

## Terreno editable del primer barrio, sobre la cuadrícula de 16 px.
@export_tool_button("Reconstruir terreno de La Boca") var reconstruir_terreno = reconstruir

const PISOS = preload("res://Assets/Overworld/pisos_atlas_12_materiales_16px.png")
const RIBERA = preload("res://Assets/Overworld/boca_riachuelo_agua_muelle_tiles_16x16.png")
const PASTO = preload("res://Assets/Overworld/pasto_variantes.png")

func _ready() -> void:
	if get_used_rect().size == Vector2i.ZERO:
		reconstruir()

func reconstruir() -> void:
	clear()
	tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	_agregar_atlas(PISOS, Vector2i(8, 6), 0)
	_agregar_atlas(RIBERA, Vector2i(8, 4), 1)
	_agregar_atlas(PASTO, Vector2i(8, 6), 2)

	# Manzana, veredas y calles del croquis; el Riachuelo ocupa el borde sur.
	_piso(Rect2i(0, 0, 896, 576), 2)
	_piso(Rect2i(112, 256, 768, 64), 0)
	_piso(Rect2i(112, 160, 48, 384), 0)
	_piso(Rect2i(160, 496, 720, 48), 0)
	_piso(Rect2i(832, 304, 48, 192), 0)
	_piso(Rect2i(240, 160, 592, 32), 0)
	for x: int in [280, 376, 472, 568, 728]:
		_piso(Rect2i(x, 192, 32, 64), 0)
	_piso(Rect2i(240, 192, 32, 64), 0)

	# Explanadas y accesos de Centro Pokémon, café y kiosco.
	_piso(Rect2i(256, 320, 320, 96), 3)
	_piso(Rect2i(256, 416, 32, 80), 1)
	_piso(Rect2i(400, 416, 32, 80), 1)
	_piso(Rect2i(528, 416, 32, 80), 1)
	_piso(Rect2i(256, 464, 304, 32), 1)
	_piso(Rect2i(640, 176, 176, 48), 11)

	# Plaza con jardines y senderos que conectan sus cuatro entradas.
	for y: int in range(21, 30):
		for x: int in range(38, 51):
			set_cell(Vector2i(x, y), 2, Vector2i(posmod(x * 3 + y, 4), posmod(y, 4)))
	_piso(Rect2i(592, 320, 240, 16), 1)
	_piso(Rect2i(592, 480, 240, 16), 1)
	_piso(Rect2i(592, 336, 16, 144), 1)
	_piso(Rect2i(816, 336, 16, 144), 1)
	_piso(Rect2i(592, 400, 240, 32), 6)
	_piso(Rect2i(704, 320, 32, 176), 6)
	_piso(Rect2i(688, 384, 64, 64), 3)

	# Puerto lateral y paseo costero: la madera termina antes del agua.
	_piso(Rect2i(0, 224, 96, 352), 10)
	_piso(Rect2i(96, 320, 16, 224), 9)
	_piso(Rect2i(96, 544, 800, 32), 9)
	_piso(Rect2i(0, 160, 96, 64), 9)
	for y: int in range(36, 46):
		for x: int in range(56):
			set_cell(Vector2i(x, y), 1, Vector2i(posmod(x * 3 + y, 8), posmod(y, 2)))
	_piso(Rect2i(32, 576, 32, 64), 10)
	_piso(Rect2i(176, 576, 32, 48), 10)

func _agregar_atlas(textura: Texture2D, cantidad: Vector2i, id: int) -> void:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = textura
	atlas.texture_region_size = Vector2i(16, 16)
	for y: int in range(cantidad.y):
		for x: int in range(cantidad.x):
			atlas.create_tile(Vector2i(x, y))
	tile_set.add_source(atlas, id)

func _piso(rect: Rect2i, material: int) -> void:
	var origen := Vector2i((material % 4) * 2, (material / 4) * 2)
	for y: int in range(rect.position.y / 16, rect.end.y / 16):
		for x: int in range(rect.position.x / 16, rect.end.x / 16):
			set_cell(Vector2i(x, y), 0, origen + Vector2i(posmod(x, 2), posmod(y, 2)))
