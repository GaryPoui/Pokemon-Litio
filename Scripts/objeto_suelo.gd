extends StaticBody2D

@export var item_id: String= "potion"
@export var cantidad: int =1
@export var clave: String= ""

func _ready() -> void:
	if clave!= "" and Estado.tiene(clave):
		queue_free()
		return
	add_to_group("interactuable")

func celda() -> Vector2i:
	return Vector2i((global_position/ 16.0).floor())

func interactuar(_jugador: Node) -> void:
	if not Inventario.add_item(item_id, cantidad):
		return
	if clave !="":
		Estado.marcar(clave)
	remove_from_group("interactuable")
	visible= false
	$CollisionShape2D.set_deferred("disabled", true)
	var nombre:= Inventario.get_item_name(item_id)
	var o:= Inventario.get_objeto(item_id)
	Sonido.jingle("objeto_clave" if o!= null and o.categoria== "CLAVE" else "objeto")
	if cantidad> 1:
		await Dialogo.mostrar("¡Encontraste %s x%d!" % [nombre, cantidad])
	else:
		await Dialogo.mostrar("¡Encontraste %s!" % nombre)
	Sonido.cortar_jingle()
	queue_free()
