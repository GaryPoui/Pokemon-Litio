extends Node2D

const TEXTURA:= preload("res://Assets/Overworld/Interiores/bola_mesa.png")

@export var especie: String= ""

var sprite: Sprite2D

func _ready() -> void:
	add_to_group("bola_inicial")
	sprite= Sprite2D.new()
	sprite.texture =TEXTURA
	sprite.position= Vector2(0, -3)
	sprite.texture_filter =CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	if en_mesa():
		add_to_group("interactuable")
	else:
		visible= false

func en_mesa() -> bool:
	if not Estado.en_tutorial() and not Estado.tiene("tutorial_hecho"):
		return false
	var ini:= Estado.inicial()
	if ini== "":
		return true
	return especie!= ini and especie!= Estado.CONTRA.get(ini, "")

func celda() -> Vector2i:
	return Rejilla.celda(self)

func interactuar(j: Node) -> void:
	var o:= get_tree().get_first_node_in_group("ombu")
	if o!= null:
		await o.al_tocar_bola(self, j)

func quitar() -> void:
	visible= false
	remove_from_group("interactuable")
