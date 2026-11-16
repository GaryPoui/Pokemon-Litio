extends Node2D

const ARTE:= preload("res://Assets/Overworld/Rutas9/farol_corrientes.png")
const APAGON :=preload("res://Scripts/apagon.gd")

@export var conectados: Array= []
@export var prendido:= false
@export var clave :String= "r9_faroles"
@export_multiline var texto_sin_llama: String= "Está apagado. Haría falta una llama para encenderlo."
@export_multiline var texto_resuelto :String= "Todos los faroles de Corrientes brillan otra vez. Las sombras que cortaban la avenida se deshacen en el aire."

var sprite: Sprite2D
var luz: PointLight2D

func _ready() -> void:
	add_to_group("interactuable")
	add_to_group("farol")
	if Estado.tiene(clave):
		prendido= true
	sprite= Sprite2D.new()
	sprite.texture =ARTE
	sprite.region_enabled= true
	sprite.centered= false
	sprite.position =Vector2(-8, 8- ARTE.get_height())
	add_child(sprite)
	var cuerpo:= StaticBody2D.new()
	var forma:= CollisionShape2D.new()
	var r:= RectangleShape2D.new()
	r.size= Vector2(14, 14)
	forma.shape =r
	cuerpo.add_child(forma)
	add_child(cuerpo)
	luz= APAGON.nueva_luz(52.0, Color(1.0, 0.86, 0.55), 1.1)
	luz.position= Vector2(0, -28)
	add_child(luz)
	_pintar()
	_cables.call_deferred()

func celda() -> Vector2i:
	return Rejilla.celda(self)

func _pintar() -> void:
	sprite.region_rect= Rect2(16 if prendido else 0, 0, 16, ARTE.get_height())
	luz.enabled =prendido

func alternar() -> void:
	prendido= not prendido
	_pintar()
	Sonido.efecto("farol")

func _cables() -> void:
	for n in conectados:
		var otro= get_parent().get_node_or_null(str(n))
		if otro== null or str(name)> str(otro.name):
			continue
		var cable:= Line2D.new()
		cable.width= 1.0
		cable.default_color =Color(0.12, 0.12, 0.16)
		cable.z_index= 3
		var a:= global_position+ Vector2(0, -34)
		var b: Vector2= otro.global_position+ Vector2(0, -34)
		var medio:= (a+ b)/ 2.0+ Vector2(0, 6)
		cable.points= PackedVector2Array([a, medio, b])
		get_parent().add_child(cable)

func interactuar(_jugador: Node) -> void:
	if get_parent().get_node_or_null("Litwick")== null:
		await Dialogo.mostrar(texto_sin_llama)
		return
	alternar()
	for n in conectados:
		var otro= get_parent().get_node_or_null(str(n))
		if otro!= null:
			otro.alternar()
	if Estado.tiene(clave):
		return
	for f in get_tree().get_nodes_in_group("farol"):
		if not f.prendido:
			return
	Estado.marcar(clave)
	for s in get_tree().get_nodes_in_group("sombra"):
		if s.has_method("desvanecer"):
			s.desvanecer()
	Sonido.jingle("objeto_clave")
	await Dialogo.mostrar(texto_resuelto)
	Sonido.cortar_jingle()
