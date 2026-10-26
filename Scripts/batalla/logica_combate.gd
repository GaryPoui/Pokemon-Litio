class_name LogicaCombate
extends RefCounted

const ESTADOS:= {"burn": "que", "poison": "env", "paralysis": "par", "sleep": "dor", "freeze": "con"}
const TEXTO_ESTADO :={
	"que": "¡%s se quemó!",
	"env": "¡%s fue envenenado!",
	"par": "¡%s está paralizado! ¡Quizás no pueda moverse!",
	"dor": "¡%s se durmió!",
	"con": "¡%s se congeló!",
}
const INMUNES:= {"que": ["fuego"], "env": ["veneno", "acero"], "con": ["hielo"]}
const NOMBRE_STAT :={
	"ataque": "el Ataque",
	"defensa": "la Defensa",
	"at_esp": "el Ataque Especial",
	"def_esp": "la Defensa Especial",
	"velocidad": "la Velocidad",
	"precision": "la Precisión",
	"evasion": "la Evasión",
}
const TEXTO_SACUDIDAS:= {
	0: "¡Oh, no! ¡El Pokémon se ha escapado!",
	1: "¡Vaya! ¡Parecía que lo había atrapado!",
	3: "¡Rayos! ¡Casi lo consigues!",
}
const MAGNITUDES :=[[4, 10, 5], [5, 30, 10], [6, 50, 20], [7, 70, 30], [8, 90, 20], [9, 110, 10], [10, 150, 5]]
const OBJETIVO_PROPIO :=["user", "users-field", "user-and-allies", "ally", "user-or-ally"]

var equipo_j: Array[PokemonInstancia]= []
var equipo_r: Array[PokemonInstancia] =[]
var salvaje:= true
var nombre_entrenador :=""
var pago_base:= 0
var dinero_ganado :=0
var turnos:= 0
var sin_exp :=false
var aleatorio_fijo:= -1
var capturados_dex :=0
var rng:= RandomNumberGenerator.new()
var j: Luchador
var r: Luchador
var participantes: Array[PokemonInstancia]= []
var intentos_huida:= 0
var terminado :=false
var resultado:= ""
var esperando_reemplazo :=false
var j_anunciado:= false
var forcejeo: Movimiento
var inventario: Node
var equipo :Node
var eventos: Array[Dictionary]= []
var espacio_raro:= 0
var objetos_rival: Array[String] =[]
var trampas:= {"jugador": {"puas": 0, "rocas": false}, "rival": {"puas": 0, "rocas": false}}
var ultimo_caido :={"jugador": -1, "rival": -1}
const PUAS:= [0.0, 1.0/ 8.0, 1.0/ 6.0, 1.0/ 4.0]
const ILUSION:= ["zorua", "zoroark"]
const CURAS_RIVAL :={"hyper_potion": 0.0, "super_potion": 0.0, "potion": 0.0}

func _init(jugador: Array[PokemonInstancia], rival: Array[PokemonInstancia], es_salvaje: bool, entrenador: String= "") -> void:
	equipo_j= jugador
	equipo_r =rival
	salvaje= es_salvaje
	nombre_entrenador =entrenador
	rng.randomize()
	forcejeo= Movimiento.new()
	forcejeo.id ="struggle"
	forcejeo.nombre= "Forcejeo"
	forcejeo.tipo =""
	forcejeo.poder= 50
	forcejeo.precision =0
	forcejeo.pp= 1

func iniciar() -> Array[Dictionary]:
	r= _nuevo_rival(_siguiente_util(equipo_r))
	j =Luchador.new(_siguiente_util(equipo_j))
	participantes= [j.pokemon]
	if salvaje:
		_ev_sale("rival", r.pokemon)
		_texto("¡Un %s salvaje apareció!" % r.pokemon.nombre())
	else:
		_texto("¡%s quiere luchar!" % nombre_entrenador)
		_texto("¡%s envió a %s!" % [nombre_entrenador, r.nombre_visible()])
		_ev_sale("rival", r.pokemon)
		_anunciar_trinkets(r.pokemon)
	_texto("¡Adelante, %s!" % j.pokemon.nombre())
	_ev_sale("jugador", j.pokemon)
	if _entrar_trampas(j):
		_revisar_debilitados()
	return _tomar()

func turno(accion: Dictionary) -> Array[Dictionary]:
	if terminado or esperando_reemplazo:
		return _tomar()
	turnos+= 1
	j.retrocede= false
	r.retrocede =false
	for l in [j, r]:
		l.actuo_turno= false
		l.herido_turno =false
	var tipo: String= accion.get("tipo", "movimiento")
	if tipo== "huir":
		if not salvaje:
			_texto("¡No puedes huir de un combate contra un Entrenador!")
			return _tomar()
		if _huir():
			return _tomar()
	elif tipo =="objeto":
		if not _usar_objeto(accion) or terminado:
			return _tomar()
	elif tipo== "cambio":
		_cambiar(int(accion["indice"]))
	var accion_r:= _accion_rival()
	var ir: int= int(accion_r.get("indice", -1))
	if accion_r.get("tipo", "")== "objeto":
		_usar_objeto_rival(str(accion_r["id"]))
	var orden: Array= []
	if tipo== "movimiento":
		var ij:= int(accion.get("indice", -1))
		if _primero_j(ij, ir):
			orden= [["j", ij], ["r", ir]]
		else:
			orden =[["r", ir], ["j", ij]]
		if accion_r.get("tipo", "")== "objeto":
			orden= [["j", ij]]
	elif accion_r.get("tipo", "")!= "objeto":
		orden= [["r", ir]]
	for par in orden:
		var atacante: Luchador= j if par[0]== "j" else r
		var defensor: Luchador =r if atacante== j else j
		if terminado or atacante.pokemon.esta_debilitado() or defensor.pokemon.esta_debilitado():
			continue
		_ejecutar(atacante, defensor, par[1])
		_revisar_baya(defensor)
		_revisar_baya(atacante)
		if _revisar_debilitados():
			break
	if not terminado and not esperando_reemplazo:
		_fin_de_turno()
		_revisar_debilitados()
	return _tomar()

