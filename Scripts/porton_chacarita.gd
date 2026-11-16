extends Node2D

@export var celdas: Array= []
@export var adentro :Array= []
@export_multiline var texto_cruza: String= "Litwick se adelantó y atravesó las rejas del cementerio. Su llama violeta flotó un rato entre las bóvedas…"
@export_multiline var texto_vuelve :String= "…y volvió. Se quedó mirándote, con la llama más tranquila que nunca. Parece que quiere quedarse con vos."

var ocupado:= false

func _ready() -> void:
	_conectar.call_deferred()

func _conectar() -> void:
	var j= get_parent().get_node_or_null("Jugador")
	if j!= null and j.has_signal("paso_terminado"):
		j.paso_terminado.connect(_al_paso)

func _es_celda(c: Vector2i) -> bool:
	for v in celdas:
		if Vector2i(int(v[0]), int(v[1]))== c:
			return true
	return false

func _al_paso(c: Vector2i) -> void:
	if ocupado or not _es_celda(c) or not Seguidor.activo():
		return
	var s:= Seguidor.en(get_parent())
	if s== null:
		return
	ocupado= true
	var j= get_parent().get_node_or_null("Jugador")
	j.en_evento =true
	await get_tree().create_timer(0.2).timeout
	await s.despedir(Vector2i(int(adentro[0]), int(adentro[1])))
	await Dialogo.mostrar(texto_cruza)
	await Dialogo.mostrar(texto_vuelve)
	var rng:= RandomNumberGenerator.new()
	rng.randomize()
	var p:= PokemonInstancia.crear(BaseDatos.especie("litwick"), 25, rng, 0.0)
	var donde:= Equipo.recibir(p)
	Sonido.jingle("objeto_clave")
	if donde== "equipo":
		await Dialogo.mostrar("¡Litwick se unió a tu equipo!")
	else:
		await Dialogo.mostrar("Tu equipo está lleno, así que Litwick fue a la caja del PC. Te va a esperar ahí.")
	Sonido.cortar_jingle()
	await Combate.pedir_mote(p)
	Estado.marcar(Seguidor.UNIDO)
	s.queue_free()
	if is_instance_valid(j):
		j.en_evento= false
	ocupado =false
