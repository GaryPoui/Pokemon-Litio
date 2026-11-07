extends Node2D

@export var item_id: String= "potion"
@export var cantidad: int =1
@export var clave: String= ""
@export var brillo :=true

const RADIO_DETECTOR :=3

var tiempo:= 0.0
var encendido :=false

func _ready() -> void:
	if clave!= "" and Estado.tiene(clave):
		queue_free()
		return
	add_to_group("interactuable")
	add_to_group("objeto_oculto")
	tiempo= randf()* 4.0

func celda() -> Vector2i:
	return Rejilla.celda(self)

func cerca_de(c: Vector2i, radio: int) -> bool:
	var d:= (c -celda()).abs()
	return maxi(d.x, d.y)<= radio

func _periodo() -> float:
	var escena:= get_tree().current_scene
	var j: Node= escena.get_node_or_null("Jugador") if escena!= null else null
	if j!= null and cerca_de(j.celda(), RADIO_DETECTOR) and EfectosTrinket.total("detector", null, Equipo.miembros)> 0.0:
		return 1.2
	return 4.5

func _process(delta: float) -> void:
	if not brillo:
		return
	tiempo+= delta
	var antes:= encendido
	encendido= fmod(tiempo, _periodo())< 0.18
	if antes!= encendido:
		queue_redraw()

func _draw() -> void:
	if not encendido:
		return
	var c:= Color(1, 1, 0.85, 0.9)
	draw_rect(Rect2(-1, 1, 3, 1), c)
	draw_rect(Rect2(0, 0, 1, 3), c)

func interactuar(_jugador: Node) -> void:
	if not Inventario.add_item(item_id, cantidad):
		return
	if clave!= "":
		Estado.marcar(clave)
	remove_from_group("interactuable")
	var nombre:= Inventario.get_item_name(item_id)
	Sonido.jingle("objeto")
	if cantidad> 1:
		await Dialogo.mostrar("¡Encontraste %s x%d escondido!" % [nombre, cantidad])
	else:
		await Dialogo.mostrar("¡Encontraste %s escondido!" % nombre)
	Sonido.cortar_jingle()
	queue_free()
