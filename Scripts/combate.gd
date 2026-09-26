extends Node

signal termino(resultado: String)

const ESCENA:= "res://Escenas/Batalla/Batalla.tscn"
const CASA :="res://Escenas/Casa.tscn"

var activo:= false
var ultima: Node

func iniciar_salvaje(especie: EspeciePokemon, nivel: int) -> String:
	var rivales: Array[PokemonInstancia]= [PokemonInstancia.crear(especie, nivel)]
	return await _iniciar(rivales, true, "")

func iniciar_entrenador(nombre: String, equipo: Array[PokemonInstancia]) -> String:
	return await _iniciar(equipo, false, nombre)

func _iniciar(rivales: Array[PokemonInstancia], salvaje: bool, nombre: String) -> String:
	if activo or Equipo.primero_util()== null or rivales.is_empty():
		return "cancelado"
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
	var res: String= await b.empezar(rivales, salvaje, nombre)
	b.queue_free()
	ultima= null
	if res== "derrota":
		Sonido.detener_musica(0.3)
		Equipo.curar_todo()
		await Dialogo.mostrar("Corriste a casa para que tus Pokémon descansaran.")
		await GestorEscenas.cambiar_mapa(CASA, "Entrada", Vector2.UP)
		Sonido.jingle("curacion")
	elif escena!= null and "musica" in escena:
		Sonido.musica(str(escena.get("musica")), 0.8)
	activo =false
	termino.emit(res)
	return res
