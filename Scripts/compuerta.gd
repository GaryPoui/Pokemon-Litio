extends Node2D

const ARTE:= preload("res://Assets/Overworld/Rutas9/volante_compuerta.png")

@export var alternativo: Array= []
@export var clave :String= "r9_compuerta"
@export_multiline var texto_cerrar: String= "Giraste el volante. La compuerta bajó y el agua de ese tramo quedó quieta."
@export_multiline var texto_abrir :String= "Giraste el volante. La compuerta subió y el agua vuelve a correr."

var original: Array= []
var sprite: Sprite2D

func _ready() -> void:
	add_to_group("interactuable")
	var cuerpo :=StaticBody2D.new()
	var forma:= CollisionShape2D.new()
	var r :=RectangleShape2D.new()
	r.size= Vector2(16, 16)
	forma.shape= r
	cuerpo.add_child(forma)
	add_child(cuerpo)
	sprite= Sprite2D.new()
	sprite.texture =ARTE
	sprite.hframes= 2
	sprite.centered= false
	sprite.position =Vector2(-8, -24)
	add_child(sprite)
	_iniciar.call_deferred()

func celda() -> Vector2i:
	return Rejilla.celda(self)

func cerrada() -> bool:
	return clave!= "" and Estado.banderas.get(clave, false)== true

func _iniciar() -> void:
	var su= get_parent().get_node_or_null("Suelo")
	if su== null:
		return
	original.clear()
	for c in alternativo:
		var v:= Vector2i(int(c[0]), int(c[1]))
		var a: Vector2i= su.get_cell_atlas_coords(v)
		original.append([v.x, v.y, su.get_cell_source_id(v), a.x, a.y])
	_pintar()

func _pintar() -> void:
	sprite.frame= 1 if cerrada() else 0
	var mapa= get_parent()
	if mapa!= null and mapa.has_method("cambiar_celdas"):
		mapa.cambiar_celdas(alternativo if cerrada() else original)

func interactuar(_jugador: Node) -> void:
	if cerrada():
		Estado.banderas.erase(clave)
	else:
		Estado.banderas[clave]= true
	_pintar()
	Sonido.efecto("chapoteo")
	await get_tree().create_timer(0.3).timeout
	await Dialogo.mostrar(texto_cerrar if cerrada() else texto_abrir)
