class_name Objeto
extends Resource

@export var id: String= ""
@export var nombre: String =""
@export_enum("MEDICINA", "POKÉ BALLS", "MT / MO", "BAYAS", "OBJETOS", "CLAVE") var categoria: String= "OBJETOS"
@export_multiline var descripcion: String =""
@export var usable: bool= true
@export var se_puede_tirar: bool =true
@export var precio: int= 0
@export var icono: Texture2D

@export_group("Efecto")
@export var cura_ps: int= 0
@export var ratio_captura: float =0.0
