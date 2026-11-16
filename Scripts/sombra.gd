extends StaticBody2D

@export var clave: String= "r9_faroles"

var tiempo:= 0.0
var base: float

func _ready() -> void:
	if clave!= "" and Estado.tiene(clave):
		queue_free()
		return
	add_to_group("sombra")
	var s= get_node_or_null("Sprite")
	base= s.position.y if s!= null else 0.0

func _process(delta: float) -> void:
	tiempo+= delta
	var s= get_node_or_null("Sprite")
	if s!= null:
		s.position.y= base+ (0.0 if fmod(tiempo, 1.0)< 0.5 else -1.0)

func desvanecer() -> void:
	remove_from_group("sombra")
	collision_layer= 0
	var t:= create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.8)
	await t.finished
	queue_free()
