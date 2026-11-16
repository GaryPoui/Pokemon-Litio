extends Node2D

@export var estatuas: Array= []
@export var pedestales: Array= []
@export var entrada: Array= []
@export var area: Array= []
@export var clave:= "r8_estatuas"
@export var escalera :String= ""
@export_multiline var texto_atrapado: String= "Sentiste un frío en la nuca… y de golpe estabas otra vez en la entrada de la plaza."
@export_multiline var texto_abierto :String= "Las dos estatuas quedaron quietas sobre sus pedestales. Algo crujió en el mausoleo: ¡la reja de la cripta se abrió!"

var nodos: Array= []
var atrapando:= false

func _ready() -> void:
	_preparar.call_deferred()

func _preparar() -> void:
	for n in estatuas:
		var e= get_parent().get_node_or_null(str(n))
		if e!= null:
			nodos.append(e)
	if Estado.tiene(clave):
		for i in nodos.size():
			if i< pedestales.size():
				nodos[i].colocar_en(_v(pedestales[i]))
				nodos[i].trabada= true
	var j= get_parent().get_node_or_null("Jugador")
	if j!= null:
		j.paso_terminado.connect(_al_paso)

func _v(a) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))

func en_area(c: Vector2i) -> bool:
	if area.size()< 4:
		return true
	return c.x>= int(area[0]) and c.y >=int(area[1]) and c.x<= int(area[2]) and c.y<= int(area[3])

static func delante(e: Vector2i, p: Vector2i, mira: Vector2i) -> bool:
	return (e.x- p.x)* mira.x+ (e.y- p.y) * mira.y> 0

static func vecinas(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x- b.x)+ absi(a.y -b.y)== 1

func _libre(c: Vector2i, p: Vector2i, propia: Node) -> bool:
	if c== p or not en_area(c):
		return false
	for e in nodos:
		if e!= propia and e.celda()== c:
			return false
	var q:= PhysicsPointQueryParameters2D.new()
	q.position= Rejilla.centro(self, c)
	var fuera: Array[RID]= []
	for e in nodos:
		fuera.append(e.get_rid())
	var j= get_parent().get_node_or_null("Jugador")
	if j!= null:
		fuera.append(j.get_rid())
	q.exclude= fuera
	return get_world_2d().direct_space_state.intersect_point(q).is_empty()

func paso(e: Node, p: Vector2i) -> Vector2i:
	var c: Vector2i= e.celda()
	var dx:= p.x- c.x
	var dy :=p.y- c.y
	var sx:= signi(dx)
	var sy:= signi(dy)
	var ejes: Array[Vector2i]= []
	if absi(dy)>= absi(dx):
		ejes= [Vector2i(0, sy), Vector2i(sx, 0)]
	else:
		ejes =[Vector2i(sx, 0), Vector2i(0, sy)]
	for d in ejes:
		if d== Vector2i.ZERO:
			continue
		if _libre(c+ d, p, e):
			return c+ d
	return c

func _al_paso(c: Vector2i) -> void:
	if atrapando or Estado.tiene(clave) or nodos.is_empty():
		return
	var j= get_parent().get_node("Jugador")
	if not en_area(c):
		for e in nodos:
			if not e.trabada and e.celda()!= e.inicio:
				e.colocar_en(e.inicio)
		return
	var mira:= Vector2i(j.last_direction)
	var ped: Array= pedestales.map(_v)
	for e in nodos:
		if e.trabada or delante(e.celda(), c, mira):
			continue
		var n:= paso(e, c)
		if n!= e.celda():
			e.mover_a(n)
			if ped.has(n):
				e.trabar()
	if nodos.all(func(e): return e.trabada):
		await _abrir(j)
		return
	for e in nodos:
		if not e.trabada and vecinas(e.celda(), c) and not delante(e.celda(), c, mira):
			await _atrapar(j)
			return

func _atrapar(j: Node) -> void:
	atrapando= true
	j.en_evento =true
	await get_tree().create_timer(0.2).timeout
	await GestorEscenas.fundido(func():
		j.colocar(Rejilla.centro(j, _v(entrada)), Vector2.UP)
		for e in nodos:
			if not e.trabada:
				e.colocar_en(e.inicio)
	)
	await Dialogo.mostrar(texto_atrapado)
	if is_instance_valid(j):
		j.en_evento= false
	atrapando =false

func _abrir(j: Node) -> void:
	Estado.marcar(clave)
	j.en_evento= true
	Sonido.jingle("objeto_clave")
	var r= get_parent().get_node_or_null(escalera)
	if r!= null and r.has_method("abrir"):
		r.abrir()
	await Dialogo.mostrar(texto_abierto)
	Sonido.cortar_jingle()
	if is_instance_valid(j):
		j.en_evento =false
