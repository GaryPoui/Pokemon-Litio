class_name EfectosTrinket
extends RefCounted

const MAX_POR_POKEMON:= 5
const NOMBRES_TIER :=["", "Común", "Poco común", "Raro", "Épico", "Legendario"]
const LETRAS_TIER:= ["", "D", "C", "B", "A", "S"]
const COLORES_TIER :=["ffffff", "a8a8a8", "58b858", "4890e8", "a060e0", "e8b030"]
const NOMBRES_CATEGORIA:= {"economia": "Economía", "combate": "Combate", "captura": "Captura", "utilidad": "Utilidad"}
const TOPES :={
	"danio_hecho": [0.0, 0.6],
	"danio_recibido": [0.0, 0.5],
	"critico": [0.0, 3.0],
	"stab": [0.0, 0.5],
	"velocidad": [0.0, 0.6],
	"stats_todas": [0.0, 0.3],
	"aguante": [0.0, 1.0],
	"cura_victoria": [0.0, 1.0],
	"exp": [0.0, 1.0],
	"captura": [0.0, 1.0],
	"rareza": [0.0, 0.8],
	"encuentros": [-0.9, 1.0],
	"dinero": [0.0, 2.0],
	"descuento": [0.0, 0.5],
	"hallazgo": [0.0, 0.75],
	"grado_torre": [0.0, 2.0],
}

static func apilar(t: Trinket, copias: int) -> float:
	if t== null or copias<= 0:
		return 0.0
	var v: float
	match t.apilado:
		"no_apila":
			v= t.valor
		"curva":
			v =0.0
			for k in copias:
				v+= t.valor* pow(t.factor_curva, k)
		_:
			v= t.valor* copias
	if t.maximo!= 0.0:
		v =clampf(v, -absf(t.maximo), absf(t.maximo))
	return v

static func contar(efecto: String, portador: PokemonInstancia= null, equipo: Array= []) -> Dictionary:
	var cuenta:= {}
	if portador!= null:
		for id in portador.trinkets:
			var t:= BaseDatos.trinket(id)
			if t!= null and t.efecto== efecto and t.alcance== "portador":
				cuenta[id]= int(cuenta.get(id, 0))+ 1
	for p in equipo:
		if p== null:
			continue
		for id in p.trinkets:
			var t:= BaseDatos.trinket(id)
			if t!= null and t.efecto== efecto and t.alcance== "equipo":
				cuenta[id]= int(cuenta.get(id, 0))+ 1
	return cuenta

static func total(efecto: String, portador: PokemonInstancia= null, equipo: Array= []) -> float:
	var suma:= 0.0
	var cuenta:= contar(efecto, portador, equipo)
	for id in cuenta:
		suma+= apilar(BaseDatos.trinket(id), cuenta[id])
	var tope: Array= TOPES.get(efecto, [-INF, INF])
	return clampf(suma, tope[0], tope[1])

static func valor_texto(t: Trinket, v: float) -> String:
	match t.unidad:
		"fase":
			return "%+d fase%s" % [roundi(v), "" if absi(roundi(v))== 1 else "s"]
		"multiplicador":
			return "×%s" % _num(1.0+ v)
		"unico":
			return "activo"
	return "%s%%" % _num(v* 100.0, true)

static func _num(v: float, signo:= false) -> String:
	var s:= str(snappedf(v, 0.1))
	if s.ends_with(".0"):
		s= s.trim_suffix(".0")
	if signo and v>= 0.0:
		s ="+"+ s
	return s

static func limite(t: Trinket) -> float:
	var lim:= INF
	if t.apilado== "curva" and t.factor_curva< 1.0:
		lim= absf(t.valor)/ (1.0- t.factor_curva)
	if t.maximo!= 0.0:
		lim =minf(lim, absf(t.maximo))
	return lim

static func texto_apilado(t: Trinket) -> String:
	var tope:= ""
	var lim:= limite(t)
	if lim< INF:
		tope= " (máx. %s)" % valor_texto(t, lim* signf(t.valor))
	match t.apilado:
		"no_apila":
			return "No se apila: más copias no suman efecto."
		"curva":
			var pasos: Array[String]= []
			for k in 3:
				pasos.append(valor_texto(t, t.valor* pow(t.factor_curva, k)))
			return "Apilable con rendimiento decreciente: %s...%s" % [", ".join(pasos), tope]
	return "Apilable: cada copia suma %s%s." % [valor_texto(t, t.valor), tope]

static func texto_alcance(t: Trinket) -> String:
	return "Portador" if t.alcance== "portador" else "Todo el equipo"

static func texto_tier(t: Trinket) -> String:
	return "Nivel %d · %s" % [t.tier, NOMBRES_TIER[t.tier]]

static func color_tier(tier: int) -> Color:
	return Color(COLORES_TIER[clampi(tier, 0, 5)])

static func icono(t: Trinket) -> Texture2D:
	if t.icono!= null:
		return t.icono
	var ruta:= "res://Assets/Trinkets/%s.png" % t.id
	return load(ruta) if ResourceLoader.exists(ruta) else null

static func todos() -> Array[Trinket]:
	var lista: Array[Trinket]= []
	for id in BaseDatos.ids(BaseDatos.TRINKETS):
		var t:= BaseDatos.trinket(id)
		if t!= null:
			lista.append(t)
	return lista

static func de_tier(tier: int) -> Array[Trinket]:
	return todos().filter(func(t): return t.tier== tier)

static func al_azar(tier: int, rng: RandomNumberGenerator) -> Trinket:
	var lista:= de_tier(tier)
	if lista.is_empty():
		return null
	return lista[rng.randi_range(0, lista.size()- 1)]

static func grado(turnos: int, ps_fraccion: float) -> Dictionary:
	var puntos:= 60.0* clampf(ps_fraccion, 0.0, 1.0)+ 40.0* clampf(1.0- (turnos- 1)/ 6.0, 0.0, 1.0)
	var tier:= 1
	if puntos>= 85.0:
		tier= 5
	elif puntos>= 70.0:
		tier =4
	elif puntos>= 50.0:
		tier= 3
	elif puntos>= 30.0:
		tier =2
	return {"puntos": roundi(puntos), "tier": tier}
