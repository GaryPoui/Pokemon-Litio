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
	offset= _offset_base()
	position =pos_base
	modulate= Color.WHITE
	visible =true

func tam_cuadro() -> Vector2:
	if texture== null:
		return Vector2.ZERO
	return Vector2(floori(texture.get_width()/ float(hframes)), texture.get_height())

func _offset_base() -> Vector2:
	var t:= tam_cuadro()
	return Vector2(-floori(t.x/ 2.0), -t.y)

func ajustar(escala: Vector2, limite: Rect2, encoger: bool) -> Vector2:
	var t:= tam_cuadro()
	offset= _offset_base()
	if t== Vector2.ZERO:
		return escala
	var s:= escala
	if encoger:
		var alto_libre:= pos_base.y- limite.position.y
		var f:= minf(1.0, minf(alto_libre/ (t.y* s.y), limite.size.x/ (t.x* s.x)))
		s= s* f
	var izq:= pos_base.x+ offset.x* s.x
	var der:= izq+ t.x* s.x
	if izq< limite.position.x:
		offset.x+= (limite.position.x- izq)/ s.x
	elif der> limite.end.x:
		offset.x-= (der- limite.end.x)/ s.x
	var arriba:= pos_base.y+ offset.y* s.y
	if not encoger and arriba< limite.position.y:
		offset.y+= (limite.position.y- arriba)/ s.y
	return s

func encajar_en(marco: Rect2) -> void:
	var t:= tam_cuadro()
	if t== Vector2.ZERO:
		return
	var f:= minf(1.0, minf(marco.size.x/ t.x, marco.size.y/ t.y))
	scale= Vector2(f, f)
	offset= Vector2(-floori(t.x/ 2.0), -floori(t.y/ 2.0))
	pos_base= marco.get_center().round()
	position= pos_base

func _process(delta: float) -> void:
	if texture== null or hframes<= 1 or not visible:
		return
	tiempo+= delta
	var n:= int(tiempo* fps) % hframes
	if n!= frame:
		frame =n
