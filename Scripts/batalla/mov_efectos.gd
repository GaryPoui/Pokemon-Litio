class_name MovEfectos
extends RefCounted

const DOS_TURNOS:= {
	"razor_wind": ["¡%s provocó un remolino!", ""],
	"solar_beam": ["¡%s absorbió luz solar!", ""],
	"skull_bash": ["¡%s bajó la cabeza!", ""],
	"sky_attack": ["¡%s se rodeó de un aura brillante!", ""],
	"freeze_shock": ["¡%s se rodeó de un aire gélido!", ""],
	"ice_burn": ["¡%s se rodeó de un aire helado!", ""],
	"fly": ["¡%s voló muy alto!", "vuela"],
	"bounce": ["¡%s saltó muy alto!", "vuela"],
	"dig": ["¡%s se ocultó bajo tierra!", "excava"],
	"dive": ["¡%s se sumergió!", "buceo"],
	"shadow_force": ["¡%s desapareció en un instante!", "desaparece"],
	"sky_drop": ["¡%s se llevó al rival por los aires!", "vuela"],
}
const BLOQUEO:= ["thrash", "outrage", "petal_dance"]
const RODAR :=["rollout", "ice_ball"]
const PROTECCION:= ["protect", "detect", "endure", "quick_guard", "wide_guard"]
const NATURALEZA :={"pasto": "seed_bomb", "orilla": "seed_bomb", "campo": "earthquake", "agua": "hydro_pump", "cemento": "tri_attack", "roca": "rock_slide"}
const CAMUFLAJE:= {"pasto": "planta", "orilla": "planta", "campo": "tierra", "agua": "agua", "cemento": "normal", "roca": "roca"}
const SECRETO :={"pasto": ["estado", "dor"], "orilla": ["estado", "dor"], "campo": ["stat", "precision"], "agua": ["stat", "ataque"], "cemento": ["estado", "par"], "roca": ["retroceso", ""]}
const SIN_ROL:= ["wonder_guard", "multitype", "illusion", "zen_mode", "trace", "forecast", "flower_gift", "imposter"]
const TIPOS_PODER_OCULTO:= ["lucha", "volador", "veneno", "tierra", "roca", "bicho", "fantasma", "acero", "fuego", "agua", "planta", "electrico", "psiquico", "hielo", "dragon", "siniestro"]

static func _t(c: LogicaCombate, l: Luchador) -> String:
	return c._cap(c.nombre_de(l))

static func _fallo(c: LogicaCombate) -> bool:
	c._texto("¡Pero falló!")
	return true

static func antes(c: LogicaCombate, a: Luchador, d: Luchador, mov: Movimiento, segunda: bool) -> bool:
	var id:= mov.id
	if a.tiene("bide") and id== "bide":
		var bd: Dictionary= a.valor("bide")
		bd["turnos"]= int(bd["turnos"])- 1
		if int(bd["turnos"])> 0:
			c._texto("¡%s está acumulando energía!" % _t(c, a))
			return true
		c._texto("¡%s liberó la energía acumulada!" % _t(c, a))
		a.mov_bloqueado= null
		a.turnos_bloqueo =0
		if int(bd["danio"])<= 0:
			a.quitar("bide")
			return _fallo(c)
		return false
	if id== "bide":
		a.poner("bide", {"turnos": 2, "danio": 0, "de": null})
		a.mov_bloqueado= mov
		a.turnos_bloqueo= 3
		c._texto("¡%s empezó a acumular energía!" % _t(c, a))
		return true
	if DOS_TURNOS.has(id) and not segunda:
		if id== "solar_beam" and c.clima_activo()== "sol":
			return false
		if id== "sky_drop" and d.peso()>= 200.0:
			return _fallo(c)
		a.cargando= mov
		var datos: Array= DOS_TURNOS[id]
		c._texto(datos[0] % _t(c, a))
		if datos[1]!= "":
			a.invulnerable= datos[1]
			c._ev({"tipo": "oculto", "lado": c._lado(a), "oculto": true})
		if id== "skull_bash":
			c._cambiar_etapa(a, "defensa", 1, false)
		if id== "sky_drop":
			d.poner("levantado", a)
			c._ev({"tipo": "oculto", "lado": c._lado(d), "oculto": true})
		return true
	if segunda:
		a.cargando= null
		if a.invulnerable!= "":
			a.invulnerable= ""
			c._ev({"tipo": "oculto", "lado": c._lado(a), "oculto": false})
		if id== "sky_drop" and d.tiene("levantado"):
			d.quitar("levantado")
			c._ev({"tipo": "oculto", "lado": c._lado(d), "oculto": false})
	if id in ["feint", "shadow_force"] and d.protegido:
		d.protegido= false
		c._texto("¡%s cayó en la finta!" % _t(c, d))
	match id:
		"fake_out":
			if a.turnos_en_campo> 0:
				return _fallo(c)
		"sucker_punch":
			var em: Movimiento= c.elegido[c._lado(d)]
			if d.actuo_turno or em== null or em.categoria== "estado":
				return _fallo(c)
		"dream_eater":
			if d.pokemon.estado!= "dor" and not c.activa(d, "comatose"):
				c._texto("¡%s no se ve afectado!" % _t(c, d))
				return true
		"snore":
			if a.pokemon.estado!= "dor":
				return _fallo(c)
		"last_resort":
			var usados: Dictionary= a.valor("usados", {})
			var otros:= 0
			for m in a.movimientos():
				if m.id!= "last_resort":
					otros+= 1
					if not usados.has(m.id):
						return _fallo(c)
			if otros== 0:
				return _fallo(c)
		"synchronoise":
			var comparte:= false
			for t in a.tipos():
				if t in d.tipos():
					comparte= true
			if not comparte:
				c._texto("No afecta %s..." % c._a(d))
				return true
		"counter", "mirror_coat", "metal_burst":
			var dr: Dictionary= a.danio_recibido
			if dr.is_empty() or dr.get("de")!= d or int(dr.get("cantidad", 0))<= 0:
				return _fallo(c)
			if id== "counter" and dr["categoria"]!= "fisico":
				return _fallo(c)
			if id== "mirror_coat" and dr["categoria"]!= "especial":
				return _fallo(c)
		"spit_up":
			if int(a.valor("reserva", 0))<= 0:
				return _fallo(c)
		"natural_gift", "fling":
			if a.pokemon.objeto== "" or c.zona_magica> 0 or a.tiene("embargo"):
				return _fallo(c)
		"explosion", "self_destruct":
			for l in [a, d]:
				if c.activa(l, "damp"):
					c.anunciar_habilidad(l)
					c._texto("¡%s impide que explote!" % _t(c, l))
					return true
			a.poner("explota")
		"final_gambit":
			a.poner("explota")
		"present":
			var p:= c.rng.randi_range(1, 100)
			if p<= 20:
				if d.pokemon.ps_actuales>= d.pokemon.ps_max():
					c._texto("¡%s no puede recuperar más PS!" % _t(c, d))
				else:
					c._curar(d, floori(d.pokemon.ps_max()/ 4.0))
					c._texto("¡%s recuperó PS!" % _t(c, d))
				return true
			a.poner("regalo", 40 if p<= 60 else (80 if p<= 90 else 120))
		"metronome":
			var lista:= _todos_movimientos().filter(func(m): return m.tiene("metronome"))
			if lista.is_empty():
				return _fallo(c)
			c.usar_movimiento(a, d, lista[c.rng.randi_range(0, lista.size()- 1)], -1, false)
			return true
		"sleep_talk":
			if a.pokemon.estado!= "dor":
				return _fallo(c)
			var opciones:= a.movimientos().filter(func(m): return m.id!= "sleep_talk" and not m.tiene("nosleeptalk") and not DOS_TURNOS.has(m.id) and m.id!= "bide")
			if opciones.is_empty():
				return _fallo(c)
			c.usar_movimiento(a, d, opciones[c.rng.randi_range(0, opciones.size()- 1)], -1, false)
			return true
		"assist":
			var lista_a: Array[Movimiento]= []
			var equipo:= c.equipo_j if a== c.j else c.equipo_r
			for o in equipo:
				if o== a.pokemon:
					continue
				for m in o.movimientos:
					if not m.tiene("noassist") and m.id!= "assist":
						lista_a.append(m)
			if lista_a.is_empty():
				return _fallo(c)
			c.usar_movimiento(a, d, lista_a[c.rng.randi_range(0, lista_a.size()- 1)], -1, false)
			return true
		"copycat":
			var ult: Movimiento= c.ultimo_mov_combate
			if ult== null or ult== mov or ult.tiene("failcopycat"):
				return _fallo(c)
			c.usar_movimiento(a, d, ult, -1, false)
			return true
		"mirror_move":
			var um: Movimiento= d.ultimo_mov
			if um== null or not um.tiene("mirror"):
				return _fallo(c)
			c.usar_movimiento(a, d, um, -1, false)
			return true
		"nature_power":
			var nm:= BaseDatos.movimiento(NATURALEZA.get(c.terreno, "tri_attack"))
			c._texto("¡%s se convirtió en %s!" % [mov.nombre, nm.nombre])
			c.usar_movimiento(a, d, nm, -1, false)
			return true
		"me_first":
			var em2: Movimiento= c.elegido[c._lado(d)]
			if d.actuo_turno or em2== null or em2.categoria== "estado" or em2.tiene("failmefirst"):
				return _fallo(c)
			a.poner("me_first")
			c.usar_movimiento(a, d, em2, -1, false)
			a.quitar("me_first")
			return true
		"future_sight", "doom_desire":
			for f in c.futuros:
				if f["lado"]== c._lado(d):
					return _fallo(c)
			c.futuros.append({"lado": c._lado(d), "turnos": 3, "mov": mov, "atacante": a})
			c._texto("¡%s previó un ataque!" % _t(c, a) if mov.id== "future_sight" else "¡%s eligió Deseo Oculto como destino!" % _t(c, a))
			return true
		"teleport":
			if not c.salvaje:
				return _fallo(c)
			c._texto("¡%s huyó del combate!" % _t(c, a))
			c._terminar("huida")
			return true
	if id in BLOQUEO and a.mov_bloqueado!= mov:
		a.mov_bloqueado= mov
		a.turnos_bloqueo= c.rng.randi_range(2, 3)
		a.poner("bloqueo_iniciado", true)
	if id in RODAR and a.mov_bloqueado!= mov:
		a.mov_bloqueado= mov
		a.turnos_bloqueo =5
		a.poner("rodar", 0)
		a.poner("bloqueo_iniciado", true)
	if id== "uproar" and a.mov_bloqueado!= mov:
		a.mov_bloqueado= mov
		a.turnos_bloqueo= 3
		a.poner("bloqueo_iniciado", true)
		c._texto("¡%s armó un alboroto!" % _t(c, a))
		if d.pokemon.estado== "dor":
			c._poner_estado(d, "")
			c._texto("¡%s se despertó por el alboroto!" % _t(c, d))
	if id== "fury_cutter":
		a.poner("corte_furia", mini(int(a.valor("corte_furia", 0))+ 1, 4))
	elif a.tiene("corte_furia"):
		a.quitar("corte_furia")
	if id== "echoed_voice":
		var n:= 1
		if not c.eco.is_empty() and int(c.eco["turno"])== c.turnos- 1:
			n= mini(int(c.eco["n"])+ 1, 5)
		elif not c.eco.is_empty() and int(c.eco["turno"])== c.turnos:
			n= int(c.eco["n"])
		c.eco= {"turno": c.turnos, "n": n}
	return false

