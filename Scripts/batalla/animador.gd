extends RefCounted

const RUTA:= "res://Assets/Batalla/anim/"
const CATALOGOS :=["res://Scripts/batalla/anims_galerias.gd"]

static var activo:= true
static var en_curso :=false
static var ultima:= ""
static var cuenta :=0
static var cargados: Array= []

static func catalogo(id: String):
	if cargados.is_empty():
		for ruta in CATALOGOS:
			cargados.append(load(ruta))
	for c in cargados:
		if c.LISTA.has(id):
			return c
	return null

static func tiene(id: String) -> bool:
	return catalogo(id)!= null

static func reproducir(b: Node, e: Dictionary) -> void:
	var id:= str(e.get("mov", ""))
	var cat= catalogo(id)
	if not activo or cat== null:
		return
	en_curso= true
	ultima =id
	cuenta+= 1
	var guardado:= guardar(b)
	await cat.call(str(cat.LISTA[id]), b, str(e["de"]), str(e["a"]))
	if is_instance_valid(b):
		limpiar(b)
		restaurar(b, guardado)
	en_curso= false

static func capa(b: Node) -> Node2D:
	var c: Node2D= b.get_node_or_null("Efectos")
	if c== null:
		c= Node2D.new()
		c.name= "Efectos"
		b.add_child(c)
		b.move_child(c, b.get_node("PanelRival").get_index())
	return c

static func sprite(b: Node, lado: String) -> Sprite2D:
	return b.sprite_rival if lado== "rival" else b.sprite_jugador

static func pies(b: Node, lado: String) -> Vector2:
	var s:= sprite(b, lado)
	return s.pos_base if "pos_base" in s else s.position

static func centro(b: Node, lado: String) -> Vector2:
	var s:= sprite(b, lado)
	var alto:= 48.0
	if s.texture!= null:
		alto= clampf(s.texture.get_height()* s.scale.y, 32.0, 110.0)
	return (pies(b, lado)+ Vector2(0, -alto* 0.5)).round()

static func guardar(b: Node) -> Array:
	var out:= []
	for s in [b.sprite_rival, b.sprite_jugador]:
		out.append({"position": s.position, "scale": s.scale, "offset": s.offset, "modulate": s.modulate, "self_modulate": s.self_modulate, "visible": s.visible, "rotation": s.rotation})
	return out

static func restaurar(b: Node, guardado: Array) -> void:
	var lista:= [b.sprite_rival, b.sprite_jugador]
	for k in lista.size():
		for prop in guardado[k]:
			lista[k].set(prop, guardado[k][prop])

static func limpiar(b: Node) -> void:
	var c: Node= b.get_node_or_null("Efectos")
	if c== null:
		return
	for h in c.get_children():
		c.remove_child(h)
		h.queue_free()

static func figura(b: Node, nombre: String, pos: Vector2, cuadros:= 1) -> Sprite2D:
	var s:= Sprite2D.new()
	s.texture= load(RUTA+ nombre+ ".png")
	s.hframes= maxi(1, cuadros)
	s.position =pos.round()
	s.texture_filter= CanvasItem.TEXTURE_FILTER_NEAREST
	capa(b).add_child(s)
	return s

static func cuadros(b: Node, s: Sprite2D, dur: float, desde:= 0, hasta:= -1) -> void:
	var fin:= s.hframes- 1 if hasta< 0 else hasta
	var n:= absi(fin- desde)+ 1
	var sentido:= 1 if fin>= desde else -1
	var paso:= func(v: float) -> void:
		if is_instance_valid(s):
			s.frame= clampi(desde+ sentido* int(v), mini(desde, fin), maxi(desde, fin))
	var t:= b.create_tween()
	t.tween_method(paso, 0.0, float(n)- 0.01, dur)
	await t.finished

static func rafaga(b: Node, nombre: String, n_cuadros: int, o: Vector2, d: Vector2, n: int, dur: float, dispersion: Vector2, cuadro_fijo:= -1) -> void:
	var lista: Array= []
	for k in n:
		var s:= figura(b, nombre, o, n_cuadros)
		s.visible= false
		s.flip_h =d.x< o.x
		if cuadro_fijo>= 0:
			s.frame= cuadro_fijo
		elif n_cuadros> 1:
			s.frame =k% n_cuadros
		lista.append(s)
	var paso:= func(u: float) -> void:
		for k in lista.size():
			var s: Sprite2D= lista[k]
			if not is_instance_valid(s):
				continue
			var fase:= u* (1.0+ 0.12* n)- 0.12* k
			s.visible= fase> 0.0 and fase< 1.0
			var corr:= Vector2(sin(k* 2.4)* dispersion.x, cos(k* 1.7)* dispersion.y)
			s.position =((o+ corr).lerp(d+ corr, clampf(fase, 0.0, 1.0))).round()
	var t:= b.create_tween()
	t.tween_method(paso, 0.0, 1.0, dur)
	await t.finished

static func recorrer(b: Node, paso: Callable, dur: float) -> void:
	var t:= b.create_tween()
	t.tween_method(paso, 0.0, 1.0, dur)
	await t.finished

static func luchador(b: Node, lado: String) -> Luchador:
	return b.logica.j if lado== "jugador" else b.logica.r

static func ciclo(b: Node, s: Sprite2D, desde: int, hasta: int, fps: float, dur: float) -> void:
	var n:= hasta- desde+ 1
	var paso:= func(v: float) -> void:
		if is_instance_valid(s):
			s.frame= desde+ int(v* fps) % n
	var t:= b.create_tween()
	t.tween_method(paso, 0.0, dur, dur)

static func mover(b: Node, n: Node2D, hasta: Vector2, dur: float, trans:= Tween.TRANS_SINE, suavizado:= Tween.EASE_IN_OUT) -> void:
	var t:= b.create_tween()
	t.tween_property(n, "position", hasta, dur).set_trans(trans).set_ease(suavizado)
	await t.finished

static func destello(b: Node, n: CanvasItem, color: Color, dur: float) -> void:
	var t:= b.create_tween()
	t.tween_property(n, "modulate", color, dur* 0.4)
	t.tween_property(n, "modulate", Color.WHITE, dur* 0.6)
	await t.finished

static func sacudir(b: Node, n: Node2D, px: float, dur: float, vertical:= false) -> void:
	var base:= n.position
	var eje:= Vector2(0, 1) if vertical else Vector2(1, 0)
	var t:= b.create_tween()
	var pasos:= maxi(2, int(dur/ 0.05))
	for k in pasos:
		t.tween_property(n, "position", base+ eje* (px if k% 2== 0 else -px), dur/ pasos)
	t.tween_property(n, "position", base, 0.03)
	await t.finished

static func esperar(b: Node, t: float) -> void:
	await b.get_tree().create_timer(t).timeout

static func sonido(b: Node, nombre: String, tono:= 1.0) -> void:
	var s:= b.get_node_or_null("/root/Sonido")
	if s!= null:
		s.efecto(nombre, tono)
