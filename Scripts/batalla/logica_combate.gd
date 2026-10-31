class_name LogicaCombate
extends RefCounted

const ESTADOS:= {"burn": "que", "poison": "env", "paralysis": "par", "sleep": "dor", "freeze": "con"}
const TEXTO_ESTADO :={
	"que": "¡%s se quemó!",
	"env": "¡%s fue envenenado!",
	"tox": "¡%s fue gravemente envenenado!",
	"par": "¡%s está paralizado! ¡Quizás no pueda moverse!",
	"dor": "¡%s se durmió!",
	"con": "¡%s se congeló!",
}
const INMUNES:= {"que": ["fuego"], "env": ["veneno", "acero"], "tox": ["veneno", "acero"], "con": ["hielo"]}
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
const OBJETIVO_PROPIO :=["user", "users-field", "user-and-allies", "ally", "user-or-ally", "entire-field", "opponents-field", "all-allies"]
const NOMBRE_CLIMA:= {"lluvia": "Lluvia", "sol": "Sol", "arena": "Tormenta de arena", "granizo": "Granizo"}

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
var trampas:= {"jugador": lado_nuevo(), "rival": lado_nuevo()}
var ultimo_caido :={"jugador": -1, "rival": -1}
var clima:= ""
var turnos_clima :=0
var gravedad:= 0
var zona_magica :=0
var zona_extrana:= 0
var futuros: Array[Dictionary]= []
var ultimo_mov_combate: Movimiento
var elegido :={"jugador": null, "rival": null}
var cola: Array= []
var relevo_pendiente:= ""
var terreno :="campo"
var sin_habilidades:= false
var forzar_acierto :=false
var sin_criticos:= false
var forzar_secundarios :=false
var objetos_perdidos: Dictionary= {}
var temporales :Dictionary= {}
var eco:= {}
const PUAS:= [0.0, 1.0/ 8.0, 1.0/ 6.0, 1.0/ 4.0]
const ILUSION:= ["zorua", "zoroark"]
const CURAS_RIVAL :={"hyper_potion": 0.0, "super_potion": 0.0, "potion": 0.0}

static func lado_nuevo() -> Dictionary:
	return {"puas": 0, "rocas": false, "puas_toxicas": 0, "reflejo": 0, "pantalla_luz": 0, "velo_sagrado": 0, "neblina": 0, "viento_afin": 0, "conjuro": 0, "deseo": 0, "deseo_ps": 0, "deseo_cura": "", "chapoteo": false, "hidrochorro": false}

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
	forcejeo.banderas= PackedStringArray(["contact", "protect"])

func iniciar() -> Array[Dictionary]:
	r= _nuevo_rival(_siguiente_util(equipo_r))
	j =_nuevo_luchador(_siguiente_util(equipo_j))
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
	for l in _por_velocidad([j, r]):
		_al_entrar(l)
	_revisar_debilitados(true)
	return _tomar()

func _nuevo_luchador(p: PokemonInstancia) -> Luchador:
	var l:= Luchador.new(p)
	if sin_habilidades:
		l.habilidad= ""
	return l

func activa(l: Luchador, id: String) -> bool:
	return l!= null and l.habilidad== id and not sin_habilidades and not l.tiene("gastro")

func rompe_moldes(a: Luchador) -> bool:
	return activa(a, "mold_breaker") or activa(a, "turboblaze") or activa(a, "teravolt")

func habilidad_def(a: Luchador, d: Luchador, id: String) -> bool:
	return activa(d, id) and not (a!= d and rompe_moldes(a) and HabCombate.ROMPIBLES.has(id))

func _al_entrar(l: Luchador) -> void:
	if l.pokemon== null or l.pokemon.esta_debilitado():
		return
	var t: Dictionary= trampas[_lado(l)]
	if t["deseo_cura"]!= "":
		var tipo: String= t["deseo_cura"]
		t["deseo_cura"]= ""
		var antes:= l.pokemon.ps_actuales
		l.pokemon.ps_actuales= l.pokemon.ps_max()
		_poner_estado(l, "")
		if tipo== "lunar":
			for k in l.pokemon.pp.size():
				l.pokemon.pp[k]= l.pokemon.movimientos[k].pp
		_ev_ps(l, antes)
		_texto("¡%s recibió el deseo de sanación!" % _cap(nombre_de(l)))
	if _entrar_trampas(l):
		return
	HabCombate.al_entrar(self, l)

func turno(accion: Dictionary) -> Array[Dictionary]:
	if terminado or esperando_reemplazo or relevo_pendiente!= "":
		return _tomar()
	var tipo: String= accion.get("tipo", "movimiento")
	if tipo== "cambio" and not _puede_cambiar(j):
		_texto("¡%s no puede cambiarse!" % j.pokemon.nombre())
		return _tomar()
	turnos+= 1
	for l in [j, r]:
		l.retrocede= false
		l.actuo_turno= false
		l.herido_turno =false
		l.protegido= false
		l.danio_recibido= {}
		for k in ["aguante", "concentrado", "rebote", "robo", "me_first", "guardia_rapida", "guardia_amplia", "perdio_concentracion", "respiro"]:
			l.quitar(k)
	elegido= {"jugador": null, "rival": null}
	cola.clear()
	if tipo== "huir":
		if not salvaje:
			_texto("¡No puedes huir de un combate contra un Entrenador!")
			return _tomar()
		if _huir():
			return _tomar()
	elif tipo =="objeto":
		if not _usar_objeto(accion) or terminado:
			return _tomar()
	var accion_r:= _accion_rival()
	var ir: int= int(accion_r.get("indice", -1))
	var ij:= int(accion.get("indice", -1))
	if tipo== "movimiento":
		ij= _indice_forzado(j, ij)
		elegido["jugador"]= movimiento_de(j, ij)
	if accion_r.get("tipo", "")!= "objeto":
		ir =_indice_forzado(r, ir)
		elegido["rival"]= movimiento_de(r, ir)
	if tipo== "cambio":
		if accion_r.get("tipo", "")!= "objeto" and movimiento_de(r, ir).id== "pursuit" and not r.recarga and r.cargando== null:
			r.poner("persecucion")
			_texto("¡%s ataca mientras %s se retira!" % [_cap(nombre_de(r)), j.pokemon.nombre()])
			_ejecutar(r, j, ir)
			r.quitar("persecucion")
			if _revisar_debilitados(false):
				_cerrar_turno()
				return _tomar()
			_cambiar(int(accion["indice"]))
			_finalizar_cola()
			return _tomar()
		_cambiar(int(accion["indice"]))
	if accion_r.get("tipo", "")== "objeto":
		_usar_objeto_rival(str(accion_r["id"]))
	for l in [j, r]:
		var m: Movimiento= elegido[_lado(l)]
		if m!= null and m.id== "focus_punch" and l.cargando== null and not l.recarga:
			l.poner("concentrado")
			_texto("¡%s se está concentrando!" % _cap(nombre_de(l)))
	if tipo== "movimiento" and accion_r.get("tipo", "")!= "objeto":
		if _primero(j, ij, r, ir):
			cola= [[j, ij], [r, ir]]
		else:
			cola =[[r, ir], [j, ij]]
	elif tipo== "movimiento":
		cola= [[j, ij]]
	elif accion_r.get("tipo", "")!= "objeto":
		cola= [[r, ir]]
	_finalizar_cola()
	return _tomar()

func accion_forzada() -> bool:
	if j== null:
		return false
	return j.recarga or j.cargando!= null or (j.mov_bloqueado!= null and j.turnos_bloqueo> 0) or j.tiene("bide")

func _indice_forzado(l: Luchador, i: int) -> int:
	var movs:= l.movimientos()
	if l.cargando!= null:
		var k:= movs.find(l.cargando)
		return k if k>= 0 else i
	if l.mov_bloqueado!= null and l.turnos_bloqueo> 0:
		var k2:= movs.find(l.mov_bloqueado)
		if k2>= 0:
			return k2
	if l.tiene("bide"):
		var k3:= _indice_mov(l, "bide")
		if k3>= 0:
			return k3
	if l.tiene("otra_vez"):
		var k4:= movs.find(l.valor("otra_vez")["mov"])
		if k4>= 0 and l.pp()[k4]> 0:
			return k4
	if i>= 0 and (i>= movs.size() or l.pp()[i]<= 0):
		return _primer_util(l)
	if i>= 0 and not _usable(l, movs[i]):
		var otro:= _primer_util(l)
		return otro
	return i

func _primer_util(l: Luchador) -> int:
	var movs:= l.movimientos()
	for k in movs.size():
		if l.pp()[k]> 0 and _usable(l, movs[k]):
			return k
	return -1

func _usable(l: Luchador, m: Movimiento) -> bool:
	if l.tiene("anulado") and l.valor("anulado")["mov"]== m:
		return false
	if l.tiene("mofa") and m.categoria== "estado":
		return false
	if l.tiene("tormento") and l.ultimo_mov== m:
		return false
	if l.tiene("anticura") and m.tiene("heal"):
		return false
	if gravedad> 0 and m.tiene("gravity"):
		return false
	var otro:= r if l== j else j
	if otro!= null and otro.tiene("cerrojo"):
		for om in otro.movimientos():
			if om.id== m.id:
				return false
	return true

func movimientos_usables(l: Luchador) -> Array[bool]:
	var lista: Array[bool]= []
	for k in l.movimientos().size():
		lista.append(l.pp()[k]> 0 and _usable(l, l.movimientos()[k]))
	return lista

