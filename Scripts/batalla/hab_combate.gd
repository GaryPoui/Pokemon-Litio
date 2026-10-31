class_name HabCombate
extends RefCounted

const ROMPIBLES:= ["battle_armor", "big_pecks", "clear_body", "contrary", "damp", "dry_skin", "filter", "flash_fire", "flower_gift", "friend_guard", "heatproof", "hyper_cutter", "immunity", "inner_focus", "insomnia", "keen_eye", "leaf_guard", "levitate", "lightning_rod", "limber", "magic_bounce", "magma_armor", "marvel_scale", "motor_drive", "multiscale", "oblivious", "overcoat", "own_tempo", "sand_veil", "sap_sipper", "shell_armor", "shield_dust", "simple", "snow_cloak", "solid_rock", "soundproof", "sticky_hold", "storm_drain", "sturdy", "suction_cups", "tangled_feet", "thick_fat", "unaware", "vital_spirit", "volt_absorb", "water_absorb", "water_veil", "white_smoke", "wonder_guard", "wonder_skin", "heavy_metal", "light_metal", "telepathy"]
const NO_CALCABLES:= ["trace", "multitype", "illusion", "flower_gift", "imposter", "zen_mode", "forecast"]
const ABSORBE:= {"volt_absorb": ["electrico", "cura"], "water_absorb": ["agua", "cura"], "dry_skin": ["agua", "cura"], "motor_drive": ["electrico", "velocidad"], "lightning_rod": ["electrico", "at_esp"], "storm_drain": ["agua", "at_esp"], "sap_sipper": ["planta", "ataque"], "flash_fire": ["fuego", "fuego"]}
const CLIMAS:= {"drizzle": "lluvia", "drought": "sol", "sand_stream": "arena", "snow_warning": "granizo"}
const PINCH:= {"blaze": "fuego", "overgrow": "planta", "torrent": "agua", "swarm": "bicho"}
const EVITA:= {"immunity": ["env", "tox"], "limber": ["par"], "insomnia": ["dor"], "vital_spirit": ["dor"], "water_veil": ["que"], "magma_armor": ["con"]}
const NOMBRE_EST:= {"env": "envenenado", "tox": "envenenado", "par": "paralizado", "dor": "dormido", "que": "quemado", "con": "congelado"}

static func _t(c: LogicaCombate, l: Luchador) -> String:
	return c._cap(c.nombre_de(l))

