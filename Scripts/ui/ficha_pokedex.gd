extends CanvasLayer

signal cerrada

const FONDO:= preload("res://Assets/Fondos/pokedex.png")
const SPRITE :=preload("res://Scripts/batalla/sprite_pokemon.gd")

var lista_para:= false

func _ready() -> void:
	layer= 107

func armar(e: EspeciePokemon, titulo:= "¡Datos registrados en la Pokédex!") -> void:
	var fondo:= TextureRect.new()
	fondo.texture= FONDO
	add_child(fondo)
	var cab:= Panel.new()
	cab.position= Vector2(6, 3)
	cab.size =Vector2(244, 19)
	cab.add_theme_stylebox_override("panel", EstiloUI.panel())
	add_child(cab)
	var t:= EstiloUI.nuevo_label(titulo, 8, Vector2(6, 2))
	t.name= "Titulo"
	cab.add_child(t)
	var marco:= Panel.new()
	marco.name= "Marco"
	marco.position= Vector2(6, 24)
	marco.size =Vector2(100, 92)
	marco.add_theme_stylebox_override("panel", EstiloUI.madera())
	add_child(marco)
	var hoja:= Panel.new()
	hoja.position= Vector2(4, 4)
	hoja.size =Vector2(92, 84)
	hoja.add_theme_stylebox_override("panel", EstiloUI.hoja())
	marco.add_child(hoja)
	var spr: Sprite2D= SPRITE.new()
	spr.name= "Sprite"
	spr.texture_filter =CanvasItem.TEXTURE_FILTER_NEAREST
	spr.position= Vector2(56, 106)
	add_child(spr)
	spr.mostrar(e, false)
	spr.encajar_en(Rect2(12, 30, 88, 80))
	var datos:= Panel.new()
	datos.name= "Datos"
	datos.position= Vector2(110, 24)
	datos.size =Vector2(140, 92)
	datos.add_theme_stylebox_override("panel", EstiloUI.panel())
	add_child(datos)
	datos.add_child(_chico("N.º %03d" % e.numero, Vector2(6, 2), EstiloUI.TENUE))
	var nombre:= EstiloUI.nuevo_label(e.nombre, 9, Vector2(6, 12))
	nombre.name= "Nombre"
	datos.add_child(nombre)
	var cat:= _chico(e.categoria, Vector2(6, 28), EstiloUI.TENUE)
	cat.name= "Categoria"
	datos.add_child(cat)
	for k in e.tipos.size():
		var x:= 6+ k* 64
		datos.add_child(IconoTipo.crear(e.tipos[k], Vector2(x, 42)))
		var tl:= _chico(Tipos.nombre(e.tipos[k]), Vector2(x+ 15, 41), EstiloUI.color_tipo(e.tipos[k]).lightened(0.35))
		datos.add_child(tl)
	datos.add_child(_chico("Altura", Vector2(6, 58), EstiloUI.TENUE))
	datos.add_child(_chico(_num(e.altura)+ " m", Vector2(56, 58)))
	datos.add_child(_chico("Peso", Vector2(6, 72), EstiloUI.TENUE))
	datos.add_child(_chico(_num(e.peso_kg)+ " kg", Vector2(56, 72)))
	var abajo:= Panel.new()
	abajo.name= "Descripcion"
	abajo.position= Vector2(6, 118)
	abajo.size =Vector2(244, 70)
	abajo.add_theme_stylebox_override("panel", EstiloUI.panel())
	add_child(abajo)
	var texto:= EstiloUI.nuevo_label("", 8, Vector2(6, 3))
	texto.name= "Texto"
	texto.size= Vector2(232, 60)
	abajo.add_child(texto)
	texto.text= "\n".join(EstiloUI.envolver(e.descripcion, texto, 232))
	texto.add_theme_constant_override("line_spacing", -2)
	Sonido.grito(e.numero)

func esperar() -> void:
	await get_tree().create_timer(0.4).timeout
	lista_para= true
	await cerrada

static func _chico(t: String, pos: Vector2, color: Color= EstiloUI.TEXTO) -> Label:
	var l:= EstiloUI.nuevo_label(t, 8, pos, color)
	EstiloUI.fuente_batalla(l)
	return l

static func _num(v: float) -> String:
	return ("%.1f" % v).replace(".", ",")

func _unhandled_input(event: InputEvent) -> void:
	if lista_para and (event.is_action_pressed("aceptar") or event.is_action_pressed("cancelar")):
		get_viewport().set_input_as_handled()
		lista_para= false
		Sonido.efecto("confirmar")
		cerrada.emit()