func _finalizar_cola() -> void:
	while not cola.is_empty():
		if terminado or relevo_pendiente!= "":
			return
		var par: Array= cola.pop_front()
		var atacante: Luchador= par[0]
		if atacante!= j and atacante!= r:
			continue
		var defensor: Luchador= r if atacante== j else j
		if atacante.pokemon.esta_debilitado():
			continue
		_ejecutar(atacante, defensor, par[1])
		_revisar_debilitados(false)
	if relevo_pendiente!= "" or terminado:
		return
	_cerrar_turno()

func _cerrar_turno() -> void:
	if not terminado:
		_fin_de_turno()
		_revisar_debilitados(true)

func reemplazar(indice: int) -> Array[Dictionary]:
	if relevo_pendiente!= "":
		if indice< 0 or indice>= equipo_j.size() or equipo_j[indice].esta_debilitado() or equipo_j[indice]== j.pokemon:
			return _tomar()
		var modo:= relevo_pendiente
		relevo_pendiente= ""
		_meter(j, equipo_j[indice], modo== "relevo")
		_finalizar_cola()
		return _tomar()
	if not esperando_reemplazo or equipo_j[indice].esta_debilitado():
		return _tomar()
	esperando_reemplazo= false
	j_anunciado =false
	j= _nuevo_luchador(equipo_j[indice])
	if not participantes.has(j.pokemon):
		participantes.append(j.pokemon)
	_texto("¡Adelante, %s!" % j.pokemon.nombre())
	_ev_sale("jugador", j.pokemon)
	_al_entrar(j)
	_revisar_debilitados(true)
	return _tomar()

func nombre_de(l: Luchador) -> String:
	if l== j:
		return l.nombre_visible()
	return ("el %s salvaje" if salvaje else "el %s enemigo") % l.nombre_visible()

func movimiento_de(l: Luchador, indice: int) -> Movimiento:
	var movs:= l.movimientos()
	return forcejeo if indice< 0 or indice>= movs.size() else movs[indice]

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

func otro_de(l: Luchador) -> Luchador:
	return r if l== j else j

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
	_ev({"tipo": "sale", "lado": lado, "pokemon": visto, "ps": p.ps_actuales, "max": p.ps_max(), "nivel": p.nivel, "estado": p.estado, "exp": p.experiencia, "ball": p.ball, "habilidad": p.habilidad})

func _nuevo_rival(p: PokemonInstancia) -> Luchador:
	var l:= _nuevo_luchador(p)
	if p!= null and (p.especie.id in ILUSION or activa(l, "illusion")):
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

func anunciar_habilidad(l: Luchador) -> void:
	var h:= BaseDatos.habilidad(l.habilidad)
	_ev({"tipo": "habilidad", "lado": _lado(l), "nombre": l.nombre_visible(), "habilidad": h.nombre if h!= null else l.habilidad})

func _herir(l: Luchador, cantidad: int, sonido: String ="golpe_normal") -> int:
	var antes:= l.pokemon.ps_actuales
	if antes<= 0:
		return 0
	var aguanta:= false
	var aguante_mov:= false
	if cantidad>= antes and antes> 0 and l.tiene("aguante"):
		cantidad= antes- 1
		aguante_mov= true
	elif cantidad>= antes and antes> 1 and not l.aguante_usado and EfectosTrinket.total("aguante", l.pokemon)> 0.0:
		cantidad= antes- 1
		l.aguante_usado =true
		aguanta= true
	var real:= l.pokemon.recibir_danio(cantidad)
	if l.pokemon.esta_debilitado() and antes> 0:
		ultimo_caido[_lado(l)]= turnos
	_ev_ps(l, antes, sonido)
	if aguante_mov:
		_texto("¡%s aguantó el golpe!" % _cap(nombre_de(l)))
	if aguanta:
		var ids:= EfectosTrinket.contar("aguante", l.pokemon).keys()
		_ev({"tipo": "sonido", "nombre": "objeto_activo"})
		_texto("¡%s aguantó el golpe gracias a su %s!" % [_cap(nombre_de(l)), BaseDatos.trinket(ids[0]).nombre])
	if real> 0:
		_revisar_baya(l)
	return real

func _curar(l: Luchador, cantidad: int) -> int:
	if l.pokemon.esta_debilitado() or l.tiene("anticura"):
		return 0
	var antes:= l.pokemon.ps_actuales
	var real:= l.pokemon.curar_ps(maxi(1, cantidad))
	if real> 0:
		_ev_ps(l, antes)
	return real

func _accion_rival() -> Dictionary:
	var p:= r.pokemon
	if not salvaje and not p.esta_debilitado() and p.ps_actuales* 10<= p.ps_max()* 3 and not r.tiene("embargo"):
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
	if r.recarga or r.cargando!= null or (r.mov_bloqueado!= null and r.turnos_bloqueo> 0):
		return 0
	if not r.pokemon.ia.is_empty():
		var elegido_i:= _ia_reglas(r.pokemon.ia)
		if elegido_i>= 0 and _usable(r, r.movimientos()[elegido_i]):
			return elegido_i
	var opciones:= []
	for i in r.movimientos().size():
		if r.pp()[i]> 0 and _usable(r, r.movimientos()[i]):
			opciones.append(i)
	if opciones.is_empty():
		return -1
	if salvaje:
		return opciones[rng.randi_range(0, opciones.size()- 1)]
	return _mejor_danio()

func prioridad_de(l: Luchador, m: Movimiento) -> int:
	var p:= m.prioridad
	if m.categoria== "estado" and activa(l, "prankster"):
		p+= 1
	return p

func velocidad_de(l: Luchador) -> int:
	var v:= l.stat_efectivo("velocidad")
	var mult:= 1.0
	if (clima== "lluvia" and activa(l, "swift_swim")) or (clima== "sol" and activa(l, "chlorophyll")) or (clima== "arena" and activa(l, "sand_rush")):
		mult*= 2.0
	if activa(l, "unburden") and l.tiene("sin_objeto"):
		mult*= 2.0
	if activa(l, "slow_start") and l.turnos_en_campo< 5:
		mult*= 0.5
	if activa(l, "quick_feet") and l.pokemon.estado!= "":
		mult *=1.5
	if int(trampas[_lado(l)]["viento_afin"])> 0:
		mult*= 2.0
	if mult!= 1.0:
		v= maxi(1, floori(v* mult))
	return v

func _por_velocidad(lista: Array) -> Array:
	var copia:= lista.duplicate()
	copia.sort_custom(func(a, b): return velocidad_de(a)> velocidad_de(b) if espacio_raro== 0 else velocidad_de(a)< velocidad_de(b))
	return copia

func _primero(a: Luchador, ia_: int, b: Luchador, ib: int) -> bool:
	var ma:= movimiento_de(a, ia_)
	var mb:= movimiento_de(b, ib)
	var pa:= prioridad_de(a, ma)
	var pb :=prioridad_de(b, mb)
	if pa!= pb:
		return pa> pb
	var ua:= activa(a, "stall")
	var ub:= activa(b, "stall")
	if ua!= ub:
		return ub
	var va:= velocidad_de(a)
	var vb:= velocidad_de(b)
	if va!= vb:
		return va< vb if espacio_raro> 0 else va >vb
	return rng.randi_range(0, 1)== 0

func _primero_j(ij: int, ir: int) -> bool:
	return _primero(j, ij, r, ir)

func _ejecutar(a: Luchador, d: Luchador, indice: int) -> void:
	var p:= a.pokemon
	var nombre:= _cap(nombre_de(a))
	a.actuo_turno= true
	if a.recarga:
		a.recarga= false
		_texto("¡%s necesita recuperarse!" % nombre)
		return
	var mov:= movimiento_de(a, indice)
	if p.estado== "dor":
		a.turnos_sueno-= 2 if activa(a, "early_bird") else 1
		if a.turnos_sueno> 0:
			if not mov.id in ["sleep_talk", "snore"]:
				_texto("%s está dormido como un tronco." % nombre)
				a.cargando= null
				_cortar_bloqueo(a)
				return
		else:
			_poner_estado(a, "")
			_texto("¡%s se despertó!" % nombre)
			a.quitar("pesadilla")
	elif p.estado =="con":
		if mov.tiene("defrost") or rng.randi_range(1, 5)== 1:
			_poner_estado(a, "")
			_texto("¡%s se descongeló!" % nombre)
		else:
			_texto("¡%s está congelado!" % nombre)
			return
	if a.tiene("levantado"):
		_texto("¡%s está en el aire y no puede moverse!" % nombre)
		return
	if activa(a, "truant") and a.tiene("holgazan"):
		a.quitar("holgazan")
		anunciar_habilidad(a)
		_texto("¡%s está holgazaneando!" % nombre)
		return
	if activa(a, "truant"):
		a.poner("holgazan")
	if a.retrocede:
		_texto("¡%s retrocedió!" % nombre)
		if activa(a, "steadfast"):
			anunciar_habilidad(a)
			_cambiar_etapa(a, "velocidad", 1, false)
		_cortar_bloqueo(a)
		return
	if a.tiene("perdio_concentracion") or (mov.id== "focus_punch" and a.herido_turno and a.tiene("concentrado")):
		_texto("¡%s perdió la concentración y no pudo atacar!" % nombre)
		return
	if a.cargando== null:
		if a.tiene("anulado") and a.valor("anulado")["mov"]== mov:
			_texto("¡%s no puede usar %s porque está anulado!" % [nombre, mov.nombre])
			return
		if a.tiene("mofa") and mov.categoria== "estado":
			_texto("¡%s no puede usar %s después de la mofa!" % [nombre, mov.nombre])
			return
		if a.tiene("tormento") and a.ultimo_mov== mov and mov!= forcejeo:
			_texto("¡%s no puede usar el mismo movimiento dos veces seguidas por el tormento!" % nombre)
			return
		if a.tiene("anticura") and mov.tiene("heal"):
			_texto("¡%s no puede usar %s por el Anticura!" % [nombre, mov.nombre])
			return
		if gravedad> 0 and mov.tiene("gravity"):
			_texto("¡%s no puede usar %s por la gravedad!" % [nombre, mov.nombre])
			return
		if d.tiene("cerrojo") and _indice_mov(d, mov.id)>= 0:
			_texto("¡%s no puede usar el movimiento sellado %s!" % [nombre, mov.nombre])
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
				a.cargando= null
				_cortar_bloqueo(a)
				return
	if a.tiene("enamorado") and a.valor("enamorado")== d:
		_texto("¡%s está enamorado de %s!" % [nombre, nombre_de(d)])
		if rng.randi_range(0, 1)== 0:
			_texto("¡El amor impide que %s ataque!" % nombre_de(a))
			_cortar_bloqueo(a)
			return
	if p.estado== "par" and rng.randi_range(1, 4) ==1:
		_texto("¡%s está paralizado! ¡No se puede mover!" % nombre)
		a.cargando= null
		_cortar_bloqueo(a)
		return
	usar_movimiento(a, d, mov, indice, true)

