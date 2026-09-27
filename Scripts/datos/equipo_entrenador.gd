class_name EquipoEntrenador
extends Resource

@export var clase: String= "Joven"
@export var nombre: String =""
@export var miembros: Array[EncuentroEntrada]= []
@export var pago_base: int =16

func nombre_completo() -> String:
	return (clase+ " " +nombre).strip_edges()

func crear_equipo(rng: RandomNumberGenerator= null) -> Array[PokemonInstancia]:
	var lista: Array[PokemonInstancia]= []
	for m in miembros:
		var p:= PokemonInstancia.crear(m.especie, m.nivel_min, rng)
		for id in m.trinkets:
			if EfectosTrinket.puede_equipar(p, id)== "":
				p.trinkets.append(id)
		lista.append(p)
	return lista