static func al_entrar(c: LogicaCombate, l: Luchador) -> void:
	if l.pokemon.esta_debilitado():
		return
	if c.turnos> 0:
		l.poner("entro_turno", c.turnos)
	var o:= c.otro_de(l)
	var hay_otro:= o!= null and o.pokemon!= null and not o.pokemon.esta_debilitado()
	if c.activa(l, "trace") and hay_otro and not o.habilidad in NO_CALCABLES and o.habilidad!= "":
		c.anunciar_habilidad(l)
		l.habilidad= o.habilidad
		c._texto("¡%s calcó %s %s!" % [_t(c, l), _nombre(o.habilidad), c._de(o)])
	if c.activa(l, "imposter") and hay_otro and o.sustituto<= 0 and o.disfraz== null and o.transformado== null:
		c.anunciar_habilidad(l)
		MovEfectos.transformar(c, l, o)
		return
	var h:= l.habilidad
	if not c.activa(l, h):
		return
	if CLIMAS.has(h):
		if c.clima!= CLIMAS[h] or c.turnos_clima!= 0:
			c.anunciar_habilidad(l)
			MovEfectos.poner_clima(c, CLIMAS[h], 0)
		return
	match h:
		"intimidate":
			if hay_otro:
				c.anunciar_habilidad(l)
				if o.sustituto> 0:
					c._texto("¡%s no se ve afectado!" % _t(c, o))
				else:
					c.cambiar_etapa_desde(l, o, "ataque", -1, true)
		"download":
			if hay_otro:
				c.anunciar_habilidad(l)
				var sube:= "ataque" if o.stat_efectivo("defensa")< o.stat_efectivo("def_esp") else "at_esp"
				c._cambiar_etapa(l, sube, 1, false)
		"pressure":
			c.anunciar_habilidad(l)
			c._texto("¡%s ejerce su presión!" % _t(c, l))
		"mold_breaker":
			c.anunciar_habilidad(l)
			c._texto("¡%s rompe moldes!" % _t(c, l))
		"turboblaze":
			c.anunciar_habilidad(l)
			c._texto("¡%s desprende un aura llameante!" % _t(c, l))
		"teravolt":
			c.anunciar_habilidad(l)
			c._texto("¡%s desprende un aura chisporroteante!" % _t(c, l))
		"unnerve":
			c.anunciar_habilidad(l)
			c._texto("¡%s está tan nervioso que no puede comer bayas!" % ("El equipo rival" if l== c.j else "Tu equipo"))
		"air_lock", "cloud_nine":
			c.anunciar_habilidad(l)
			c._texto("Los efectos del clima desaparecieron.")
		"slow_start":
			c.anunciar_habilidad(l)
			c._texto("¡%s no rinde al máximo!" % _t(c, l))
		"frisk":
			if hay_otro and o.pokemon.objeto!= "":
				c.anunciar_habilidad(l)
				var ob:= BaseDatos.objeto(o.pokemon.objeto)
				c._texto("¡%s descubrió que %s lleva %s!" % [_t(c, l), c.nombre_de(o), ob.nombre if ob!= null else o.pokemon.objeto])
		"anticipation":
			if hay_otro:
				for m in o.movimientos():
					if m.categoria!= "estado" and (c.efectividad(o, l, m.tipo, m)> 1.0 or m.meta== "ohko"):
						c.anunciar_habilidad(l)
						c._texto("¡%s se estremeció!" % _t(c, l))
						break
		"forewarn":
			if hay_otro and not o.movimientos().is_empty():
				var mejor: Movimiento= o.movimientos()[0]
				var poder:= -1
				for m in o.movimientos():
					var p:= m.poder
					if m.meta== "ohko":
						p= 160
					elif m.id in ["counter", "mirror_coat", "metal_burst"]:
						p= 120
					elif m.categoria!= "estado" and p<= 1:
						p= 80
					if p> poder:
						poder= p
						mejor =m
				c.anunciar_habilidad(l)
				c._texto("¡%s alertó sobre %s!" % [_t(c, l), mejor.nombre])
		"forecast":
			pronostico(c, l)

static func _nombre(id: String) -> String:
	var h:= BaseDatos.habilidad(id)
	return h.nombre if h!= null else id

static func pronostico(c: LogicaCombate, l: Luchador) -> void:
	if l.pokemon.especie.id!= "castform" or not c.activa(l, "forecast"):
		return
	var t: String= {"sol": "fuego", "lluvia": "agua", "granizo": "hielo"}.get(c.clima_activo(), "normal")
	if l.tipos()!= [t]:
		l.tipos_forzados= [t]
		c.anunciar_habilidad(l)
		c._ev({"tipo": "tipos", "lado": c._lado(l), "tipos": l.tipos()})
		c._texto("¡%s se transformó!" % _t(c, l))

static func bloquea_estado(c: LogicaCombate, a: Luchador, d: Luchador, mov: Movimiento) -> bool:
	if a== d:
		return false
	if mov.tiene("sound") and c.habilidad_def(a, d, "soundproof"):
		c.anunciar_habilidad(d)
		c._texto("No afecta %s..." % c._a(d))
		return true
	if mov.id== "thunder_wave" and c.efectividad(a, d, "electrico", mov)== 0.0:
		c._texto("No afecta %s..." % c._a(d))
		return true
	if mov.id in ["thunder_wave", "will_o_wisp", "soak", "spore", "sleep_powder", "stun_spore", "cotton_spore", "leech_seed", "grass_whistle"] or mov.tipo in ["electrico", "agua", "planta", "fuego"]:
		if absorbe(c, a, d, mov, mov.tipo):
			return true
	if mov.categoria== "estado" and c.habilidad_def(a, d, "wonder_skin"):
		pass
	return false

