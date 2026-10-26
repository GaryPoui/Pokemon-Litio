extends "res://Scripts/npc.gd"

const ALERTA:= "res://Assets/UI/exclamacion.png"
const DIRS :=[Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT]

@export_group("Rival")
@export_enum("laboca", "cabildo") var evento: String= "laboca"
@export var clave: String =""
@export var datos_snivy: EquipoEntrenador
@export var datos_tepig :EquipoEntrenador
@export var datos_oshawott: EquipoEntrenador
@export var fila_disparo:= -1
@export var salida: Vector2= Vector2.RIGHT
@export var tiempo_paso :=0.22
@export_multiline var texto_llamada: String= "¡Eh! ¡Esperá!"
@export_multiline var texto_victoria :String= ""
@export_multiline var texto_derrota: String =""
@export_multiline var texto_despues: String= ""
@export_multiline var texto_curar :String= ""
@export_multiline var texto_salida: String =""

var ocupado:= false
var jugador: Node

func _ready() -> void:
	super._ready()
	add_to_group("rival")
	if hecho():
		queue_free()
		return
	if evento== "laboca" and Estado.inicial()== "":
		_mostrar(false)
	_conectar.call_deferred()

func hecho() -> bool:
	return clave!= "" and Estado.tiene(clave)

func datos() -> EquipoEntrenador:
	match Estado.inicial():
		"tepig":
			return datos_tepig
		"oshawott":
			return datos_oshawott
	return datos_snivy

func _conectar() -> void:
	var m:= get_tree().current_scene
	if m== null or not "jugador" in m or m.jugador== null:
		return
	jugador= m.jugador
	if fila_disparo>= 0 and not jugador.paso_terminado.is_connected(_al_paso):
		jugador.paso_terminado.connect(_al_paso)

func _mostrar(si: bool) -> void:
	visible= si
	var cs:= get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs!= null:
		cs.set_deferred("disabled", not si)
	if si:
		add_to_group("interactuable")
	else:
		remove_from_group("interactuable")

func interactuar(j: Node) -> void:
	_mirar(-j.last_direction)
	if hecho():
		await Dialogo.mostrar(texto_despues)
		return
	if ocupado or Equipo.primero_util()== null:
		return
	ocupado= true
	jugador =j
	await _pelear()
	ocupado= false

func al_elegir_inicial(j: Node) -> void:
	if evento!= "laboca" or ocupado or hecho():
		return
	ocupado= true
	jugador= j
	var objetivo:= _junto_a(j.celda())
	var inicio:= objetivo
	for k in range(1, 10):
		if not _libre(objetivo+ Vector2i(k, 0)):
			break
		inicio= objetivo+ Vector2i(k, 0)
	global_position= Rejilla.centro(self, inicio)
	_mirar(Vector2.LEFT)
	_mostrar(true)
	j.colocar(j.global_position, Vector2(_dir(j.celda(), inicio)))
	Sonido.musica("mirada_joven", 0.0)
	await Dialogo.mostrar(texto_llamada)
	await _caminar_hasta(objetivo, tiempo_paso* 0.7)
	_enfrentar(j)
	await _pelear()
	ocupado= false

func _al_paso(c: Vector2i) -> void:
	if ocupado or hecho() or c.y!= fila_disparo or Combate.activo or not visible:
		return
	if Equipo.primero_util()== null:
		return
	ocupado= true
	jugador.en_evento= true
	await get_tree().process_frame
	_mirar(Vector2(_dir(celda(), c)))
	await _alerta()
	var yo:= celda()
	var lado:= signi(yo.y- c.y)
	var objetivo:= Vector2i(c.x, c.y+ (lado if lado!= 0 else 1))
	if _camino_libre(yo, objetivo):
		await _caminar_hasta(objetivo, tiempo_paso)
	_enfrentar(jugador)
	await _pelear()
	if is_instance_valid(jugador):
		jugador.en_evento= false
	ocupado =false

