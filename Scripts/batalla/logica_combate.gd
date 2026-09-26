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
const TEXTO_SACUDIDAS:= [
	"¡Oh, no! ¡El Pokémon se ha escapado!",
	"¡Vaya! ¡Parecía que lo había atrapado!",
	"¡Qué pena! ¡Casi lo consigues!",
	"¡Rayos! ¡Parecía que lo tenía!",
]
const OBJETIVO_PROPIO :=["user", "users-field", "user-and-allies", "ally", "user-or-ally"]

var equipo_j: Array[PokemonInstancia]= []
var equipo_r: Array[PokemonInstancia] =[]
var salvaje:= true
var nombre_entrenador :=""
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
	r= Luchador.new(_siguiente_util(equipo_r))
	j =Luchador.new(_siguiente_util(equipo_j))
	participantes= [j.pokemon]
	if salvaje:
		_ev_sale("rival", r.pokemon)
		_texto("¡Un %s salvaje apareció!" % r.pokemon.nombre())
	else:
		_texto("¡%s quiere luchar!" % nombre_entrenador)
		_texto("¡%s envió a %s!" % [nombre_entrenador, r.pokemon.nombre()])
		_ev_sale("rival", r.pokemon)
	_texto("¡Adelante, %s!" % j.pokemon.nombre())
	_ev_sale("jugador", j.pokemon)
	return _tomar()

func turno(accion: Dictionary) -> Array[Dictionary]:
	if terminado or esperando_reemplazo:
		return _tomar()
	j.retrocede= false
	r.retrocede =false
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
	var ir:= _ia()
	var orden: Array= []
	if tipo== "movimiento":
		var ij:= int(accion.get("indice", -1))
		if _primero_j(ij, ir):
			orden= [[j, ij], [r, ir]]
		else:
			orden =[[r, ir], [j, ij]]
	else:
		orden= [[r, ir]]
	for par in orden:
		var atacante: Luchador= par[0]
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
		return l.pokemon.nombre()
	return ("el %s salvaje" if salvaje else "el %s enemigo") % l.pokemon.nombre()

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
	_ev({"tipo": "sale", "lado": lado, "pokemon": p, "ps": p.ps_actuales, "max": p.ps_max(), "nivel": p.nivel, "estado": p.estado, "exp": p.experiencia, "ball": p.ball})

func _ev_ps(l: Luchador, desde: int, sonido: String= "") -> void:
	_ev({"tipo": "ps", "lado": _lado(l), "desde": desde, "hasta": l.pokemon.ps_actuales, "max": l.pokemon.ps_max(), "sonido": sonido})

func _herir(l: Luchador, cantidad: int, sonido: String ="golpe_normal") -> int:
	var antes:= l.pokemon.ps_actuales
	var real:= l.pokemon.recibir_danio(cantidad)
	_ev_ps(l, antes, sonido)
	return real

func _ia() -> int:
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
		return vj >vr
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
	var mov:= movimiento_de(a, indice)
	if indice>= 0:
		p.pp[indice]= maxi(0, p.pp[indice]- 1)
	else:
		_texto("¡%s no le quedan movimientos!" % _cap(_a(a)))
	_texto("¡%s usó %s!" % [nombre, mov.nombre])
	if not mov.objetivo in OBJETIVO_PROPIO and mov.precision> 0:
		var etapa:= clampi(a.etapas["precision"]- d.etapas["evasion"], -6, 6)
		if rng.randf()* 100.0>= mov.precision* Luchador.factor("precision", etapa):
			_texto("¡Pero falló!")
			return
	if mov.categoria== "estado":
		_efecto_estado(a, d, mov)
		return
	if mov.id== "bide":
		_texto("¡Pero falló!")
		return
	var ef:= Tipos.efectividad(mov.tipo, d.pokemon.especie.tipos)
	if ef== 0.0:
		_texto("No afecta %s..." % _a(d))
		return
	var golpe:= calcular_danio(a, d, mov, ef)
	var real:= _herir(d, golpe["danio"], "golpe_eficaz" if ef> 1.0 else ("golpe_poco" if ef< 1.0 else "golpe_normal"))
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
	if mov.prob_retroceso> 0 and rng.randi_range(1, 100) <=mov.prob_retroceso:
		d.retrocede= true

