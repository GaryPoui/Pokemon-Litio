extends "res://Scripts/npc.gd"

const ESCENA_EQUIPO:= "res://Escenas/UI/PantallaEquipo.tscn"
const MARGEN_BST :=60

@export_group("Desafío")
@export var nombre_desafio: String= "Desafío"
@export var pool: Array[String] =[]
@export_multiline var texto_bienvenida: String= "¡Bienvenido a la torre de desafíos!"

var rng:= RandomNumberGenerator.new()

func _ready() -> void:
	super._ready()
	rng.randomize()

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	if Equipo.primero_util()== null:
		await Dialogo.mostrar("Necesitás al menos un Pokémon que pueda luchar para el %s." % nombre_desafio)
		return
	await Dialogo.mostrar(texto_bienvenida)
	if Estado.fichas<= 0:
		await Dialogo.mostrar("No te quedan Fichas de Desafío. Cada ciudad nueva que visites te da %d." % Estado.FICHAS_POR_CIUDAD)
		return
	var r: int= await Dialogo.preguntar("Tenés %d Fichas. Un Pokémon tuyo pelea contra un rival de su mismo nivel. Si gana, gasta una ficha, sube un nivel y gana un Trinket; si pierde, la ficha vuelve. ¿Entrar?" % Estado.fichas)
	if r!= 0:
		return
	var p:= await _elegir()
	if p== null:
		return
	if p.nivel>= PokemonInstancia.NIVEL_MAX:
		await Dialogo.mostrar("%s ya está en el nivel máximo." % p.nombre())
		return
	var copia:= {"ps": p.ps_actuales, "estado": p.estado, "pp": p.pp.duplicate()}
	var rival:= elegir_rival(p)
	var res: Dictionary= await Combate.iniciar_torre(p, rival)
	p.ps_actuales= copia["ps"]
	p.estado =copia["estado"]
	p.pp.assign(copia["pp"])
	if res.get("resultado", "")!= "victoria":
		await Dialogo.mostrar("Esta vez no pudo ser. La ficha vuelve a tu bolsillo y %s vuelve tal como entró." % p.nombre())
		return
	Estado.fichas-= 1
	var g:= EfectosTrinket.grado(int(res["turnos"]), float(res["ps_fraccion"]))
	var extra:= roundi(EfectosTrinket.total("grado_torre", p))
	var tier:= mini(5, int(g["tier"])+ extra)
	await Dialogo.mostrar("Turnos: %d · PS restantes: %d%%\nCalificación: %s (%d puntos)%s" % [int(res["turnos"]), roundi(float(res["ps_fraccion"])* 100.0), EfectosTrinket.LETRAS_TIER[tier], int(g["puntos"]), " +%d por Trinket" % extra if extra> 0 else ""])
	await Combate.subir_nivel(p)
	var t:= EfectosTrinket.al_azar(tier, rng)
	Estado.stock_tienda.clear()
	if t!= null:
		Inventario.agregar_trinket(t.id)
		Sonido.jingle("objeto_clave")
		await Dialogo.mostrar("¡Recibiste el Trinket %s (%s)! Equipalo desde el menú POKéMON → TRINKETS." % [t.nombre, EfectosTrinket.texto_tier(t)])
		Sonido.cortar_jingle()
	await Dialogo.mostrar("Te quedan %d Fichas de Desafío." % Estado.fichas)

func _elegir() -> PokemonInstancia:
	var pe= load(ESCENA_EQUIPO).instantiate()
	var validar:= func(i: int) -> String:
		return "¡%s no puede luchar!" % Equipo.miembros[i].nombre() if Equipo.miembros[i].esta_debilitado() else ""
	await GestorEscenas.fundido(func():
		get_tree().current_scene.add_child(pe)
		pe.abrir("elegir", "¿Qué Pokémon entra al desafío?", validar))
	await pe.cerrado
	var i: int= pe.resultado
	await GestorEscenas.fundido(func(): pe.queue_free())
	return Equipo.miembros[i] if i>= 0 else null

static func bst(e: EspeciePokemon) -> int:
	return e.ps+ e.ataque+ e.defensa+ e.at_esp+ e.def_esp+ e.velocidad

func elegir_rival(p: PokemonInstancia) -> PokemonInstancia:
	var ids: Array= pool if not pool.is_empty() else Array(BaseDatos.ids(BaseDatos.ESPECIES))
	var propio:= bst(p.especie)
	var cerca: Array[EspeciePokemon]= []
	var mejor: EspeciePokemon= null
	for id in ids:
		var e:= BaseDatos.especie(str(id))
		if e== null:
			continue
		var dif:= absi(bst(e)- propio)
		if dif<= MARGEN_BST:
			cerca.append(e)
		if mejor== null or dif< absi(bst(mejor)- propio):
			mejor= e
	var elegida: EspeciePokemon= cerca[rng.randi_range(0, cerca.size()- 1)] if not cerca.is_empty() else mejor
	return PokemonInstancia.crear(elegida, p.nivel, rng)
