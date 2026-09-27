class_name Luchador
extends RefCounted

const ETAPAS:= ["ataque", "defensa", "at_esp", "def_esp", "velocidad", "precision", "evasion"]

var pokemon: PokemonInstancia
var etapas: Dictionary= {}
var turnos_sueno :=0
var retrocede:= false
var critico_extra: int =0
var aguante_usado:= false

func _init(p: PokemonInstancia) -> void:
	pokemon= p
	for e in ETAPAS:
		etapas[e] =0

static func factor(stat: String, etapa: int) -> float:
	if stat== "precision" or stat== "evasion":
		return (3.0+ maxi(etapa, 0))/ (3.0 -mini(etapa, 0))
	return (2.0 +maxi(etapa, 0))/ (2.0- mini(etapa, 0))

func stat_con_etapa(stat: String, etapa: int) -> int:
	var base:= float(pokemon.stat(stat))* (1.0+ EfectosTrinket.total("stats_todas", pokemon))
	if stat== "velocidad":
		base*= 1.0+ EfectosTrinket.total("velocidad", pokemon)
	return maxi(1, floori(base* factor(stat, etapa)))

func stat_efectivo(stat: String) -> int:
	var v:= stat_con_etapa(stat, etapas[stat])
	if stat== "velocidad" and pokemon.estado =="par":
		v= maxi(1, floori(v* 0.25))
	return v

func cambiar_etapa(stat: String, cambio: int) -> int:
	var antes: int= etapas[stat]
	etapas[stat] =clampi(antes+ cambio, -6, 6)
	return etapas[stat]- antes