func _pelear() -> void:
	var d:= datos()
	if d== null:
		return
	Sonido.musica("mirada_joven", 0.0)
	await Dialogo.mostrar(texto)
	var extra:= {"objetos": d.objetos, "rival": true}
	if evento== "laboca":
		extra["sin_derrota"]= true
	var res: String= await Combate.iniciar_entrenador(d.nombre_completo(), d.crear_equipo(), d.pago_base, extra)
	if not is_instance_valid(self) or not is_inside_tree():
		return
	if res!= "victoria" and evento!= "laboca":
		return
	if clave!= "":
		Estado.marcar(clave)
	await Dialogo.mostrar(texto_victoria if res== "victoria" else texto_derrota)
	if texto_curar!= "":
		await Dialogo.mostrar(texto_curar)
		Equipo.curar_todo()
		Sonido.jingle("curacion")
		await Dialogo.mostrar("Tu equipo recuperó toda su energía.")
		Sonido.cortar_jingle()
	if texto_salida!= "":
		await Dialogo.mostrar(texto_salida)
	await _irse()

func _irse() -> void:
	var dirs: Array[Vector2i]= [Vector2i(salida)]
	for d in DIRS:
		if not dirs.has(d):
			dirs.append(d)
	var mejor:= Vector2i.ZERO
	var largo:= 0
	for d in dirs:
		var n:= 0
		while n< 6 and _libre(celda()+ d* (n+ 1)):
			n+= 1
		if n> largo:
			largo= n
			mejor =d
		if largo>= 4:
			break
	if largo> 0:
		await _caminar_hasta(celda()+ mejor* largo, tiempo_paso)
	var tw:= create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	await tw.finished
	queue_free()

func _alerta() -> void:
	var s:= Sprite2D.new()
	s.texture= load(ALERTA)
	s.texture_filter =CanvasItem.TEXTURE_FILTER_NEAREST
	s.position= Vector2(0, -36)
	s.z_index =5
	s.scale= Vector2(1, 0.2)
	add_child(s)
	Sonido.efecto("confirmar", 1.4)
	var tw:= create_tween()
	tw.tween_property(s, "scale", Vector2.ONE, 0.1)
	tw.tween_interval(0.55)
	await tw.finished
	s.queue_free()

func _enfrentar(j: Node) -> void:
	var d:= _dir(celda(), j.celda())
	_mirar(Vector2(d))
	j.colocar(j.global_position, Vector2(-d))

func _dir(desde: Vector2i, hacia: Vector2i) -> Vector2i:
	var v:= hacia- desde
	if absi(v.x)>= absi(v.y):
		return Vector2i(signi(v.x), 0) if v.x!= 0 else Vector2i.DOWN
	return Vector2i(0, signi(v.y))

func _junto_a(c: Vector2i) -> Vector2i:
	for d in DIRS:
		if _libre(c+ d):
			return c+ d
	return c+ Vector2i.RIGHT

func _camino_libre(desde: Vector2i, hasta: Vector2i) -> bool:
	var c:= desde
	while c!= hasta:
		c+= Vector2i(signi(hasta.x- c.x), 0) if c.x!= hasta.x else Vector2i(0, signi(hasta.y- c.y))
		if not _libre(c):
			return false
	return true

func _caminar_hasta(hasta: Vector2i, t: float) -> void:
	while is_inside_tree() and celda()!= hasta:
		var c:= celda()
		var d:= Vector2i(signi(hasta.x- c.x), 0) if c.x!= hasta.x else Vector2i(0, signi(hasta.y- c.y))
		_mirar(Vector2(d))
		var tw:= create_tween()
		tw.tween_property(self, "global_position", Rejilla.centro(self, c+ d), t)
		tw.parallel().tween_property(sprite, "offset:y", -1.0, t* 0.5)
		tw.parallel().tween_property(sprite, "offset:y", 0.0, t* 0.5).set_delay(t* 0.5)
		await tw.finished

func _libre(c: Vector2i) -> bool:
	var q:= PhysicsShapeQueryParameters2D.new()
	var forma:= RectangleShape2D.new()
	forma.size= Rejilla.tam(self)- Vector2(4, 4)
	q.shape =forma
	q.transform= Transform2D(0.0, Rejilla.centro(self, c))
	q.exclude =[get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()
