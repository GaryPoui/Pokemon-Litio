extends StaticBody2D

@export var clave: String= ""

func _ready() -> void:
	if clave!= "" and Estado.tiene(clave):
		queue_free()

func abrir() -> void:
	collision_layer= 0
	var t:= create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.6)
	t.tween_callback(queue_free)
