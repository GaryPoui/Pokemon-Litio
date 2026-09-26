extends Sprite2D

var fps: float= 10.0
var tiempo :=0.0
var pos_base: Vector2

func _ready() -> void:
	pos_base= position
	centered =false

func mostrar(especie: EspeciePokemon, espalda: bool) -> void:
	texture= especie.sprite_espalda if espalda else especie.sprite_frente
	hframes =maxi(1, especie.cuadros_espalda if espalda else especie.cuadros_frente)
	frame= 0
	tiempo =0.0
	fps= especie.fps_sprite
	var ancho:= floori(texture.get_width()/ float(hframes))
	offset= Vector2(-floori(ancho/ 2.0), -texture.get_height())
	position =pos_base
	modulate= Color.WHITE
	visible =true

func _process(delta: float) -> void:
	if texture== null or hframes<= 1 or not visible:
		return
	tiempo+= delta
	var n:= int(tiempo* fps) % hframes
	if n!= frame:
		frame =n
