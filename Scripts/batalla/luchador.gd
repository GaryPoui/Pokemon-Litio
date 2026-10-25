class_name Luchador
extends RefCounted

const ETAPAS:= ["ataque", "defensa", "at_esp", "def_esp", "velocidad", "precision", "evasion"]

var pokemon: PokemonInstancia
var etapas: Dictionary= {}
var turnos_sueno :=0
var retrocede:= false
var critico_extra: int =0
var aguante_usado:= false
var actuo_turno :=false
var herido_turno:= false
var confusion:= 0
var tipos_forzados: Array= []
var cargado :=0
var disfraz: PokemonInstancia

func _init(p: PokemonInstancia) -> void:
	pokemon= p
	for e in ETAPAS:
		etapas[e] =0

static func fraccion(stat: String, etapa: int) -> Vector2i:
	var b:= 3 if stat== "precision" or stat== "evasion" else 2
	return Vector2i(b+ maxi(etapa, 0), b- mini(etapa, 0))

static func factor(stat: String, etapa: int) -> float:
	var f:= fraccion(stat, etapa)
	return float(f.x)/ f.y

func stat_con_etapa(stat: String, etapa: int) -> int:
	var base:= pokemon.stat(stat)
	var extra:= EfectosTrinket.total("stats_todas", pokemon)
	if stat== "velocidad":
		extra =(1.0+ extra)* (1.0+ EfectosTrinket.total("velocidad", pokemon))- 1.0
	if extra!= 0.0:
		base= LogicaCombate.redondear(base, 1.0+ extra)
	var f:= fraccion(stat, etapa)
	return maxi(1, base* f.x/ f.y)

func stat_efectivo(stat: String) -> int:
	var v:= stat_con_etapa(stat, etapas[stat])
	if stat== "velocidad" and pokemon.estado =="par":
		v= maxi(1, floori(v* 0.25))
	return v

func cambiar_etapa(stat: String, cambio: int) -> int:
	var antes: int= etapas[stat]
	etapas[stat] =clampi(antes+ cambio, -6, 6)
	return etapas[stat]- antes

func tipos() -> Array:
	return tipos_forzados if not tipos_forzados.is_empty() else Array(pokemon.especie.tipos)

func nombre_visible() -> String:
	return disfraz.nombre() if disfraz!= null else pokemon.nombre()