static func absorberia(c: LogicaCombate, a: Luchador, d: Luchador, tipo: String, mov: Movimiento) -> bool:
	for h in ABSORBE:
		if c.habilidad_def(a, d, h) and ABSORBE[h][0]== tipo:
			return true
	if tipo== "tierra" and c.habilidad_def(a, d, "levitate") and not c._en_tierra(d, a):
		return true
	return false

static func absorbe(c: LogicaCombate, a: Luchador, d: Luchador, mov: Movimiento, tipo: String) -> bool:
	if a== d:
		return false
	for h in ABSORBE:
		if not c.habilidad_def(a, d, h) or ABSORBE[h][0]!= tipo:
			continue
		var efecto: String= ABSORBE[h][1]
		c.anunciar_habilidad(d)
		match efecto:
			"cura":
				var div:= 4.0
				if c._curar(d, floori(d.pokemon.ps_max()/ div))> 0:
					c._texto("¡%s recuperó PS!" % _t(c, d))
				else:
					c._texto("No afecta %s..." % c._a(d))
			"fuego":
				if not d.tiene("fuego_flash"):
					d.poner("fuego_flash")
					c._texto("¡%s potenció sus ataques de tipo Fuego!" % _t(c, d))
				else:
					c._texto("No afecta %s..." % c._a(d))
			_:
				if not c._cambiar_etapa(d, efecto, 1, false):
					c._texto("No afecta %s..." % c._a(d))
		return true
	if tipo== "tierra" and mov.categoria!= "estado" and c.habilidad_def(a, d, "levitate") and not c._en_tierra(d, a):
		c.anunciar_habilidad(d)
		c._texto("No afecta %s..." % c._a(d))
		return true
	return false

static func contacto(c: LogicaCombate, a: Luchador, d: Luchador, mov: Movimiento) -> void:
	if a.pokemon.esta_debilitado():
		return
	if d.pokemon.esta_debilitado():
		if c.activa(d, "aftermath") and not c.activa(a, "damp") and not c.activa(a, "magic_guard"):
			c.anunciar_habilidad(d)
			c._herir(a, maxi(1, floori(a.pokemon.ps_max()/ 4.0)))
			c._texto("¡%s fue alcanzado!" % _t(c, a))
		return
	var h:= d.habilidad
	if c.activa(d, h):
		match h:
			"static":
				if c.rng.randi_range(1, 100)<= 30 and a.pokemon.estado== "":
					c.anunciar_habilidad(d)
					c.aplicar_estado_desde(d, a, "par", false)
			"flame_body":
				if c.rng.randi_range(1, 100)<= 30 and a.pokemon.estado== "":
					c.anunciar_habilidad(d)
					c.aplicar_estado_desde(d, a, "que", false)
			"poison_point":
				if c.rng.randi_range(1, 100)<= 30 and a.pokemon.estado== "":
					c.anunciar_habilidad(d)
					c.aplicar_estado_desde(d, a, "env", false)
			"effect_spore":
				if c.rng.randi_range(1, 100)<= 30 and a.pokemon.estado== "":
					c.anunciar_habilidad(d)
					c.aplicar_estado_desde(d, a, ["env", "par", "dor"][c.rng.randi_range(0, 2)], false)
			"rough_skin", "iron_barbs":
				if not c.activa(a, "magic_guard"):
					c.anunciar_habilidad(d)
					c._herir(a, maxi(1, floori(a.pokemon.ps_max()/ 8.0)))
					c._texto("¡%s resultó herido!" % _t(c, a))
			"cute_charm":
				if c.rng.randi_range(1, 100)<= 30 and MovEfectos._genero_opuesto(a, d) and not a.tiene("enamorado") and not c.activa(a, "oblivious"):
					c.anunciar_habilidad(d)
					a.poner("enamorado", d)
					c._texto("¡%s se enamoró!" % _t(c, a))
			"mummy":
				if a.habilidad!= "mummy" and a.habilidad!= "multitype":
					c.anunciar_habilidad(d)
					a.habilidad= "mummy"
					c._texto("¡La habilidad %s se convirtió en Momia!" % c._de(a))
			"pickpocket":
				if d.pokemon.objeto== "" and a.pokemon.objeto!= "" and not c.activa(a, "sticky_hold"):
					c.anunciar_habilidad(d)
					var ob:= c.perder_objeto(a)
					d.pokemon.objeto= ob
					c._texto("¡%s robó el objeto %s!" % [_t(c, d), c._de(a)])
	if c.activa(a, "poison_touch") and c.rng.randi_range(1, 100)<= 30 and d.pokemon.estado== "" and d.sustituto<= 0:
		c.anunciar_habilidad(a)
		c.aplicar_estado_desde(a, d, "env", false)

