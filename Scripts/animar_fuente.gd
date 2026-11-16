extends Node2D

@export var fuente:= 15
@export var texturas: Array= []
@export var periodo :float= 0.06

var cuadros: Array= []
var origen: TileSetAtlasSource
var t:= 0.0
var k :=0

func _ready() -> void:
	var su= get_parent().get_node_or_null("Suelo")
	if su== null or su.tile_set== null or not su.tile_set.has_source(fuente):
		set_process(false)
		return
	origen= su.tile_set.get_source(fuente) as TileSetAtlasSource
	for ruta in texturas:
		var tex= load(str(ruta))
		if tex!= null:
			cuadros.append(tex)
	if cuadros.size()< 2:
		set_process(false)

func _process(delta: float) -> void:
	t+= delta
	if t< periodo:
		return
	t =0.0
	k= (k+ 1)% cuadros.size()
	origen.texture= cuadros[k]

func _exit_tree() -> void:
	if origen!= null and not cuadros.is_empty():
		origen.texture =cuadros[0]