func _cortar_bloqueo(a: Luchador) -> void:
	if a.mov_bloqueado!= null and a.mov_bloqueado.id in ["thrash", "outrage", "petal_dance", "rollout", "ice_ball", "uproar"]:
		a.mov_bloqueado= null
		a.turnos_bloqueo =0
	a.quitar("rodar")

func usar_movimiento(a: Luchador, d: Luchador, mov: Movimiento, indice: int, gastar_pp: bool) -> void:
	if a.cargando!= mov:
		a.quitar("mismo_destino")
		a.quitar("rencor")
	if not mov.id in ["protect", "detect", "endure", "quick_guard", "wide_guard"]:
		a.racha_proteccion= 0
	if mov.id!= "rage":
		a.quitar("furia")
	_usar_cuerpo(a, d, mov, indice, gastar_pp)
	if a.tiene("explota") and not a.pokemon.esta_debilitado():
		a.quitar("explota")
		var antes:= a.pokemon.ps_actuales
		a.pokemon.ps_actuales= 0
		ultimo_caido[_lado(a)]= turnos
		_ev_ps(a, antes)
	var usados: Dictionary= a.valor("usados", {})
	usados[mov.id]= true
	a.poner("usados", usados)

func _usar_cuerpo(a: Luchador, d: Luchador, mov: Movimiento, indice: int, gastar_pp: bool) -> void:
	var nombre:= _cap(nombre_de(a))
	var segunda:= a.cargando== mov
	if indice>= 0 and gastar_pp and not segunda and not (a.mov_bloqueado== mov and a.turnos_bloqueo> 0 and a.valor("bloqueo_iniciado", false)):
		var pps:= a.pp()
		var coste:= 2 if activa(d, "pressure") and mov.objetivo!= "user" else 1
		pps[indice]= maxi(0, pps[indice]- coste)
	elif indice< 0 and gastar_pp:
		_texto("¡%s no le quedan movimientos!" % _cap(_a(a)))
	if not segunda:
		_texto("¡%s usó %s!" % [nombre, mov.nombre])
	a.ultimo_mov= mov
	if mov.id!= "struggle":
		ultimo_mov_combate= mov
	if MovEfectos.antes(self, a, d, mov, segunda):
		return
	var guardia:= (d.tiene("guardia_rapida") and prioridad_de(a, mov)> 0) or (d.tiene("guardia_amplia") and mov.objetivo in ["all-opponents", "all-other-pokemon"])
	if not mov.objetivo in OBJETIVO_PROPIO and (d.protegido or guardia) and mov.tiene("protect"):
		_texto("¡%s se protegió!" % _cap(nombre_de(d)))
		if mov.id in ["jump_kick", "high_jump_kick"]:
			_choque(a, mov)
		_cortar_bloqueo(a)
		return
	if not mov.objetivo in OBJETIVO_PROPIO and mov.categoria== "estado" and mov.tiene("reflectable"):
		if d.tiene("rebote") or (habilidad_def(a, d, "magic_bounce") and a!= d):
			if habilidad_def(a, d, "magic_bounce"):
				anunciar_habilidad(d)
			_texto("¡%s devolvió %s!" % [_cap(nombre_de(d)), mov.nombre])
			if not MovEfectos.antes(self, d, a, mov, false):
				_efecto_estado(d, a, mov)
			return
	if not mov.objetivo in OBJETIVO_PROPIO and not _acierta(a, d, mov):
		if d.invulnerable!= "":
			_texto("¡%s esquivó el ataque!" % _cap(nombre_de(d)))
		else:
			_texto("¡Pero falló!")
		if mov.id in ["jump_kick", "high_jump_kick"]:
			_choque(a, mov)
		_cortar_bloqueo(a)
		a.quitar("corte_furia")
		return
	if mov.categoria== "estado":
		if not mov.objetivo in OBJETIVO_PROPIO and HabCombate.bloquea_estado(self, a, d, mov):
			return
		if not mov.objetivo in OBJETIVO_PROPIO and mov.tiene("powder") and "planta" in d.tipos():
			_texto("No afecta %s..." % _a(d))
			return
		if not mov.objetivo in OBJETIVO_PROPIO and d.sustituto> 0 and a!= d and not mov.objetivo in ["entire-field", "all-pokemon"] and MovEfectos.lo_frena_sustituto(mov):
			_texto("¡Pero falló!")
			return
		if d.tiene("robo") and mov.tiene("snatch"):
			d.quitar("robo")
			_texto("¡%s robó el efecto de %s!" % [_cap(nombre_de(d)), mov.nombre])
			_efecto_estado(d, a, mov)
			return
		_efecto_estado(a, d, mov)
		return
	_golpear(a, d, mov)

func _vinculos(a: Luchador, d: Luchador, mov: Movimiento) -> void:
	if d.tiene("mismo_destino") and not a.pokemon.esta_debilitado():
		_texto("¡%s se llevó a %s con él!" % [_cap(nombre_de(d)), nombre_de(a)])
		var antes:= a.pokemon.ps_actuales
		a.pokemon.ps_actuales= 0
		ultimo_caido[_lado(a)]= turnos
		_ev_ps(a, antes)
	if d.tiene("rencor"):
		var k:= a.movimientos().find(mov)
		if k>= 0:
			a.pp()[k]= 0
			_texto("¡%s perdió todos los PP de %s por el rencor!" % [_cap(nombre_de(a)), mov.nombre])

func _choque(a: Luchador, mov: Movimiento) -> void:
	if activa(a, "magic_guard"):
		return
	_texto("¡%s siguió de largo y se estrelló!" % _cap(nombre_de(a)))
	_herir(a, maxi(1, floori(a.pokemon.ps_max()/ 2.0)))

func tipo_de(a: Luchador, mov: Movimiento) -> String:
	var t:= MovEfectos.tipo(self, a, mov)
	if activa(a, "normalize") and mov!= forcejeo:
		t= "normal"
	return t

func efectividad(a: Luchador, d: Luchador, tipo: String, mov: Movimiento) -> float:
	if tipo== "":
		return 1.0
	var ef:= 1.0
	for t in d.tipos():
		var m:= Tipos.multiplicador(tipo, t)
		if m== 0.0:
			if t== "fantasma" and tipo in ["normal", "lucha"] and (activa(a, "scrappy") or d.tiene("identificado")):
				m= 1.0
			elif t== "siniestro" and tipo== "psiquico" and d.tiene("ojo_milagro"):
				m =1.0
			elif t== "volador" and tipo== "tierra" and _en_tierra(d, a):
				m= 1.0
		ef*= m
	if tipo== "tierra" and not _en_tierra(d, a) and not ("volador" in d.tipos() and ef== 0.0):
		if mov== null or mov.id!= "thousand_arrows":
			return 0.0
	return ef

func _en_tierra(l: Luchador, atacante: Luchador= null) -> bool:
	if gravedad> 0 or l.tiene("arraigo") or l.tiene("derribado"):
		return true
	if "volador" in l.tipos():
		return false
	var levita:= habilidad_def(atacante, l, "levitate") if atacante!= null else activa(l, "levitate")
	if levita or l.tiene("levitar") or l.tiene("telequinesis"):
		return false
	return true

