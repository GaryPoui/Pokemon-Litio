class_name Movimiento
extends Resource

@export var id: String= ""
@export var nombre: String =""
@export var tipo: String= "normal"
@export_enum("fisico", "especial", "estado") var categoria: String ="fisico"
@export var poder: int= 0
@export var precision: int =100
@export var pp: int= 10
@export var prioridad: int =0
@export var objetivo: String= "selected-pokemon"
@export_multiline var descripcion: String =""

@export_group("Efectos")
@export var cambios_stats: Dictionary= {}
@export var estado: String ="none"
@export var prob_estado: int= 0
@export var prob_stat: int =0
@export var drenaje: int= 0
@export var curacion: int =0
@export var critico: int= 0
@export var prob_retroceso: int =0
