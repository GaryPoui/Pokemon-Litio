extends Node2D

@export var tinte: Color= Color(0.88, 0.76, 0.84)

func _ready() -> void:
	add_to_group("ambiente_luz")
	var m:= CanvasModulate.new()
	m.name= "Tinte"
	m.color =tinte
	add_child(m)
