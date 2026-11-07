extends StaticBody2D

var tranquera: Node
var indice := 0

func _ready() -> void:
	add_to_group("empujable")

func celda() -> Vector2i:
	return Rejilla.celda(self)

func empujar(dir: Vector2i) -> bool:
	if tranquera ==null:
		return false
	var brazo: Vector2i= tranquera.dirs[indice]
	if brazo.x* dir.x +brazo.y* dir.y !=0:
		return false
	tranquera.girar(brazo, dir)
	return true
