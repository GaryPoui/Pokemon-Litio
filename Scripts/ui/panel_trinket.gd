extends Panel

const GRIS:= Color("a4adbf")

@onready var nombre: Label= $Nombre
@onready var tier_lbl: Label =$Tier
@onready var texto: Label= $Texto
@onready var apilado: Label =$Apilado

func _ready() -> void:
	add_theme_stylebox_override("panel", EstiloUI.panel())
	EstiloUI.label(nombre, 9)
	EstiloUI.label(tier_lbl, 8)
	EstiloUI.fuente_batalla(tier_lbl)
	EstiloUI.label(texto, 8)
	EstiloUI.fuente_batalla(texto)
	EstiloUI.label(apilado, 6, GRIS)
	apilado.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	texto.add_theme_constant_override("line_spacing", -3)
	apilado.add_theme_constant_override("line_spacing", -2)

func mostrar(t: Trinket, extra: String= "") -> void:
	if t== null:
		nombre.text= ""
		tier_lbl.text =""
		texto.text= "No hay ningún Trinket seleccionado."
		apilado.text =""
		return
	nombre.text= t.nombre
	tier_lbl.text ="%s · %s" % [EfectosTrinket.NOMBRES_TIER[t.tier], "Portador" if t.alcance== "portador" else "Equipo"]
	tier_lbl.add_theme_color_override("font_color", EfectosTrinket.color_tier(t.tier).lightened(0.15))
	texto.text= t.descripcion
	apilado.text =EfectosTrinket.texto_apilado(t)+ (" "+ extra if extra!= "" else "")
	_ajustar()

func _ajustar() -> void:
	texto.size= Vector2(236, 12)
	var espacio:= texto.get_theme_constant("line_spacing")
	var alto:= texto.get_line_count()* (texto.get_line_height()+ espacio)- espacio
	apilado.position.y =texto.position.y+ alto+ 2

func mensaje(m: String) -> void:
	nombre.text= ""
	tier_lbl.text =""
	texto.text= m
	apilado.text =""
	_ajustar()