func _acierta(a: Luchador, d: Luchador, mov: Movimiento) -> bool:
	if d.invulnerable!= "" and not MovEfectos.alcanza_invulnerable(mov, d.invulnerable) and not activa(a, "no_guard") and not activa(d, "no_guard"):
		return false
	if forzar_acierto and mov.meta!= "ohko":
		return true
	if activa(a, "no_guard") or activa(d, "no_guard"):
		return true
	if a.tiene("fijado"):
		a.quitar("fijado")
		return true
	if mov.meta== "ohko":
		if activa(d, "sturdy") and not rompe_moldes(a):
			return false
		if d.pokemon.nivel> a.pokemon.nivel:
			return false
		return rng.randi_range(1, 100)<= a.pokemon.nivel- d.pokemon.nivel+ 30
	var prec:= mov.precision
	if mov.id in ["thunder", "hurricane"]:
		if clima== "lluvia":
			return true
		if clima== "sol":
			prec= 50
	if mov.id== "blizzard" and clima== "granizo":
		return true
	if prec<= 0:
		return true
	var et_a: int= a.etapas["precision"]
	var et_d :int= d.etapas["evasion"]
	if habilidad_def(a, d, "unaware"):
		et_a= 0
	if activa(a, "unaware") or activa(a, "keen_eye") or d.tiene("identificado") or d.tiene("ojo_milagro") or mov.id in ["chip_away", "sacred_sword"]:
		et_d= mini(et_d, 0) if activa(a, "keen_eye") or d.tiene("identificado") or d.tiene("ojo_milagro") else 0
	var etapa:= clampi(et_a- et_d, -6, 6)
	var f:= Luchador.fraccion("precision", etapa)
	var p:= float(prec)* f.x/ f.y
	p*= HabCombate.mult_precision(self, a, d, mov)
	if gravedad> 0:
		p*= 5.0/ 3.0
	return rng.randf()* 100.0< p

func _golpear(a: Luchador, d: Luchador, mov: Movimiento) -> void:
	var nombre:= _cap(nombre_de(a))
	var tipo:= tipo_de(a, mov)
	var ef:= efectividad(a, d, tipo, mov)
	if HabCombate.absorbe(self, a, d, mov, tipo):
		_cortar_bloqueo(a)
		return
	if ef== 0.0 and tipo!= "":
		_texto("No afecta %s..." % _a(d))
		_cortar_bloqueo(a)
		if mov.id in ["jump_kick", "high_jump_kick"]:
			_choque(a, mov)
		return
	if mov.tiene("powder") and "planta" in d.tipos():
		_texto("No afecta %s..." % _a(d))
		return
	if habilidad_def(a, d, "wonder_guard") and ef<= 1.0 and mov.id!= "struggle" and MovEfectos.danio_fijo(self, a, d, mov)< 0:
		anunciar_habilidad(d)
		_texto("¡No afecta %s!" % _a(d))
		return
	if habilidad_def(a, d, "soundproof") and mov.tiene("sound"):
		anunciar_habilidad(d)
		_texto("No afecta %s..." % _a(d))
		return
	var golpes:= MovEfectos.golpes(self, a, mov)
	var dados:= 0
	var total:= 0
	var hubo_critico:= false
	var rompio_sub:= false
	for k in golpes:
		if d.pokemon.esta_debilitado() or a.pokemon.esta_debilitado():
			break
		if k> 0 and mov.id== "triple_kick" and not _acierta(a, d, mov):
			break
		a.poner("golpe_n", k)
		var fijo:= MovEfectos.danio_fijo(self, a, d, mov)
		var golpe: Dictionary
		if fijo>= 0:
			golpe= {"danio": fijo, "critico": false}
		else:
			golpe =calcular_danio(a, d, mov, ef)
		var cant: int= golpe["danio"]
		if d.sustituto> 0 and not MovEfectos.atraviesa_sustituto(mov) and not activa(a, "infiltrator") and a!= d:
			var al_sub:= mini(cant, d.sustituto)
			d.sustituto-= al_sub
			total+= al_sub
			_texto("¡El sustituto recibió el daño en lugar %s!" % _de(d))
			if d.sustituto<= 0:
				d.sustituto =0
				_ev({"tipo": "sustituto", "lado": _lado(d), "activo": false})
				_texto("¡El sustituto %s se rompió!" % _de(d))
				rompio_sub= true
			dados+= 1
			if golpe["critico"]:
				hubo_critico= true
			continue
		if mov.id== "false_swipe" and cant>= d.pokemon.ps_actuales:
			cant= d.pokemon.ps_actuales- 1
		if cant>= d.pokemon.ps_actuales and d.pokemon.ps_actuales== d.pokemon.ps_max() and habilidad_def(a, d, "sturdy"):
			cant= d.pokemon.ps_actuales- 1
			d.poner("robustez")
		var real:= _herir(d, cant, "golpe_eficaz" if ef> 1.0 else ("golpe_poco" if ef< 1.0 else "golpe_normal"))
		total+= real
		dados+= 1
		if d.tiene("bide"):
			var bd: Dictionary= d.valor("bide")
			bd["danio"]= int(bd["danio"])+ real
			bd["de"]= a
		if d.pokemon.esta_debilitado():
			_vinculos(a, d, mov)
		d.herido_turno= true
		d.danio_recibido= {"cantidad": real, "categoria": mov.categoria, "de": a}
		if d.tiene("robustez"):
			d.quitar("robustez")
			anunciar_habilidad(d)
			_texto("¡%s resistió el golpe!" % _cap(nombre_de(d)))
		if golpe["critico"]:
			hubo_critico= true
			if golpes> 1:
				_texto("¡Un golpe crítico!")
		if not d.pokemon.esta_debilitado():
			_romper_ilusion(d)
		if mov.tiene("contact"):
			HabCombate.contacto(self, a, d, mov)
		if d.tiene("furia") and real> 0 and not d.pokemon.esta_debilitado():
			_cambiar_etapa(d, "ataque", 1, false)
	a.quitar("golpe_n")
	if dados== 0:
		return
	if golpes> 1:
		_texto("¡Recibió %d golpe%s!" % [dados, "" if dados== 1 else "s"])
	elif hubo_critico:
		_texto("¡Un golpe crítico!")
		if habilidad_def(a, d, "anger_point") and not d.pokemon.esta_debilitado() and not rompio_sub:
			anunciar_habilidad(d)
			d.etapas["ataque"]= 6
			_ev({"tipo": "etapa", "lado": _lado(d), "stat": "ataque", "cambio": 6})
			_texto("¡%s maximizó su Ataque!" % _cap(nombre_de(d)))
	if MovEfectos.danio_fijo(self, a, d, mov)< 0:
		if ef> 1.0:
			_texto("¡Es muy eficaz!")
		elif ef< 1.0 and ef> 0.0:
			_texto("No es muy eficaz...")
	if tipo== "electrico":
		a.cargado= 0
	if mov.meta== "ohko" and d.pokemon.esta_debilitado():
		_texto("¡Fulminado de un golpe!")
	var p:= a.pokemon
	if mov.id== "struggle":
		_herir(a, maxi(1, floori(p.ps_max()/ 4.0)))
		_texto("¡%s también se ha hecho daño!" % nombre)
	elif mov.drenaje> 0 and not p.esta_debilitado() and total> 0:
		var cura:= maxi(1, floori(total* mov.drenaje/ 100.0))
		if habilidad_def(a, d, "liquid_ooze"):
			anunciar_habilidad(d)
			_herir(a, cura)
			_texto("¡%s absorbió el lodo líquido!" % nombre)
		elif _curar(a, cura)> 0:
			_texto("¡%s ha perdido energía!" % _cap(nombre_de(d)))
	elif mov.drenaje< 0 and not p.esta_debilitado() and total> 0 and not activa(a, "rock_head") and not activa(a, "magic_guard"):
		_herir(a, maxi(1, floori(total* -mov.drenaje/ 100.0)))
		_texto("¡%s también se ha hecho daño!" % nombre)
	var fuerza_bruta:= activa(a, "sheer_force") and MovEfectos.tiene_secundario(mov)
	var serena:= 100 if forzar_secundarios else (2 if activa(a, "serene_grace") else 1)
	var escudo:= habilidad_def(a, d, "shield_dust")
	if not mov.cambios_stats.is_empty() and not fuerza_bruta:
		var obj: Luchador= a if mov.meta== "damage-raise" else d
		var prob:= mov.prob_stat if mov.prob_stat> 0 else 100
		var bloqueado_sub:= obj== d and rompio_sub
		if not obj.pokemon.esta_debilitado() and not bloqueado_sub and not (obj== d and (escudo or d.sustituto> 0)) and rng.randi_range(1, 100)<= prob* serena:
			for s in mov.cambios_stats:
				cambiar_etapa_desde(a, obj, s, int(mov.cambios_stats[s]), false)
	if d.pokemon.esta_debilitado():
		MovEfectos.despues(self, a, d, mov, total)
		return
	if not fuerza_bruta and not escudo and d.sustituto<= 0 and not rompio_sub:
		if ESTADOS.has(mov.estado) and mov.prob_estado> 0 and rng.randi_range(1, 100)<= mov.prob_estado* serena:
			aplicar_estado_desde(a, d, ESTADOS[mov.estado], false)
		elif mov.estado== "confusion" and mov.prob_estado> 0 and rng.randi_range(1, 100)<= mov.prob_estado* serena:
			_confundir(d, false)
		var flinch:= mov.prob_retroceso
		if flinch== 0 and activa(a, "stench"):
			flinch =10
		if flinch> 0 and rng.randi_range(1, 100) <=flinch* serena and not habilidad_def(a, d, "inner_focus"):
			d.retrocede= true
	MovEfectos.despues(self, a, d, mov, total)
	if not d.pokemon.esta_debilitado() and total> 0:
		HabCombate.al_recibir_golpe(self, a, d, mov, tipo)

