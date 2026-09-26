class_name EstiloUI
extends RefCounted

const TEXTO:= Color("383838")
const SOMBRA :=Color("d0d0c8")
const FONDO:= Color("f8f8f8")
const BORDE :=Color("3a4a6a")
const COLORES_TIPO:= {
	"normal": "a8a878", "fuego": "f08030", "agua": "6890f0", "planta": "78c850",
	"electrico": "f8d030", "hielo": "98d8d8", "lucha": "c03028", "veneno": "a040a0",
	"tierra": "e0c068", "volador": "a890f0", "psiquico": "f85888", "bicho": "a8b820",
	"roca": "b8a038", "fantasma": "705898", "dragon": "7038f8", "siniestro": "705848",
	"acero": "b8b8d0",
}
const ABREV_ESTADO :={"que": "QUE", "env": "ENV", "par": "PAR", "dor": "DOR", "con": "CON"}
const ANCHO_INSIGNIA:= 48
const FUENTE_NORMAL:= preload("res://Assets/Fuentes/TruthAndIdeals.ttf")
const FUENTE_PEQUENA :=preload("res://Assets/Fuentes/SmallTruths.ttf")
const FUENTE_BATALLA:= preload("res://Assets/Fuentes/FightingIdeals.ttf")

static func panel(fondo: Color= FONDO, borde: Color= BORDE) -> StyleBoxFlat:
	var e:= StyleBoxFlat.new()
	e.bg_color= fondo
	e.set_border_width_all(2)
	e.border_color =borde
	e.set_corner_radius_all(3)
	return e

static func fuente(c: Control, tam: int) -> void:
	if tam>= 16:
		c.add_theme_font_override("font", FUENTE_NORMAL)
		c.add_theme_font_size_override("font_size", 20)
	elif tam>= 7:
		c.add_theme_font_override("font", FUENTE_NORMAL)
		c.add_theme_font_size_override("font_size", 10)
	else:
		c.add_theme_font_override("font", FUENTE_PEQUENA)
		c.add_theme_font_size_override("font_size", 10)

static func fuente_batalla(c: Control) -> void:
	c.add_theme_font_override("font", FUENTE_BATALLA)
	c.add_theme_font_size_override("font_size", 10)

static func label(l: Label, tam: int, color: Color= TEXTO) -> void:
	fuente(l, tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", SOMBRA if color== TEXTO else Color(0, 0, 0, 0.35))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)

static func nuevo_label(texto: String, tam: int, pos: Vector2, color: Color= TEXTO) -> Label:
	var l:= Label.new()
	label(l, tam, color)
	l.text= texto
	l.position =pos
	return l

static func color_tipo(tipo: String) -> Color:
	return Color(COLORES_TIPO.get(tipo, "888888"))

static func insignia_tipo(tipo: String, pos: Vector2) -> Panel:
	var p:= Panel.new()
	p.position= pos
	p.size =Vector2(ANCHO_INSIGNIA, 11)
	p.add_theme_stylebox_override("panel", panel(color_tipo(tipo), color_tipo(tipo).darkened(0.35)))
	var l:= nuevo_label(Tipos.nombre(tipo).to_upper(), 6, Vector2(0, 0), Color.WHITE)
	l.horizontal_alignment =HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment= VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return p

static func icono(especie: EspeciePokemon) -> AtlasTexture:
	var at:= AtlasTexture.new()
	at.atlas= especie.sprite_frente
	var ancho:= floori(especie.sprite_frente.get_width()/ float(maxi(1, especie.cuadros_frente)))
	at.region =Rect2(0, 0, ancho, especie.sprite_frente.get_height())
	return at