static func al_recibir_golpe(c: LogicaCombate, a: Luchador, d: Luchador, mov: Movimiento, tipo: String) -> void:
	if d.pokemon.esta_debilitado() or a== d:
		return
	var h:= d.habilidad
	if not c.activa(d, h):
		return
	match h:
		"color_change":
			if tipo!= "" and d.tipos()!= [tipo]:
				c.anunciar_habilidad(d)
				d.tipos_forzados= [tipo]
				c._ev({"tipo": "tipos", "lado": c._lado(d), "tipos": d.tipos()})
				c._texto("¡%s ahora es de tipo %s!" % [_t(c, d), Tipos.nombre(tipo)])
		"cursed_body":
			if c.rng.randi_range(1, 100)<= 30 and not a.tiene("anulado") and a.movimientos().has(mov):
				c.anunciar_habilidad(d)
				a.poner("anulado", {"mov": mov, "turnos": 4})
				c._texto("¡Se anuló %s %s!" % [mov.nombre, c._de(a)])
		"weak_armor":
			if MovEfectos.es_fisico(mov):
				c.anunciar_habilidad(d)
				c._cambiar_etapa(d, "defensa", -1, false)
				c._cambiar_etapa(d, "velocidad", 1, false)
		"justified":
			if tipo== "siniestro":
				c.anunciar_habilidad(d)
				c._cambiar_etapa(d, "ataque", 1, false)
		"rattled":
			if tipo in ["bicho", "fantasma", "siniestro"]:
				c.anunciar_habilidad(d)
				c._cambiar_etapa(d, "velocidad", 1, false)

static func mult_precision(c: LogicaCombate, a: Luchador, d: Luchador, mov: Movimiento) -> float:
	var m:= 1.0
	if c.activa(a, "compound_eyes"):
		m*= 1.3
	if c.activa(a, "hustle") and MovEfectos.es_fisico(mov):
		m*= 0.8
	if c.activa(a, "victory_star"):
		m*= 1.1
	var cl:= c.clima_activo()
	if cl== "arena" and c.habilidad_def(a, d, "sand_veil"):
		m*= 0.8
	if cl== "granizo" and c.habilidad_def(a, d, "snow_cloak"):
		m*= 0.8
	if d.confusion> 0 and c.habilidad_def(a, d, "tangled_feet"):
		m*= 0.5
	if mov.categoria== "estado" and mov.precision> 50 and c.habilidad_def(a, d, "wonder_skin"):
		m*= 50.0/ mov.precision
	return m

static func mod_ataque(c: LogicaCombate, a: Luchador, d: Luchador, mov: Movimiento, valor: int, fisico: bool) -> int:
	var m:= 1.0
	var tipo:= c.tipo_de(a, mov)
	if fisico and (c.activa(a, "huge_power") or c.activa(a, "pure_power")):
		m*= 2.0
	if fisico and c.activa(a, "hustle"):
		m*= 1.5
	if fisico and c.activa(a, "guts") and a.pokemon.estado!= "":
		m*= 1.5
	for h in PINCH:
		if c.activa(a, h) and tipo== PINCH[h] and a.pokemon.ps_actuales* 3<= a.pokemon.ps_max():
			m*= 1.5
	if tipo== "fuego" and a.tiene("fuego_flash") and c.activa(a, "flash_fire"):
		m*= 1.5
	if not fisico and c.activa(a, "solar_power") and c.clima_activo()== "sol":
		m*= 1.5
	if fisico and c.activa(a, "flower_gift") and c.clima_activo()== "sol":
		m*= 1.5
	if c.activa(a, "defeatist") and a.pokemon.ps_actuales* 2<= a.pokemon.ps_max():
		m*= 0.5
	if fisico and c.activa(a, "slow_start") and a.turnos_en_campo< 5:
		m*= 0.5
	if tipo in ["fuego", "hielo"] and c.habilidad_def(a, d, "thick_fat"):
		m*= 0.5
	if m== 1.0:
		return valor
	return maxi(1, LogicaCombate.redondear(valor, m))

