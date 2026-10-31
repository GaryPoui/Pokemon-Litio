extends CanvasLayer

signal cerrado

const FILAS_VISIBLES:= 11
const FICHA :=preload("res://Scripts/ui/ficha_pokedex.gd")
const MARCA:= preload("res://Assets/UI/Archivos/stat_pokedex.png")

@onready var lista: ListaOpciones= $PanelLista/Ventana/Lista
@onready var sprite: Sprite2D =$Sprite
@onready var detalle: Control= $Detalle
@onready var totales: Label =$Totales
@onready var titulo: Label= $Titulo

var especies: Array[EspeciePokemon]= []
var viendo:= false

func _ready() -> void:
	layer= 105
	$PanelLista.add_theme_stylebox_override("panel", EstiloUI.panel())
	$PanelDetalle.add_theme_stylebox_override("panel", EstiloUI.panel())
	EstiloUI.label(titulo, 10, Color.WHITE)
	EstiloUI.label(totales, 6, Color.WHITE)
	lista.sangria= 13.0

func abrir() -> void:
	especies.clear()
	for id in BaseDatos.ids(BaseDatos.ESPECIES):
		especies.append(BaseDatos.especie(id))
	especies.sort_custom(func(a, b): return a.numero< b.numero)
	var textos:= []
	for e in especies:
		var nombre:= e.nombre if Estado.vistos.has(e.id) else "-----"
		textos.append("%03d %s" % [e.numero, nombre])
	lista.poner(textos)
	for i in especies.size():
		if Estado.capturados.has(especies[i].id):
			var marca:= TextureRect.new()
			marca.texture= MARCA
			marca.position= Vector2(-12, 3)
			marca.name= "Capturado"
			lista.etiquetas[i].add_child(marca)
	totales.text= "Vistos: %d   Capturados: %d" % [Estado.vistos.size(), Estado.capturados.size()]
	totales.size= totales.get_combined_minimum_size()
	totales.position.x= 250.0- totales.size.x
	_actualizar()

func _unhandled_input(event: InputEvent) -> void:
	if GestorEscenas.en_transicion or viendo:
		return
	if event.is_action_pressed("aceptar") and not especies.is_empty() and Estado.capturados.has(especies[lista.cursor].id):
		get_viewport().set_input_as_handled()
		Sonido.efecto("confirmar")
		_ver_ficha(especies[lista.cursor])
		return
	if event.is_action_pressed("cancelar") or event.is_action_pressed("menu"):
		Sonido.efecto("cancelar")
		cerrado.emit()
	elif lista.mover_con_evento(event):
		_actualizar()
	else:
		return
	get_viewport().set_input_as_handled()

func _ver_ficha(e: EspeciePokemon) -> void:
	viendo= true
	var f= FICHA.new()
	await GestorEscenas.fundido(func():
		add_child(f)
		f.armar(e, "Pokédex"))
	await f.esperar()
	await GestorEscenas.fundido(func(): f.queue_free())
	viendo =false

func _actualizar() -> void:
	var primera:= roundi(-lista.position.y/ lista.alto_fila)
	if lista.cursor< primera:
		primera= lista.cursor
	elif lista.cursor>= primera+ FILAS_VISIBLES:
		primera =lista.cursor- FILAS_VISIBLES+ 1
	lista.position.y= -primera* lista.alto_fila
	for h in detalle.get_children():
		h.queue_free()
	if especies.is_empty():
		sprite.visible= false
		return
	var e:= especies[lista.cursor]
	if not Estado.vistos.has(e.id):
		sprite.visible =false
		detalle.add_child(EstiloUI.nuevo_label("???", 9, Vector2(6, 2)))
		return
	sprite.mostrar(e, false)
	sprite.encajar_en(Rect2(132, 24, 116, 86))
	detalle.add_child(EstiloUI.nuevo_label("%03d  %s" % [e.numero, e.nombre], 9, Vector2(6, 2)))
	if Estado.capturados.has(e.id):
		for k in e.tipos.size():
			detalle.add_child(EstiloUI.insignia_tipo(e.tipos[k], Vector2(6+ k* (EstiloUI.ANCHO_INSIGNIA+ 4), 18)))
		detalle.add_child(EstiloUI.nuevo_label("Capturado", 7, Vector2(6, 34), Color("78d890")))
		var ver:= EstiloUI.nuevo_label("A: ver ficha", 8, Vector2(6, 50), EstiloUI.TENUE)
		EstiloUI.fuente_batalla(ver)
		detalle.add_child(ver)
	else:
		detalle.add_child(EstiloUI.nuevo_label("Solo visto", 7, Vector2(6, 34), EstiloUI.TENUE))
