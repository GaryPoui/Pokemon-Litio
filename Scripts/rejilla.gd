class_name Rejilla
extends RefCounted

const POR_DEFECTO:= Vector2(16, 16)

static func tam(n: Node) -> Vector2:
	var p:= n
	while p!= null:
		if "tam_celda" in p:
			return Vector2(p.tam_celda)
		p =p.get_parent()
	return POR_DEFECTO

static func celda(n: Node2D) -> Vector2i:
	return Vector2i((n.global_position/ tam(n)).floor())

static func centro(n: Node, c: Vector2i) -> Vector2:
	return (Vector2(c)+ Vector2(0.5, 0.5))* tam(n)
