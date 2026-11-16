extends StaticBody2D

const APAGON:= preload("res://Scripts/apagon.gd")

@export var radio: float= 40.0
@export var energia :float= 0.5
@export var color: Color= Color(1.0, 0.84, 0.58)
@export var altura :float= 31.0

func _ready() -> void:
	var l:= APAGON.nueva_luz(radio, color, energia)
	l.name= "Luz"
	l.position =Vector2(0, -altura)
	l.add_to_group("ambiente_luz")
	add_child(l)
