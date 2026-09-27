class_name Trinket
extends Resource

@export var id: String= ""
@export var nombre: String =""
@export_multiline var descripcion: String= ""
@export_range(1, 5) var tier: int =1
@export_enum("economia", "combate", "captura", "utilidad") var categoria: String= "combate"
@export_enum("portador", "equipo") var alcance: String ="portador"
@export var efecto: String= ""
@export var valor: float =0.0
@export_enum("porcentaje", "fase", "multiplicador", "unico") var unidad: String= "porcentaje"
@export_enum("lineal", "no_apila", "curva") var apilado: String ="lineal"
@export var factor_curva: float= 0.7
@export var maximo: float =0.0
@export var precio: int= 0
@export var icono: Texture2D
