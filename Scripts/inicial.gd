extends "res://Scripts/npc.gd"

const OPCIONES:= ["snivy", "tepig", "oshawott"]
const TIPOS :={"snivy": "Planta", "tepig": "Fuego", "oshawott": "Agua"}

@export_multiline var texto_elegir: String= "¿Cuál te llevás?"
@export_multiline var texto_pensar :String= "Pensalo tranquilo. ¡Volvé cuando te decidas!"

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	if Estado.inicial()!= "":
		await Dialogo.mostrar(texto)
		return
	await Dialogo.mostrar(texto_regalo)
	var id:= ""
	var nombres:= OPCIONES.map(func(x): return BaseDatos.especie(x).nombre.to_upper())
	while id== "":
		var r: int= await Dialogo.preguntar(texto_elegir, nombres)
		if r< 0:
			await Dialogo.mostrar(texto_pensar)
			return
		var esp:= BaseDatos.especie(OPCIONES[r])
		var c: int= await Dialogo.preguntar("¿Elegís a %s, el Pokémon de tipo %s?" % [esp.nombre, TIPOS[OPCIONES[r]]])
		if c== 0:
			id= OPCIONES[r]
	var especie:= BaseDatos.especie(id)
	var destino:= Equipo.recibir(PokemonInstancia.crear(especie, regalo_nivel))
	Estado.marcar("inicial_" +id)
	Sonido.jingle("captura")
	await Dialogo.mostrar("¡Recibiste a %s!" % especie.nombre+ ("" if destino== "equipo" else " Como tu equipo está lleno, fue enviado a la Caja del PC."))
	Sonido.cortar_jingle()
	await Dialogo.mostrar("¡Cuidalo mucho!")
	for r in get_tree().get_nodes_in_group("rival"):
		if r.has_method("al_elegir_inicial"):
			await r.al_elegir_inicial(jugador)
