extends "res://Scripts/npc.gd"

var trabada:= false
var inicio: Vector2i
var ocupada :Vector2i
var base_sprite: Vector2

func _ready() -> void:
	super._ready()
	inicio= Rejilla.celda(self)
	ocupada =inicio
	base_sprite= sprite.position

func celda() -> Vector2i:
	return ocupada

func mover_a(c: Vector2i) -> void:
	var antes:= position
	var dir:= Vector2(c- ocupada)
	ocupada= c
	position =Rejilla.centro(self, c)
	_mirar(dir)
	sprite.position= base_sprite+ (antes- position)
	Sonido.efecto("estatua")
	var t:= create_tween()
	t.tween_property(sprite, "position", base_sprite, 0.15)

func colocar_en(c: Vector2i) -> void:
	ocupada= c
	position= Rejilla.centro(self, c)
	sprite.position =base_sprite
	_mirar(mirando)

func trabar() -> void:
	trabada= true
	var t:= create_tween()
	t.tween_property(sprite, "modulate", Color(1.7, 1.6, 1.1), 0.15)
	t.tween_property(sprite, "modulate", Color(1, 1, 1), 0.4)

func interactuar(_jugador: Node) -> void:
	if texto!= "":
		await Dialogo.mostrar(texto)
