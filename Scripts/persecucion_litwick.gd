extends Node2D

@export var puntos: Array = []
@export var clave :String= "r7_litwick"

const MARCOS:= preload("res://Recursos/Personajes/litwick_paseo.tres")
const VIOLETA:= Color(0.78, 0.66, 1.0)

var lista: Array[Vector2i] =[]
var indice := 0
var sprite: AnimatedSprite2D
var jugador: Node
var saltando :=false
var rastro: Array = []
var capa: CanvasLayer
var faro: Node2D
var tiempo := 0.0

func _ready() -> void:
	if Estado.tiene(clave) or Estado.tiene(Seguidor.BANDERA):
		queue_free()
		return
	for p in puntos:
		lista.append(Vector2i(int(p[0]), int(p[1])))
	if lista.is_empty():
		queue_free()
		return
	add_to_group("interactuable")
	sprite =AnimatedSprite2D.new()
	sprite.sprite_frames =MARCOS
	sprite.offset = Vector2(0, -7)
	sprite.play("abajo")
	add_child(sprite)
	capa =CanvasLayer.new()
	capa.layer= 31
	add_child(capa)
	faro = Node2D.new()
	faro.draw.connect(_dibujar_faro)
	capa.add_child(faro)
	position = Rejilla.centro(self, lista[0])
	jugador = get_parent().get_node_or_null("Jugador")
	if jugador != null:
		jugador.paso_terminado.connect(_al_paso)

func celda() -> Vector2i:
	return Rejilla.celda(self)

func _al_paso(c: Vector2i) -> void:
	if saltando or indice >=lista.size():
		return
	var d:= (c- lista[indice]).abs()
	if maxi(d.x, d.y) <=1:
		_reaccionar.call_deferred()

func interactuar(_j: Node) -> void:
	await _reaccionar()

func _reaccionar() -> void:
	if saltando:
		return
	if indice <lista.size()- 1:
		_huir()
	else:
		await _rendirse()

func _huir() -> void:
	saltando= true
	var desde:= position
	indice+= 1
	var hasta :=Rejilla.centro(self, lista[indice])
	var d :=lista[indice] -lista[indice -1]
	sprite.play("derecha" if absi(d.x) >=absi(d.y) and d.x> 0 else "izquierda" if absi(d.x) >= absi(d.y) else "abajo" if d.y> 0 else "arriba")
	Sonido.efecto("chispa")
	for k in 9:
		rastro.append([desde.lerp(hasta, k/ 8.0), 1.6+ k *0.12])
	var tw := create_tween()
	tw.tween_property(self, "position", hasta, 0.5).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(sprite, "position:y", -10.0, 0.25)
	tw.chain().tween_property(sprite, "position:y", 0.0, 0.25)
	await tw.finished
	sprite.play("abajo")
	saltando =false

func _rendirse() -> void:
	saltando= true
	jugador.en_evento= true
	var hacia: Vector2i = jugador.celda()- celda()
	sprite.play("derecha" if hacia.x > 0 else "izquierda" if hacia.x <0 else "abajo" if hacia.y >0 else "arriba")
	await Dialogo.mostrar("El Litwick quedó contra el muro viejo. Tiembla un poco… y te muestra un papelito arrugado: un boleto de tranvía.")
	await Dialogo.mostrar("«Tranvía Fúnebre · 3.ª clase · Ida». Parece que quiere llegar a la Chacarita y se perdió en la niebla.")
	Inventario.add_item("boleto_tercera")
	Sonido.jingle("objeto_clave")
	await Dialogo.mostrar("¡Recibiste el Boleto de 3.ª!")
	Sonido.cortar_jingle()
	Estado.marcar(Seguidor.BANDERA)
	Estado.marcar(clave)
	await Dialogo.mostrar("Litwick se acerca y su llama crece. Va a acompañarte en el último viaje.")
	Seguidor.poner(get_parent())
	if is_instance_valid(jugador):
		jugador.en_evento = false
	queue_free()

func _process(delta: float) -> void:
	tiempo +=delta
	for r in rastro:
		r[1]-= delta
	rastro = rastro.filter(func(r): return r[1] >0.0)
	queue_redraw()
	faro.queue_redraw()

func _pantalla(p: Vector2) -> Vector2:
	var cam: Camera2D = jugador.get_node_or_null("Camara") if jugador != null else null
	var foco: Vector2= cam.get_screen_center_position() if cam!= null else p
	return (p- foco+ Vector2(128, 96)).floor()

func _dibujar_faro() -> void:
	var base:= _pantalla(global_position+ Vector2(0, -16))
	var titila := 1 if fmod(tiempo, 0.8)< 0.4 else 0
	faro.draw_rect(Rect2(base- Vector2(1, 1 +titila), Vector2(3, 3)), VIOLETA)
	faro.draw_rect(Rect2(base -Vector2(0, 2 + titila), Vector2(1, 1)), Color(1, 1, 1))
	for r in rastro:
		var p := _pantalla(r[0] +Vector2(0, -12))
		if fmod(r[1]* 6.0, 1.0) <0.6:
			faro.draw_rect(Rect2(p, Vector2(1, 1)), VIOLETA)