func reemplazar(indice: int) -> Array[Dictionary]:
	if not esperando_reemplazo or equipo_j[indice].esta_debilitado():
		return _tomar()
	esperando_reemplazo= false
	j_anunciado =false
	j= Luchador.new(equipo_j[indice])
	if not participantes.has(j.pokemon):
		participantes.append(j.pokemon)
	_texto("¡Adelante, %s!" % j.pokemon.nombre())
	_ev_sale("jugador", j.pokemon)
	return _tomar()

func nombre_de(l: Luchador) -> String:
	if l== j:
		return l.nombre_visible()
	return ("el %s salvaje" if salvaje else "el %s enemigo") % l.nombre_visible()

func movimiento_de(l: Luchador, indice: int) -> Movimiento:
	return forcejeo if indice< 0 else l.pokemon.movimientos[indice]

func _ev(d: Dictionary) -> void:
	eventos.append(d)

func _texto(t: String) -> void:
	_ev({"tipo": "texto", "texto": t})

func _tomar() -> Array[Dictionary]:
	var e:= eventos
	eventos= []
	return e

func _lado(l: Luchador) -> String:
	return "jugador" if l== j else "rival"

func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper()+ s.substr(1)

func _de(l: Luchador) -> String:
	var n:= nombre_de(l)
	return "del "+ n.substr(3) if n.begins_with("el ") else "de " +n

func _a(l: Luchador) -> String:
	var n:= nombre_de(l)
	return "al "+ n.substr(3) if n.begins_with("el ") else "a "+ n

func _siguiente_util(lista: Array[PokemonInstancia]) -> PokemonInstancia:
	for p in lista:
		if not p.esta_debilitado():
			return p
	return null

func _ev_sale(lado: String, p: PokemonInstancia) -> void:
	var visto:= p
	if lado== "rival" and r!= null and r.pokemon== p and r.disfraz!= null:
		visto= r.disfraz
	_ev({"tipo": "sale", "lado": lado, "pokemon": visto, "ps": p.ps_actuales, "max": p.ps_max(), "nivel": p.nivel, "estado": p.estado, "exp": p.experiencia, "ball": p.ball})

func _nuevo_rival(p: PokemonInstancia) -> Luchador:
	var l:= Luchador.new(p)
	if p!= null and p.especie.id in ILUSION:
		for k in range(equipo_r.size()- 1, -1, -1):
			var o:= equipo_r[k]
			if o!= p and not o.esta_debilitado():
				l.disfraz= o
				break
	return l

func _romper_ilusion(l: Luchador) -> void:
	if l.disfraz== null:
		return
	l.disfraz= null
	var p:= l.pokemon
	_ev({"tipo": "ilusion", "lado": _lado(l), "pokemon": p, "ps": p.ps_actuales, "max": p.ps_max(), "nivel": p.nivel, "estado": p.estado})
	_texto("¡La ilusión de %s se desvaneció!" % p.nombre())

func _anunciar_trinkets(p: PokemonInstancia) -> void:
	var nombres:= []
	for id in p.trinkets:
		var t:= BaseDatos.trinket(id)
		if t!= null and not nombres.has(t.nombre):
			nombres.append(t.nombre)
	if nombres.is_empty():
		return
	var lista: String= nombres[0] if nombres.size()== 1 else ", ".join(nombres.slice(0, nombres.size()- 1))+ " y " +nombres.back()
	var quien:= r.nombre_visible() if r!= null and r.pokemon== p else p.nombre()
	_texto("¡%s lleva %s!" % [quien, lista])

func _ev_ps(l: Luchador, desde: int, sonido: String= "") -> void:
	_ev({"tipo": "ps", "lado": _lado(l), "desde": desde, "hasta": l.pokemon.ps_actuales, "max": l.pokemon.ps_max(), "sonido": sonido})

func _herir(l: Luchador, cantidad: int, sonido: String ="golpe_normal") -> int:
	var antes:= l.pokemon.ps_actuales
	var aguanta:= false
	if cantidad>= antes and antes> 1 and not l.aguante_usado and EfectosTrinket.total("aguante", l.pokemon)> 0.0:
		cantidad= antes- 1
		l.aguante_usado =true
		aguanta= true
	var real:= l.pokemon.recibir_danio(cantidad)
	if l.pokemon.esta_debilitado() and antes> 0:
		ultimo_caido[_lado(l)]= turnos
	_ev_ps(l, antes, sonido)
	if aguanta:
		var ids:= EfectosTrinket.contar("aguante", l.pokemon).keys()
		_ev({"tipo": "sonido", "nombre": "objeto_activo"})
		_texto("¡%s aguantó el golpe gracias a su %s!" % [_cap(nombre_de(l)), BaseDatos.trinket(ids[0]).nombre])
	return real

func _accion_rival() -> Dictionary:
	var p:= r.pokemon
	if not salvaje and not p.esta_debilitado() and p.ps_actuales* 10<= p.ps_max()* 3:
		for id in CURAS_RIVAL:
			if objetos_rival.has(id):
				return {"tipo": "objeto", "id": id}
	return {"tipo": "movimiento", "indice": _ia()}

func _usar_objeto_rival(id: String) -> void:
	objetos_rival.erase(id)
	var o:= BaseDatos.objeto(id)
	var antes:= r.pokemon.ps_actuales
	r.pokemon.curar_ps(o.cura_ps if o!= null else 20)
	_texto("¡%s usó %s!" % [nombre_entrenador, o.nombre if o!= null else id])
	_ev_ps(r, antes)

func _ia() -> int:
	if not r.pokemon.ia.is_empty():
		var elegido:= _ia_reglas(r.pokemon.ia)
		if elegido>= 0:
			return elegido
	var opciones:= []
	for i in r.pokemon.movimientos.size():
		if r.pokemon.pp[i]> 0:
			opciones.append(i)
	if opciones.is_empty():
		return -1
	return opciones[rng.randi_range(0, opciones.size()- 1)]

