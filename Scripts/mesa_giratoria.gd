extends Node2D

const FOSO:= preload("res://Assets/Overworld/Gimnasios/mesa_giratoria.png")
const PUENTE :=preload("res://Assets/Overworld/Gimnasios/puente_giratorio.png")

@export var clave: String= ""
@export var vertical_inicial:= false

var puente: Sprite2D
var cuerpo :StaticBody2D
var brazos: Array[CollisionShape2D]= []

func _ready() -> void:
	add_to_group("mesa_giratoria")
	var foso:= Sprite2D.new()
	foso.texture= FOSO
	foso.z_index =-1
	add_child(foso)
	puente= Sprite2D.new()
	puente.texture =PUENTE
	puente.z_index= -1
	add_child(puente)
	cuerpo= StaticBody2D.new()
	add_child(cuerpo)
	for p in [Vector2(-16, -16), Vector2(16, -16), Vector2(-16, 16), Vector2(16, 16)]:
		_forma(p)
	for k in 2:
		brazos.append(_forma(Vector2.ZERO))
	_aplicar(false)

func _forma(p: Vector2) -> CollisionShape2D:
	var f:= CollisionShape2D.new()
	var r:= RectangleShape2D.new()
	r.size= Vector2(16, 16)
	f.shape =r
	f.position= p
	cuerpo.add_child(f)
	return f

func vertical() -> bool:
	return vertical_inicial!= (clave!= "" and Estado.tiene(clave))

func celdas() -> Array[Vector2i]:
	var c:= Rejilla.celda(self)
	var lista: Array[Vector2i]= []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			lista.append(c+ Vector2i(dx, dy))
	return lista

func girar() -> void:
	Estado.banderas[clave]= not Estado.tiene(clave)
	_aplicar(true)

func _aplicar(animar: bool) -> void:
	var v:= vertical()
	var cerrados:= [Vector2(-16, 0), Vector2(16, 0)] if v else [Vector2(0, -16), Vector2(0, 16)]
	for k in 2:
		brazos[k].position= cerrados[k]
	var destino:= PI/ 2.0 if v else 0.0
	if animar:
		var t:= create_tween()
		t.tween_property(puente, "rotation", destino, 0.45).set_trans(Tween.TRANS_SINE)
	else:
		puente.rotation =destino
