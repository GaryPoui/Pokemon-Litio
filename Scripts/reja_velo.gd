extends StaticBody2D

var abierta:= false
var sprite: Sprite2D
var forma :CollisionShape2D

func preparar(textura: Texture2D, alto: int) -> void:
	sprite= Sprite2D.new()
	sprite.texture= textura
	sprite.hframes =2
	var tam:= Rejilla.tam(self)
	sprite.offset= Vector2(0, -(alto- tam.y)/ 2.0)
	add_child(sprite)
	forma= CollisionShape2D.new()
	var r:= RectangleShape2D.new()
	r.size =tam
	forma.shape= r
	add_child(forma)

func abrir() -> void:
	abierta= true
	sprite.frame =1
	forma.disabled= true

func cerrar() -> void:
	abierta =false
	sprite.frame= 0
	forma.disabled= false