func _primero_j(ij: int, ir: int) -> bool:
	var pj:= movimiento_de(j, ij).prioridad
	var pr :=movimiento_de(r, ir).prioridad
	if pj!= pr:
		return pj> pr
	var vj:= j.stat_efectivo("velocidad")
	var vr:= r.stat_efectivo("velocidad")
	if vj!= vr:
		return vj< vr if espacio_raro> 0 else vj >vr
	return rng.randi_range(0, 1)== 0

func _ejecutar(a: Luchador, d: Luchador, indice: int) -> void:
	var p:= a.pokemon
	var nombre:= _cap(nombre_de(a))
	if p.estado== "dor":
		a.turnos_sueno-= 1
		if a.turnos_sueno> 0:
			_texto("%s está dormido como un tronco." % nombre)
			return
		_poner_estado(a, "")
		_texto("¡%s se despertó!" % nombre)
	elif p.estado =="con":
		if rng.randi_range(1, 5)== 1:
			_poner_estado(a, "")
			_texto("¡%s se descongeló!" % nombre)
		else:
			_texto("¡%s está congelado!" % nombre)
			return
	if a.retrocede:
		_texto("¡%s retrocedió!" % nombre)
		return
	if p.estado== "par" and rng.randi_range(1, 4) ==1:
		_texto("¡%s está paralizado! ¡No se puede mover!" % nombre)
		return
	if a.confusion> 0:
		a.confusion-= 1
		if a.confusion== 0:
			_texto("¡%s ya no está confuso!" % nombre)
		else:
			_texto("¡%s está confuso!" % nombre)
			if rng.randi_range(0, 1)== 0:
				_texto("¡Está tan confuso que se hirió a sí mismo!")
				_herir(a, danio_confusion(a))
				return
	var mov:= movimiento_de(a, indice)
	a.actuo_turno= true
	if indice>= 0:
		p.pp[indice]= maxi(0, p.pp[indice]- 1)
	else:
		_texto("¡%s no le quedan movimientos!" % _cap(_a(a)))
	_texto("¡%s usó %s!" % [nombre, mov.nombre])
	if not mov.objetivo in OBJETIVO_PROPIO and mov.precision> 0:
		var etapa:= clampi(a.etapas["precision"]- d.etapas["evasion"], -6, 6)
		var f:= Luchador.fraccion("precision", etapa)
		if rng.randi_range(1, 100)> mov.precision* f.x/ f.y:
			_texto("¡Pero falló!")
			return
	if mov.categoria== "estado":
		_efecto_estado(a, d, mov)
		return
	if mov.id== "bide":
		_texto("¡Pero falló!")
		return
	var ef:= Tipos.efectividad(mov.tipo, d.tipos())
	if ef== 0.0:
		_texto("No afecta %s..." % _a(d))
		return
	var golpe:= calcular_danio(a, d, mov, ef)
	if mov.tipo== "electrico":
		a.cargado= 0
	var real:= _herir(d, golpe["danio"], "golpe_eficaz" if ef> 1.0 else ("golpe_poco" if ef< 1.0 else "golpe_normal"))
	d.herido_turno= true
	if not d.pokemon.esta_debilitado():
		_romper_ilusion(d)
	if golpe["critico"]:
		_texto("¡Un golpe crítico!")
	if ef> 1.0:
		_texto("¡Es muy eficaz!")
	elif ef< 1.0:
		_texto("No es muy eficaz...")
	if mov.id== "struggle":
		_herir(a, maxi(1, floori(p.ps_max()/ 4.0)))
		_texto("¡%s también se ha hecho daño!" % nombre)
	elif mov.drenaje> 0 and not p.esta_debilitado():
		var antes:= p.ps_actuales
		if p.curar_ps(maxi(1, floori(real* mov.drenaje/ 100.0)))> 0:
			_ev_ps(a, antes)
			_texto("¡%s ha perdido energía!" % _cap(nombre_de(d)))
	elif mov.drenaje< 0 and not p.esta_debilitado():
		_herir(a, maxi(1, floori(real* -mov.drenaje/ 100.0)))
		_texto("¡%s también se ha hecho daño!" % nombre)
	if not mov.cambios_stats.is_empty():
		var obj: Luchador= a if mov.meta== "damage-raise" else d
		var prob:= mov.prob_stat if mov.prob_stat> 0 else 100
		if not obj.pokemon.esta_debilitado() and rng.randi_range(1, 100)<= prob:
			for s in mov.cambios_stats:
				_cambiar_etapa(obj, s, int(mov.cambios_stats[s]), false)
	if d.pokemon.esta_debilitado():
		return
	if ESTADOS.has(mov.estado) and mov.prob_estado> 0 and rng.randi_range(1, 100)<= mov.prob_estado:
		_aplicar_estado(d, ESTADOS[mov.estado], false)
	elif mov.estado== "confusion" and mov.prob_estado> 0 and rng.randi_range(1, 100)<= mov.prob_estado:
		_confundir(d, false)
	if mov.prob_retroceso> 0 and rng.randi_range(1, 100) <=mov.prob_retroceso:
		d.retrocede= true