static func _todos_movimientos() -> Array[Movimiento]:
	var lista: Array[Movimiento]= []
	for id in BaseDatos.ids(BaseDatos.MOVIMIENTOS):
		var m:= BaseDatos.movimiento(id)
		if m!= null:
			lista.append(m)
	return lista

static func lo_frena_sustituto(mov: Movimiento) -> bool:
	return not atraviesa_sustituto(mov)

static func atraviesa_sustituto(mov: Movimiento) -> bool:
	if mov.tiene("sound") and not mov.id in ["roar", "perish_song", "heal_bell"]:
		return false
	return mov.tiene("bypasssub")

static func tipo(c: LogicaCombate, a: Luchador, mov: Movimiento) -> String:
	match mov.id:
		"hidden_power":
			return TIPOS_PODER_OCULTO[_indice_oculto(a.pokemon)]
		"weather_ball":
			match c.clima_activo():
				"sol":
					return "fuego"
				"lluvia":
					return "agua"
				"arena":
					return "roca"
				"granizo":
					return "hielo"
		"judgment", "techno_blast":
			return "normal"
		"natural_gift":
			return "normal"
	return mov.tipo

static func _indice_oculto(p: PokemonInstancia) -> int:
	var orden:= ["ps", "ataque", "defensa", "velocidad", "at_esp", "def_esp"]
	var suma:= 0
	for k in orden.size():
		suma+= (int(p.ivs.get(orden[k], 0))& 1)<< k
	return floori(suma* 15.0/ 63.0)

static func _poder_oculto(p: PokemonInstancia) -> int:
	var orden:= ["ps", "ataque", "defensa", "velocidad", "at_esp", "def_esp"]
	var suma:= 0
	for k in orden.size():
		suma+= ((int(p.ivs.get(orden[k], 0))>> 1)& 1)<< k
	return floori(suma* 40.0/ 63.0)+ 30

static func danio_fijo(c: LogicaCombate, a: Luchador, d: Luchador, mov: Movimiento) -> int:
	match mov.id:
		"seismic_toss", "night_shade":
			return a.pokemon.nivel
		"dragon_rage":
			return 40
		"sonic_boom":
			return 20
		"psywave":
			return maxi(1, floori(a.pokemon.nivel* (c.rng.randi_range(0, 100)+ 50)/ 100.0))
		"super_fang":
			return maxi(1, floori(d.pokemon.ps_actuales/ 2.0))
		"endeavor":
			return maxi(0, d.pokemon.ps_actuales- a.pokemon.ps_actuales)
		"counter", "mirror_coat":
			return int(a.danio_recibido.get("cantidad", 0))* 2
		"metal_burst":
			return floori(int(a.danio_recibido.get("cantidad", 0))* 1.5)
		"bide":
			var bd: Dictionary= a.valor("bide", {})
			return int(bd.get("danio", 0))* 2
		"final_gambit":
			return a.pokemon.ps_actuales
	if mov.meta== "ohko":
		return d.pokemon.ps_actuales
	return -1

static func alcanza_invulnerable(mov: Movimiento, estado: String) -> bool:
	match estado:
		"vuela":
			return mov.id in ["gust", "twister", "thunder", "sky_uppercut", "hurricane", "smack_down"]
		"excava":
			return mov.id in ["earthquake", "magnitude", "fissure"]
		"buceo":
			return mov.id in ["surf", "whirlpool"]
	return false