func calcular_danio(a: Luchador, d: Luchador, mov: Movimiento, ef: float) -> Dictionary:
	if mov.id== "super_fang":
		return {"danio": maxi(1, floori(d.pokemon.ps_actuales/ 2.0)), "critico": false}
	var fisico:= MovEfectos.es_fisico(mov)
	var s_at:= "ataque" if fisico else "at_esp"
	var s_df :="defensa" if fisico else "def_esp"
	if mov.id in ["psyshock", "psystrike", "secret_sword"]:
		s_df= "defensa"
	if zona_extrana> 0:
		s_df= "def_esp" if s_df== "defensa" else "defensa"
	var tabla:= [16, 8, 4, 3, 2]
	var etapa_crit:= a.critico_extra+ mov.critico+ roundi(EfectosTrinket.total("critico", a.pokemon))+ (1 if activa(a, "super_luck") else 0)
	var critico:= rng.randi_range(1, tabla[clampi(etapa_crit, 0, 4)])== 1 and not sin_criticos
	if mov.id in ["storm_throw", "frost_breath"]:
		critico= true
	if critico and (habilidad_def(a, d, "battle_armor") or habilidad_def(a, d, "shell_armor") or int(trampas[_lado(d)]["conjuro"])> 0):
		critico= false
	var ataque: int
	var defensa: int
	var fuente: Luchador= d if mov.id== "foul_play" else a
	var et_at: int= fuente.etapas[s_at]
	var et_df: int= d.etapas[s_df]
	if habilidad_def(a, d, "unaware"):
		et_at= 0
	if activa(a, "unaware") or mov.id in ["chip_away", "sacred_sword"]:
		et_df= 0
	if critico:
		ataque= fuente.stat_con_etapa(s_at, maxi(et_at, 0))
		defensa =d.stat_con_etapa(s_df, mini(et_df, 0))
	else:
		ataque= fuente.stat_con_etapa(s_at, et_at)
		defensa= d.stat_con_etapa(s_df, et_df)
	ataque= HabCombate.mod_ataque(self, a, d, mov, ataque, fisico)
	defensa =HabCombate.mod_defensa(self, a, d, mov, defensa, fisico)
	if clima== "arena" and "roca" in d.tipos() and not fisico and not mov.id in ["psyshock", "psystrike", "secret_sword"]:
		defensa= redondear(defensa, 1.5)
	var nivel:= a.pokemon.nivel
	var poder:= HabCombate.mod_poder(self, a, d, mov, poder_de(a, d, mov))
	var base:= (2* nivel/ 5+ 2)* poder* ataque/ maxi(1, defensa)/ 50+ 2
	var tipo:= tipo_de(a, mov)
	var m_clima:= 1.0
	if clima== "sol" and not _clima_anulado():
		m_clima= 1.5 if tipo== "fuego" else (0.5 if tipo== "agua" else 1.0)
	elif clima== "lluvia" and not _clima_anulado():
		m_clima= 1.5 if tipo== "agua" else (0.5 if tipo== "fuego" else 1.0)
	if m_clima!= 1.0:
		base= redondear(base, m_clima)
	if critico:
		base*= 2
	base= base* (aleatorio_fijo if aleatorio_fijo>= 0 else rng.randi_range(85, 100))/ 100
	if tipo!= "" and tipo in a.tipos():
		base =redondear(base, (2.0 if activa(a, "adaptability") else 1.5)+ EfectosTrinket.total("stab", a.pokemon))
	base= floori(base *ef)
	if fisico and a.pokemon.estado== "que" and not activa(a, "guts"):
		base= base/ 2
	var final:= encadenar(1.0+ EfectosTrinket.total("danio_hecho", a.pokemon), 1.0- EfectosTrinket.total("danio_recibido", d.pokemon))
	var extra:= HabCombate.mod_final(self, a, d, mov, ef, critico)
	var lado_d: Dictionary= trampas[_lado(d)]
	if not critico and not activa(a, "infiltrator") and mov.id!= "brick_break":
		if (fisico and int(lado_d["reflejo"])> 0) or (not fisico and int(lado_d["pantalla_luz"])> 0):
			extra*= 0.5
	if extra!= 1.0:
		final= (final* a_4096(extra)+ 2048)>> 12
	base =redondear_fijo(base, final)
	return {"danio": maxi(1, base), "critico": critico}

func _clima_anulado() -> bool:
	for l in [j, r]:
		if l!= null and (activa(l, "cloud_nine") or activa(l, "air_lock")):
			return true
	return false

func clima_activo() -> String:
	return "" if _clima_anulado() else clima

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
	var base_p:= MovEfectos.poder(self, a, d, mov)
	if a.cargado> 0 and tipo_de(a, mov)== "electrico":
		return base_p* 2
	return base_p

func danio_confusion(a: Luchador) -> int:
	var ataque:= a.stat_con_etapa("ataque", a.etapas["ataque"])
	var defensa:= a.stat_con_etapa("defensa", a.etapas["defensa"])
	var base:= (2* a.pokemon.nivel/ 5+ 2)* 40* ataque/ defensa/ 50+ 2
	base= base* (aleatorio_fijo if aleatorio_fijo>= 0 else rng.randi_range(85, 100))/ 100
	return maxi(1, base)

func _efecto_estado(a: Luchador, d: Luchador, mov: Movimiento) -> void:
	if MovEfectos.estado_unico(self, a, d, mov):
		return
	var hizo:= false
	if mov.curacion> 0:
		var p:= a.pokemon
		if p.ps_actuales>= p.ps_max():
			_texto("¡Los PS %s están al máximo!" % _de(a))
			return
		if _curar(a, floori(p.ps_max()* mov.curacion/ 100.0))> 0:
			_texto("¡%s recuperó salud!" % _cap(nombre_de(a)))
		hizo= true
	if not mov.cambios_stats.is_empty():
		var obj: Luchador= a if mov.objetivo in OBJETIVO_PROPIO else d
		if obj== d and d.sustituto> 0 and a!= d and not mov.tiene("bypasssub"):
			_texto("¡Pero falló!")
			return
		var algo:= false
		for s in mov.cambios_stats:
			if cambiar_etapa_desde(a, obj, s, int(mov.cambios_stats[s]), true):
				algo= true
		hizo =true
	if ESTADOS.has(mov.estado):
		var est: String= ESTADOS[mov.estado]
		if mov.id== "toxic":
			est= "tox"
		aplicar_estado_desde(a, d, est, true)
		hizo= true
	elif mov.estado== "confusion":
		if d.sustituto> 0 and a!= d:
			_texto("¡Pero falló!")
			return
		_confundir(d, true)
		hizo =true
	if not hizo:
		_texto("¡Pero no pasó nada!")

func _confundir(l: Luchador, anunciar_fallo: bool) -> bool:
	if l.pokemon.esta_debilitado():
		return false
	if activa(l, "own_tempo"):
		if anunciar_fallo:
			anunciar_habilidad(l)
			_texto("¡%s no se confunde!" % _cap(nombre_de(l)))
		return false
	if l.confusion> 0:
		if anunciar_fallo:
			_texto("¡%s ya está confuso!" % _cap(nombre_de(l)))
		return false
	if int(trampas[_lado(l)]["velo_sagrado"])> 0 and anunciar_fallo:
		_texto("¡%s está protegido por Velo Sagrado!" % _cap(nombre_de(l)))
		return false
	l.confusion= rng.randi_range(2, 5)
	_texto("¡%s se encuentra confuso!" % _cap(nombre_de(l)))
	return true

func _relevo(a: Luchador) -> void:
	var lista:= equipo_r if a== r else equipo_j
	var hay:= false
	for o in lista:
		if o!= a.pokemon and not o.esta_debilitado():
			hay= true
	if not hay:
		_texto("¡Pero falló!")
		return
	_texto("¡%s pasó el relevo!" % _cap(nombre_de(a)))
	if a== j:
		relevo_pendiente= "relevo"
		_ev({"tipo": "elegir_relevo"})
		return
	var sig: PokemonInstancia= null
	for k in range(lista.size()- 1, -1, -1):
		if lista[k]!= a.pokemon and not lista[k].esta_debilitado():
			sig= lista[k]
			break
	_meter(a, sig, true)

func ida_y_vuelta(a: Luchador) -> void:
	var lista:= equipo_r if a== r else equipo_j
	var sig: PokemonInstancia= null
	for o in lista:
		if o!= a.pokemon and not o.esta_debilitado():
			sig= o
			break
	if sig== null:
		return
	if a== j:
		relevo_pendiente= "ida"
		_ev({"tipo": "elegir_relevo"})
		return
	_meter(a, sig, false)

