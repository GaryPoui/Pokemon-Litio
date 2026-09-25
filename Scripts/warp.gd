extends Node2D

@export_file("*.tscn") var destino: String= ""
@export var llegada: String =""
@export var direccion: Vector2= Vector2.DOWN

func _ready() -> void:
	add_to_group("warp")

func celda() -> Vector2i:
	return Vector2i((global_position/ 16.0).floor())