func calcular_danio(a: Luchador, d: Luchador, mov: Movimiento, ef: float) -> Dictionary:
	if mov.id== "super_fang":
		return {"danio": maxi(1, floori(d.pokemon.ps_actuales/ 2.0)), "critico": false}
	var fisico:= mov.categoria== "fisico"
	var s_at:= "ataque" if fisico else "at_esp"
	var s_df :="defensa" if fisico else "def_esp"
	var tabla:= [16, 8, 4, 3, 2]
	var critico:= rng.randi_range(1, tabla[clampi(a.critico_extra+ mov.critico+ roundi(EfectosTrinket.total("critico", a.pokemon)), 0, 4)])== 1
	var ataque: int
	var defensa: int
	var fuente: Luchador= d if mov.id== "foul_play" else a
	if critico:
		ataque= fuente.stat_con_etapa(s_at, maxi(fuente.etapas[s_at], 0))
		defensa =d.stat_con_etapa(s_df, mini(d.etapas[s_df], 0))
	else:
		ataque= fuente.stat_con_etapa(s_at, fuente.etapas[s_at])
		defensa= d.stat_con_etapa(s_df, d.etapas[s_df])
	var nivel:= a.pokemon.nivel
	var base:= (2* nivel/ 5+ 2)* poder_de(a, d, mov)* ataque/ defensa/ 50+ 2
	if critico:
		base*= 2
	base= base* (aleatorio_fijo if aleatorio_fijo>= 0 else rng.randi_range(85, 100))/ 100
	if mov.tipo in a.tipos():
		base =redondear(base, 1.5+ EfectosTrinket.total("stab", a.pokemon))
	base= floori(base *ef)
	if fisico and a.pokemon.estado== "que":
		base= base/ 2
	var final:= encadenar(1.0+ EfectosTrinket.total("danio_hecho", a.pokemon), 1.0- EfectosTrinket.total("danio_recibido", d.pokemon))
	base =redondear_fijo(base, final)
	return {"danio": maxi(1, base), "critico": critico}

static func a_4096(m: float) -> int:
	return roundi(m* 4096.0)

static func redondear_fijo(d: int, m4096: int) -> int:
	var q:= d* m4096
	var entero:= q/ 4096
	return entero+ 1 if q% 4096> 2048 else entero

static func redondear(d: int, m: float) -> int:
	return redondear_fijo(d, a_4096(m))

static func encadenar(m1: float, m2: float) -> int:
	return (a_4096(m1)* a_4096(m2)+ 2048)>> 12

func poder_de(a: Luchador, d: Luchador, mov: Movimiento) -> int:
	var base_p:= _poder_base(a, d, mov)
	if a.cargado> 0 and mov.tipo== "electrico":
		return base_p* 2
	return base_p

func danio_confusion(a: Luchador) -> int:
	var ataque:= a.stat_con_etapa("ataque", a.etapas["ataque"])
	var defensa:= a.stat_con_etapa("defensa", a.etapas["defensa"])
	var base:= (2* a.pokemon.nivel/ 5+ 2)* 40* ataque/ defensa/ 50+ 2
	base= base* (aleatorio_fijo if aleatorio_fijo>= 0 else rng.randi_range(85, 100))/ 100
	return maxi(1, base)

func _poder_base(a: Luchador, d: Luchador, mov: Movimiento) -> int:
	var pa:= a.pokemon
	var pd:= d.pokemon
	match mov.id:
		"reversal", "flail":
			var p48:= floori(48.0* a.pokemon.ps_actuales/ a.pokemon.ps_max())
			if p48<= 1:
				return 200
			if p48<= 4:
				return 150
			if p48 <=9:
				return 100
			if p48<= 16:
				return 80
			if p48<= 32:
				return 40
			return 20
		"wring_out":
			return maxi(1, 120* pd.ps_actuales/ pd.ps_max())
		"eruption", "water_spout":
			return maxi(1, 150* pa.ps_actuales/ pa.ps_max())
		"low_kick", "grass_knot":
			var kg:= BaseDatos.peso(pd.especie.id)
			if kg< 10.0:
				return 20
			if kg< 25.0:
				return 40
			if kg< 50.0:
				return 60
			if kg< 100.0:
				return 80
			if kg< 200.0:
				return 100
			return 120
		"heat_crash", "heavy_slam":
			var r:= BaseDatos.peso(pa.especie.id)/ maxf(0.1, BaseDatos.peso(pd.especie.id))
			if r>= 5.0:
				return 120
			if r>= 4.0:
				return 100
			if r>= 3.0:
				return 80
			if r>= 2.0:
				return 60
			return 40
		"gyro_ball":
			return mini(150, 25* d.stat_efectivo("velocidad")/ maxi(1, a.stat_efectivo("velocidad"))+ 1)
		"electro_ball":
			var v:= a.stat_efectivo("velocidad")/ maxi(1, d.stat_efectivo("velocidad"))
			if v>= 4:
				return 150
			if v== 3:
				return 120
			if v== 2:
				return 80
			if v== 1:
				return 60
			return 40
		"acrobatics":
			return mov.poder* 2 if pa.objeto== "" else mov.poder
		"assurance":
			return mov.poder* 2 if d.herido_turno else mov.poder
		"brine":
			return mov.poder* 2 if pd.ps_actuales* 2<= pd.ps_max() else mov.poder
		"facade":
			return mov.poder* 2 if pa.estado in ["que", "env", "par"] else mov.poder
		"hex":
			return mov.poder* 2 if pd.estado!= "" else mov.poder
		"payback":
			return mov.poder* 2 if d.actuo_turno else mov.poder
		"retaliate":
			return mov.poder* 2 if represalia_lista(a) else mov.poder
		"revenge":
			return mov.poder* 2 if a.herido_turno else mov.poder
		"punishment":
			return mini(200, 60+ 20* _subidas(d))
		"stored_power":
			return 20+ 20* _subidas(a)
		"magnitude":
			var tiro:= rng.randi_range(1, 100)
			for fila in MAGNITUDES:
				tiro-= fila[2]
				if tiro<= 0:
					_texto("¡Magnitud %d!" % fila[0])
					return fila[1]
			return 70
	return maxi(1, mov.poder)

func _subidas(l: Luchador) -> int:
	var n:= 0
	for e in l.etapas:
		n+= maxi(0, int(l.etapas[e]))
	return n