static func golpes(c: LogicaCombate, a: Luchador, mov: Movimiento) -> int:
	if mov.id== "beat_up":
		var equipo:= c.equipo_j if a== c.j else c.equipo_r
		var n:= 0
		for o in equipo:
			if not o.esta_debilitado() and o.estado== "":
				n+= 1
		return maxi(1, n)
	if mov.golpes_max<= 1:
		return 1
	if mov.golpes_min== mov.golpes_max:
		return mov.golpes_max
	if c.activa(a, "skill_link"):
		return mov.golpes_max
	var p:= c.rng.randi_range(1, 6)
	return 2 if p<= 2 else (3 if p<= 4 else (4 if p== 5 else 5))

static func tiene_secundario(mov: Movimiento) -> bool:
	if mov.prob_estado> 0 or mov.prob_retroceso> 0:
		return true
	if mov.id in ["tri_attack", "secret_power", "relic_song"]:
		return true
	if not mov.cambios_stats.is_empty():
		if mov.meta== "damage-lower":
			return true
		if mov.meta== "damage-raise":
			for s in mov.cambios_stats:
				if int(mov.cambios_stats[s])< 0:
					return false
			return true
	return false

static func es_fisico(mov: Movimiento) -> bool:
	return mov.categoria== "fisico"

static func poder(c: LogicaCombate, a: Luchador, d: Luchador, mov: Movimiento) -> int:
	var pa:= a.pokemon
	var pd:= d.pokemon
	var p:= mov.poder
	match mov.id:
		"reversal", "flail":
			var p48:= floori(48.0* pa.ps_actuales/ pa.ps_max())
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
		"wring_out", "crush_grip":
			return maxi(1, floori(120.0* pd.ps_actuales/ pd.ps_max()))
		"eruption", "water_spout":
			return maxi(1, floori(150.0* pa.ps_actuales/ pa.ps_max()))
		"low_kick", "grass_knot":
			var kg:= d.peso()
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
		"heavy_slam", "heat_crash":
			var rel:= a.peso()/ maxf(0.1, d.peso())
			if rel>= 5.0:
				return 120
			if rel>= 4.0:
				return 100
			if rel>= 3.0:
				return 80
			if rel>= 2.0:
				return 60
			return 40
		"gyro_ball":
			return mini(150, floori(25.0* c.velocidad_de(d)/ maxi(1, c.velocidad_de(a)))+ 1)
		"electro_ball":
			var v:= floori(c.velocidad_de(a)/ maxf(1.0, c.velocidad_de(d)))
			return 150 if v>= 4 else (120 if v== 3 else (80 if v== 2 else (60 if v== 1 else 40)))
		"acrobatics":
			return p* 2 if pa.objeto== "" else p
		"assurance":
			return p* 2 if d.herido_turno else p
		"brine":
			return p* 2 if pd.ps_actuales* 2<= pd.ps_max() else p
		"facade":
			return p* 2 if pa.estado in ["que", "env", "tox", "par"] else p
		"hex":
			return p* 2 if pd.estado!= "" else p
		"venoshock":
			return p* 2 if pd.estado in ["env", "tox"] else p
		"payback":
			return p* 2 if d.actuo_turno else p
		"retaliate":
			return p* 2 if c.represalia_lista(a) else p
		"revenge", "avalanche":
			return p* 2 if a.herido_turno else p
		"punishment":
			return mini(200, 60+ 20* c._subidas(d))
		"stored_power":
			return 20+ 20* c._subidas(a)
		"magnitude":
			var tirada:= c.rng.randi_range(1, 100)
			var acum:= 0
			for fila in LogicaCombate.MAGNITUDES:
				acum+= fila[2]
				if tirada<= acum:
					c._texto("¡Magnitud %d!" % fila[0])
					return fila[1]* (2 if d.invulnerable== "excava" else 1)
			return 70
		"earthquake":
			return p* 2 if d.invulnerable== "excava" else p
		"surf", "whirlpool":
			return p* 2 if d.invulnerable== "buceo" else p
		"gust", "twister":
			return p* 2 if d.invulnerable== "vuela" else p
		"stomp", "steamroller":
			return p* 2 if d.tiene("minimizado") else p
		"smelling_salts":
			return p* 2 if pd.estado== "par" else p
		"wake_up_slap":
			return p* 2 if pd.estado== "dor" else p
		"weather_ball":
			return p* 2 if c.clima_activo()!= "" else p
		"solar_beam":
			return floori(p/ 2.0) if c.clima_activo() in ["lluvia", "arena", "granizo"] else p
		"return":
			return maxi(1, floori(pa.amistad* 2.0/ 5.0))
		"frustration":
			return maxi(1, floori((255- pa.amistad)* 2.0/ 5.0))
		"hidden_power":
			return _poder_oculto(pa)
		"present":
			return int(a.valor("regalo", 40))
		"trump_card":
			var k:= a.movimientos().find(mov)
			var resto:= int(a.pp()[k]) if k>= 0 else 4
			return 200 if resto== 0 else (80 if resto== 1 else (60 if resto== 2 else (50 if resto== 3 else 40)))
		"fury_cutter":
			return mini(160, p* int(pow(2, int(a.valor("corte_furia", 1))- 1)))
		"echoed_voice":
			return mini(200, 40* int(c.eco.get("n", 1)))
		"rollout", "ice_ball":
			var n:= int(a.valor("rodar", 0))
			return p* int(pow(2, n))* (2 if a.tiene("rizo") else 1)
		"pursuit":
			return p* 2 if a.tiene("persecucion") else p
		"spit_up":
			return 100* int(a.valor("reserva", 1))
		"triple_kick":
			return 10* (int(a.valor("golpe_n", 0))+ 1)
		"beat_up":
			var equipo:= c.equipo_j if a== c.j else c.equipo_r
			var vivos:= equipo.filter(func(o): return not o.esta_debilitado() and o.estado== "")
			var k2:= int(a.valor("golpe_n", 0))
			var base: int= vivos[k2].especie.ataque if k2< vivos.size() else pa.especie.ataque
			return floori(base/ 10.0)+ 5
		"fling":
			return 30
		"natural_gift":
			return 60
		"fusion_flare", "fusion_bolt":
			var ult: Movimiento= c.ultimo_mov_combate
			if ult!= null and ult!= mov and ((mov.id== "fusion_flare" and ult.id== "fusion_bolt") or (mov.id== "fusion_bolt" and ult.id== "fusion_flare")) and d.actuo_turno:
				return p* 2
		"round":
			return p
	if a.tiene("me_first"):
		return floori(p* 1.5)
	return p

