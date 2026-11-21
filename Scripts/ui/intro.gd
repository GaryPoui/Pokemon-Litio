extends CanvasLayer

signal terminado
signal aspecto_listo

const RETRATO_OMBU:= preload("res://Assets/UI/Intro/ombu.png")
const SPRITE :=preload("res://Scripts/batalla/sprite_pokemon.gd")
const TECLADO:= preload("res://Scripts/ui/teclado_mote.gd")
const HEROES :="res://Assets/Personajes/Heroes/%s"
const POKEMON:= "res://Datos/Especies/lillipup.tres"
const CELDA :=Vector2(60, 80)
const X0:= 8
const Y0 :=16
const BASE:= 140

var ombu: TextureRect
var pokemon: Sprite2D
var grilla: Control
var retratos: Array[TextureRect]= []
var marco: Panel
var elegido: TextureRect
var destello: ColorRect
var eligiendo_aspecto:= false
var cursor :=0

func _ready() -> void:
	layer= 105
	var g:= Gradient.new()
	g.set_color(0, Color("eef3f7"))
	g.set_color(1, Color("c4d2e0"))
	var gt:= GradientTexture2D.new()
	gt.gradient= g
	gt.fill_to =Vector2(0, 1)
	gt.width= 256
	gt.height =192
	var fondo:= TextureRect.new()
	fondo.texture= gt
	add_child(fondo)
	ombu= _imagen(RETRATO_OMBU, Vector2(100, BASE- RETRATO_OMBU.get_height()))
	add_child(ombu)
	pokemon= SPRITE.new()
	pokemon.position =Vector2(194, BASE)
	pokemon.visible= false
	add_child(pokemon)
	elegido= TextureRect.new()
	elegido.texture_filter =CanvasItem.TEXTURE_FILTER_NEAREST
	elegido.visible= false
	add_child(elegido)
	grilla= Control.new()
	grilla.visible =false
	add_child(grilla)
	grilla.add_child(EstiloUI.nuevo_label("ELEGÍ TU ASPECTO", 9, Vector2(8, 3), EstiloUI.TEXTO_OSCURO))
	for i in Estado.HEROES.size():
		var pos:= _celda(i)
		var p:= Panel.new()
		p.position= pos+ Vector2(1, 1)
		p.size =CELDA- Vector2(2, 2)
		p.add_theme_stylebox_override("panel", EstiloUI.hoja())
		grilla.add_child(p)
		var tex: Texture2D= load(HEROES % (Estado.HEROES[i]+ "_retrato.png"))
		var r:= _imagen(tex, pos+ Vector2(floori((CELDA.x- tex.get_width())/ 2.0), CELDA.y- 3- tex.get_height()))
		grilla.add_child(r)
		retratos.append(r)
	marco= Panel.new()
	marco.size= CELDA
	marco.add_theme_stylebox_override("panel", EstiloUI.panel(Color(1, 0.85, 0.3, 0.12), Color("ffd84a")))
	marco.mouse_filter =Control.MOUSE_FILTER_IGNORE
	grilla.add_child(marco)
	grilla.add_child(EstiloUI.nuevo_label("A: elegir", 8, Vector2(200, 4), EstiloUI.TEXTO_OSCURO))
	destello= ColorRect.new()
	destello.color =Color(1, 1, 1, 0)
	destello.size= Vector2(256, 192)
	destello.mouse_filter= Control.MOUSE_FILTER_IGNORE
	add_child(destello)
	_pintar()

func _imagen(tex: Texture2D, pos: Vector2) -> TextureRect:
	var r:= TextureRect.new()
	r.texture= tex
	r.position =pos
	r.size= tex.get_size()
	r.texture_filter =CanvasItem.TEXTURE_FILTER_NEAREST
	r.mouse_filter= Control.MOUSE_FILTER_IGNORE
	return r

func _celda(i: int) -> Vector2:
	return Vector2(X0+ (i% 4)* CELDA.x, Y0+ (i/ 4)* CELDA.y)

func _pintar() -> void:
	marco.position= _celda(cursor)
	for i in retratos.size():
		retratos[i].modulate =Color.WHITE if i== cursor else Color(0.62, 0.62, 0.66)