func _efecto_estado(a: Luchador, d: Luchador, mov: Movimiento) -> void:
	match mov.id:
		"trick_room":
			if espacio_raro> 0:
				espacio_raro= 0
				_texto("¡Las dimensiones retorcidas volvieron a la normalidad!")
			else:
				espacio_raro =5
				_texto("¡%s retorció las dimensiones!" % _cap(nombre_de(a)))
			return
		"baton_pass":
			_relevo(a)
			return
		"spikes":
			var t: Dictionary= trampas[_lado(d)]
			if int(t["puas"])>= 3:
				_texto("¡Pero falló!")
			else:
				t["puas"]= int(t["puas"])+ 1
				_texto("¡Se esparcieron púas alrededor de los pies %s!" % _equipo_de(d))
			return
		"stealth_rock":
			var t2: Dictionary= trampas[_lado(d)]
			if t2["rocas"]:
				_texto("¡Pero falló!")
			else:
				t2["rocas"] =true
				_texto("¡Rocas puntiagudas flotan alrededor %s!" % _equipo_de(d))
			return
		"roar", "whirlwind":
			_arrastrar(a, d)
			return
		"soak":
			if d.tipos()== ["agua"]:
				_texto("¡Pero falló!")
			else:
				d.tipos_forzados= ["agua"]
				_ev({"tipo": "tipos", "lado": _lado(d), "tipos": d.tipos()})
				_texto("¡%s ahora es de tipo Agua!" % _cap(nombre_de(d)))
			return
	var hizo:= false
	if mov.id== "charge":
		a.cargado= 2
		_texto("¡%s comenzó a cargarse de energía!" % _cap(nombre_de(a)))
		hizo= true
	if mov.curacion> 0:
		var p:= a.pokemon
		var antes:= p.ps_actuales
		if p.curar_ps(maxi(1, floori(p.ps_max()* mov.curacion/ 100.0)))> 0:
			_ev_ps(a, antes)
			_texto("¡%s recuperó salud!" % _cap(nombre_de(a)))
		else:
			_texto("¡Los PS %s están al máximo!" % _de(a))
		hizo= true
	if not mov.cambios_stats.is_empty():
		var obj: Luchador= a if mov.objetivo in OBJETIVO_PROPIO else d
		for s in mov.cambios_stats:
			_cambiar_etapa(obj, s, int(mov.cambios_stats[s]), true)
		hizo =true
	if ESTADOS.has(mov.estado):
		_aplicar_estado(d, ESTADOS[mov.estado], true)
		hizo= true
	elif mov.estado== "confusion":
		_confundir(d, true)
		hizo =true
	if mov.id== "focus_energy":
		a.critico_extra= 2
		_texto("¡%s se está preparando para luchar!" % _cap(nombre_de(a)))
		hizo =true
	if not hizo:
		_texto("¡Pero no pasó nada!")

func _confundir(l: Luchador, anunciar_fallo: bool) -> bool:
	if l.pokemon.esta_debilitado():
		return false
	if l.confusion> 0:
		if anunciar_fallo:
			_texto("¡%s ya está confuso!" % _cap(nombre_de(l)))
		return false
	l.confusion= rng.randi_range(2, 5)
	_texto("¡%s se encuentra confuso!" % _cap(nombre_de(l)))
	return true

func _relevo(a: Luchador) -> void:
	var lista:= equipo_r if a== r else equipo_j
	var sig: PokemonInstancia= null
	for k in range(lista.size()- 1, -1, -1):
		if lista[k]!= a.pokemon and not lista[k].esta_debilitado():
			sig= lista[k]
			break
	if sig== null:
		_texto("¡Pero falló!")
		return
	var etapas:= a.etapas.duplicate()
	var conf:= a.confusion
	var lado:= _lado(a)
	_texto("¡%s pasó el relevo!" % _cap(nombre_de(a)))
	_ev({"tipo": "retirar", "lado": lado, "ball": a.pokemon.ball})
	var nuevo:= _nuevo_rival(sig) if a== r else Luchador.new(sig)
	nuevo.etapas= etapas
	nuevo.confusion =conf
	if a== r:
		r= nuevo
		_texto("¡%s envió a %s!" % [nombre_entrenador, r.nombre_visible()])
		_ev_sale("rival", sig)
		_anunciar_trinkets(sig)
		_entrar_trampas(r)
	else:
		j= nuevo
		if not participantes.has(sig):
			participantes.append(sig)
		_texto("¡Adelante, %s!" % sig.nombre())
		_ev_sale("jugador", sig)
		_entrar_trampas(j)

func _equipo_de(l: Luchador) -> String:
	return "del equipo rival" if l== r else "de tu equipo"

func _entrar_trampas(l: Luchador) -> bool:
	var t: Dictionary= trampas[_lado(l)]
	var p:= l.pokemon
	if p.esta_debilitado():
		return false
	if int(t["puas"])> 0 and not "volador" in l.tipos():
		_herir(l, maxi(1, floori(p.ps_max()* PUAS[int(t["puas"])])), "golpe_normal")
		_texto("¡%s fue herido por las púas!" % _cap(nombre_de(l)))
	if t["rocas"] and not p.esta_debilitado():
		var ef:= Tipos.efectividad("roca", l.tipos())
		_herir(l, maxi(1, floori(p.ps_max()* ef/ 8.0)), "golpe_eficaz" if ef> 1.0 else "golpe_normal")
		_texto("¡Las rocas puntiagudas hirieron a %s!" % nombre_de(l))
	return p.esta_debilitado()

func _arrastrar(a: Luchador, d: Luchador) -> void:
	if salvaje:
		_texto("¡Pero falló!")
		return
	var lista:= equipo_r if d== r else equipo_j
	var opciones: Array[PokemonInstancia]= []
	for o in lista:
		if o!= d.pokemon and not o.esta_debilitado():
			opciones.append(o)
	if opciones.is_empty():
		_texto("¡Pero falló!")
		return
	var sig: PokemonInstancia= opciones[rng.randi_range(0, opciones.size()- 1)]
	var lado:= _lado(d)
	_ev({"tipo": "retirar", "lado": lado, "ball": d.pokemon.ball})
	if d== r:
		r= _nuevo_rival(sig)
		_texto("¡%s fue arrastrado al combate!" % _cap(r.nombre_visible()))
		_ev_sale("rival", sig)
		_anunciar_trinkets(sig)
		_entrar_trampas(r)
	else:
		j= Luchador.new(sig)
		if not participantes.has(sig):
			participantes.append(sig)
		_texto("¡%s fue arrastrado al combate!" % sig.nombre())
		_ev_sale("jugador", sig)
		_entrar_trampas(j)

