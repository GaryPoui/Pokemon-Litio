extends StaticBody2D

@export var metas: Array= []
@export var barrera :String= ""
@export var clave: String= ""
@export_multiline var texto_gol :String= "¡GOOOL! ¡La barrera se abrió!"

var moviendo:= false

func _ready() -> void:
	if clave!= "" and Estado.tiene(clave):
		queue_free()
		return
	add_to_group("empujable")

func celda() -> Vector2i:
	return Rejilla.celda(self)

func celdas_meta() -> Array[Vector2i]:
	var lista: Array[Vector2i]= []
	for m in metas:
		lista.append(Vector2i(int(m[0]), int(m[1])) if m is Array else Vector2i(m))
	return lista

func empujar(dir: Vector2i) -> bool:
	if moviendo:
		return false
	var destino:= celda()+ dir
	var gol:= celdas_meta().has(destino)
	if not gol and not _libre(destino):
		return false
	moviendo= true
	Sonido.efecto("choque")
	var t:= create_tween()
	t.tween_property(self, "position", Rejilla.centro(self, destino), 0.14)
	await t.finished
	moviendo =false
	if gol:
		await _gol()
	return true

func _libre(c: Vector2i) -> bool:
	for n in get_tree().get_nodes_in_group("empujable"):
		if n!= self and n.celda()== c:
			return false
	for n in get_tree().get_nodes_in_group("interactuable"):
		if n.has_method("celda") and n.celda()== c and n is PhysicsBody2D:
			return false
	var q:= PhysicsPointQueryParameters2D.new()
	q.position= Rejilla.centro(self, c)
	q.exclude= [get_rid()]
	return get_world_2d().direct_space_state.intersect_point(q).is_empty()

func _gol() -> void:
	if clave!= "":
		Estado.marcar(clave)
	remove_from_group("empujable")
	var j= get_tree().current_scene.get_node_or_null("Jugador")
	if j!= null:
		j.en_evento= true
	Sonido.jingle("objeto_clave")
	var b= get_tree().current_scene.get_node_or_null(barrera)
	if b!= null and b.has_method("abrir"):
		b.abrir()
	var t:= create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.4)
	await Dialogo.mostrar(texto_gol)
	Sonido.cortar_jingle()
	if j!= null and is_instance_valid(j):
		j.en_evento= false
	queue_free()
