extends CanvasLayer

signal cerrado

const ICONOS:= "res://Assets/Pokemones/iconos/"
const INICIALES :=[
	["I", ["bulbasaur", "charmander", "squirtle"]],
	["II", ["chikorita", "cyndaquil", "totodile"]],
	["III", ["treecko", "torchic", "mudkip"]],
	["IV", ["turtwig", "chimchar", "piplup"]],
	["V", ["snivy", "tepig", "oshawott"]],
]
const NIVEL:= 5
const X_CELDA :=30
const PASO_X:= 38
const PASO_Y :=31
const ICONO_Y:= 16

@onready var grilla: Panel= $Grilla
@onready var marco: Panel =$Grilla/Marco
@onready var info: Panel= $Info
@onready var sprite: Sprite2D =$Info/Pokemon
@onready var nombre: Label= $Info/Nombre
@onready var nivel: Label =$Info/Nivel
@onready var tipos: Control= $Info/Tipos

var fila:= 0
var col :=0
var iconos: Array= []
var tiempo:= 0.0
var ocupado :=false

func _ready() -> void:
	layer= 107
	for p in [$Cabecera, grilla, info]:
		p.add_theme_stylebox_override("panel", EstiloUI.panel())
	EstiloUI.label($Cabecera/Titulo, 9)
	$Cabecera/Titulo.text= "POKÉMON INICIALES"
	EstiloUI.label(nombre, 9)
	EstiloUI.label(nivel, 8)
	EstiloUI.fuente_batalla(nivel)
	EstiloUI.label($Info/Ayuda, 6, EstiloUI.TENUE)
	$Info/Ayuda.text= "A: RECIBIR   B: SALIR"
	var m:= StyleBoxFlat.new()
	m.bg_color =Color(0, 0, 0, 0)
	m.set_border_width_all(2)
	m.border_color= Color("e05a30")
	m.set_corner_radius_all(4)
	marco.add_theme_stylebox_override("panel", m)
	for f in INICIALES.size():
		var g:= EstiloUI.nuevo_label(INICIALES[f][0], 8, Vector2(4, 8+ f* PASO_Y))
		EstiloUI.fuente_batalla(g)
		g.size.x= 22
		g.horizontal_alignment =HORIZONTAL_ALIGNMENT_CENTER
		grilla.add_child(g)
		var linea: Array= []
		for c in 3:
			var hueco:= Panel.new()
			hueco.position= _celda(f, c)
			hueco.size =Vector2(34, 29)
			var st:= StyleBoxFlat.new()
			st.bg_color= Color("2a3448")
			st.set_border_width_all(1)
			st.border_color =Color("5a6c90")
			st.set_corner_radius_all(3)
			hueco.add_theme_stylebox_override("panel", st)
			grilla.add_child(hueco)
			var ic:= Sprite2D.new()
			ic.texture= load(ICONOS+ "%s.png" % INICIALES[f][1][c])
			ic.hframes =2
			ic.position= Vector2(17, ICONO_Y)
			hueco.add_child(ic)
			linea.append(ic)
		iconos.append(linea)
	grilla.move_child(marco, -1)
	_pintar()

func _celda(f: int, c: int) -> Vector2:
	return Vector2(X_CELDA+ c* PASO_X, 3+ f* PASO_Y)

func especie_elegida() -> EspeciePokemon:
	return BaseDatos.especie(INICIALES[fila][1][col])

func _pintar() -> void:
	marco.position= _celda(fila, col)- Vector2(2, 2)
	marco.size =Vector2(38, 33)
	var e:= especie_elegida()
	nombre.text= e.nombre
	sprite.mostrar(e, false)
	nivel.text ="Nv. %d" % NIVEL
	for h in tipos.get_children():
		h.queue_free()
	for i in e.tipos.size():
		var ins:= EstiloUI.insignia_tipo(e.tipos[i], Vector2(0, i* 13))
		ins.position.x= (tipos.size.x- ins.size.x)/ 2.0
		tipos.add_child(ins)

func _process(delta: float) -> void:
	tiempo+= delta
	for f in iconos.size():
		for c in 3:
			var ic: Sprite2D= iconos[f][c]
			var elegido:= f== fila and c== col
			var fase:= int(tiempo/ (0.14 if elegido else 0.3))% 2
			ic.frame= fase
			ic.position.y =ICONO_Y- fase* (2 if elegido else 0)

func _unhandled_input(event: InputEvent) -> void:
	if ocupado or GestorEscenas.en_transicion or Dialogo.esta_abierto:
		return
	if event.is_action_pressed("cancelar") or event.is_action_pressed("menu"):
		Sonido.efecto("cancelar")
		cerrado.emit()
	elif event.is_action_pressed("aceptar"):
		get_viewport().set_input_as_handled()
		Sonido.efecto("confirmar")
		_recibir()
		return
	elif event.is_action_pressed("izquierda"):
		col= posmod(col- 1, 3)
	elif event.is_action_pressed("derecha"):
		col =posmod(col+ 1, 3)
	elif event.is_action_pressed("arriba"):
		fila= posmod(fila- 1, INICIALES.size())
	elif event.is_action_pressed("abajo"):
		fila =posmod(fila+ 1, INICIALES.size())
	else:
		return
	Sonido.efecto("cursor")
	_pintar()
	get_viewport().set_input_as_handled()

func _recibir() -> void:
	ocupado= true
	var e:= especie_elegida()
	var r: int= await Dialogo.preguntar("¿Quieres recibir a %s (Nv. %d)?" % [e.nombre, NIVEL])
	if r== 0:
		var destino:= Equipo.recibir(PokemonInstancia.crear(e, NIVEL))
		Sonido.jingle("captura")
		await Dialogo.mostrar("¡Recibiste a %s!" % e.nombre+ (" Como tu equipo está lleno, fue enviado a la Caja." if destino== "caja" else ""))
		Sonido.cortar_jingle()
	ocupado =false
