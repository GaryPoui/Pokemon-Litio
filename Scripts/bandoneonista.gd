extends "res://Scripts/npc.gd"

const TANGO :=preload("res://Scripts/tango.gd")

@export var frase:= 0
@export var tango :String= "Tango"

var burbuja: Sprite2D

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	if texto!= "":
		await Dialogo.mostrar(texto)
	_mostrar_figura()
	await Sonido.jingle("tango_frase_%d" % frase)
	if is_instance_valid(burbuja):
		burbuja.queue_free()
	var t= get_parent().get_node_or_null(tango)
	if t!= null and t.has_method("tocar"):
		await t.tocar(frase)

func _mostrar_figura() -> void:
	burbuja= Sprite2D.new()
	burbuja.texture =TANGO.figura(frase)
	burbuja.position= Vector2(0, -30)
	burbuja.z_index= 5
	add_child(burbuja)
	var t:= create_tween().set_loops(3)
	t.tween_property(burbuja, "position:y", -32.0, 0.3)
	t.tween_property(burbuja, "position:y", -30.0, 0.3)