static func estado_util(c: LogicaCombate, a: Luchador, d: Luchador, mov: Movimiento) -> bool:
	match mov.id:
		"leech_seed":
			return not d.tiene("drenadoras") and not "planta" in d.tipos()
		"spikes":
			return int(c.trampas[c._lado(d)]["puas"])< 3
		"toxic_spikes":
			return int(c.trampas[c._lado(d)]["puas_toxicas"])< 2
		"stealth_rock":
			return not c.trampas[c._lado(d)]["rocas"]
		"reflect":
			return int(c.trampas[c._lado(a)]["reflejo"])== 0
		"light_screen":
			return int(c.trampas[c._lado(a)]["pantalla_luz"])== 0
		"substitute":
			return a.sustituto== 0 and a.pokemon.ps_actuales* 4> a.pokemon.ps_max()
		"taunt":
			return not d.tiene("mofa")
		"confuse_ray", "supersonic", "sweet_kiss", "teeter_dance":
			return d.confusion== 0
		"protect", "detect", "endure":
			return a.racha_proteccion== 0
		"rest":
			return a.pokemon.ps_actuales< a.pokemon.ps_max()
		"after_you", "ally_switch", "helping_hand", "follow_me", "rage_powder", "quash", "splash":
			return false
		"trick_room":
			return c.espacio_raro== 0
		"gravity":
			return c.gravedad== 0
		"wonder_room":
			return c.zona_extrana== 0
		"magic_room":
			return c.zona_magica== 0
		"rain_dance", "sunny_day", "sandstorm", "hail":
			return c.clima!= {"rain_dance": "lluvia", "sunny_day": "sol", "sandstorm": "arena", "hail": "granizo"}[mov.id]
		"tailwind":
			return int(c.trampas[c._lado(a)]["viento_afin"])== 0
		"safeguard":
			return int(c.trampas[c._lado(a)]["velo_sagrado"])== 0
		"mist":
			return int(c.trampas[c._lado(a)]["neblina"])== 0
	if mov.curacion> 0:
		return a.pokemon.ps_actuales* 2< a.pokemon.ps_max()
	if LogicaCombate.ESTADOS.has(mov.estado):
		return c._estado_sirve(a, d, mov)
	if not mov.cambios_stats.is_empty():
		var obj:= a if mov.objetivo in LogicaCombate.OBJETIVO_PROPIO else d
		for s in mov.cambios_stats:
			var cambio:= int(mov.cambios_stats[s])
			if (cambio> 0 and int(obj.etapas.get(s, 0))< 6) or (cambio< 0 and int(obj.etapas.get(s, 0))> -6):
				return true
		return false
	return true

static func _proteccion(c: LogicaCombate, a: Luchador) -> bool:
	if c.rng.randf()>= 1.0/ pow(2.0, a.racha_proteccion):
		a.racha_proteccion= 0
		_fallo(c)
		return false
	a.racha_proteccion+= 1
	return true