func _cambiar_etapa(l: Luchador, stat: String, cambio: int, anunciar_tope: bool) -> bool:
	if not l.etapas.has(stat) or cambio== 0:
		return false
	var real:= l.cambiar_etapa(stat, cambio)
	var nombre_s: String= NOMBRE_STAT.get(stat, stat)
	if real== 0:
		if anunciar_tope:
			_texto("¡%s %s no puede %s más!" % [_cap(nombre_s), _de(l), "subir" if cambio> 0 else "bajar"])
		return false
	var verbo: String
	if real>= 2:
		verbo= "subió mucho"
	elif real== 1:
		verbo ="subió"
	elif real== -1:
		verbo= "bajó"
	else:
		verbo= "bajó mucho"
	_ev({"tipo": "etapa", "lado": _lado(l), "stat": stat, "cambio": real})
	_texto("¡%s %s %s!" % [_cap(nombre_s), _de(l), verbo])
	return true

func _aplicar_estado(l: Luchador, est: String, anunciar_fallo: bool) -> bool:
	var p:= l.pokemon
	if p.esta_debilitado():
		return false
	if p.estado!= "":
		if anunciar_fallo:
			_texto("¡Pero falló!")
		return false
	for t in INMUNES.get(est, []):
		if t in l.tipos():
			if anunciar_fallo:
				_texto("No afecta %s..." % _a(l))
			return false
	_poner_estado(l, est)
	if est== "dor":
		l.turnos_sueno =rng.randi_range(2, 4)
	_texto(TEXTO_ESTADO[est] % _cap(nombre_de(l)))
	return true

func _poner_estado(l: Luchador, est: String) -> void:
	l.pokemon.estado= est
	_ev({"tipo": "estado", "lado": _lado(l), "estado": est})

func _fin_de_turno() -> void:
	for l in [j, r]:
		if l.cargado> 0:
			l.cargado-= 1
	if espacio_raro> 0:
		espacio_raro -=1
		if espacio_raro== 0:
			_texto("¡Las dimensiones retorcidas volvieron a la normalidad!")
	for l in [j, r]:
		var p: PokemonInstancia= l.pokemon
		if p.esta_debilitado() or not p.estado in ["que", "env"]:
			continue
		_herir(l, maxi(1, floori(p.ps_max()/ 8.0)), "estado_"+ p.estado)
		if p.estado== "que":
			_texto("¡%s se resiente de la quemadura!" % _cap(nombre_de(l)))
		else:
			_texto("¡El veneno resta PS %s!" % _a(l))
		_revisar_baya(l)

func _revisar_baya(l: Luchador) -> void:
	var p:= l.pokemon
	if p.objeto== "" or p.esta_debilitado() or p.ps_actuales* 2> p.ps_max():
		return
	var o:= BaseDatos.objeto(p.objeto)
	if o== null or o.categoria!= "BAYAS" or o.cura_ps<= 0:
		return
	var antes:= p.ps_actuales
	p.curar_ps(o.cura_ps)
	p.objeto =""
	_ev({"tipo": "sonido", "nombre": "objeto_activo"})
	_ev_ps(l, antes)
	_texto("¡%s recuperó PS con su %s!" % [_cap(nombre_de(l)), o.nombre])

func _revisar_debilitados() -> bool:
	var algo:= false
	if r.pokemon.esta_debilitado() and not terminado:
		algo= true
		_ev({"tipo": "debilitado", "lado": "rival"})
		_texto("¡%s se debilitó!" % _cap(nombre_de(r)))
		_dar_experiencia()
		var sig:= _siguiente_util(equipo_r)
		if sig== null:
			if not salvaje:
				_texto("¡Has derrotado a %s!" % nombre_entrenador)
				if pago_base> 0:
					dinero_ganado= roundi(pago_base* r.pokemon.nivel* (1.0+ EfectosTrinket.total("dinero", null, equipo_j)))
					_texto("¡Ganaste %d$ por tu victoria!" % dinero_ganado)
			_terminar("victoria")
		else:
			r= _nuevo_rival(sig)
			participantes.clear()
			if not j.pokemon.esta_debilitado():
				participantes.append(j.pokemon)
			_texto("¡%s envió a %s!" % [nombre_entrenador, r.nombre_visible()])
			_ev_sale("rival", sig)
			_anunciar_trinkets(sig)
			if _entrar_trampas(r):
				return _revisar_debilitados() or true
	if j.pokemon.esta_debilitado() and not j_anunciado:
		algo =true
		j_anunciado= true
		_ev({"tipo": "debilitado", "lado": "jugador"})
		_texto("¡%s se debilitó!" % j.pokemon.nombre())
		participantes.erase(j.pokemon)
		if terminado:
			return algo
		if _siguiente_util(equipo_j)== null:
			_texto("¡No te quedan Pokémon que puedan luchar!")
			_terminar("derrota")
		else:
			esperando_reemplazo= true
			_ev({"tipo": "elegir_reemplazo"})
	return algo

func _terminar(res: String) -> void:
	terminado= true
	resultado =res
	_ev({"tipo": "fin", "resultado": res})

func exp_ganada(p: PokemonInstancia, derrotado: PokemonInstancia, cantidad_participantes: int) -> int:
	var a:= 1.0 if salvaje else 1.5
	var nv:= derrotado.nivel
	var base:= a* derrotado.especie.exp_base* nv/ (5.0* cantidad_participantes)
	var total:= floori(base* pow(2.0* nv+ 10.0, 2.5)/ pow(nv+ p.nivel+ 10.0, 2.5))+ 1
	return floori(total* (1.0+ EfectosTrinket.total("exp", p)))