func correr() -> void:
	await Dialogo.mostrar("¡Hola! ¡Qué bueno verte por acá!")
	await Dialogo.mostrar("Soy Ombú. Algunos me dicen profesor; yo estudio a los Pokémon... y tomo mucho mate.")
	await _sacar_pokemon()
	await Dialogo.mostrar("Este es Lillipup. Acá la gente y los Pokémon viven juntos: juegan, trabajan y combaten codo a codo.")
	await _guardar_pokemon()
	await Dialogo.mostrar("Pero no te quiero aburrir con discursos. Contame un poco de vos.")
	while true:
		var id:= await _elegir_aspecto()
		_mostrar_elegido(id)
		var r: int= await Dialogo.preguntar("¿Así sos vos?")
		if r== 0:
			Estado.heroe= id
			break
	await Dialogo.mostrar("¿Y cómo te llamás?")
	var nombre:= ""
	while true:
		nombre= await _pedir_nombre(nombre)
		var r: int= await Dialogo.preguntar("Así que te llamás %s. ¿Está bien?" % nombre)
		if r== 0:
			break
	Estado.nombre_jugador= nombre
	await Dialogo.mostrar("¡%s! Lindo nombre. %s al mundo de los Pokémon." % [nombre, Estado.g("Bienvenido", "Bienvenida")])
	await Dialogo.mostrar("Te espero en la Usina del Arte, acá en La Boca. Tengo algo para vos. ¡Nos vemos!")
	terminado.emit()

func _sacar_pokemon() -> void:
	var e: EspeciePokemon= load(POKEMON)
	Sonido.efecto("ball_abrir")
	var tw:= create_tween()
	tw.tween_property(destello, "color:a", 0.85, 0.08)
	await tw.finished
	pokemon.mostrar(e, false)
	pokemon.modulate.a= 1.0
	tw= create_tween()
	tw.tween_property(destello, "color:a", 0.0, 0.3)
	Sonido.grito(e.numero)
	await tw.finished

func _guardar_pokemon() -> void:
	var tw:= create_tween()
	tw.tween_property(pokemon, "modulate:a", 0.0, 0.3)
	await tw.finished
	pokemon.visible= false

func _elegir_aspecto() -> String:
	ombu.visible= false
	elegido.visible =false
	grilla.visible= true
	eligiendo_aspecto =true
	_pintar()
	await aspecto_listo
	eligiendo_aspecto= false
	grilla.visible =false
	return Estado.HEROES[cursor]

func _mostrar_elegido(id: String) -> void:
	ombu.position= Vector2(40, BASE- RETRATO_OMBU.get_height())
	ombu.visible =true
	var tex: Texture2D= load(HEROES % (id+ "_retrato.png"))
	elegido.texture= tex
	elegido.size =tex.get_size()
	elegido.position= Vector2(176- floori(tex.get_width()/ 2.0), BASE- tex.get_height())
	elegido.visible= true

func _pedir_nombre(previo: String) -> String:
	var t= TECLADO.new()
	var icono:= AtlasTexture.new()
	icono.atlas= load(HEROES % (Estado.heroe+ ".png"))
	icono.region =Rect2(0, 40, 40, 40)
	await GestorEscenas.fundido(func():
		add_child(t)
		t.armar_texto("Tu nombre", icono, 10)
		t.exigir= true
		t.escribir(previo))
	var n: String= await t.esperar()
	await GestorEscenas.fundido(func(): t.queue_free())
	return n

func _unhandled_input(event: InputEvent) -> void:
	if not eligiendo_aspecto:
		return
	var n:= Estado.HEROES.size()
	if event.is_action_pressed("derecha"):
		cursor= wrapi(cursor+ 1, 0, n)
	elif event.is_action_pressed("izquierda"):
		cursor =wrapi(cursor- 1, 0, n)
	elif event.is_action_pressed("abajo") or event.is_action_pressed("arriba"):
		cursor= wrapi(cursor+ 4, 0, n)
	elif event.is_action_pressed("aceptar"):
		get_viewport().set_input_as_handled()
		Sonido.efecto("confirmar")
		aspecto_listo.emit()
		return
	else:
		return
	get_viewport().set_input_as_handled()
	Sonido.efecto("cursor")
	_pintar()