static func estado_unico(c: LogicaCombate, a: Luchador, d: Luchador, mov: Movimiento) -> bool:
	var ta:= _t(c, a)
	var td:= _t(c, d)
	var lado_a: Dictionary= c.trampas[c._lado(a)]
	var lado_d: Dictionary= c.trampas[c._lado(d)]
	match mov.id:
		"protect", "detect":
			if c.cola.is_empty():
				a.racha_proteccion= 0
				return _fallo(c)
			if _proteccion(c, a):
				a.protegido= true
				c._texto("¡%s se está protegiendo!" % ta)
			return true
		"endure":
			if c.cola.is_empty():
				a.racha_proteccion= 0
				return _fallo(c)
			if _proteccion(c, a):
				a.poner("aguante")
				c._texto("¡%s se prepara para aguantar!" % ta)
			return true
		"quick_guard", "wide_guard":
			if c.cola.is_empty():
				return _fallo(c)
			if _proteccion(c, a):
				a.poner("guardia_rapida" if mov.id== "quick_guard" else "guardia_amplia")
				c._texto("¡%s protege a su equipo!" % ta)
			return true
		"after_you", "ally_switch", "helping_hand", "follow_me", "rage_powder", "quash":
			return _fallo(c)
		"splash":
			c._texto("¡Pero no pasó nada!")
			return true
		"trick_room":
			if c.espacio_raro> 0:
				c.espacio_raro= 0
				c._texto("¡Las dimensiones retorcidas volvieron a la normalidad!")
			else:
				c.espacio_raro =5
				c._texto("¡%s retorció las dimensiones!" % ta)
			return true
		"gravity":
			if c.gravedad> 0:
				return _fallo(c)
			c.gravedad= 5
			c._texto("¡La gravedad se intensificó!")
			for l in [a, d]:
				if l.invulnerable== "vuela":
					l.invulnerable= ""
					l.cargando= null
					c._ev({"tipo": "oculto", "lado": c._lado(l), "oculto": false})
				l.quitar("levitar")
				l.quitar("telequinesis")
			return true
		"wonder_room":
			c.zona_extrana= 0 if c.zona_extrana> 0 else 5
			c._texto("¡Se creó una zona extraña que intercambia las defensas!" if c.zona_extrana> 0 else "¡La zona extraña desapareció!")
			return true
		"magic_room":
			c.zona_magica= 0 if c.zona_magica> 0 else 5
			c._texto("¡Se creó una zona mágica en la que los objetos no tienen efecto!" if c.zona_magica> 0 else "¡La zona mágica desapareció!")
			return true
		"rain_dance", "sunny_day", "sandstorm", "hail":
			var cl: String= {"rain_dance": "lluvia", "sunny_day": "sol", "sandstorm": "arena", "hail": "granizo"}[mov.id]
			if c.clima== cl:
				return _fallo(c)
			poner_clima(c, cl, 5)
			return true
		"mud_sport", "water_sport":
			var k:= "chapoteo" if mov.id== "mud_sport" else "hidrochorro"
			lado_a[k]= true
			c._texto("¡Se debilitaron los ataques de tipo %s!" % ("Eléctrico" if mov.id== "mud_sport" else "Fuego"))
			return true
		"haze":
			for l in [a, d]:
				for s in l.etapas:
					l.etapas[s]= 0
			c._ev({"tipo": "etapas_reset"})
			c._texto("¡Se eliminaron todos los cambios en las estadísticas!")
			return true
		"reflect", "light_screen", "safeguard", "mist", "lucky_chant", "tailwind":
			var clave: String= {"reflect": "reflejo", "light_screen": "pantalla_luz", "safeguard": "velo_sagrado", "mist": "neblina", "lucky_chant": "conjuro", "tailwind": "viento_afin"}[mov.id]
			if int(lado_a[clave])> 0:
				return _fallo(c)
			lado_a[clave]= 4 if mov.id== "tailwind" else 5
			var eq:= c._equipo_de(a)
			var al:= "a tu equipo" if a== c.j else "al equipo rival"
			match mov.id:
				"reflect":
					c._texto("¡Reflejo aumentó la Defensa %s!" % eq)
				"light_screen":
					c._texto("¡Pantalla de Luz aumentó la Defensa Especial %s!" % eq)
				"safeguard":
					c._texto("¡%s quedó protegido por Velo Sagrado!" % _cap_equipo(c, a))
				"mist":
					c._texto("¡%s quedó envuelto en neblina!" % _cap_equipo(c, a))
				"lucky_chant":
					c._texto("¡Conjuro protege %s de los golpes críticos!" % al)
				"tailwind":
					c._texto("¡Sopla un viento afín detrás %s!" % eq)
			return true
		"spikes":
			if int(lado_d["puas"])>= 3:
				return _fallo(c)
			lado_d["puas"]= int(lado_d["puas"])+ 1
			c._texto("¡Se esparcieron púas alrededor de los pies %s!" % c._equipo_de(d))
			return true
		"toxic_spikes":
			if int(lado_d["puas_toxicas"])>= 2:
				return _fallo(c)
			lado_d["puas_toxicas"]= int(lado_d["puas_toxicas"])+ 1
			c._texto("¡Se esparcieron púas tóxicas alrededor de los pies %s!" % c._equipo_de(d))
			return true
		"stealth_rock":
			if lado_d["rocas"]:
				return _fallo(c)
			lado_d["rocas"] =true
			c._texto("¡Rocas puntiagudas flotan alrededor %s!" % c._equipo_de(d))
			return true
		"defog":
			c.cambiar_etapa_desde(a, d, "evasion", -1, true)
			for k2 in ["reflejo", "pantalla_luz", "velo_sagrado", "neblina"]:
				lado_d[k2]= 0
			lado_d["puas"]= 0
			lado_d["puas_toxicas"]= 0
			lado_d["rocas"]= false
			return true
		"roar", "whirlwind":
			c._arrastrar(a, d)
			return true
		"baton_pass":
			c._relevo(a)
			return true
		"soak":
			if d.tipos()== ["agua"] or c.activa(d, "multitype"):
				return _fallo(c)
			d.tipos_forzados= ["agua"]
			c._ev({"tipo": "tipos", "lado": c._lado(d), "tipos": d.tipos()})
			c._texto("¡%s ahora es de tipo Agua!" % td)
			return true
		"charge":
			a.cargado= 2
			c._texto("¡%s comenzó a cargarse de energía!" % ta)
			c._cambiar_etapa(a, "def_esp", 1, false)
			return true
		"focus_energy":
			if a.critico_extra>= 2:
				return _fallo(c)
			a.critico_extra= 2
			c._texto("¡%s se está preparando para luchar!" % ta)
			return true
		"leech_seed":
			if "planta" in d.tipos():
				c._texto("No afecta %s..." % c._a(d))
				return true
			if d.tiene("drenadoras"):
				return _fallo(c)
			d.poner("drenadoras")
			c._texto("¡%s fue infectado!" % td)
			return true
		"substitute":
			var cuarto:= floori(a.pokemon.ps_max()/ 4.0)
			if a.sustituto> 0:
				c._texto("¡%s ya tiene un sustituto!" % ta)
				return true
			if a.pokemon.ps_actuales<= cuarto or cuarto<= 0:
				c._texto("¡No le quedan PS suficientes para crear un sustituto!")
				return true
			c._herir(a, cuarto)
			a.sustituto= cuarto
			c._ev({"tipo": "sustituto", "lado": c._lado(a), "activo": true})
			c._texto("¡%s creó un sustituto!" % ta)
			return true
		"rest":
			if a.pokemon.ps_actuales>= a.pokemon.ps_max():
				c._texto("¡Los PS %s están al máximo!" % c._de(a))
				return true
			if c.activa(a, "insomnia") or c.activa(a, "vital_spirit") or c._hay_alboroto():
				return _fallo(c)
			c._poner_estado(a, "dor")
			a.turnos_sueno= 3
			c._texto("¡%s se durmió y recuperó salud!" % ta)
			c._curar(a, a.pokemon.ps_max())
			return true
		"refresh":
			if not a.pokemon.estado in ["que", "env", "tox", "par"]:
				return _fallo(c)
			c._poner_estado(a, "")
			c._texto("¡%s se curó de su problema de estado!" % ta)
			return true
		"heal_bell", "aromatherapy":
			var equipo:= c.equipo_j if a== c.j else c.equipo_r
			for o in equipo:
				o.estado= ""
			c._poner_estado(a, "")
			c._texto("¡Se curaron los problemas de estado del equipo!")
			return true
		"psycho_shift":
			if a.pokemon.estado== "" or d.pokemon.estado!= "":
				return _fallo(c)
			var est:= a.pokemon.estado
			if c.aplicar_estado_desde(a, d, est, true):
				c._poner_estado(a, "")
			return true
		"belly_drum":
			var mitad:= floori(a.pokemon.ps_max()/ 2.0)
			if a.pokemon.ps_actuales<= mitad or int(a.etapas["ataque"])>= 6:
				return _fallo(c)
			c._herir(a, mitad)
			a.etapas["ataque"]= 6
			c._ev({"tipo": "etapa", "lado": c._lado(a), "stat": "ataque", "cambio": 6})
			c._texto("¡%s redujo sus PS y maximizó su Ataque!" % ta)
			return true
		"curse":
			if "fantasma" in a.tipos():
				if d.tiene("maldito"):
					return _fallo(c)
				c._herir(a, maxi(1, floori(a.pokemon.ps_max()/ 2.0)))
				d.poner("maldito")
				c._texto("¡%s sacrificó PS y lanzó una maldición sobre %s!" % [ta, c.nombre_de(d)])
			else:
				c._cambiar_etapa(a, "velocidad", -1, true)
				c._cambiar_etapa(a, "ataque", 1, true)
				c._cambiar_etapa(a, "defensa", 1, true)
			return true
		"growth":
			var n:= 2 if c.clima_activo()== "sol" else 1
			c._cambiar_etapa(a, "ataque", n, true)
			c._cambiar_etapa(a, "at_esp", n, true)
			return true
		"defense_curl":
			c._cambiar_etapa(a, "defensa", 1, true)
			a.poner("rizo")
			return true
		"minimize":
			c._cambiar_etapa(a, "evasion", 2, true)
			a.poner("minimizado")
			return true
		"autotomize":
			if c._cambiar_etapa(a, "velocidad", 2, true):
				a.peso_extra-= 100.0
				c._texto("¡%s se volvió más liviano!" % ta)
			return true
		"stockpile":
			var res:= int(a.valor("reserva", 0))
			if res>= 3:
				return _fallo(c)
			a.poner("reserva", res+ 1)
			c._texto("¡%s reservó %d!" % [ta, res+ 1])
			c._cambiar_etapa(a, "defensa", 1, false)
			c._cambiar_etapa(a, "def_esp", 1, false)
			return true
		"swallow":
			var res2:= int(a.valor("reserva", 0))
			if res2<= 0:
				return _fallo(c)
			var frac:= 0.25 if res2== 1 else (0.5 if res2== 2 else 1.0)
			c._curar(a, floori(a.pokemon.ps_max()* frac))
			c._texto("¡%s recuperó salud!" % ta)
			_vaciar_reserva(c, a)
			return true
		"moonlight", "morning_sun", "synthesis":
			if a.pokemon.ps_actuales>= a.pokemon.ps_max():
				c._texto("¡Los PS %s están al máximo!" % c._de(a))
				return true
			var cl2:= c.clima_activo()
			var f2:= 2.0/ 3.0 if cl2== "sol" else (0.5 if cl2== "" else 0.25)
			c._curar(a, floori(a.pokemon.ps_max()* f2))
			c._texto("¡%s recuperó salud!" % ta)
			return true
		"roost":
			if a.pokemon.ps_actuales>= a.pokemon.ps_max():
				c._texto("¡Los PS %s están al máximo!" % c._de(a))
				return true
			c._curar(a, floori(a.pokemon.ps_max()/ 2.0))
			c._texto("¡%s recuperó salud!" % ta)
			if "volador" in a.tipos():
				a.poner("respiro")
			return true
		"heal_pulse":
			if d.pokemon.ps_actuales>= d.pokemon.ps_max():
				return _fallo(c)
			c._curar(d, floori(d.pokemon.ps_max()/ 2.0))
			c._texto("¡%s recuperó salud!" % td)
			return true
		"wish":
			if int(lado_a["deseo"])> 0:
				return _fallo(c)
			lado_a["deseo"]= 2
			lado_a["deseo_ps"]= floori(a.pokemon.ps_max()/ 2.0)
			c._texto("¡%s pidió un deseo!" % ta)
			return true
		"healing_wish", "lunar_dance":
			var equipo2:= c.equipo_j if a== c.j else c.equipo_r
			var quedan:= equipo2.filter(func(o): return o!= a.pokemon and not o.esta_debilitado())
			if quedan.is_empty():
				return _fallo(c)
			lado_a["deseo_cura"]= "lunar" if mov.id== "lunar_dance" else "cura"
			a.poner("explota")
			return true
		"memento":
			c.cambiar_etapa_desde(a, d, "ataque", -2, true)
			c.cambiar_etapa_desde(a, d, "at_esp", -2, true)
			a.poner("explota")
			return true
		"pain_split":
			var media:= floori((a.pokemon.ps_actuales+ d.pokemon.ps_actuales)/ 2.0)
			for l: Luchador in [a, d]:
				var antes: int= l.pokemon.ps_actuales
				l.pokemon.ps_actuales= mini(media, l.pokemon.ps_max())
				c._ev_ps(l, antes)
			c._texto("¡Los combatientes compartieron su dolor!")
			return true
		"disable":
			if d.ultimo_mov== null or d.tiene("anulado") or d.ultimo_mov.id== "struggle":
				return _fallo(c)
			d.poner("anulado", {"mov": d.ultimo_mov, "turnos": 4})
			c._texto("¡Se anuló %s %s!" % [d.ultimo_mov.nombre, c._de(d)])
			return true
		"encore":
			var um: Movimiento= d.ultimo_mov
			if um== null or d.tiene("otra_vez") or um.tiene("failencore") or um.id in ["encore", "transform", "mimic", "mirror_move", "sketch", "struggle"]:
				return _fallo(c)
			d.poner("otra_vez", {"mov": um, "turnos": 3})
			c._texto("¡%s sufre los efectos de Otra Vez!" % td)
			return true
		"taunt":
			if d.tiene("mofa"):
				return _fallo(c)
			d.poner("mofa", 3)
			c._texto("¡%s cayó en la mofa!" % td)
			return true
		"torment":
			if d.tiene("tormento"):
				return _fallo(c)
			d.poner("tormento")
			c._texto("¡%s sufre tormento!" % td)
			return true
		"imprison":
			if a.tiene("cerrojo"):
				return _fallo(c)
			a.poner("cerrojo")
			c._texto("¡%s selló los movimientos que conoce!" % ta)
			return true
		"embargo":
			if d.tiene("embargo"):
				return _fallo(c)
			d.poner("embargo", 5)
			c._texto("¡%s no puede usar objetos!" % td)
			return true
		"heal_block":
			if d.tiene("anticura"):
				return _fallo(c)
			d.poner("anticura", 5)
			c._texto("¡%s no puede curarse!" % td)
			return true
		"foresight", "odor_sleuth":
			d.poner("identificado")
			d.etapas["evasion"]= mini(int(d.etapas["evasion"]), 0)
			c._texto("¡%s fue identificado!" % td)
			return true
		"miracle_eye":
			d.poner("ojo_milagro")
			c._texto("¡%s fue identificado!" % td)
			return true
		"lock_on", "mind_reader":
			a.poner("fijado")
			c._texto("¡%s apuntó a %s!" % [ta, c.nombre_de(d)])
			return true
		"mean_look", "block", "spider_web":
			if d.tiene("sin_escape"):
				return _fallo(c)
			d.poner("sin_escape")
			c._texto("¡%s ya no puede escapar!" % td)
			return true
		"ingrain":
			if a.tiene("arraigo"):
				return _fallo(c)
			a.poner("arraigo")
			c._texto("¡%s echó raíces!" % ta)
			return true
		"aqua_ring":
			if a.tiene("acua_aro"):
				return _fallo(c)
			a.poner("acua_aro")
			c._texto("¡%s se rodeó de un velo de agua!" % ta)
			return true
		"magnet_rise":
			if a.tiene("levitar") or a.tiene("arraigo") or c.gravedad> 0:
				return _fallo(c)
			a.poner("levitar", 5)
			c._texto("¡%s levita gracias al electromagnetismo!" % ta)
			return true
		"telekinesis":
			if d.tiene("telequinesis") or c.gravedad> 0 or d.tiene("arraigo"):
				return _fallo(c)
			d.poner("telequinesis", 3)
			c._texto("¡%s fue lanzado por los aires!" % td)
			return true
		"nightmare":
			if d.pokemon.estado!= "dor" or d.tiene("pesadilla"):
				return _fallo(c)
			d.poner("pesadilla")
			c._texto("¡%s empezó a tener pesadillas!" % td)
			return true
		"yawn":
			if d.pokemon.estado!= "" or d.tiene("bostezo") or int(lado_d["velo_sagrado"])> 0 or c.activa(d, "insomnia") or c.activa(d, "vital_spirit"):
				return _fallo(c)
			d.poner("bostezo", 2)
			c._texto("¡%s hizo bostezar a %s!" % [ta, c.nombre_de(d)])
			return true
		"perish_song":
			for l in [a, d]:
				if not l.tiene("canto_mortal") and not c.habilidad_def(a, l, "soundproof"):
					l.poner("canto_mortal", 4)
			c._texto("¡Todos los Pokémon que oyeron la canción caerán en tres turnos!")
			return true
		"attract":
			if not _genero_opuesto(a, d) or d.tiene("enamorado"):
				return _fallo(c)
			if c.habilidad_def(a, d, "oblivious"):
				c.anunciar_habilidad(d)
				c._texto("¡%s no se ve afectado!" % td)
				return true
			d.poner("enamorado", a)
			c._texto("¡%s se enamoró!" % td)
			return true
		"captivate":
			if not _genero_opuesto(a, d) or c.habilidad_def(a, d, "oblivious"):
				return _fallo(c)
			c.cambiar_etapa_desde(a, d, "at_esp", -2, true)
			return true
		"destiny_bond":
			a.poner("mismo_destino")
			c._texto("¡%s quiere llevarse al rival con él!" % ta)
			return true
		"grudge":
			a.poner("rencor")
			c._texto("¡%s quiere que el rival sienta su rencor!" % ta)
			return true
		"spite":
			var um2: Movimiento= d.ultimo_mov
			var k3:= d.movimientos().find(um2) if um2!= null else -1
			if k3< 0 or d.pp()[k3]<= 0:
				return _fallo(c)
			var quita:= mini(4, d.pp()[k3])
			d.pp()[k3]-= quita
			c._texto("¡%s perdió %d PP de %s!" % [td, quita, um2.nombre])
			return true
		"magic_coat":
			a.poner("rebote")
			c._texto("¡%s se envolvió en una capa mágica!" % ta)
			return true
		"snatch":
			a.poner("robo")
			c._texto("¡%s espera el movimiento del rival!" % ta)
			return true
		"psych_up":
			for s in d.etapas:
				a.etapas[s]= d.etapas[s]
			c._ev({"tipo": "etapas_reset"})
			c._texto("¡%s copió los cambios de estadísticas %s!" % [ta, c._de(d)])
			return true
		"guard_swap", "power_swap", "heart_swap":
			var stats: Array= ["defensa", "def_esp"] if mov.id== "guard_swap" else (["ataque", "at_esp"] if mov.id== "power_swap" else Luchador.ETAPAS)
			for s in stats:
				var tmp: int= a.etapas[s]
				a.etapas[s]= d.etapas[s]
				d.etapas[s]= tmp
			c._texto("¡%s intercambió cambios de estadísticas con el rival!" % ta)
			return true
		"guard_split", "power_split":
			var st: Array= ["defensa", "def_esp"] if mov.id== "guard_split" else ["ataque", "at_esp"]
			for s in st:
				var media2:= floori((a.stat_base_batalla(s)+ d.stat_base_batalla(s))/ 2.0)
				a.stats_transformado[s]= media2
				d.stats_transformado[s]= media2
			c._texto("¡%s compartió su %s con el rival!" % [ta, "defensa" if mov.id== "guard_split" else "fuerza"])
			return true
		"power_trick":
			var at:= a.stat_base_batalla("ataque")
			var df:= a.stat_base_batalla("defensa")
			a.stats_transformado["ataque"]= df
			a.stats_transformado["defensa"]= at
			c._texto("¡%s intercambió su Ataque y su Defensa!" % ta)
			return true
		"acupressure":
			var posibles:= Luchador.ETAPAS.filter(func(s): return int(a.etapas[s])< 6)
			if posibles.is_empty():
				return _fallo(c)
			c._cambiar_etapa(a, posibles[c.rng.randi_range(0, posibles.size()- 1)], 2, true)
			return true
		"shell_smash":
			c._cambiar_etapa(a, "defensa", -1, false)
			c._cambiar_etapa(a, "def_esp", -1, false)
			c._cambiar_etapa(a, "ataque", 2, true)
			c._cambiar_etapa(a, "at_esp", 2, true)
			c._cambiar_etapa(a, "velocidad", 2, true)
			return true
		"camouflage":
			var t: String= CAMUFLAJE.get(c.terreno, "normal")
			if a.tipos()== [t]:
				return _fallo(c)
			a.tipos_forzados= [t]
			c._ev({"tipo": "tipos", "lado": c._lado(a), "tipos": a.tipos()})
			c._texto("¡%s cambió a tipo %s!" % [ta, Tipos.nombre(t)])
			return true
		"conversion":
			for m in a.movimientos():
				if m.tipo!= "" and not m.tipo in a.tipos():
					a.tipos_forzados= [m.tipo]
					c._ev({"tipo": "tipos", "lado": c._lado(a), "tipos": a.tipos()})
					c._texto("¡%s cambió a tipo %s!" % [ta, Tipos.nombre(m.tipo)])
					return true
			return _fallo(c)
		"conversion_2":
			var um3: Movimiento= d.ultimo_mov
			if um3== null or um3.tipo== "":
				return _fallo(c)
			var resisten:= TIPOS_PODER_OCULTO.duplicate()
			resisten.append("normal")
			resisten= resisten.filter(func(t2): return Tipos.multiplicador(um3.tipo, t2)< 1.0 and not t2 in a.tipos())
			if resisten.is_empty():
				return _fallo(c)
			var nt: String= resisten[c.rng.randi_range(0, resisten.size()- 1)]
			a.tipos_forzados= [nt]
			c._ev({"tipo": "tipos", "lado": c._lado(a), "tipos": a.tipos()})
			c._texto("¡%s cambió a tipo %s!" % [ta, Tipos.nombre(nt)])
			return true
		"reflect_type":
			a.tipos_forzados= d.tipos().duplicate()
			c._ev({"tipo": "tipos", "lado": c._lado(a), "tipos": a.tipos()})
			c._texto("¡%s adoptó los tipos %s!" % [ta, c._de(d)])
			return true
		"simple_beam", "worry_seed":
			var nueva:= "simple" if mov.id== "simple_beam" else "insomnia"
			if d.habilidad in ["multitype", "truant", nueva]:
				return _fallo(c)
			d.habilidad= nueva
			c._texto("¡%s adquirió %s!" % [td, BaseDatos.habilidad(nueva).nombre])
			if nueva== "insomnia" and d.pokemon.estado== "dor":
				c._poner_estado(d, "")
				c._texto("¡%s se despertó!" % td)
			return true
		"entrainment":
			if d.habilidad in ["multitype", "truant", a.habilidad] or a.habilidad in SIN_ROL:
				return _fallo(c)
			d.habilidad= a.habilidad
			c._texto("¡%s adquirió %s!" % [td, BaseDatos.habilidad(a.habilidad).nombre if BaseDatos.habilidad(a.habilidad)!= null else a.habilidad])
			return true
		"role_play":
			if d.habilidad in SIN_ROL or d.habilidad== a.habilidad or d.habilidad== "":
				return _fallo(c)
			a.habilidad= d.habilidad
			c._texto("¡%s copió %s %s!" % [ta, BaseDatos.habilidad(d.habilidad).nombre, c._de(d)])
			return true
		"skill_swap":
			if a.habilidad in SIN_ROL or d.habilidad in SIN_ROL:
				return _fallo(c)
			var h:= a.habilidad
			a.habilidad= d.habilidad
			d.habilidad= h
			c._texto("¡%s intercambió su habilidad con el rival!" % ta)
			return true
		"gastro_acid":
			if d.tiene("gastro") or d.habilidad== "multitype":
				return _fallo(c)
			d.poner("gastro")
			c._texto("¡Se anuló la habilidad %s!" % c._de(d))
			return true
		"transform":
			if d.transformado!= null or a.transformado!= null:
				return _fallo(c)
			transformar(c, a, d)
			return true
		"mimic":
			var um4: Movimiento= d.ultimo_mov
			if um4== null or um4.tiene("failmimic") or um4.id in ["mimic", "transform", "sketch", "struggle", "metronome"] or a.movimientos().has(um4):
				return _fallo(c)
			var k4:= a.movimientos().find(mov)
			if k4< 0:
				return _fallo(c)
			c.temporal_mov(a, k4, um4, 5)
			c._texto("¡%s aprendió %s!" % [ta, um4.nombre])
			return true
		"sketch":
			var um5: Movimiento= d.ultimo_mov
			if um5== null or um5.tiene("nosketch") or um5.id in ["sketch", "struggle", "chatter"] or a.pokemon.movimientos.has(um5):
				return _fallo(c)
			var k5:= a.pokemon.movimientos.find(mov)
			if k5< 0:
				return _fallo(c)
			a.pokemon.movimientos[k5]= um5
			a.pokemon.pp[k5]= um5.pp
			c._texto("¡%s dibujó %s!" % [ta, um5.nombre])
			return true
		"recycle":
			var baya: String= a.valor("baya_usada", "")
			if baya== "" or a.pokemon.objeto!= "":
				return _fallo(c)
			a.pokemon.objeto= baya
			a.quitar("baya_usada")
			c._texto("¡%s recuperó su %s!" % [ta, BaseDatos.objeto(baya).nombre if BaseDatos.objeto(baya)!= null else baya])
			return true
		"trick", "switcheroo":
			if (a.pokemon.objeto== "" and d.pokemon.objeto== "") or c.habilidad_def(a, d, "sticky_hold") or d.sustituto> 0:
				return _fallo(c)
			c.cambiar_objetos(a, d)
			c._texto("¡%s intercambió objetos con el rival!" % ta)
			return true
		"bestow":
			if a.pokemon.objeto== "" or d.pokemon.objeto!= "":
				return _fallo(c)
			c.cambiar_objetos(a, d)
			c._texto("¡%s le dio su objeto a %s!" % [ta, c.nombre_de(d)])
			return true
	return false