func _dar_experiencia() -> void:
	if sin_exp:
		return
	var vivos: Array[PokemonInstancia]= []
	for p in participantes:
		if not p.esta_debilitado() and not vivos.has(p):
			vivos.append(p)
	for p in vivos:
		_dar_evs(p, r.pokemon.especie.evs_otorgados)
		if p.nivel>= PokemonInstancia.NIVEL_MAX:
			continue
		var cant:= exp_ganada(p, r.pokemon, vivos.size())
		var exp_antes:= p.experiencia
		var nivel_antes :=p.nivel
		_texto("¡%s ganó %d puntos de experiencia!" % [p.nombre(), cant])
		var res:= p.ganar_experiencia(cant)
		_ev({"tipo": "exp", "pokemon": p, "desde": exp_antes, "nivel_desde": nivel_antes, "hasta": p.experiencia, "nivel_hasta": p.nivel})
		for e in res:
			match e["tipo"]:
				"nivel":
					_ev({"tipo": "nivel", "pokemon": p, "nivel": e["nivel"], "ps": e["ps"], "max": e["ps_max"]})
					_texto("¡%s subió al nivel %d!" % [p.nombre(), e["nivel"]])
				"aprendio":
					_ev({"tipo": "jingle", "nombre": "aprender"})
					_texto("¡%s aprendió %s!" % [p.nombre(), e["movimiento"].nombre])
				"quiere_aprender":
					_ev({"tipo": "quiere_aprender", "pokemon": p, "movimiento": e["movimiento"]})

func _dar_evs(p: PokemonInstancia, evs: Dictionary) -> void:
	var total:= 0
	for s in p.evs:
		total+= int(p.evs[s])
	for s in evs:
		var suma:= mini(int(evs[s]), 510- total)
		suma= mini(suma, 255 -int(p.evs.get(s, 0)))
		if suma> 0:
			p.evs[s]= int(p.evs.get(s, 0))+ suma
			total+= suma

func _huir() -> bool:
	intentos_huida+= 1
	var va:= j.stat_efectivo("velocidad")
	var vb:= r.stat_efectivo("velocidad")
	if va>= vb or floori(va* 128.0/ vb)+ 30* intentos_huida> rng.randi_range(0, 255):
		_ev({"tipo": "sonido", "nombre": "huir"})
		_texto("¡Escapaste sin problemas!")
		_terminar("huida")
		return true
	_texto("¡No puedes escapar!")
	return false

func _cambiar(indice: int) -> void:
	_texto("¡%s, vuelve!" % j.pokemon.nombre())
	_ev({"tipo": "retirar", "lado": "jugador", "ball": j.pokemon.ball})
	j= Luchador.new(equipo_j[indice])
	if not participantes.has(j.pokemon):
		participantes.append(j.pokemon)
	_texto("¡Adelante, %s!" % j.pokemon.nombre())
	_ev_sale("jugador", j.pokemon)
	_entrar_trampas(j)

func _usar_objeto(accion: Dictionary) -> bool:
	var o:= BaseDatos.objeto(str(accion.get("id", "")))
	if o== null or inventario== null or inventario.cantidad_de(o.id)<= 0 or o.solo_safari:
		return false
	if o.ratio_captura> 0.0:
		if not salvaje:
			return false
		inventario.consumir(o.id)
		_texto("¡Lanzaste una %s!" % o.nombre)
		var res:= capturar(o.ratio_captura)
		_ev({"tipo": "captura", "objeto": o.id, "sacudidas": res["sacudidas"], "exito": res["exito"], "critica": res["critica"]})
		if res["exito"]:
			_capturado(o.id)
		else:
			_texto(TEXTO_SACUDIDAS[res["sacudidas"]])
		return true
	if o.revivir> 0.0:
		var muerto:= equipo_j[int(accion.get("objetivo", 0))]
		if not muerto.esta_debilitado():
			return false
		inventario.consumir(o.id)
		muerto.ps_actuales= maxi(1, floori(muerto.ps_max()* o.revivir))
		muerto.estado =""
		_texto("¡Usaste %s!" % o.nombre)
		_texto("¡%s se reanimó!" % muerto.nombre())
		return true
	if o.cura_estado!= "":
		var c:= equipo_j[int(accion.get("objetivo", 0))]
		if c.esta_debilitado() or c.estado== "" or (o.cura_estado!= "todos" and c.estado!= o.cura_estado):
			return false
		inventario.consumir(o.id)
		_texto("¡Usaste %s!" % o.nombre)
		if c== j.pokemon:
			_poner_estado(j, "")
			if o.cura_estado== "todos":
				j.confusion= 0
		else:
			c.estado= ""
		_ev({"tipo": "sonido", "nombre": "curar_estado"})
		_texto("¡%s se recuperó!" % c.nombre())
		return true
	if o.cura_ps> 0:
		var p:= equipo_j[int(accion.get("objetivo", 0))]
		if p.esta_debilitado() or p.ps_actuales>= p.ps_max():
			return false
		inventario.consumir(o.id)
		var antes:= p.ps_actuales
		var cura:= p.curar_ps(o.cura_ps)
		_texto("¡Usaste %s!" % o.nombre)
		if p== j.pokemon:
			_ev_ps(j, antes)
		_texto("¡%s recuperó %d PS!" % [p.nombre(), cura])
		return true
	return false

func _capturado(ball_id: String) -> void:
	r.pokemon.ball= ball_id
	_texto("¡Ya está! ¡%s atrapado!" % r.pokemon.nombre())
	if equipo!= null and equipo.agregar(r.pokemon):
		_texto("¡%s se unió a tu equipo!" % r.pokemon.nombre())
	elif equipo!= null and equipo.has_method("a_caja"):
		equipo.a_caja(r.pokemon)
		_texto("Tu equipo está lleno, así que %s fue enviado a la Caja del PC." % r.pokemon.nombre())
	else:
		_texto("Tu equipo está lleno, así que %s volvió a la naturaleza." % r.pokemon.nombre())
	_terminar("captura")

