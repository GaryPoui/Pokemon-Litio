extends CanvasLayer

signal cerrado

const FILAS_VISIBLES:= 11

@onready var lista: ListaOpciones= $PanelLista/Ventana/Lista
@onready var sprite: Sprite2D =$Sprite
@onready var detalle: Control= $Detalle
@onready var totales: Label =$Totales
@onready var titulo: Label= $Titulo

var especies: Array[EspeciePokemon]= []

func _ready() -> void:
	layer= 105
	$PanelLista.add_theme_stylebox_override("panel", EstiloUI.panel())
	$PanelDetalle.add_theme_stylebox_override("panel", EstiloUI.panel())
	EstiloUI.label(titulo, 10, Color.WHITE)
	EstiloUI.label(totales, 6, Color.WHITE)

func abrir() -> void:
	especies.clear()
	for id in BaseDatos.ids(BaseDatos.ESPECIES):
		especies.append(BaseDatos.especie(id))
	especies.sort_custom(func(a, b): return a.numero< b.numero)
	var textos:= []
	for e in especies:
		var nombre:= e.nombre if Estado.vistos.has(e.id) else "-----"
		textos.append("%s%03d %s" % ["●" if Estado.capturados.has(e.id) else " ", e.numero, nombre])
	lista.poner(textos)
	totales.text= "Vistos: %d   Capturados: %d" % [Estado.vistos.size(), Estado.capturados.size()]
	_actualizar()

func _unhandled_input(event: InputEvent) -> void:
	if GestorEscenas.en_transicion:
		return
	if event.is_action_pressed("cancelar") or event.is_action_pressed("menu"):
		Sonido.efecto("cancelar")
		cerrado.emit()
	elif lista.mover_con_evento(event):
		_actualizar()
	else:
		return
	get_viewport().set_input_as_handled()

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
	detalle.add_child(EstiloUI.nuevo_label("%03d  %s" % [e.numero, e.nombre], 9, Vector2(6, 2)))
	if Estado.capturados.has(e.id):
		for k in e.tipos.size():
			detalle.add_child(EstiloUI.insignia_tipo(e.tipos[k], Vector2(6+ k* (EstiloUI.ANCHO_INSIGNIA+ 4), 18)))
		detalle.add_child(EstiloUI.nuevo_label("Capturado", 7, Vector2(6, 34), Color("2a8a3a")))
	else:
		detalle.add_child(EstiloUI.nuevo_label("Solo visto", 7, Vector2(6, 34), Color("7a7a7a")))
