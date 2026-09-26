class_name PokemonInstancia
extends Resource

const STATS:= ["ps", "ataque", "defensa", "at_esp", "def_esp", "velocidad"]
const NIVEL_MAX :=100
const MAX_MOVIMIENTOS:= 4

@export var especie: EspeciePokemon
@export var apodo: String= ""
@export var nivel: int =5
@export var experiencia: int= 0
@export var naturaleza: String ="fuerte"
@export var ivs: Dictionary= {}
@export var evs: Dictionary ={}
@export var ps_actuales: int= 1
@export var movimientos: Array[Movimiento] =[]
@export var pp: Array[int]= []
@export var estado: String =""
@export var objeto: String= ""
@export var genero: String =""

static func crear(esp: EspeciePokemon, niv: int, rng: RandomNumberGenerator= null) -> PokemonInstancia:
	if rng== null:
		rng =RandomNumberGenerator.new()
		rng.randomize()
	var p:= PokemonInstancia.new()
	p.especie= esp
	p.nivel =clampi(niv, 1, NIVEL_MAX)
	p.experiencia= Crecimiento.exp_para_nivel(esp.crecimiento, p.nivel)
	var nats:= Naturalezas.ids()
	p.naturaleza =nats[rng.randi_range(0, nats.size()- 1)]
	for s in STATS:
		p.ivs[s]= rng.randi_range(0, 31)
		p.evs[s] =0
	var conocidos:= esp.movimientos_hasta(p.nivel)
	for m in conocidos.slice(maxi(0, conocidos.size()- MAX_MOVIMIENTOS)):
		p.movimientos.append(m)
		p.pp.append(m.pp)
	p.genero= sortear_genero(esp, rng)
	p.ps_actuales= p.ps_max()
	return p

static func sortear_genero(esp: EspeciePokemon, rng: RandomNumberGenerator) -> String:
	if esp.ratio_genero< 0:
		return ""
	return "F" if rng.randi_range(1, 8)<= esp.ratio_genero else "M"

func simbolo_genero() -> String:
	match genero:
		"M":
			return "♂"
		"F":
			return "♀"
	return ""

func color_genero() -> Color:
	return Color("3068d8") if genero== "M" else Color("e03848")

func nombre() -> String:
	return apodo if apodo!= "" else especie.nombre

func stat(nombre_stat: String) -> int:
	var base:= especie.stat_base(nombre_stat)
	var iv: int= ivs.get(nombre_stat, 0)
	var ev: int =evs.get(nombre_stat, 0)
	var parcial:= floori((2* base+ iv+ floori(ev/ 4.0))* nivel /100.0)
	if nombre_stat== "ps":
		return parcial+ nivel +10
	return floori((parcial+ 5)* Naturalezas.porcentaje(naturaleza, nombre_stat)/ 100.0)

func ps_max() -> int:
	return stat("ps")

func esta_debilitado() -> bool:
	return ps_actuales<= 0

func recibir_danio(cantidad: int) -> int:
	var real:= mini(cantidad, ps_actuales)
	ps_actuales -=real
	return real

func curar_ps(cantidad: int) -> int:
	if esta_debilitado():
		return 0
	var real:= mini(cantidad, ps_max()- ps_actuales)
	ps_actuales+= real
	return real

func curar() -> void:
	ps_actuales= ps_max()
	estado =""
	for i in movimientos.size():
		pp[i]= movimientos[i].pp

func exp_siguiente_nivel() -> int:
	return Crecimiento.exp_para_nivel(especie.crecimiento, mini(nivel+ 1, NIVEL_MAX))

func ganar_experiencia(cantidad: int) -> Array[Dictionary]:
	var eventos: Array[Dictionary]= []
	if nivel>= NIVEL_MAX or esta_debilitado():
		return eventos
	experiencia +=cantidad
	while nivel< NIVEL_MAX and experiencia>= Crecimiento.exp_para_nivel(especie.crecimiento, nivel+ 1):
		var antes:= ps_max()
		nivel+= 1
		ps_actuales +=ps_max()- antes
		eventos.append({"tipo": "nivel", "nivel": nivel, "ps": ps_actuales, "ps_max": ps_max()})
		for m in especie.movimientos_en(nivel):
			if movimientos.has(m):
				continue
			if movimientos.size()< MAX_MOVIMIENTOS:
				movimientos.append(m)
				pp.append(m.pp)
				eventos.append({"tipo": "aprendio", "movimiento": m})
			else:
				eventos.append({"tipo": "quiere_aprender", "movimiento": m})
	if nivel>= NIVEL_MAX:
		experiencia= Crecimiento.exp_para_nivel(especie.crecimiento, NIVEL_MAX)
	return eventos

func reemplazar_movimiento(indice: int, nuevo: Movimiento) -> void:
	movimientos[indice]= nuevo
	pp[indice] =nuevo.pp

func a_diccionario() -> Dictionary:
	var movs:= []
	for m in movimientos:
		movs.append(m.resource_path)
	return {
		"especie": especie.resource_path,
		"apodo": apodo,
		"nivel": nivel,
		"experiencia": experiencia,
		"naturaleza": naturaleza,
		"ivs": ivs,
		"evs": evs,
		"ps": ps_actuales,
		"movimientos": movs,
		"pp": pp,
		"estado": estado,
		"objeto": objeto,
		"genero": genero,
	}

static func desde_diccionario(d: Dictionary) -> PokemonInstancia:
	var p:= PokemonInstancia.new()
	p.especie= load(d["especie"])
	p.apodo =str(d.get("apodo", ""))
	p.nivel= int(d["nivel"])
	p.experiencia =int(d["experiencia"])
	p.naturaleza= str(d["naturaleza"])
	for s in STATS:
		p.ivs[s]= int(d["ivs"].get(s, 0))
		p.evs[s] =int(d["evs"].get(s, 0))
	for ruta in d["movimientos"]:
		p.movimientos.append(load(ruta))
	for v in d["pp"]:
		p.pp.append(int(v))
	p.ps_actuales= int(d["ps"])
	p.estado =str(d.get("estado", ""))
	p.objeto= str(d.get("objeto", ""))
	p.genero =str(d.get("genero", ""))
	return p
