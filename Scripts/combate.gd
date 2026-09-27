extends Node

signal termino(resultado: String)

const ESCENA:= "res://Escenas/Batalla/Batalla.tscn"
const CASA :="res://Escenas/Casa.tscn"
const ESCENA_EVOLUCION:= "res://Escenas/UI/Evolucion.tscn"

const POOL_HALLAZGO:= ["potion", "super_potion", "pokeball", "greatball", "oran", "repel"]

var activo:= false
var ultima: Node
var ultimo_resultado :={}
var rng:= RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func iniciar_salvaje(especie: EspeciePokemon, nivel: int) -> String:
	var rivales: Array[PokemonInstancia]= [PokemonInstancia.crear(especie, nivel)]
	return await _iniciar(rivales, true, "")

func iniciar_entrenador(nombre: String, equipo: Array[PokemonInstancia], pago_base: int= 0) -> String:
	return await _iniciar(equipo, false, nombre, {"pago_base": pago_base})

func iniciar_torre(pokemon: PokemonInstancia, rival: PokemonInstancia) -> Dictionary:
	var propio: Array[PokemonInstancia]= [pokemon]
	var rivales: Array[PokemonInstancia]= [rival]
	await _iniciar(rivales, false, "Retador de la Torre", {"equipo": propio, "torre": true})
	return ultimo_resultado

func _iniciar(rivales: Array[PokemonInstancia], salvaje: bool, nombre: String, config: Dictionary= {}) -> String:
	var propio: Array= config.get("equipo", Equipo.miembros)
	if activo or rivales.is_empty() or not propio.any(func(p): return not p.esta_debilitado()):
		return "cancelado"
	var torre:= bool(config.get("torre", false))
	activo= true
	var pista:= "batalla_salvaje" if salvaje else "batalla_entrenador"
	Sonido.musica(pista, 0.0)
	if salvaje:
		await GestorEscenas.barras_cubrir()
	var b= load(ESCENA).instantiate()
	b.entrada_barras= salvaje
	b.pista= pista
	ultima =b
	add_child(b)
	var escena:= get_tree().current_scene
	b.poner_fondo(escena.get("fondo_batalla") if escena!= null and "fondo_batalla" in escena else null)
	var res: String= await b.empezar(rivales, salvaje, nombre, config)
	var logica: LogicaCombate= b.logica
	var subieron: Array[PokemonInstancia]= b.subieron.duplicate()
	ultimo_resultado= {"resultado": res, "turnos": logica.turnos, "ps_fraccion": float(propio[0].ps_actuales)/ maxf(1.0, propio[0].ps_max())}
	b.queue_free()
	ultima= null
	if torre:
		if escena!= null and "musica" in escena:
			Sonido.musica(str(escena.get("musica")), 0.8)
		activo= false
		termino.emit(res)
		return res
	if res== "derrota":
		Sonido.detener_musica(0.3)
		Equipo.curar_todo()
		await Dialogo.mostrar("Corriste a casa para que tus Pokémon descansaran.")
		await GestorEscenas.cambiar_mapa(CASA, "Entrada", Vector2.UP)
		Sonido.jingle("curacion")
	else:
		Estado.sumar_dinero(logica.dinero_ganado)
		if escena!= null and "musica" in escena:
			Sonido.musica(str(escena.get("musica")), 0.8)
		if res in ["victoria", "captura"]:
			await _curar_con_trinkets()
		if res== "victoria" and salvaje:
			await _hallazgo()
		var evoluciono:= false
		for p in subieron:
			if Equipo.miembros.has(p) and p.puede_evolucionar():
				await _evolucionar(p)
				evoluciono= true
		if evoluciono and escena!= null and "musica" in escena:
			Sonido.musica(str(escena.get("musica")), 0.8)
	activo =false
	termino.emit(res)
	return res

func _curar_con_trinkets() -> void:
	var curados: Array[String]= []
	for p in Equipo.miembros:
		if p.esta_debilitado() or p.ps_actuales>= p.ps_max():
			continue
		var f:= EfectosTrinket.total("cura_victoria", p)
		if f> 0.0:
			p.curar_ps(maxi(1, floori(p.ps_max()* f)))
			curados.append(p.nombre())
	if not curados.is_empty():
		Sonido.efecto("curar_ps")
		await Dialogo.mostrar("Los Trinkets curativos restauraron PS a %s." % ", ".join(curados))

func _hallazgo() -> void:
	var prob:= EfectosTrinket.total("hallazgo", null, Equipo.miembros)
	if prob<= 0.0 or rng.randf()>= prob:
		return
	var id: String= POOL_HALLAZGO[rng.randi_range(0, POOL_HALLAZGO.size()- 1)]
	Inventario.add_item(id)
	Sonido.jingle("objeto")
	await Dialogo.mostrar("¡Tu equipo encontró %s tras el combate!" % Inventario.get_item_name(id))
	Sonido.cortar_jingle()

func _evolucionar(p: PokemonInstancia) -> bool:
	var e= load(ESCENA_EVOLUCION).instantiate()
	await GestorEscenas.fundido(func(): add_child(e))
	var r: bool= await e.evolucionar(p)
	await GestorEscenas.fundido(func(): e.queue_free())
	return r