static func mod_defensa(c: LogicaCombate, a: Luchador, d: Luchador, mov: Movimiento, valor: int, fisico: bool) -> int:
	var m:= 1.0
	if fisico and c.habilidad_def(a, d, "marvel_scale") and d.pokemon.estado!= "":
		m*= 1.5
	if not fisico and c.habilidad_def(a, d, "flower_gift") and c.clima_activo()== "sol":
		m*= 1.5
	if m== 1.0:
		return valor
	return maxi(1, LogicaCombate.redondear(valor, m))

static func mod_poder(c: LogicaCombate, a: Luchador, d: Luchador, mov: Movimiento, p: int) -> int:
	var m:= 1.0
	var tipo:= c.tipo_de(a, mov)
	if c.activa(a, "technician") and p<= 60:
		m*= 1.5
	if c.activa(a, "iron_fist") and mov.tiene("punch"):
		m*= 1.2
	if c.activa(a, "reckless") and (mov.drenaje< 0 or mov.id in ["jump_kick", "high_jump_kick"]):
		m*= 1.2
	if c.activa(a, "sheer_force") and MovEfectos.tiene_secundario(mov):
		m*= 1.3
	if c.activa(a, "sand_force") and c.clima_activo()== "arena" and tipo in ["roca", "tierra", "acero"]:
		m*= 1.3
	if c.activa(a, "analytic") and d.actuo_turno:
		m*= 1.3
	if c.activa(a, "toxic_boost") and MovEfectos.es_fisico(mov) and a.pokemon.estado in ["env", "tox"]:
		m*= 1.5
	if c.activa(a, "flare_boost") and not MovEfectos.es_fisico(mov) and a.pokemon.estado== "que":
		m*= 1.5
	if c.activa(a, "rivalry") and a.pokemon.genero!= "" and d.pokemon.genero!= "":
		m*= 1.25 if a.pokemon.genero== d.pokemon.genero else 0.75
	if tipo== "fuego" and c.habilidad_def(a, d, "heatproof"):
		m*= 0.5
	if tipo== "fuego" and c.habilidad_def(a, d, "dry_skin"):
		m*= 1.25
	for lado in ["jugador", "rival"]:
		if tipo== "electrico" and c.trampas[lado]["chapoteo"]:
			m*= 0.5
		if tipo== "fuego" and c.trampas[lado]["hidrochorro"]:
			m*= 0.5
	if m== 1.0:
		return p
	return maxi(1, LogicaCombate.redondear(p, m))

static func mod_final(c: LogicaCombate, a: Luchador, d: Luchador, mov: Movimiento, ef: float, critico: bool) -> float:
	var m:= 1.0
	if c.activa(a, "tinted_lens") and ef< 1.0:
		m*= 2.0
	if c.activa(a, "sniper") and critico:
		m*= 1.5
	if ef> 1.0 and (c.habilidad_def(a, d, "filter") or c.habilidad_def(a, d, "solid_rock")):
		m*= 0.75
	if c.habilidad_def(a, d, "multiscale") and d.pokemon.ps_actuales>= d.pokemon.ps_max():
		m*= 0.5
	return m

static func al_salir(c: LogicaCombate, l: Luchador) -> void:
	if l.pokemon== null or l.pokemon.esta_debilitado():
		return
	if c.activa(l, "natural_cure") and l.pokemon.estado!= "":
		l.pokemon.estado= ""
	if c.activa(l, "regenerator"):
		l.pokemon.curar_ps(floori(l.pokemon.ps_max()/ 3.0))

