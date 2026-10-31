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
var habilidad: String= ""
var v: Dictionary ={}
var sustituto:= 0
var cargando: Movimiento
var invulnerable :=""
var recarga:= false
var ultimo_mov: Movimiento
var mov_bloqueado: Movimiento
var turnos_bloqueo :=0
var turnos_en_campo:= 0
var danio_recibido: Dictionary ={}
var peso_extra :=0.0
var transformado: PokemonInstancia
var movs_transformado: Array[Movimiento]= []
var pp_transformado: Array[int] =[]
var stats_transformado: Dictionary= {}
var toxico :=0
var protegido:= false
var racha_proteccion :=0
var objeto_perdido:= false

func _init(p: PokemonInstancia) -> void:
	pokemon= p
	for e in ETAPAS:
		etapas[e] =0
	if p!= null:
		habilidad= p.habilidad

static func fraccion(stat: String, etapa: int) -> Vector2i:
	var b:= 3 if stat== "precision" or stat== "evasion" else 2
	return Vector2i(b+ maxi(etapa, 0), b- mini(etapa, 0))

static func factor(stat: String, etapa: int) -> float:
	var f:= fraccion(stat, etapa)
	return float(f.x)/ f.y

func tiene(clave: String) -> bool:
	return v.has(clave)

func valor(clave: String, defecto= 0):
	return v.get(clave, defecto)

func poner(clave: String, dato= true) -> void:
	v[clave]= dato

func quitar(clave: String) -> void:
	v.erase(clave)

func stat_base_batalla(stat: String) -> int:
	if not stats_transformado.is_empty() and stats_transformado.has(stat):
		return int(stats_transformado[stat])
	return pokemon.stat(stat)

func stat_con_etapa(stat: String, etapa: int) -> int:
	var base:= stat_base_batalla(stat)
	var extra:= EfectosTrinket.total("stats_todas", pokemon)
	if stat== "velocidad":
		extra =(1.0+ extra)* (1.0+ EfectosTrinket.total("velocidad", pokemon))- 1.0
	if extra!= 0.0:
		base= LogicaCombate.redondear(base, 1.0+ extra)
	var f:= fraccion(stat, etapa)
	return maxi(1, base* f.x/ f.y)

func stat_efectivo(stat: String) -> int:
	var v2:= stat_con_etapa(stat, etapas[stat])
	if stat== "velocidad" and pokemon.estado =="par" and habilidad!= "quick_feet":
		v2= maxi(1, floori(v2* 0.25))
	return v2

func cambiar_etapa(stat: String, cambio: int) -> int:
	var antes: int= etapas[stat]
	etapas[stat] =clampi(antes+ cambio, -6, 6)
	return etapas[stat]- antes

func tipos() -> Array:
	var base:= tipos_forzados if not tipos_forzados.is_empty() else Array(pokemon.especie.tipos)
	if tiene("respiro"):
		return base.filter(func(t): return t!= "volador") if base.size()> 1 or base!= ["volador"] else ["normal"]
	return base

func movimientos() -> Array[Movimiento]:
	return movs_transformado if transformado!= null else pokemon.movimientos

func pp() -> Array[int]:
	return pp_transformado if transformado!= null else pokemon.pp

func nombre_visible() -> String:
	return disfraz.nombre() if disfraz!= null else pokemon.nombre()

func peso() -> float:
	var kg:= BaseDatos.peso(pokemon.especie.id)
	if transformado!= null:
		kg= BaseDatos.peso(transformado.especie.id)
	kg= maxf(0.1, kg+ peso_extra)
	if habilidad== "heavy_metal":
		kg*= 2.0
	elif habilidad== "light_metal":
		kg= maxf(0.1, kg/ 2.0)
	return kg