func calcular_danio(a: Luchador, d: Luchador, mov: Movimiento, ef: float) -> Dictionary:
	if mov.id== "super_fang":
		return {"danio": maxi(1, floori(d.pokemon.ps_actuales/ 2.0)), "critico": false}
	var fisico:= mov.categoria== "fisico"
	var s_at:= "ataque" if fisico else "at_esp"
	var s_df :="defensa" if fisico else "def_esp"
	var tabla:= [16, 8, 4, 3, 2]
	var critico:= rng.randi_range(1, tabla[clampi(a.critico_extra+ mov.critico, 0, 4)])== 1
	var ataque: int
	var defensa: int
	if critico:
		ataque= a.stat_con_etapa(s_at, maxi(a.etapas[s_at], 0))
		defensa =d.stat_con_etapa(s_df, mini(d.etapas[s_df], 0))
	else:
		ataque= a.stat_con_etapa(s_at, a.etapas[s_at])
		defensa= d.stat_con_etapa(s_df, d.etapas[s_df])
	var nivel:= a.pokemon.nivel
	var base:= floori(floori(floori(2.0* nivel/ 5.0+ 2.0)* poder_de(a, d, mov)* ataque/ float(defensa))/ 50.0) +2
	if critico:
		base*= 2
	base= floori(base* rng.randi_range(85, 100)/ 100.0)
	if mov.tipo in a.pokemon.especie.tipos:
		base =floori(base* 1.5)
	base= floori(base *ef)
	if fisico and a.pokemon.estado== "que":
		base= floori(base* 0.5)
	return {"danio": maxi(1, base), "critico": critico}

func poder_de(a: Luchador, d: Luchador, mov: Movimiento) -> int:
	match mov.id:
		"reversal":
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
			return maxi(1, floori(120.0* d.pokemon.ps_actuales/ d.pokemon.ps_max()))
		"heat_crash":
			return 60
	return maxi(1, mov.poder)

func _efecto_estado(a: Luchador, d: Luchador, mov: Movimiento) -> void:
	var hizo:= false
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
	if mov.id== "focus_energy":
		a.critico_extra= 2
		_texto("¡%s se está preparando para luchar!" % _cap(nombre_de(a)))
		hizo =true
	if not hizo:
		_texto("¡Pero no pasó nada!")

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
		if t in p.especie.tipos:
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
			_terminar("victoria")
		else:
			r= Luchador.new(sig)
			participantes.clear()
			if not j.pokemon.esta_debilitado():
				participantes.append(j.pokemon)
			_texto("¡%s envió a %s!" % [nombre_entrenador, sig.nombre()])
			_ev_sale("rival", sig)
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
	return floori(base* pow(2.0* nv+ 10.0, 2.5)/ pow(nv+ p.nivel+ 10.0, 2.5))+ 1

func _dar_experiencia() -> void:
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

func _usar_objeto(accion: Dictionary) -> bool:
	var o:= BaseDatos.objeto(str(accion.get("id", "")))
	if o== null or inventario== null or inventario.cantidad_de(o.id)<= 0:
		return false
	if o.ratio_captura> 0.0:
		if not salvaje:
			return false
		inventario.consumir(o.id)
		_texto("¡Lanzaste una %s!" % o.nombre)
		var res:= capturar(o.ratio_captura)
		_ev({"tipo": "captura", "objeto": o.id, "sacudidas": res["sacudidas"], "exito": res["exito"]})
		if res["exito"]:
			r.pokemon.ball= o.id
			_texto("¡Ya está! ¡%s atrapado!" % r.pokemon.nombre())
			if equipo!= null and equipo.agregar(r.pokemon):
				_texto("¡%s se unió a tu equipo!" % r.pokemon.nombre())
			else:
				_texto("Tu equipo está lleno, así que %s volvió a la naturaleza." % r.pokemon.nombre())
			_terminar("captura")
		else:
			_texto(TEXTO_SACUDIDAS[res["sacudidas"]])
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

func capturar(ball: float) -> Dictionary:
	var p:= r.pokemon
	var m:= p.ps_max()
	var bonus:= 1.0
	if p.estado in ["dor", "con"]:
		bonus= 2.5
	elif p.estado!= "":
		bonus =1.5
	var x:= floori((3.0* m- 2.0* p.ps_actuales)* p.especie.ratio_captura* ball/ (3.0* m)* bonus)
	if x>= 255:
		return {"sacudidas": 3, "exito": true}
	x= maxi(x, 1)
	var y:= floori(65536.0/ pow(255.0/ x, 0.1875))
	var s:= 0
	while s< 3 and rng.randi_range(0, 65535)< y:
		s+= 1
	return {"sacudidas": s, "exito": s== 3}