static func _vaciar_reserva(c: LogicaCombate, a: Luchador) -> void:
	var n:= int(a.valor("reserva", 0))
	if n<= 0:
		return
	a.quitar("reserva")
	c._cambiar_etapa(a, "defensa", -n, false)
	c._cambiar_etapa(a, "def_esp", -n, false)

static func _cap_equipo(c: LogicaCombate, a: Luchador) -> String:
	return "Tu equipo" if a== c.j else "El equipo rival"

static func _genero_opuesto(a: Luchador, d: Luchador) -> bool:
	return a.pokemon.genero!= "" and d.pokemon.genero!= "" and a.pokemon.genero!= d.pokemon.genero

static func poner_clima(c: LogicaCombate, cl: String, turnos: int) -> void:
	c.clima= cl
	c.turnos_clima= turnos
	c._ev({"tipo": "clima", "clima": cl})
	c._texto({"lluvia": "¡Empezó a llover!", "sol": "¡El sol pega fuerte!", "arena": "¡Se desató una tormenta de arena!", "granizo": "¡Empezó a granizar!"}[cl])
	for l in [c.j, c.r]:
		if l!= null and l.pokemon!= null:
			HabCombate.pronostico(c, l)

static func transformar(c: LogicaCombate, a: Luchador, d: Luchador) -> void:
	a.transformado= d.pokemon
	a.tipos_forzados= d.tipos().duplicate()
	a.habilidad= d.habilidad
	for s in ["ataque", "defensa", "at_esp", "def_esp", "velocidad"]:
		a.stats_transformado[s]= d.stat_base_batalla(s)
	for s in d.etapas:
		a.etapas[s]= d.etapas[s]
	a.movs_transformado.assign(d.movimientos().duplicate())
	a.pp_transformado.assign(d.movimientos().map(func(m): return 5))
	c._ev({"tipo": "transformar", "lado": c._lado(a), "pokemon": d.pokemon})
	c._texto("¡%s se transformó en %s!" % [_t(c, a), d.pokemon.especie.nombre])

