extends Node2D

@export var brazos: Array = []

const POSTE :=preload("res://Assets/Overworld/Rutas7/tranquera_poste.png")
const BRAZO_H := preload("res://Assets/Overworld/Rutas7/tranquera_brazo_h.png")
const BRAZO_V := preload("res://Assets/Overworld/Rutas7/tranquera_brazo_v.png")
const BRAZO :=preload("res://Scripts/brazo_tranquera.gd")
const DIR:= {"arriba": Vector2i.UP, "abajo": Vector2i.DOWN, "izquierda": Vector2i.LEFT, "derecha": Vector2i.RIGHT}

var dirs: Array[Vector2i] =[]
var cuerpos: Array= []
var giros:= 0
var girando :=false
var giro: Node2D

func _ready() -> void:
	y_sort_enabled= true
	for b in brazos:
		dirs.append(DIR.get(str(b), Vector2i.ZERO))
	var poste := StaticBody2D.new()
	poste.add_child(_forma())
	var sp :=Sprite2D.new()
	sp.texture =POSTE
	sp.offset= Vector2(0, -1)
	poste.add_child(sp)
	add_child(poste)
	giro= Node2D.new()
	add_child(giro)
	for k in dirs.size():
		var c:= StaticBody2D.new()
		c.set_script(BRAZO)
		c.tranquera = self
		c.indice =k
		c.add_child(_forma())
		var s :=Sprite2D.new()
		s.name= "Sprite"
		c.add_child(s)
		add_child(c)
		cuerpos.append(c)
	_ubicar()

func _forma() -> CollisionShape2D:
	var f :=CollisionShape2D.new()
	var r:= RectangleShape2D.new()
	r.size= Vector2(Rejilla.tam(self))- Vector2(2, 2)
	f.shape =r
	return f

func celda() -> Vector2i:
	return Rejilla.celda(self)

func estado() -> Array:
	var out: Array =[]
	for d in dirs:
		out.append(DIR.find_key(d))
	return out

func _ubicar() -> void:
	var t := Vector2(Rejilla.tam(self))
	for k in dirs.size():
		var c: Node2D = cuerpos[k]
		c.position = Vector2(dirs[k]) *t
		var s: Sprite2D= c.get_node("Sprite")
		s.texture= BRAZO_H if dirs[k].y == 0 else BRAZO_V
		s.visible = true

func _rotar(v: Vector2i, sentido: int) -> Vector2i:
	return Vector2i(-v.y, v.x) if sentido > 0 else Vector2i(v.y, -v.x)

func _libre(c: Vector2i) -> bool:
	var q:= PhysicsPointQueryParameters2D.new()
	q.position = Rejilla.centro(self, c)
	var propios: Array[RID] = []
	for b in cuerpos:
		propios.append(b.get_rid())
	q.exclude= propios
	for h in get_world_2d().direct_space_state.intersect_point(q):
		if h["collider"]!= null and h["collider"].get_parent() == self:
			continue
		return false
	return true

func girar(brazo: Vector2i, empuje: Vector2i) -> bool:
	if girando or brazo.x * empuje.x+ brazo.y* empuje.y != 0:
		return false
	var cruz:= brazo.x *empuje.y - brazo.y * empuje.x
	var sentido :=1 if cruz >0 else -1
	var poste := celda()
	for d in dirs:
		var nd := _rotar(d, sentido)
		for c in [poste+ d+ nd, poste +nd]:
			if not _libre(c):
				return false
	var nuevos: Array[Vector2i]= []
	for d in dirs:
		nuevos.append(_rotar(d, sentido))
	girando= true
	giros +=1
	Sonido.efecto("bisagra")
	var visuales: Array = []
	for k in dirs.size():
		var s:= Sprite2D.new()
		s.texture = BRAZO_H if dirs[k].y == 0 else BRAZO_V
		s.position = Vector2(dirs[k])* Vector2(Rejilla.tam(self))
		giro.add_child(s)
		visuales.append(s)
		cuerpos[k].get_node("Sprite").visible= false
	dirs = nuevos
	for k in dirs.size():
		cuerpos[k].position =Vector2(dirs[k]) * Vector2(Rejilla.tam(self))
	var tw := create_tween()
	tw.tween_property(giro, "rotation", PI /2.0 * sentido, 0.25)
	await tw.finished
	for s in visuales:
		s.queue_free()
	giro.rotation =0.0
	_ubicar()
	girando = false
	return true
