extends StaticBody2D

const TEXTURA:= preload("res://Assets/Overworld/Gimnasios/Galerias/campanilla.png")

@export_multiline var texto: String= "Tocaste la campanilla. Tu ánima volvió a su lugar."
@export_multiline var texto_paz :String= "La campanilla ya no hace falta: esta sala quedó en paz."

func _ready() -> void:
	add_to_group("interactuable")
	var tam:= Rejilla.tam(self)
	var s:= Sprite2D.new()
	s.texture= TEXTURA
	s.offset =Vector2(0, -(TEXTURA.get_height()- tam.y)/ 2.0)
	add_child(s)
	var f:= CollisionShape2D.new()
	var r :=RectangleShape2D.new()
	r.size= tam
	f.shape =r
	add_child(f)

func celda() -> Vector2i:
	return Rejilla.celda(self)

func interactuar(_jugador: Node) -> void:
	var sala:= get_parent()
	Sonido.efecto("campanada_sala", 1.7)
	if sala.resuelta():
		await Dialogo.mostrar(texto_paz)
		return
	sala.reiniciar()
	await Dialogo.mostrar(texto)