static func evita_bajada(c: LogicaCombate, a: Luchador, l: Luchador, stat: String, anunciar: bool) -> bool:
	var h:= ""
	for id in ["clear_body", "white_smoke"]:
		if c.habilidad_def(a, l, id):
			h= id
	if h== "" and stat== "ataque" and c.habilidad_def(a, l, "hyper_cutter"):
		h= "hyper_cutter"
	if h== "" and stat== "precision" and c.habilidad_def(a, l, "keen_eye"):
		h= "keen_eye"
	if h== "" and stat== "defensa" and c.habilidad_def(a, l, "big_pecks"):
		h= "big_pecks"
	if h== "":
		return false
	c.anunciar_habilidad(l)
	c._texto("¡%s %s no puede bajar!" % [c._cap(LogicaCombate.NOMBRE_STAT.get(stat, stat)), c._de(l)])
	return true

static func tras_bajada(c: LogicaCombate, l: Luchador) -> void:
	if c.activa(l, "defiant") and not l.tiene("desafio_activo"):
		l.poner("desafio_activo")
		c.anunciar_habilidad(l)
		c._cambiar_etapa(l, "ataque", 2, false)
		l.quitar("desafio_activo")

static func evita_estado(c: LogicaCombate, a: Luchador, l: Luchador, est: String, anunciar: bool) -> bool:
	var atacante: Luchador= a if a!= null else l
	for h in EVITA:
		if est in EVITA[h] and c.habilidad_def(atacante, l, h):
			if anunciar or a!= null:
				c.anunciar_habilidad(l)
				c._texto("¡%s no puede quedar %s!" % [_t(c, l), NOMBRE_EST.get(est, est)])
			return true
	if c.clima_activo()== "sol" and c.habilidad_def(atacante, l, "leaf_guard"):
		if anunciar or a!= null:
			c.anunciar_habilidad(l)
			c._texto("¡%s está protegido por la luz del sol!" % _t(c, l))
		return true
	return false

static func clima_fin_turno(c: LogicaCombate, l: Luchador) -> void:
	var p:= l.pokemon
	if p.esta_debilitado():
		return
	var cl:= c.clima_activo()
	match cl:
		"arena":
			if not _inmune_clima(c, l, ["roca", "tierra", "acero"], ["sand_veil", "sand_rush", "sand_force"]):
				c._herir(l, maxi(1, floori(p.ps_max()/ 16.0)))
				c._texto("¡La tormenta de arena zarandea a %s!" % c.nombre_de(l))
		"granizo":
			if c.activa(l, "ice_body"):
				if p.ps_actuales< p.ps_max():
					c.anunciar_habilidad(l)
					c._curar(l, floori(p.ps_max()/ 16.0))
			elif not _inmune_clima(c, l, ["hielo"], ["snow_cloak"]):
				c._herir(l, maxi(1, floori(p.ps_max()/ 16.0)))
				c._texto("¡El granizo golpea a %s!" % c.nombre_de(l))
		"lluvia":
			if c.activa(l, "rain_dish") and p.ps_actuales< p.ps_max():
				c.anunciar_habilidad(l)
				c._curar(l, floori(p.ps_max()/ 16.0))
			if c.activa(l, "dry_skin") and p.ps_actuales< p.ps_max():
				c.anunciar_habilidad(l)
				c._curar(l, floori(p.ps_max()/ 8.0))
			if c.activa(l, "hydration") and p.estado!= "":
				c.anunciar_habilidad(l)
				c._poner_estado(l, "")
				c._texto("¡%s se curó de su problema de estado!" % _t(c, l))
		"sol":
			if (c.activa(l, "dry_skin") or c.activa(l, "solar_power")) and not c.activa(l, "magic_guard"):
				c.anunciar_habilidad(l)
				c._herir(l, maxi(1, floori(p.ps_max()/ 8.0)))

static func _inmune_clima(c: LogicaCombate, l: Luchador, tipos: Array, habs: Array) -> bool:
	for t in tipos:
		if t in l.tipos():
			return true
	for h in habs+ ["overcoat", "magic_guard"]:
		if c.activa(l, h):
			return true
	return l.invulnerable in ["excava", "buceo"]

