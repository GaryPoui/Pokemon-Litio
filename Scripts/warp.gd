extends Node2D

@export_file("*.tscn") var destino: String= ""
@export var llegada: String =""
@export var direccion: Vector2= Vector2.DOWN
@export var sonido :String= "puerta"

func _ready() -> void:
	add_to_group("warp")

func celda() -> Vector2i:
	return Rejilla.celda(self)
