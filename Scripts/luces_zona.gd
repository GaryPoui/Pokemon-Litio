extends Node2D

const APAGON:= preload("res://Scripts/apagon.gd")
const COLORES:= [Color("ff5ab4"), Color("5ad8f0"), Color("ffd84a"), Color("b48cff")]

@export var clave: String= ""
@export var puntos :Array= []
@export var color: Color= Color(1.0, 0.85, 0.6)
@export var radio :float= 56.0
@export var energia: float= 1.0
@export var baile:= false

var luces: Array[PointLight2D]= []
var tiempo :=0.0

func _ready() -> void:
	add_to_group("luces_zona")
	for p in puntos:
		var c:= Vector2i(int(p[0]), int(p[1])) if p is Array else Vector2i(p)
		var l:= APAGON.nueva_luz(radio, color, energia)
		add_child(l)
		l.global_position= Rejilla.centro(self, c)
		luces.append(l)
	for l in luces:
		l.enabled= encendida()

func encendida() -> bool:
	return clave== "" or Estado.tiene(clave)

func revisar() -> void:
	if not encendida():
		return
	for l in luces:
		if l.enabled:
			continue
		l.enabled =true
		l.energy= 0.0
		var t:= create_tween()
		t.tween_property(l, "energy", energia, 0.8)

func _process(delta: float) -> void:
	if not baile or luces.is_empty() or not luces[0].enabled:
		return
	tiempo+= delta
	var k:= int(tiempo* 2.0)
	for i in luces.size():
		luces[i].color= COLORES[(k+ i)% COLORES.size()]
