extends Control

const ARTE:= "res://Assets/UI/Archivos/"
const HEROE :=preload("res://Assets/Personajes/hero_godot_grid_40x40.png")
const CUADRO_HEROE:= Rect2i(0, 40, 40, 40)
const ICONOS :="res://Assets/Pokemones/iconos/"
const ANCHO:= 68
const ALTO :=56
const SUELO:= 52

var capas: Array[String]= []

func _ready() -> void:
	custom_minimum_size= Vector2(ANCHO, ALTO)
	size =Vector2(ANCHO, ALTO)
	clip_contents= true

func mostrar(r: Dictionary) -> void:
	for c in get_children():
		c.queue_free()
	capas.clear()
	if r.is_empty():
		_poner(load(ARTE+ "pagina_vacia.png"), Vector2.ZERO, "vacia")
		return
	_poner(load(ARTE+ "pagina.png"), Vector2.ZERO, "pagina")
	var ciudad:= str(r.get("ciudad", ""))
	if ciudad!= "" and ResourceLoader.exists(ARTE+ "ciudad_%s.png" % ciudad):
		var t: Texture2D= load(ARTE+ "ciudad_%s.png" % ciudad)
		_poner(t, Vector2(floori((ANCHO- t.get_width())/ 2.0)+ 3, 33- t.get_height()), "ciudad_" +ciudad)
	var usado_h:= HEROE.get_image().get_region(CUADRO_HEROE).get_used_rect()
	var h:= AtlasTexture.new()
	h.atlas= HEROE
	h.region =Rect2(usado_h.position+ CUADRO_HEROE.position, usado_h.size)
	_poner(h, Vector2(20- floori(usado_h.size.x/ 2.0), SUELO- usado_h.size.y), "heroe")
	var comp:= str(r.get("companero", ""))
	if comp!= "" and ResourceLoader.exists(ICONOS+ comp+ ".png"):
		var tex: Texture2D= load(ICONOS+ comp+ ".png")
		var usado:= tex.get_image().get_region(Rect2i(0, 0, 32, 32)).get_used_rect()
		var a:= AtlasTexture.new()
		a.atlas= tex
		a.region =Rect2(usado)
		_poner(a, Vector2(44- floori(usado.size.x/ 2.0), SUELO- usado.size.y), "companero_" +comp)
	var k:= 0
	for m in r.get("medallas", []):
		if ResourceLoader.exists(ARTE+ "pin_%s.png" % m):
			_poner(load(ARTE+ "pin_%s.png" % m), Vector2(11+ k* 10, 2), "pin_" +str(m))
			k+= 1
	if int(r.get("registros", 0))>= int(r.get("total_registros", 1)):
		_poner(load(ARTE+ "sello_safari.png"), Vector2(ANCHO- 14, 13), "sello_safari")
	if int(r.get("trinkets", 0))>= int(r.get("total_trinkets", 1)):
		_poner(load(ARTE+ "sello_trinkets.png"), Vector2(ANCHO- 14, 26), "sello_trinkets")
	if int(r.get("capturados", 0))>= int(r.get("total", 1)):
		_poner(load(ARTE+ "marco_oro.png"), Vector2.ZERO, "marco_oro")

func _poner(t: Texture2D, pos: Vector2, nombre: String) -> void:
	var tr:= TextureRect.new()
	tr.texture= t
	tr.position =pos
	tr.size= t.get_size()
	tr.stretch_mode =TextureRect.STRETCH_KEEP
	tr.texture_filter= CanvasItem.TEXTURE_FILTER_NEAREST
	tr.mouse_filter =Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	capas.append(nombre)