func capturar(ball: float, humor :=1.0) -> Dictionary:
	var p:= r.pokemon
	var m:= p.ps_max()
	var estado:= 1.0
	if p.estado in ["dor", "con"]:
		estado= 2.5
	elif p.estado!= "":
		estado =1.5
	var b:= ball* humor* (1.0+ EfectosTrinket.total("captura", null, equipo_j))
	var x:= _abajo(_cerca(_abajo(_cerca(_cerca(3.0* m- 2.0* p.ps_actuales)* p.especie.ratio_captura* b)/ (3.0* m))* estado))
	if x>= 255.0:
		return {"sacudidas": 3, "exito": true, "critica": false}
	x= maxf(x, 1.0/ 4096.0)
	var pc:= 0.0
	for fila in [[600, 2.5], [450, 2.0], [300, 1.5], [150, 1.0], [30, 0.5]]:
		if capturados_dex> fila[0]:
			pc= fila[1]
			break
	var critica:= rng.randi_range(0, 255)< floori(minf(255.0, x)* pc/ 6.0)
	var y:= floori(65536.0/ sqrt(sqrt(255.0/ x)))
	var chequeos:= 1 if critica else 3
	var ok:= 0
	while ok< chequeos and rng.randi_range(0, 65535)< y:
		ok+= 1
	if ok== chequeos:
		return {"sacudidas": 1 if critica else 3, "exito": true, "critica": critica}
	var mostradas:int= 1 if critica else [0, 1, 3][ok]
	return {"sacudidas": mostradas, "exito": false, "critica": critica}

static func _abajo(v: float) -> float:
	return floorf(v* 4096.0)/ 4096.0

static func _cerca(v: float) -> float:
	return floorf(v* 4096.0+ 0.5)/ 4096.0

func _ia_reglas(reglas: Array[String]) -> int:
	for regla in reglas:
		var partes:= regla.split(":")
		var i:= -1
		match partes[0]:
			"espacio_raro":
				if espacio_raro== 0:
					i= _indice_mov(r, "trick_room")
			"carga":
				if r.cargado== 0 and r.pokemon.ps_actuales* 2> r.pokemon.ps_max():
					i= _indice_mov(r, "charge")
			"empapar":
				if j.tipos()!= ["agua"]:
					i= _indice_mov(r, "soak")
			"confundir":
				var mov_c: String= partes[1] if partes.size()> 1 else "confuse_ray"
				if j.confusion== 0 and (mov_c!= "swagger" or int(j.etapas.get("ataque", 0))< 2):
					i= _indice_mov(r, mov_c)
			"estado":
				if j.pokemon.estado== "" and partes.size()> 1:
					i= _indice_mov(r, partes[1])
			"subir":
				if partes.size()> 3 and int(r.etapas.get(partes[2], 0))< int(partes[3]):
					i= _indice_mov(r, partes[1])
			"puas":
				if int(trampas["jugador"]["puas"])< (int(partes[1]) if partes.size()> 1 else 3) and _quedan_j()>= 2:
					i= _indice_mov(r, "spikes")
			"rocas":
				if not trampas["jugador"]["rocas"] and _quedan_j()>= 2:
					i= _indice_mov(r, "stealth_rock")
			"silbato":
				var hay: bool= int(trampas["jugador"]["puas"])> 0 or bool(trampas["jugador"]["rocas"])
				if hay and _quedan_j()>= 2 and (_subidas(j)>= 1 or rng.randf()< 0.4):
					i= _indice_mov(r, "roar")
					if i< 0:
						i= _indice_mov(r, "whirlwind")
			"represalia":
				if represalia_lista(r):
					i= _indice_mov(r, "retaliate")
			"desquite":
				if r.pokemon.ps_actuales* 2> r.pokemon.ps_max():
					i =_indice_mov(r, "revenge")
			"vendetta":
				if r.stat_efectivo("velocidad")< j.stat_efectivo("velocidad"):
					i= _indice_mov(r, "payback")
			"relevo":
				if _subidas(r)>= 2:
					for o in equipo_r:
						if o!= r.pokemon and not o.esta_debilitado():
							i= _indice_mov(r, "baton_pass")
							break
			"danio":
				i= _mejor_danio()
		if i>= 0 and r.pokemon.pp[i]> 0:
			return i
	return _mejor_danio()

func represalia_lista(l: Luchador) -> bool:
	return int(ultimo_caido[_lado(l)])== turnos- 1

func _quedan_j() -> int:
	var n:= 0
	for o in equipo_j:
		if not o.esta_debilitado():
			n+= 1
	return n

func _indice_mov(l: Luchador, id: String) -> int:
	for k in l.pokemon.movimientos.size():
		if l.pokemon.movimientos[k].id== id:
			return k
	return -1

func estimar_danio(a: Luchador, d: Luchador, mov: Movimiento) -> float:
	if mov.categoria== "estado":
		return 0.0
	var ef:= Tipos.efectividad(mov.tipo, d.tipos())
	if ef== 0.0:
		return 0.0
	var fisico:= mov.categoria== "fisico"
	var fuente: Luchador= d if mov.id== "foul_play" else a
	var ataque:= fuente.stat_efectivo("ataque" if fisico else "at_esp")
	var defensa:= d.stat_efectivo("defensa" if fisico else "def_esp")
	var poder:= mov.poder if mov.id== "magnitude" else poder_de(a, d, mov)
	var base:= (2.0* a.pokemon.nivel/ 5.0+ 2.0)* poder* ataque/ maxf(1.0, defensa)/ 50.0+ 2.0
	if mov.tipo in a.tipos():
		base*= 1.5+ EfectosTrinket.total("stab", a.pokemon)
	var prec:= 1.0 if mov.precision<= 0 else mov.precision/ 100.0
	return base* ef* prec* 0.925

func _mejor_danio() -> int:
	var mejor:= -1
	var valor:= -1.0
	for k in r.pokemon.movimientos.size():
		if r.pokemon.pp[k]<= 0:
			continue
		var v:= estimar_danio(r, j, r.pokemon.movimientos[k])
		if v> valor:
			valor= v
			mejor =k
	if valor<= 0.0:
		var opciones:= []
		for k in r.pokemon.movimientos.size():
			if r.pokemon.pp[k]> 0:
				opciones.append(k)
		return -1 if opciones.is_empty() else opciones[rng.randi_range(0, opciones.size()- 1)]
	return mejor
