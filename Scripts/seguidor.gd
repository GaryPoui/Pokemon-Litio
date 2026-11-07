class_name Seguidor
extends Node2D

const BANDERA:= "litwick_sigue"
const UNIDO :="litwick_unido"
const RADIO_AVISO:= 2
const MARCOS :=preload("res://Recursos/Personajes/litwick_paseo.tres")
const APAGON := preload("res://Scripts/apagon.gd")
const GENERICA := "Litwick te mira y su llama violeta titila contenta."
const LINEAS:= {
	"ruta_7": "Litwick aprieta su boleto de 3.ª clase. Su llama apunta al oeste, hacia la Chacarita.",
	"ruta_8": "Litwick se queda mirando las vidrieras. La llama se le agranda cuando suena un bandoneón.",
	"ruta_9": "Litwick sigue las vías del tranvía con la mirada. Ya falta poco para el último viaje.",
}
const NOMBRE_DIR:= {Vector2i.DOWN: "abajo", Vector2i.UP: "arriba", Vector2i.LEFT: "izquierda", Vector2i.RIGHT: "derecha"}

var sprite: AnimatedSprite2D
var luz: PointLight2D
var jugador: Node
var avisando := false
var caminando := false
var tiempo :=0.0
var revisar :=0.0
var chispas: Array[Vector2]= []

static func activo() -> bool:
	return Estado.tiene(BANDERA) and not Estado.tiene(UNIDO)

static func en(mapa: Node) -> Seguidor:
	if mapa== null:
		return null
	for n in mapa.get_children():
		if n is Seguidor:
			return n
	return null

static func poner(mapa: Node2D) -> Seguidor:
	var previo :=en(mapa)
	if previo != null:
		return previo
	var s:= Seguidor.new()
	s.name ="Litwick"
	mapa.add_child(s)
	var j :=mapa.get_node_or_null("Jugador")
	if j != null:
		mapa.move_child(s, j.get_index())
	s.atar(j)
	return s

func _ready() -> void:
	add_to_group("interactuable")
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames =MARCOS
	sprite.offset= Vector2(0, -7)
	sprite.play("abajo")
	add_child(sprite)
	luz =APAGON.nueva_luz(48.0, Color(0.72, 0.6, 1.0), 1.0)
	luz.position= Vector2(0, -10)
	add_child(luz)
	_ajustar_luz.call_deferred()

func atar(j: Node) -> void:
	jugador = j
	if j ==null:
		return
	j.paso_iniciado.connect(_al_paso)
	j.colocado.connect(colocar_detras)
	colocar_detras()

func celda() -> Vector2i:
	return Rejilla.celda(self)

func radio_luz_celdas() -> int:
	for n in get_tree().get_nodes_in_group("niebla"):
		if n.get_parent()== get_parent():
			return 4
	return 3

func _hay_oscuridad() -> bool:
	var mapa :=get_parent()
	if mapa == null:
		return false
	for n in mapa.get_children():
		if n.get_script() == APAGON:
			return true
	return false

func _ajustar_luz() -> void:
	luz.visible =_hay_oscuridad()
	luz.texture_scale =(radio_luz_celdas() +0.5) *Rejilla.tam(self).x * 2.0 / 128.0

func colocar_detras() -> void:
	if jugador == null or not is_instance_valid(jugador):
		return
	var atras: Vector2i =jugador.celda()- Vector2i(jugador.last_direction)
	var opciones: Array[Vector2i]= [atras]
	var izquierda:= Vector2i(Vector2(jugador.last_direction).orthogonal())
	opciones.append_array([jugador.celda() + izquierda, jugador.celda()- izquierda, jugador.celda()+ Vector2i(jugador.last_direction)])
	var elegida:= atras
	for c in opciones:
		if _libre(c):
			elegida = c
			break
	position= Rejilla.centro(self, elegida)
	_mirar(jugador.celda() - elegida)

func _libre(c: Vector2i) -> bool:
	var mapa :=get_parent()
	if mapa== null or not (mapa is Node2D):
		return true
	var q:= PhysicsPointQueryParameters2D.new()
	q.position = Rejilla.centro(self, c)
	return mapa.get_world_2d().direct_space_state.intersect_point(q).is_empty()

func _al_paso(destino: Vector2i, direccion: Vector2) -> void:
	var dejada: Vector2i = jugador.celda()
	if dejada== celda():
		return
	var desde:= celda()
	var paso:= dejada -desde
	if absi(paso.x)+ absi(paso.y)> 1:
		position = Rejilla.centro(self, dejada)
		_mirar(Vector2i(direccion))
		return
	_mirar(paso)
	caminando= true
	var duracion: float =1.0/ (jugador.move_speed* (jugador.run_multiplier if jugador.is_running else 1.0))
	var tw :=create_tween()
	tw.tween_property(self, "position", Rejilla.centro(self, dejada), duracion)
	tw.finished.connect(func(): caminando =false)

func _mirar(d: Vector2i) -> void:
	if NOMBRE_DIR.has(d) and sprite !=null:
		sprite.play(NOMBRE_DIR[d])

func _process(delta: float) -> void:
	tiempo+= delta
	if sprite!= null:
		sprite.position.y= -1.0 if fmod(tiempo, 1.2) < 0.6 and not caminando else 0.0
	revisar -= delta
	if revisar <= 0.0:
		revisar = 0.25
		_revisar_ocultos()
	if avisando:
		queue_redraw()

func _revisar_ocultos() -> void:
	var antes := avisando
	avisando = false
	if jugador ==null or not is_instance_valid(jugador):
		return
	for o in get_tree().get_nodes_in_group("objeto_oculto"):
		if o.has_method("cerca_de") and o.cerca_de(jugador.celda(), RADIO_AVISO):
			avisando= true
			if not caminando:
				var d: Vector2i =o.celda()- celda()
				_mirar(Vector2i(signi(d.x), 0) if absi(d.x) >=absi(d.y) else Vector2i(0, signi(d.y)))
			break
	if antes and not avisando:
		queue_redraw()

func _draw() -> void:
	if not avisando:
		return
	var k: int= int(tiempo* 8.0)
	for i in 3:
		var a: float = tiempo * 5.0 +i *TAU/ 3.0
		var p:= Vector2(cos(a) *6.0, -22.0 + sin(a) *3.0- (k +i)% 3)
		draw_rect(Rect2(p.floor(), Vector2(1, 1)), Color(0.86, 0.8, 1.0) if (k +i) %2 ==0 else Color(0.62, 0.5, 1.0))

func interactuar(_j: Node) -> void:
	var mapa :=get_tree().current_scene
	var zona: String =str(mapa.get("zona_id")) if mapa != null and "zona_id" in mapa else ""
	_mirar(jugador.celda()- celda() if jugador != null else Vector2i.DOWN)
	await Dialogo.mostrar(LINEAS.get(zona, GENERICA))

func despedir(adentro: Vector2i) -> void:
	var camino: Array[Vector2i] =[]
	var c :=celda()
	while c != adentro:
		var d := adentro -c
		c += Vector2i(signi(d.x), 0) if d.x != 0 else Vector2i(0, signi(d.y))
		camino.append(c)
	for p in camino:
		_mirar(p - celda())
		var tw :=create_tween()
		tw.tween_property(self, "position", Rejilla.centro(self, p), 0.3)
		if p == camino.back():
			tw.parallel().tween_property(self, "modulate:a", 0.5, 0.3)
		await tw.finished
	await get_tree().create_timer(1.2).timeout
	_mirar(Vector2i.DOWN)
	await get_tree().create_timer(0.6).timeout
	modulate.a = 1.0
	colocar_detras()