func _meter(a: Luchador, sig: PokemonInstancia, pasa_relevo: bool) -> void:
	var lado:= _lado(a)
	HabCombate.al_salir(self, a)
	_ev({"tipo": "retirar", "lado": lado, "ball": a.pokemon.ball})
	var nuevo:= _nuevo_rival(sig) if a== r else _nuevo_luchador(sig)
	if pasa_relevo:
		nuevo.etapas= a.etapas.duplicate()
		nuevo.confusion =a.confusion
		nuevo.sustituto= a.sustituto
		nuevo.critico_extra =a.critico_extra
		for k in ["drenadoras", "arraigo", "acua_aro", "maldito", "sin_escape", "levitar", "canto_mortal", "fijado", "gastro", "embargo", "anticura", "truco_fuerza"]:
			if a.tiene(k):
				nuevo.poner(k, a.valor(k))
	if a== r:
		r= nuevo
		if nuevo.sustituto> 0:
			_ev({"tipo": "sustituto", "lado": lado, "activo": false})
		_texto("¡%s envió a %s!" % [nombre_entrenador, r.nombre_visible()])
		_ev_sale("rival", sig)
		_anunciar_trinkets(sig)
		_al_entrar(r)
	else:
		j= nuevo
		if not participantes.has(sig):
			participantes.append(sig)
		_texto("¡Adelante, %s!" % sig.nombre())
		_ev_sale("jugador", sig)
		_al_entrar(j)
	if nuevo.sustituto> 0:
		_ev({"tipo": "sustituto", "lado": lado, "activo": true})

func _equipo_de(l: Luchador) -> String:
	return "del equipo rival" if l== r else "de tu equipo"

func _entrar_trampas(l: Luchador) -> bool:
	var t: Dictionary= trampas[_lado(l)]
	var p:= l.pokemon
	if p.esta_debilitado() or activa(l, "magic_guard"):
		return false
	if int(t["puas"])> 0 and _en_tierra(l):
		_herir(l, maxi(1, floori(p.ps_max()* PUAS[int(t["puas"])])), "golpe_normal")
		_texto("¡%s fue herido por las púas!" % _cap(nombre_de(l)))
	if t["rocas"] and not p.esta_debilitado():
		var ef:= Tipos.efectividad("roca", l.tipos())
		_herir(l, maxi(1, floori(p.ps_max()* ef/ 8.0)), "golpe_eficaz" if ef> 1.0 else "golpe_normal")
		_texto("¡Las rocas puntiagudas hirieron a %s!" % nombre_de(l))
	if int(t["puas_toxicas"])> 0 and _en_tierra(l) and not p.esta_debilitado():
		if "veneno" in l.tipos():
			t["puas_toxicas"]= 0
			_texto("¡%s absorbió las púas tóxicas!" % _cap(nombre_de(l)))
		elif not "acero" in l.tipos() and p.estado== "":
			aplicar_estado_desde(null, l, "tox" if int(t["puas_toxicas"])>= 2 else "env", false)
	return p.esta_debilitado()

func puede_huir(l: Luchador) -> bool:
	if activa(l, "run_away") or "fantasma" in l.tipos():
		return true
	return _puede_cambiar(l)

func _puede_cambiar(l: Luchador) -> bool:
	if "fantasma" in l.tipos():
		return true
	if l.tiene("atrapado") or l.tiene("sin_escape") or l.tiene("arraigo"):
		return false
	var o:= otro_de(l)
	if o!= null and not o.pokemon.esta_debilitado():
		if activa(o, "shadow_tag") and not activa(l, "shadow_tag"):
			return false
		if activa(o, "arena_trap") and _en_tierra(l):
			return false
		if activa(o, "magnet_pull") and "acero" in l.tipos():
			return false
	return true

func _arrastrar(a: Luchador, d: Luchador) -> void:
	if habilidad_def(a, d, "suction_cups"):
		anunciar_habilidad(d)
		_texto("¡%s se aferra al suelo!" % _cap(nombre_de(d)))
		return
	if d.tiene("arraigo"):
		_texto("¡%s echó raíces y no se mueve!" % _cap(nombre_de(d)))
		return
	if salvaje:
		if a.pokemon.nivel>= d.pokemon.nivel:
			_texto("¡%s huyó asustado!" % _cap(nombre_de(d)) if d== r else "¡Huiste del combate!")
			_terminar("huida")
		else:
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
	HabCombate.al_salir(self, d)
	_ev({"tipo": "retirar", "lado": lado, "ball": d.pokemon.ball})
	if d== r:
		r= _nuevo_rival(sig)
		_texto("¡%s fue arrastrado al combate!" % _cap(r.nombre_visible()))
		_ev_sale("rival", sig)
		_anunciar_trinkets(sig)
		_al_entrar(r)
	else:
		j= _nuevo_luchador(sig)
		if not participantes.has(sig):
			participantes.append(sig)
		_texto("¡%s fue arrastrado al combate!" % sig.nombre())
		_ev_sale("jugador", sig)
		_al_entrar(j)

func _cambiar_etapa(l: Luchador, stat: String, cambio: int, anunciar_tope: bool) -> bool:
	return cambiar_etapa_desde(l, l, stat, cambio, anunciar_tope)

func cambiar_etapa_desde(a: Luchador, l: Luchador, stat: String, cambio: int, anunciar_tope: bool) -> bool:
	if not l.etapas.has(stat) or cambio== 0 or l.pokemon.esta_debilitado():
		return false
	var ajena:= a!= null and a!= l
	if activa(l, "simple"):
		cambio*= 2
	if activa(l, "contrary"):
		cambio= -cambio
	if cambio< 0 and ajena:
		if int(trampas[_lado(l)]["neblina"])> 0:
			if anunciar_tope:
				_texto("¡%s está protegido por la neblina!" % _cap(nombre_de(l)))
			return false
		if HabCombate.evita_bajada(self, a, l, stat, anunciar_tope):
			return false
	var real:= l.cambiar_etapa(stat, cambio)
	var nombre_s: String= NOMBRE_STAT.get(stat, stat)
	if real== 0:
		if anunciar_tope:
			_texto("¡%s %s no puede %s más!" % [_cap(nombre_s), _de(l), "subir" if cambio> 0 else "bajar"])
		return false
	var verbo: String
	if real>= 3:
		verbo= "subió muchísimo"
	elif real>= 2:
		verbo ="subió mucho"
	elif real== 1:
		verbo ="subió"
	elif real== -1:
		verbo= "bajó"
	elif real== -2:
		verbo= "bajó mucho"
	else:
		verbo ="bajó muchísimo"
	_ev({"tipo": "etapa", "lado": _lado(l), "stat": stat, "cambio": real})
	_texto("¡%s %s %s!" % [_cap(nombre_s), _de(l), verbo])
	if real< 0 and ajena:
		HabCombate.tras_bajada(self, l)
	return true

func _aplicar_estado(l: Luchador, est: String, anunciar_fallo: bool) -> bool:
	return aplicar_estado_desde(null, l, est, anunciar_fallo)

func aplicar_estado_desde(a: Luchador, l: Luchador, est: String, anunciar_fallo: bool) -> bool:
	var p:= l.pokemon
	if p.esta_debilitado():
		return false
	if p.estado!= "":
		if anunciar_fallo:
			_texto("¡Pero falló!" if p.estado!= est and not (est== "tox" and p.estado== "env") else "¡%s ya está %s!" % [_cap(nombre_de(l)), {"que": "quemado", "env": "envenenado", "tox": "envenenado", "par": "paralizado", "dor": "dormido", "con": "congelado"}[p.estado]])
		return false
	for t in INMUNES.get(est, []):
		if t in l.tipos():
			if anunciar_fallo:
				_texto("No afecta %s..." % _a(l))
			return false
	if a!= null and a!= l and int(trampas[_lado(l)]["velo_sagrado"])> 0 and not activa(a, "infiltrator"):
		if anunciar_fallo:
			_texto("¡%s está protegido por Velo Sagrado!" % _cap(nombre_de(l)))
		return false
	if a!= null and a!= l and l.sustituto> 0 and anunciar_fallo:
		_texto("¡Pero falló!")
		return false
	if est== "dor" and _hay_alboroto():
		if anunciar_fallo:
			_texto("¡Pero falló!")
		return false
	if HabCombate.evita_estado(self, a, l, est, anunciar_fallo):
		return false
	_poner_estado(l, est)
	if est== "dor":
		l.turnos_sueno =rng.randi_range(2, 4)
	if est== "tox":
		l.toxico= 0
	_texto(TEXTO_ESTADO[est] % _cap(nombre_de(l)))
	if a!= null and a!= l and est in ["que", "env", "tox", "par"] and activa(l, "synchronize"):
		anunciar_habilidad(l)
		aplicar_estado_desde(l, a, "env" if est== "tox" else est, false)
	return true

func _hay_alboroto() -> bool:
	for l in [j, r]:
		if l!= null and l.mov_bloqueado!= null and l.mov_bloqueado.id== "uproar" and l.turnos_bloqueo> 0:
			return true
	return false

func _poner_estado(l: Luchador, est: String) -> void:
	l.pokemon.estado= est
	_ev({"tipo": "estado", "lado": _lado(l), "estado": est})

