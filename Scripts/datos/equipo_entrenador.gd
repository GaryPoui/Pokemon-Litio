class_name EquipoEntrenador
extends Resource

@export var clase: String= "Joven"
@export var nombre: String =""
@export var miembros: Array[EncuentroEntrada]= []

func nombre_completo() -> String:
	return (clase+ " " +nombre).strip_edges()

func crear_equipo(rng: RandomNumberGenerator= null) -> Array[PokemonInstancia]:
	var lista: Array[PokemonInstancia]= []
	for m in miembros:
		lista.append(PokemonInstancia.crear(m.especie, m.nivel_min, rng))
	return lista
