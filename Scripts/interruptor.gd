extends Node2D

const TEXTURA:= preload("res://Assets/Overworld/Gimnasios/interruptor.png")

@export var clave: String= ""
@export var barrera :String= ""
@export_multiline var texto: String= "¡Clac! Volvió la luz."
@export_multiline var texto_hecho :String= "La térmica ya está levantada."

var sprite: Sprite2D

func _ready() -> void:
	add_to_group("interactuable")
	var cuerpo:= StaticBody2D.new()
	var forma:= CollisionShape2D.new()
	var r:= RectangleShape2D.new()
	r.size= Vector2(16, 16)
	forma.shape =r
	cuerpo.add_child(forma)
	add_child(cuerpo)
	sprite= Sprite2D.new()
	sprite.texture =TEXTURA
	sprite.hframes= 2
	sprite.centered= false
	sprite.position =Vector2(-8, -24)
	add_child(sprite)
	sprite.frame= 1 if encendido() else 0

func celda() -> Vector2i:
	return Rejilla.celda(self)

func encendido() -> bool:
	return clave!= "" and Estado.tiene(clave)

func interactuar(_jugador: Node) -> void:
	if encendido():
		await Dialogo.mostrar(texto_hecho)
		return
	Estado.marcar(clave)
	sprite.frame =1
	Sonido.efecto("confirmar")
	get_tree().call_group("luces_zona", "revisar")
	var b= get_parent().get_node_or_null(barrera) if barrera!= "" else null
	if b!= null and b.has_method("abrir"):
		b.abrir()
	Sonido.jingle("objeto_clave")
	await Dialogo.mostrar(texto)
	Sonido.cortar_jingle()