func _fin_de_turno() -> void:
	for l in [j, r]:
		if l.cargado> 0:
			l.cargado-= 1
		l.turnos_en_campo+= 1
	var orden:= _por_velocidad([j, r])
	if clima!= "":
		if turnos_clima> 0:
			turnos_clima-= 1
			if turnos_clima== 0:
				_texto({"lluvia": "Dejó de llover.", "sol": "El sol perdió su fuerza.", "arena": "La tormenta de arena amainó.", "granizo": "Dejó de granizar."}[clima])
				clima= ""
				_ev({"tipo": "clima", "clima": ""})
		if clima!= "":
			_texto({"lluvia": "Sigue lloviendo.", "sol": "El sol pega fuerte.", "arena": "La tormenta de arena arrecia.", "granizo": "Sigue granizando."}[clima])
			for l in orden:
				HabCombate.clima_fin_turno(self, l)
	for f in futuros.duplicate():
		f["turnos"]= int(f["turnos"])- 1
		if int(f["turnos"])<= 0:
			futuros.erase(f)
			MovEfectos.golpe_futuro(self, f)
	for l in orden:
		var t: Dictionary= trampas[_lado(l)]
		if int(t["deseo"])> 0:
			t["deseo"]= int(t["deseo"])- 1
			if int(t["deseo"])== 0 and not l.pokemon.esta_debilitado():
				_texto("¡El deseo se hizo realidad!")
				_curar(l, int(t["deseo_ps"]))
	for l in orden:
		var p: PokemonInstancia= l.pokemon
		if p.esta_debilitado():
			continue
		HabCombate.fin_turno_estado(self, l)
		if l.tiene("acua_aro") and _curar(l, floori(p.ps_max()/ 16.0))> 0:
			_texto("¡%s recuperó PS con el acua aro!" % _cap(nombre_de(l)))
		if l.tiene("arraigo") and _curar(l, floori(p.ps_max()/ 16.0))> 0:
			_texto("¡%s absorbió nutrientes con sus raíces!" % _cap(nombre_de(l)))
		var o:= otro_de(l)
		if l.tiene("drenadoras") and not o.pokemon.esta_debilitado() and not activa(l, "magic_guard"):
			var chupa:= maxi(1, floori(p.ps_max()/ 8.0))
			var real:= _herir(l, chupa, "golpe_normal")
			_texto("¡Las drenadoras restaron salud %s!" % _a(l))
			if activa(l, "liquid_ooze"):
				_herir(o, real)
			else:
				_curar(o, real)
			if p.esta_debilitado():
				continue
		if p.estado in ["que", "env", "tox"] and not activa(l, "magic_guard"):
			if p.estado in ["env", "tox"] and activa(l, "poison_heal"):
				if p.ps_actuales< p.ps_max():
					anunciar_habilidad(l)
					_curar(l, floori(p.ps_max()/ 8.0))
			elif p.estado== "tox":
				l.toxico= mini(l.toxico+ 1, 15)
				_herir(l, maxi(1, floori(p.ps_max()* l.toxico/ 16.0)), "estado_env")
				_texto("¡El veneno resta PS %s!" % _a(l))
			else:
				var div:= 16.0 if p.estado== "que" and activa(l, "heatproof") else 8.0
				_herir(l, maxi(1, floori(p.ps_max()/ div)), "estado_"+ p.estado)
				if p.estado== "que":
					_texto("¡%s se resiente de la quemadura!" % _cap(nombre_de(l)))
				else:
					_texto("¡El veneno resta PS %s!" % _a(l))
			_revisar_baya(l)
			if p.esta_debilitado():
				continue
		if l.tiene("pesadilla") and p.estado== "dor" and not activa(l, "magic_guard"):
			_herir(l, maxi(1, floori(p.ps_max()/ 4.0)))
			_texto("¡%s tiene pesadillas!" % _cap(nombre_de(l)))
		if l.tiene("maldito") and not p.esta_debilitado() and not activa(l, "magic_guard"):
			_herir(l, maxi(1, floori(p.ps_max()/ 4.0)))
			_texto("¡%s es víctima de la maldición!" % _cap(nombre_de(l)))
		if l.tiene("atrapado") and not p.esta_debilitado():
			var at: Dictionary= l.valor("atrapado")
			at["turnos"]= int(at["turnos"])- 1
			if int(at["turnos"])<= 0 or at["por"]!= otro_de(l):
				l.quitar("atrapado")
				_texto("¡%s se liberó de %s!" % [_cap(nombre_de(l)), at["nombre"]])
			elif not activa(l, "magic_guard"):
				_herir(l, maxi(1, floori(p.ps_max()/ 16.0)))
				_texto("¡%s sufre por %s!" % [_cap(nombre_de(l)), at["nombre"]])
		if o!= null and activa(o, "bad_dreams") and p.estado== "dor" and not p.esta_debilitado() and not activa(l, "magic_guard"):
			anunciar_habilidad(o)
			_herir(l, maxi(1, floori(p.ps_max()/ 8.0)))
			_texto("¡%s tiene un mal sueño!" % _cap(nombre_de(l)))
	for l in orden:
		_contadores(l)
	for lado in ["jugador", "rival"]:
		var t2: Dictionary= trampas[lado]
		var dueno:= "tu equipo" if lado== "jugador" else "el equipo rival"
		for k in [["reflejo", "Reflejo"], ["pantalla_luz", "Pantalla de Luz"], ["velo_sagrado", "Velo Sagrado"], ["neblina", "Neblina"], ["viento_afin", "Viento Afín"], ["conjuro", "Conjuro"]]:
			if int(t2[k[0]])> 0:
				t2[k[0]]= int(t2[k[0]])- 1
				if int(t2[k[0]])== 0:
					_texto("¡%s de %s se desvaneció!" % [k[1], dueno])
	if gravedad> 0:
		gravedad-= 1
		if gravedad== 0:
			_texto("¡La gravedad volvió a la normalidad!")
	if espacio_raro> 0:
		espacio_raro -=1
		if espacio_raro== 0:
			_texto("¡Las dimensiones retorcidas volvieron a la normalidad!")
	if zona_extrana> 0:
		zona_extrana-= 1
		if zona_extrana== 0:
			_texto("¡La zona extraña desapareció y las defensas volvieron a la normalidad!")
	if zona_magica> 0:
		zona_magica -=1
		if zona_magica== 0:
			_texto("¡La zona mágica desapareció!")
	for l in orden:
		if not l.pokemon.esta_debilitado():
			HabCombate.fin_turno(self, l)

func _contadores(l: Luchador) -> void:
	var nombre:= _cap(nombre_de(l))
	for par in [["mofa", "¡%s ya no está bajo los efectos de la mofa!"], ["levitar", "¡%s dejó de levitar!"], ["telequinesis", "¡%s se liberó de la telequinesis!"], ["anticura", "¡%s puede volver a curarse!"], ["embargo", "¡%s puede volver a usar objetos!"]]:
		if l.tiene(par[0]):
			var n: int= int(l.valor(par[0]))- 1
			if n<= 0:
				l.quitar(par[0])
				_texto(par[1] % nombre)
			else:
				l.poner(par[0], n)
	if l.tiene("anulado"):
		var an: Dictionary= l.valor("anulado")
		an["turnos"]= int(an["turnos"])- 1
		if int(an["turnos"])<= 0:
			l.quitar("anulado")
			_texto("¡%s ya no está anulado!" % nombre)
	if l.tiene("otra_vez"):
		var ov: Dictionary= l.valor("otra_vez")
		ov["turnos"]= int(ov["turnos"])- 1
		var idx:= l.movimientos().find(ov["mov"])
		if int(ov["turnos"])<= 0 or idx< 0 or l.pp()[idx]<= 0:
			l.quitar("otra_vez")
			_texto("¡%s ya no está bajo los efectos de Otra Vez!" % nombre)
	if l.tiene("bostezo"):
		var b: int= int(l.valor("bostezo"))- 1
		if b<= 0:
			l.quitar("bostezo")
			aplicar_estado_desde(null, l, "dor", false)
		else:
			l.poner("bostezo", b)
	if l.tiene("canto_mortal") and not l.pokemon.esta_debilitado():
		var c: int= int(l.valor("canto_mortal"))- 1
		l.poner("canto_mortal", c)
		_texto("¡El contador de Canto Mortal %s bajó a %d!" % [_de(l), c])
		if c<= 0:
			_herir(l, l.pokemon.ps_actuales)
	if l.mov_bloqueado!= null and l.mov_bloqueado.id== "uproar" and l.turnos_bloqueo> 0:
		l.turnos_bloqueo-= 1
		if l.turnos_bloqueo<= 0:
			l.mov_bloqueado= null
			_texto("¡%s se calmó!" % nombre)
		else:
			_texto("¡%s sigue alborotando!" % nombre)

func _revisar_baya(l: Luchador) -> void:
	var p:= l.pokemon
	if p.objeto== "" or p.esta_debilitado() or p.ps_actuales* 2> p.ps_max() or zona_magica> 0 or l.tiene("embargo") or activa(l, "klutz"):
		return
	var o:= BaseDatos.objeto(p.objeto)
	if o== null or o.categoria!= "BAYAS" or o.cura_ps<= 0:
		return
	var otro:= otro_de(l)
	if otro!= null and activa(otro, "unnerve"):
		return
	var antes:= p.ps_actuales
	p.curar_ps(o.cura_ps)
	perder_objeto(l)
	l.poner("baya_usada", o.id)
	_ev({"tipo": "sonido", "nombre": "objeto_activo"})
	_ev_ps(l, antes)
	_texto("¡%s recuperó PS con su %s!" % [_cap(nombre_de(l)), o.nombre])

func perder_objeto(l: Luchador) -> String:
	var o:= l.pokemon.objeto
	if o== "":
		return ""
	if not objetos_perdidos.has(l.pokemon):
		objetos_perdidos[l.pokemon]= o
	l.pokemon.objeto= ""
	l.poner("sin_objeto")
	return o

func temporal_mov(l: Luchador, k: int, mov: Movimiento, pps: int) -> void:
	var p:= l.pokemon
	if not temporales.has(p):
		temporales[p]= []
	temporales[p].append([k, p.movimientos[k], p.pp[k]])
	p.movimientos[k]= mov
	p.pp[k]= pps