static func fin_turno_estado(c: LogicaCombate, l: Luchador) -> void:
	var p:= l.pokemon
	if c.activa(l, "shed_skin") and p.estado!= "" and c.rng.randi_range(1, 100)<= 30:
		c.anunciar_habilidad(l)
		c._poner_estado(l, "")
		c._texto("¡%s se curó de su problema de estado!" % _t(c, l))

static func fin_turno(c: LogicaCombate, l: Luchador) -> void:
	var h:= l.habilidad
	if not c.activa(l, h):
		return
	match h:
		"speed_boost":
			if int(l.valor("entro_turno", -1))!= c.turnos and int(l.etapas["velocidad"])< 6:
				c.anunciar_habilidad(l)
				c._cambiar_etapa(l, "velocidad", 1, false)
		"moody":
			var sube:= Luchador.ETAPAS.filter(func(s): return int(l.etapas[s])< 6)
			if not sube.is_empty():
				var s1: String= sube[c.rng.randi_range(0, sube.size()- 1)]
				var baja:= Luchador.ETAPAS.filter(func(s): return s!= s1 and int(l.etapas[s])> -6)
				c.anunciar_habilidad(l)
				c._cambiar_etapa(l, s1, 2, false)
				if not baja.is_empty():
					c._cambiar_etapa(l, baja[c.rng.randi_range(0, baja.size()- 1)], -1, false)
		"harvest":
			var baya: String= l.valor("baya_usada", "")
			if baya!= "" and l.pokemon.objeto== "" and (c.clima_activo()== "sol" or c.rng.randi_range(0, 1)== 0):
				c.anunciar_habilidad(l)
				l.pokemon.objeto= baya
				l.quitar("baya_usada")
				c._texto("¡%s recolectó una baya!" % _t(c, l))
		"slow_start":
			if l.turnos_en_campo== 5:
				c.anunciar_habilidad(l)
				c._texto("¡%s ya rinde al máximo!" % _t(c, l))
		"zen_mode":
			modo_zen(c, l)
		"forecast":
			pronostico(c, l)

static func modo_zen(c: LogicaCombate, l: Luchador) -> void:
	if l.pokemon.especie.id!= "darmanitan":
		return
	var zen:= l.pokemon.ps_actuales* 2< l.pokemon.ps_max()
	if zen and not l.tiene("zen"):
		l.poner("zen")
		c.anunciar_habilidad(l)
		l.tipos_forzados= ["fuego", "psiquico"]
		for par in [["ataque", 30], ["defensa", 105], ["at_esp", 140], ["def_esp", 105], ["velocidad", 55]]:
			l.stats_transformado[par[0]]= _stat_con_base(l.pokemon, par[0], par[1])
		c._ev({"tipo": "tipos", "lado": c._lado(l), "tipos": l.tipos()})
		c._texto("¡%s entró en el Modo Daruma!" % _t(c, l))
	elif not zen and l.tiene("zen"):
		l.quitar("zen")
		l.tipos_forzados= []
		l.stats_transformado.clear()
		c._ev({"tipo": "tipos", "lado": c._lado(l), "tipos": l.tipos()})
		c._texto("¡%s volvió a su forma normal!" % _t(c, l))

static func _stat_con_base(p: PokemonInstancia, stat: String, base: int) -> int:
	var iv: int= p.ivs.get(stat, 0)
	var ev: int= p.evs.get(stat, 0)
	var parcial:= floori((2* base+ iv+ floori(ev/ 4.0))* p.nivel/ 100.0)
	return floori((parcial+ 5)* Naturalezas.porcentaje(p.naturaleza, stat)/ 100.0)

static func al_debilitar(c: LogicaCombate, l: Luchador) -> void:
	var o:= c.otro_de(l)
	if o!= null and not o.pokemon.esta_debilitado() and c.activa(o, "moxie") and l.danio_recibido.get("de")== o:
		c.anunciar_habilidad(o)
		c._cambiar_etapa(o, "ataque", 1, false)
