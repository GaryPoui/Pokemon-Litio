class_name EquipoEntrenador
extends Resource

@export var clase: String= "Joven"
@export var nombre: String =""
@export var miembros: Array[EncuentroEntrada]= []
@export var pago_base: int =16
@export var objetos: Array[String]= []

func nombre_completo() -> String:
	return (clase+ " " +nombre).strip_edges()

func crear_equipo(rng: RandomNumberGenerator= null) -> Array[PokemonInstancia]:
	var lista: Array[PokemonInstancia]= []
	for m in miembros:
		var p:= PokemonInstancia.crear(m.especie, m.nivel_min, rng)
		for id in m.trinkets:
			if EfectosTrinket.puede_equipar(p, id)== "":
				p.trinkets.append(id)
		if not m.movimientos.is_empty():
			p.movimientos.clear()
			p.pp.clear()
			for id in m.movimientos.slice(0, PokemonInstancia.MAX_MOVIMIENTOS):
				var mov:= BaseDatos.movimiento(id)
				if mov!= null:
					p.movimientos.append(mov)
					p.pp.append(mov.pp)
		p.ia.assign(m.ia)
		lista.append(p)
	return lista