func cambiar_objetos(a: Luchador, d: Luchador) -> void:
	for l in [a, d]:
		if not objetos_perdidos.has(l.pokemon):
			objetos_perdidos[l.pokemon]= l.pokemon.objeto
	var tmp:= a.pokemon.objeto
	a.pokemon.objeto= d.pokemon.objeto
	d.pokemon.objeto= tmp
	for l in [a, d]:
		if l.pokemon.objeto== "":
			l.poner("sin_objeto")

func restaurar_objetos() -> void:
	for p in temporales:
		var lista: Array= temporales[p]
		for k in range(lista.size()- 1, -1, -1):
			var e: Array= lista[k]
			p.movimientos[e[0]]= e[1]
			p.pp[e[0]]= mini(int(e[2]), e[1].pp)
	temporales.clear()
	for p in objetos_perdidos:
		if equipo_j.has(p) or equipo_r.has(p):
			p.objeto= objetos_perdidos[p]
	objetos_perdidos.clear()
	for p in equipo_j:
		if p.estado== "tox":
			p.estado= "env"

func _revisar_debilitados(reponer: bool= true) -> bool:
	var algo:= false
	if r.pokemon.esta_debilitado() and not terminado and not r.tiene("debil_anunciado"):
		algo= true
		r.poner("debil_anunciado")
		_ev({"tipo": "debilitado", "lado": "rival"})
		_texto("¡%s se debilitó!" % _cap(nombre_de(r)))
		HabCombate.al_debilitar(self, r)
		_dar_experiencia()
		if _siguiente_util(equipo_r)== null:
			if not salvaje:
				_texto("¡Has derrotado a %s!" % nombre_entrenador)
				if pago_base> 0:
					dinero_ganado= roundi(pago_base* r.pokemon.nivel* (1.0+ EfectosTrinket.total("dinero", null, equipo_j)))
					_texto("¡Ganaste %d$ por tu victoria!" % dinero_ganado)
			_terminar("victoria")
	if j.pokemon.esta_debilitado() and not j_anunciado:
		algo =true
		j_anunciado= true
		_ev({"tipo": "debilitado", "lado": "jugador"})
		_texto("¡%s se debilitó!" % j.pokemon.nombre())
		HabCombate.al_debilitar(self, j)
		j.pokemon.subir_amistad(-1)
		participantes.erase(j.pokemon)
		if not terminado and _siguiente_util(equipo_j)== null:
			_texto("¡No te quedan Pokémon que puedan luchar!")
			_terminar("derrota")
	if terminado or not reponer:
		return algo
	if r.pokemon.esta_debilitado():
		var sig:= _siguiente_util(equipo_r)
		if sig!= null:
			r= _nuevo_rival(sig)
			participantes.clear()
			if not j.pokemon.esta_debilitado():
				participantes.append(j.pokemon)
			_texto("¡%s envió a %s!" % [nombre_entrenador, r.nombre_visible()])
			_ev_sale("rival", sig)
			_anunciar_trinkets(sig)
			_al_entrar(r)
			if r.pokemon.esta_debilitado():
				return _revisar_debilitados(true) or true
	if j.pokemon.esta_debilitado() and not esperando_reemplazo and not terminado:
		esperando_reemplazo= true
		_ev({"tipo": "elegir_reemplazo"})
	return algo

func _terminar(res: String) -> void:
	if terminado:
		return
	terminado= true
	resultado =res
	restaurar_objetos()
	_ev({"tipo": "fin", "resultado": res})

func ganar_ya() -> Array[Dictionary]:
	if terminado:
		return _tomar()
	_texto("¡Modo prueba: victoria automática!")
	for p in equipo_r:
		if not p.esta_debilitado():
			var antes:= p.ps_actuales
			p.ps_actuales= 0
			if p== r.pokemon:
				_ev_ps(r, antes)
	esperando_reemplazo= false
	relevo_pendiente =""
	cola.clear()
	_revisar_debilitados(false)
	return _tomar()

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
	if not puede_huir(j):
		_texto("¡No puedes escapar!")
		return false
	intentos_huida+= 1
	var va:= velocidad_de(j)
	var vb:= velocidad_de(r)
	if activa(j, "run_away") or va>= vb or floori(va* 128.0/ vb)+ 30* intentos_huida> rng.randi_range(0, 255):
		if activa(j, "run_away"):
			anunciar_habilidad(j)
		_ev({"tipo": "sonido", "nombre": "huir"})
		_texto("¡Escapaste sin problemas!")
		_terminar("huida")
		return true
	_texto("¡No puedes escapar!")
	return false

func _cambiar(indice: int) -> void:
	_texto("¡%s, vuelve!" % j.pokemon.nombre())
	HabCombate.al_salir(self, j)
	_ev({"tipo": "retirar", "lado": "jugador", "ball": j.pokemon.ball})
	j= _nuevo_luchador(equipo_j[indice])
	if not participantes.has(j.pokemon):
		participantes.append(j.pokemon)
	_texto("¡Adelante, %s!" % j.pokemon.nombre())
	_ev_sale("jugador", j.pokemon)
	_al_entrar(j)

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
		var cura_tox:= o.cura_estado== "env" and c.estado== "tox"
		if c.esta_debilitado() or c.estado== "" or (o.cura_estado!= "todos" and c.estado!= o.cura_estado and not cura_tox):
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
	if r.transformado!= null:
		r.transformado= null
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
					if i>= 0 and not _estado_sirve(r, j, r.movimientos()[i]):
						i= -1
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
				if velocidad_de(r)< velocidad_de(j):
					i= _indice_mov(r, "payback")
			"relevo":
				if _subidas(r)>= 2:
					for o in equipo_r:
						if o!= r.pokemon and not o.esta_debilitado():
							i= _indice_mov(r, "baton_pass")
							break
			"danio":
				i= _mejor_danio()
		if i>= 0 and r.pp()[i]> 0:
			return i
	return _mejor_danio()

func _estado_sirve(a: Luchador, d: Luchador, m: Movimiento) -> bool:
	if d.pokemon.estado!= "":
		return false
	if m.tiene("powder") and "planta" in d.tipos():
		return false
	if m.id== "thunder_wave" and efectividad(a, d, "electrico", m)== 0.0:
		return false
	for t in INMUNES.get(ESTADOS.get(m.estado, ""), []):
		if t in d.tipos():
			return false
	return true

func represalia_lista(l: Luchador) -> bool:
	return int(ultimo_caido[_lado(l)])== turnos- 1

func _subidas(l: Luchador) -> int:
	var n:= 0
	for s in l.etapas:
		if int(l.etapas[s])> 0:
			n+= int(l.etapas[s])
	return n

func _quedan_j() -> int:
	var n:= 0
	for o in equipo_j:
		if not o.esta_debilitado():
			n+= 1
	return n

func _indice_mov(l: Luchador, id: String) -> int:
	var movs:= l.movimientos()
	for k in movs.size():
		if movs[k].id== id:
			return k
	return -1

func estimar_danio(a: Luchador, d: Luchador, mov: Movimiento) -> float:
	if mov.categoria== "estado":
		return 0.0
	var tipo:= tipo_de(a, mov)
	var ef:= efectividad(a, d, tipo, mov)
	if ef== 0.0 or HabCombate.absorberia(self, a, d, tipo, mov):
		return 0.0
	if mov.tiene("powder") and "planta" in d.tipos():
		return 0.0
	var fijo:= MovEfectos.danio_fijo(self, a, d, mov)
	if fijo>= 0:
		return float(fijo)
	var fisico:= MovEfectos.es_fisico(mov)
	var fuente: Luchador= d if mov.id== "foul_play" else a
	var ataque:= fuente.stat_efectivo("ataque" if fisico else "at_esp")
	var defensa:= d.stat_efectivo("defensa" if fisico else "def_esp")
	var poder:= mov.poder if mov.id== "magnitude" else poder_de(a, d, mov)
	var base:= (2.0* a.pokemon.nivel/ 5.0+ 2.0)* poder* ataque/ maxf(1.0, defensa)/ 50.0+ 2.0
	if tipo in a.tipos():
		base*= 1.5+ EfectosTrinket.total("stab", a.pokemon)
	var prec:= 1.0 if mov.precision<= 0 else mov.precision/ 100.0
	var golpes:= (mov.golpes_min+ mov.golpes_max)/ 2.0 if mov.golpes_max> 1 else 1.0
	return base* ef* prec* 0.925* golpes

func _mejor_danio() -> int:
	var mejor:= -1
	var valor:= -1.0
	var movs:= r.movimientos()
	for k in movs.size():
		if r.pp()[k]<= 0 or not _usable(r, movs[k]):
			continue
		var v:= estimar_danio(r, j, movs[k])
		if v> valor:
			valor= v
			mejor =k
	if valor<= 0.0:
		var opciones:= []
		for k in movs.size():
			if r.pp()[k]> 0 and _usable(r, movs[k]) and (movs[k].categoria!= "estado" or MovEfectos.estado_util(self, r, j, movs[k])):
				opciones.append(k)
		if opciones.is_empty():
			for k in movs.size():
				if r.pp()[k]> 0 and _usable(r, movs[k]):
					opciones.append(k)
		return -1 if opciones.is_empty() else opciones[rng.randi_range(0, opciones.size()- 1)]
	return mejor
