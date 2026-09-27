extends Node2D

const HUECOS:= [Vector2(92, 52), Vector2(101, 52), Vector2(92, 55), Vector2(101, 55), Vector2(92, 58), Vector2(101, 58)]
const PAUSA :=0.32
const DIBUJO:= [" TTT ", "TTTTT", "KKWKK", " WWW "]

var bolas: Array[Sprite2D]= []
var cache :={}

func colocar(equipo: Array) -> void:
	limpiar()
	for i in mini(equipo.size(), HUECOS.size()):
		var s:= Sprite2D.new()
		s.texture= mini_ball(str(equipo[i].ball))
		s.centered =false
		s.position= HUECOS[i]
		add_child(s)
		bolas.append(s)
		Sonido.efecto("ball_maquina")
		await get_tree().create_timer(PAUSA).timeout

func parpadear(duracion: float) -> void:
	var t:= create_tween().set_loops(maxi(1, int(duracion/ 0.3)))
	t.tween_callback(func(): _brillo(1.5))
	t.tween_interval(0.15)
	t.tween_callback(func(): _brillo(1.0))
	t.tween_interval(0.15)

func _brillo(v: float) -> void:
	for b in bolas:
		if is_instance_valid(b):
			b.modulate= Color(v, v, v)

func limpiar() -> void:
	for b in bolas:
		if is_instance_valid(b):
			b.queue_free()
	bolas.clear()

func mini_ball(id: String) -> ImageTexture:
	if cache.has(id):
		return cache[id]
	var arriba:= Color("e83838")
	var img: Image= null
	var ruta:= "res://Assets/Batalla/balls/%s.png" % id
	if ResourceLoader.exists(ruta):
		img= (load(ruta) as Texture2D).get_image().get_region(Rect2i(0, 0, 18, 18))
	else:
		var o:= BaseDatos.objeto(id)
		if o!= null and o.icono!= null:
			img= o.icono.get_image()
	if img!= null:
		var r:= img.get_used_rect()
		var conteo:= {}
		for y in range(r.position.y, r.position.y+ r.size.y/ 2):
			for x in range(r.position.x, r.end.x):
				var c:= img.get_pixel(x, y)
				if c.a> 0.9 and c.s> 0.3 and c.v> 0.35:
					conteo[c]= int(conteo.get(c, 0))+ 1
		var mas:= 0
		for c in conteo:
			if conteo[c]> mas:
				mas= conteo[c]
				arriba =c
	var ti:= Image.create(5, 4, false, Image.FORMAT_RGBA8)
	var colores:= {"K": Color("282830"), "T": arriba, "W": Color("f8f8f8")}
	for y in DIBUJO.size():
		for x in 5:
			var ch: String= DIBUJO[y][x]
			ti.set_pixel(x, y, colores[ch] if colores.has(ch) else Color(0, 0, 0, 0))
	var tex:= ImageTexture.create_from_image(ti)
	cache[id]= tex
	return tex
