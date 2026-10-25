extends Node2D

const TEXTURA:= preload("res://Assets/Overworld/Gimnasios/palanca.png")

@export var mesas: Array= []
@export_multiline var texto :String= "¡Clac! La mesa giratoria cambió de vía."

var sprite: Sprite2D

func _ready() -> void:
	add_to_group("interactuable")
	add_to_group("palanca")
	var cuerpo:= StaticBody2D.new()
	var forma:= CollisionShape2D.new()
	var r:= RectangleShape2D.new()
	r.size= Vector2(16, 16)
	forma.shape =r
	cuerpo.add_child(forma)
	add_child(cuerpo)
	sprite= Sprite2D.new()
	sprite.texture= TEXTURA
	sprite.hframes =2
	sprite.centered= false
	sprite.position =Vector2(-8, -24)
	add_child(sprite)
	_pintar()

func celda() -> Vector2i:
	return Rejilla.celda(self)

func _mesas() -> Array:
	var lista:= []
	for n in mesas:
		var m= get_parent().get_node_or_null(str(n))
		if m!= null:
			lista.append(m)
	return lista

func _pintar() -> void:
	var m:= _mesas()
	sprite.frame= 1 if not m.is_empty() and m[0].vertical()!= m[0].vertical_inicial else 0

func interactuar(jugador: Node) -> void:
	var c: Vector2i= jugador.celda()
	for m in _mesas():
		if m.celdas().has(c):
			await Dialogo.mostrar("Primero bajate de la mesa giratoria.")
			return
	Sonido.efecto("confirmar")
	for m in _mesas():
		m.girar()
	for p in get_tree().get_nodes_in_group("palanca"):
		p._pintar()
	await get_tree().create_timer(0.5).timeout
	await Dialogo.mostrar(texto)
