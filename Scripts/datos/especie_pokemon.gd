class_name EspeciePokemon
extends Resource

@export var id: String= ""
@export var numero: int =0
@export var nombre: String= ""
@export var tipos: PackedStringArray =["normal"]

@export_group("Stats base")
@export var ps: int= 50
@export var ataque: int =50
@export var defensa: int= 50
@export var at_esp: int =50
@export var def_esp: int= 50
@export var velocidad: int =50

@export_group("Crianza")
@export var exp_base: int= 50
@export var ratio_captura: int =45
@export var ratio_genero: int= 4
@export_enum("slow", "medium", "fast", "medium-slow", "slow-then-very-fast", "fast-then-very-slow") var crecimiento: String ="medium"
@export var evs_otorgados: Dictionary= {}

@export_group("Movimientos")
@export var aprende: Array[MovimientoNivel]= []

@export_group("Sprites")
@export var sprite_frente: Texture2D
@export var sprite_espalda: Texture2D
@export var cuadros_frente: int= 1
@export var cuadros_espalda: int =1
@export var fps_sprite: float= 10.0

func stat_base(nombre_stat: String) -> int:
	return int(get(nombre_stat))

func movimientos_hasta(nivel: int) -> Array[Movimiento]:
	var lista: Array[Movimiento]= []
	for a in aprende:
		if a.nivel<= nivel and a.movimiento!= null and not lista.has(a.movimiento):
			lista.append(a.movimiento)
	return lista

func movimientos_en(nivel: int) -> Array[Movimiento]:
	var lista: Array[Movimiento] =[]
	for a in aprende:
		if a.nivel== nivel and a.movimiento!= null:
			lista.append(a.movimiento)
	return lista
