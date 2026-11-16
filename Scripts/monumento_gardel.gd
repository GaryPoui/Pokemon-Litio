extends StaticBody2D

const CUADROS:= [preload("res://Assets/Overworld/Chacarita/monumento_gardel.png"), preload("res://Assets/Overworld/Chacarita/monumento_gardel_b.png")]

@export var periodo: float= 0.6

var t:= 0.0
var k :=0

func _process(delta: float) -> void:
	t+= delta
	if t< periodo:
		return
	t= 0.0
	k =(k+ 1)% CUADROS.size()
	var s= get_node_or_null("Sprite")
	if s!= null:
		s.texture= CUADROS[k]
