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
@export var ball: String= "pokeball"
@export var trinkets: Array[String] =[]
@export var habilidad: String= ""
@export var amistad :int= 70
var ia: Array[String]= []

static func crear(esp: EspeciePokemon, niv: int, rng: RandomNumberGenerator= null, prob_oculta:= 0.0) -> PokemonInstancia:
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
	p.habilidad =sortear_habilidad(esp, rng, prob_oculta)
	p.amistad= esp.amistad_base
	p.ps_actuales= p.ps_max()
	return p

static func sortear_habilidad(esp: EspeciePokemon, rng: RandomNumberGenerator, prob_oculta:= 0.0) -> String:
	if esp.habilidad_oculta!= "" and prob_oculta> 0.0 and rng.randf()< prob_oculta:
		return esp.habilidad_oculta
	if esp.habilidades.is_empty():
		return esp.habilidad_oculta
	return esp.habilidades[rng.randi_range(0, esp.habilidades.size()- 1)]

func tiene_oculta() -> bool:
	return habilidad!= "" and habilidad== especie.habilidad_oculta and not especie.habilidades.has(habilidad)

func nombre_habilidad() -> String:
	var h:= BaseDatos.habilidad(habilidad)
	return h.nombre if h!= null else ""

func subir_amistad(cantidad: int) -> void:
	amistad= clampi(amistad+ cantidad, 0, 255)

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
		subir_amistad(5 if amistad< 100 else (3 if amistad< 200 else 2))
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

func puede_evolucionar(equipo: Array= []) -> bool:
	return Evoluciones.por_nivel(self, equipo)!= ""

func evolucionar(nueva: EspeciePokemon) -> void:
	var antes:= ps_max()
	var oculta:= tiene_oculta()
	var hueco:= especie.habilidades.find(habilidad)
	if oculta and nueva.habilidad_oculta!= "":
		habilidad= nueva.habilidad_oculta
	elif not nueva.habilidades.is_empty():
		habilidad =nueva.habilidades[clampi(hueco, 0, nueva.habilidades.size()- 1)]
	var arbol:= Engine.get_main_loop() as SceneTree
	var estado: Node= arbol.root.get_node_or_null("Estado") if arbol!= null else null
	if estado!= null:
		estado.cambiar_companero(especie.id, nueva.id)
	especie= nueva
	ps_actuales =clampi(ps_actuales+ ps_max()- antes, 0, ps_max())

func aprender(m: Movimiento) -> bool:
	if movimientos.has(m) or movimientos.size()>= MAX_MOVIMIENTOS:
		return false
	movimientos.append(m)
	pp.append(m.pp)
	return true

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
		"ball": ball,
		"trinkets": trinkets.duplicate(),
		"habilidad": habilidad,
		"amistad": amistad,
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
	p.ball= str(d.get("ball", "pokeball"))
	p.trinkets.assign(Array(d.get("trinkets", [])).map(func(x): return str(x)))
	p.habilidad= str(d.get("habilidad", ""))
	if p.habilidad== "" and not p.especie.habilidades.is_empty():
		var suma:= 0
		for s in STATS:
			suma+= int(p.ivs.get(s, 0))
		p.habilidad= p.especie.habilidades[suma% p.especie.habilidades.size()]
	p.amistad= int(d.get("amistad", p.especie.amistad_base))
	return p
