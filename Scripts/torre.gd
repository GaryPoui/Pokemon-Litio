extends "res://Scripts/npc.gd"

const ESCENA_EQUIPO:= "res://Escenas/UI/PantallaEquipo.tscn"

var rng:= RandomNumberGenerator.new()

func _ready() -> void:
	super._ready()
	rng.randomize()

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	if Equipo.primero_util()== null:
		await Dialogo.mostrar("Necesitas al menos un Pokémon que pueda luchar para entrar a la Bombonera.")
		return
	var r: int= await Dialogo.preguntar("Desafío de la Bombonera: entra con un solo Pokémon y vence a un rival uno contra uno. Cuantos menos turnos y más PS te queden, mejor será el Trinket. ¿Entrar?")
	if r!= 0:
		return
	var p:= await _elegir()
	if p== null:
		return
	var copia:= {"ps": p.ps_actuales, "estado": p.estado, "pp": p.pp.duplicate()}
	var rival:= _rival(p)
	var res: Dictionary= await Combate.iniciar_torre(p, rival)
	p.ps_actuales= copia["ps"]
	p.estado =copia["estado"]
	p.pp.assign(copia["pp"])
	if res.get("resultado", "")!= "victoria":
		await Dialogo.mostrar("La Bombonera te ha vencido esta vez. Tu Pokémon vuelve tal como entró.")
		return
	var g:= EfectosTrinket.grado(int(res["turnos"]), float(res["ps_fraccion"]))
	var extra:= roundi(EfectosTrinket.total("grado_torre", p))
	var tier:= mini(5, int(g["tier"])+ extra)
	var t:= EfectosTrinket.al_azar(tier, rng)
	Estado.stock_tienda.clear()
	await Dialogo.mostrar("Turnos: %d · PS restantes: %d%%\nCalificación: %s (%d puntos)%s" % [int(res["turnos"]), roundi(float(res["ps_fraccion"])* 100.0), EfectosTrinket.LETRAS_TIER[tier], int(g["puntos"]), " +%d por Trinket" % extra if extra> 0 else ""])
	if t== null:
		return
	Inventario.agregar_trinket(t.id)
	Sonido.jingle("objeto_clave")
	await Dialogo.mostrar("¡Recibiste el Trinket %s (%s)! Equípalo desde el menú POKéMON → TRINKETS." % [t.nombre, EfectosTrinket.texto_tier(t)])
	Sonido.cortar_jingle()

func _elegir() -> PokemonInstancia:
	var pe= load(ESCENA_EQUIPO).instantiate()
	var validar:= func(i: int) -> String:
		return "¡%s no puede luchar!" % Equipo.miembros[i].nombre() if Equipo.miembros[i].esta_debilitado() else ""
	await GestorEscenas.fundido(func():
		get_tree().current_scene.add_child(pe)
		pe.abrir("elegir", "¿Qué Pokémon entra a la Torre?", validar))
	await pe.cerrado
	var i: int= pe.resultado
	await GestorEscenas.fundido(func(): pe.queue_free())
	return Equipo.miembros[i] if i>= 0 else null

func _rival(p: PokemonInstancia) -> PokemonInstancia:
	var ids:= BaseDatos.ids(BaseDatos.ESPECIES)
	var id:= ids[rng.randi_range(0, ids.size()- 1)]
	return PokemonInstancia.crear(BaseDatos.especie(id), p.nivel, rng)
