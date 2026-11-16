extends StaticBody2D

@export var color_rollo:= 0
@export var tile_tapado: Array= []

var moviendo :=false

func _ready() -> void:
	add_to_group("empujable")

func celda() -> Vector2i:
	return Rejilla.celda(self)

func empujar(dir: Vector2i) -> bool:
	if moviendo:
		return false
	var mapa:= get_tree().current_scene
	var c:= celda()
	var camino: Array[Vector2i]= []
	var cae:= false
	while camino.size()< 64:
		var n:= c+ dir
		if mapa.has_method("es_sotano") and mapa.es_sotano(n) and _sin_otros(n):
			camino.append(n)
			cae =true
			break
		if not _libre(n):
			break
		camino.append(n)
		c= n
	if camino.is_empty():
		return false
	moviendo= true
	Sonido.efecto("rollo")
	var t:= create_tween()
	for p in camino:
		t.tween_property(self, "position", Rejilla.centro(self, p), 0.08)
	await t.finished
	if cae:
		await _caer(mapa, camino.back())
		return true
	moviendo =false
	return true

func _sin_otros(c: Vector2i) -> bool:
	for n in get_tree().get_nodes_in_group("empujable"):
		if n!= self and n.celda()== c:
			return false
	return true

func _libre(c: Vector2i) -> bool:
	if not _sin_otros(c):
		return false
	for n in get_tree().get_nodes_in_group("interactuable"):
		if n.has_method("celda") and n.celda()== c and n is PhysicsBody2D:
			return false
	var q:= PhysicsPointQueryParameters2D.new()
	q.position= Rejilla.centro(self, c)
	q.exclude= [get_rid()]
	return get_world_2d().direct_space_state.intersect_point(q).is_empty()

func _caer(mapa: Node, c: Vector2i) -> void:
	Sonido.efecto("caida")
	if tile_tapado.size()>= 3:
		mapa.cambiar_celdas([[c.x, c.y, int(tile_tapado[0]), int(tile_tapado[1]), int(tile_tapado[2])]])
	var s: Node2D= get_node_or_null("Sprite")
	if s!= null:
		var t:= create_tween()
		t.tween_property(s, "scale", Vector2(0.3, 0.3), 0.12)
		await t.finished
	remove_from_group("empujable")
	queue_free()