static func golpe_futuro(c: LogicaCombate, f: Dictionary) -> void:
	var objetivo: Luchador= c.j if f["lado"]== "jugador" else c.r
	if objetivo.pokemon.esta_debilitado():
		return
	var mov: Movimiento= f["mov"]
	c._texto("¡%s recibió el ataque de %s!" % [_t(c, objetivo), mov.nombre])
	var atacante: Luchador= f["atacante"]
	var ef:= c.efectividad(atacante, objetivo, mov.tipo, mov)
	if ef== 0.0:
		c._texto("No afecta %s..." % c._a(objetivo))
		return
	var g:= c.calcular_danio(atacante, objetivo, mov, ef)
	c._herir(objetivo, g["danio"])

static func despues(c: LogicaCombate, a: Luchador, d: Luchador, mov: Movimiento, total: int) -> void:
	var id:= mov.id
	if id== "bide":
		a.quitar("bide")
	if mov.tiene("recharge"):
		a.recarga= true
	if id in BLOQUEO and a.mov_bloqueado== mov:
		a.quitar("bloqueo_iniciado")
		a.turnos_bloqueo-= 1
		if a.turnos_bloqueo<= 0:
			a.mov_bloqueado= null
			c._texto("¡%s está agotado!" % _t(c, a))
			c._confundir(a, false)
	if id in RODAR and a.mov_bloqueado== mov:
		a.quitar("bloqueo_iniciado")
		a.poner("rodar", int(a.valor("rodar", 0))+ 1)
		a.turnos_bloqueo-= 1
		if a.turnos_bloqueo<= 0:
			a.mov_bloqueado= null
			a.quitar("rodar")
	if id== "uproar":
		a.quitar("bloqueo_iniciado")
	if id== "rage":
		a.poner("furia")
	if id== "spit_up":
		_vaciar_reserva(c, a)
	if id== "pay_day":
		c.dinero_ganado+= a.pokemon.nivel* 5
		c._texto("¡Hay monedas por todas partes!")
	if id== "rapid_spin" and not a.pokemon.esta_debilitado():
		for k in ["drenadoras", "atrapado"]:
			a.quitar(k)
		var t: Dictionary= c.trampas[c._lado(a)]
		t["puas"]= 0
		t["puas_toxicas"]= 0
		t["rocas"]= false
	if d.pokemon.esta_debilitado():
		if id in ["u_turn", "volt_switch"] and not a.pokemon.esta_debilitado():
			c.ida_y_vuelta(a)
		return
	match id:
		"tri_attack":
			if c.rng.randi_range(1, 100)<= 20* (2 if c.activa(a, "serene_grace") else 1) and d.sustituto<= 0 and not c.habilidad_def(a, d, "shield_dust"):
				c.aplicar_estado_desde(a, d, ["que", "con", "par"][c.rng.randi_range(0, 2)], false)
		"secret_power":
			if c.rng.randi_range(1, 100)<= 30* (2 if c.activa(a, "serene_grace") else 1) and d.sustituto<= 0:
				var ef: Array= SECRETO.get(c.terreno, ["estado", "par"])
				match ef[0]:
					"estado":
						c.aplicar_estado_desde(a, d, ef[1], false)
					"stat":
						c.cambiar_etapa_desde(a, d, ef[1], -1, false)
					"retroceso":
						d.retrocede= true
		"smelling_salts":
			if d.pokemon.estado== "par":
				c._poner_estado(d, "")
				c._texto("¡%s ya no está paralizado!" % _t(c, d))
		"wake_up_slap":
			if d.pokemon.estado== "dor":
				c._poner_estado(d, "")
				c._texto("¡%s se despertó!" % _t(c, d))
		"knock_off":
			if d.pokemon.objeto!= "" and not c.habilidad_def(a, d, "sticky_hold"):
				var o:= BaseDatos.objeto(c.perder_objeto(d))
				c._texto("¡%s perdió su %s!" % [_t(c, d), o.nombre if o!= null else "objeto"])
		"thief", "covet":
			if d.pokemon.objeto!= "" and a.pokemon.objeto== "" and not c.habilidad_def(a, d, "sticky_hold"):
				var robado:= c.perder_objeto(d)
				a.pokemon.objeto= robado
				var o2:= BaseDatos.objeto(robado)
				c._texto("¡%s robó %s %s!" % [_t(c, a), o2.nombre if o2!= null else "el objeto", c._de(d)])
		"pluck", "bug_bite":
			var b:= BaseDatos.objeto(d.pokemon.objeto)
			if b!= null and b.categoria== "BAYAS":
				c.perder_objeto(d)
				c._texto("¡%s se comió la %s %s!" % [_t(c, a), b.nombre, c._de(d)])
				if b.cura_ps> 0:
					c._curar(a, b.cura_ps)
		"incinerate":
			var b2:= BaseDatos.objeto(d.pokemon.objeto)
			if b2!= null and b2.categoria== "BAYAS":
				c.perder_objeto(d)
				c._texto("¡La %s %s se quemó!" % [b2.nombre, c._de(d)])
		"fling", "natural_gift":
			c.perder_objeto(a)
		"clear_smog":
			for s in d.etapas:
				d.etapas[s]= 0
			c._texto("¡Se eliminaron los cambios en las estadísticas %s!" % c._de(d))
		"smack_down":
			d.poner("derribado")
			d.quitar("levitar")
			d.quitar("telequinesis")
			if d.invulnerable== "vuela":
				d.invulnerable= ""
				d.cargando= null
				c._ev({"tipo": "oculto", "lado": c._lado(d), "oculto": false})
			c._texto("¡%s cayó al suelo!" % _t(c, d))
		"dragon_tail", "circle_throw":
			if d.sustituto<= 0 and not a.pokemon.esta_debilitado():
				c._arrastrar(a, d)
				return
		"u_turn", "volt_switch":
			if not a.pokemon.esta_debilitado():
				c.ida_y_vuelta(a)
	if mov.estado== "trap" and not d.tiene("atrapado") and d.sustituto<= 0 and not a.pokemon.esta_debilitado():
		d.poner("atrapado", {"turnos": c.rng.randi_range(4, 5), "por": a, "nombre": mov.nombre})
		c._texto("¡%s quedó atrapado por %s!" % [_t(c, d), mov.nombre])
