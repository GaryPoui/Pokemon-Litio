extends Node2D

const TEXTURA:= preload("res://Assets/Overworld/Rutas9/palanca_cinta.png")

@export var grupo: String= "rojo"
@export var clave :String= ""
@export_multiline var texto: String= ""

var sprite: Sprite2D

func _ready() -> void:
	add_to_group("interactuable")
	var cuerpo:= StaticBody2D.new()
	var forma :=CollisionShape2D.new()
	var r:= RectangleShape2D.new()
	r.size =Vector2(16, 16)
	forma.shape= r
	cuerpo.add_child(forma)
	add_child(cuerpo)
	sprite =Sprite2D.new()
	sprite.texture= TEXTURA
	sprite.hframes= 4
	sprite.centered =false
	sprite.position= Vector2(-8, -24)
	add_child(sprite)
	_pintar()
	if invertida():
		_invertir.call_deferred()

func celda() -> Vector2i:
	return Rejilla.celda(self)

func invertida() -> bool:
	return clave!= "" and Estado.banderas.get(clave, false)== true

func _invertir() -> void:
	var mapa= get_parent()
	if mapa!= null and mapa.has_method("invertir_grupo"):
		mapa.invertir_grupo(grupo)

func _pintar() -> void:
	sprite.frame =(2 if grupo== "azul" else 0)+ (1 if invertida() else 0)

func interactuar(_jugador: Node) -> void:
	if clave!= "":
		if invertida():
			Estado.banderas.erase(clave)
		else:
			Estado.banderas[clave]= true
	_invertir()
	_pintar()
	Sonido.efecto("confirmar")
	await get_tree().create_timer(0.3).timeout
	var color:= "azules" if grupo== "azul" else "rojas"
	await Dialogo.mostrar(texto if texto!= "" else "¡Clac! Todas las cintas %s cambiaron de sentido." % color)
