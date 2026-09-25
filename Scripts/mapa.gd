extends Node2D

@onready var suelo: TileMapLayer= $Suelo
@onready var jugador =$Jugador
@onready var camara: Camera2D =$Jugador/Camara

func _ready() -> void:
	_ajustar_camara()
	if GestorEscenas.posicion_llegada!= null:
		jugador.colocar(GestorEscenas.posicion_llegada, GestorEscenas.direccion_llegada)
		GestorEscenas.posicion_llegada =null
	elif GestorEscenas.llegada!= "":
		var marca:= get_node_or_null("Llegadas/" +GestorEscenas.llegada)
		if marca!= null:
			jugador.colocar(marca.global_position, GestorEscenas.direccion_llegada)
		GestorEscenas.llegada= ""
	jugador.paso_terminado.connect(_al_terminar_paso)

func _ajustar_camara() -> void:
	var zona: Rect2i= suelo.get_used_rect()
	var tam: Vector2i =suelo.tile_set.tile_size
	var izq: int= zona.position.x* tam.x
	var arr: int =zona.position.y *tam.y
	var der: int= zona.end.x* tam.x
	var aba: int =zona.end.y* tam.y
	var vista:= get_viewport_rect().size
	if der- izq< vista.x:
		var extra: float= (vista.x -(der- izq))/ 2.0
		izq-= int(floor(extra))
		der +=int(ceil(extra))
	if aba -arr< vista.y:
		var extra: float =(vista.y- (aba -arr))/ 2.0
		arr -=int(floor(extra))
		aba+= int(ceil(extra))
	camara.limit_left= izq
	camara.limit_top =arr
	camara.limit_right= der
	camara.limit_bottom =aba

func _al_terminar_paso(celda: Vector2i) -> void:
	for w in get_tree().get_nodes_in_group("warp"):
		if w.celda()== celda and w.destino!= "":
			GestorEscenas.cambiar_mapa(w.destino, w.llegada, w.direccion)
			return
