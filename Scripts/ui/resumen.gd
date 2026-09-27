extends CanvasLayer

signal cerrado

const PAGINAS:= ["INFO", "STATS", "MOVS"]
const NOMBRES_STAT :={"ps": "PS", "ataque": "Ataque", "defensa": "Defensa", "at_esp": "At. Esp.", "def_esp": "Def. Esp.", "velocidad": "Velocidad"}
const COLORES_STAT:= {"ps": Color("58d060"), "ataque": Color("f08838"), "defensa": Color("f0d048"), "at_esp": Color("58a0f0"), "def_esp": Color("78d0c0"), "velocidad": Color("f070a0")}
const SUBE :=Color("ff8a70")
const BAJA:= Color("80b0ff")
const UI :="res://Assets/Batalla/ui_nueva/"
const BOTONES_TIPO:= "res://Assets/Botones/tipos/"

@onready var sprite: Sprite2D= $Sprite
@onready var contenido: Control =$Contenido
@onready var datos_izq: Control= $DatosIzq
@onready var pestanas: Control =$Pestanas

var indice:= 0
var pagina :=0
var tabs: Array[Panel]= []

func _ready() -> void:
	layer= 108
	$Izq.add_theme_stylebox_override("panel", EstiloUI.madera())
	$Der.add_theme_stylebox_override("panel", EstiloUI.madera())
	$Escenario.add_theme_stylebox_override("panel", _escenario())
	$Hoja.add_theme_stylebox_override("panel", EstiloUI.hoja())
	$Titulo.visible= false
	for i in PAGINAS.size():
		var t:= Panel.new()
		t.position= Vector2(i* 46, 0)
		t.size =Vector2(44, 14)
		var l:= EstiloUI.nuevo_label(PAGINAS[i], 8, Vector2.ZERO)
		EstiloUI.fuente_batalla(l)
		l.size= t.size
		l.horizontal_alignment =HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment= VERTICAL_ALIGNMENT_CENTER
		t.add_child(l)
		pestanas.add_child(t)
		tabs.append(t)

func _escenario() -> StyleBoxFlat:
	var s:= StyleBoxFlat.new()
	s.bg_color= Color(0.08, 0.1, 0.16, 0.9)
	s.set_border_width_all(1)
	s.border_color =Color("2a1a10")
	s.set_corner_radius_all(4)
	return s

func _pestana(activa: bool) -> StyleBoxFlat:
	var s:= StyleBoxFlat.new()
	s.bg_color= Color("e05a30") if activa else Color(0.05, 0.06, 0.09, 0.7)
	s.set_border_width_all(1)
	s.border_color =Color("f8d8a0") if activa else Color("2a1a10")
	s.set_corner_radius_all(3)
	return s

func abrir(i: int) -> void:
	indice= i
	_mostrar()

func _unhandled_input(event: InputEvent) -> void:
	if GestorEscenas.en_transicion:
		return
	if event.is_action_pressed("cancelar") or event.is_action_pressed("menu"):
		Sonido.efecto("cancelar")
		cerrado.emit()
	elif event.is_action_pressed("derecha"):
		pagina= (pagina+ 1)% PAGINAS.size()
		_mostrar()
		Sonido.efecto("cursor")
	elif event.is_action_pressed("izquierda"):
		pagina =(pagina+ PAGINAS.size()- 1)% PAGINAS.size()
		_mostrar()
		Sonido.efecto("cursor")
	elif event.is_action_pressed("abajo") and indice+ 1< Equipo.miembros.size():
		indice+= 1
		_mostrar()
		Sonido.efecto("cursor")
	elif event.is_action_pressed("arriba") and indice> 0:
		indice -=1
		_mostrar()
		Sonido.efecto("cursor")
	else:
		return
	get_viewport().set_input_as_handled()

func _limpiar(c: Control) -> void:
	for h in c.get_children():
		h.queue_free()

func _mostrar() -> void:
	var p:= Equipo.miembros[indice]
	for i in tabs.size():
		tabs[i].add_theme_stylebox_override("panel", _pestana(i== pagina))
	sprite.mostrar(p.especie, false)
	_limpiar(datos_izq)
	var nombre:= EstiloUI.nuevo_label(p.nombre(), 9, Vector2(6, 2))
	datos_izq.add_child(nombre)
	var gen:= EstiloUI.nuevo_label(p.simbolo_genero(), 9, Vector2(6+ nombre.get_combined_minimum_size().x+ 2, 2), p.color_genero())
	datos_izq.add_child(gen)
	var ball:= BaseDatos.objeto(p.ball)
	if ball!= null and ball.icono!= null:
		var ic:= TextureRect.new()
		ic.texture= ball.icono
		ic.position =Vector2(66, -6)
		datos_izq.add_child(ic)
	var nv:= EstiloUI.nuevo_label("Nv. %d" % p.nivel, 8, Vector2(8, 110))
	EstiloUI.fuente_batalla(nv)
	datos_izq.add_child(nv)
	if EstiloUI.ABREV_ESTADO.has(p.estado):
		var st:= EstiloUI.nuevo_label(EstiloUI.ABREV_ESTADO[p.estado], 8, Vector2(62, 110), SUBE)
		EstiloUI.fuente_batalla(st)
		datos_izq.add_child(st)
	for k in p.especie.tipos.size():
		datos_izq.add_child(EstiloUI.insignia_tipo(p.especie.tipos[k], Vector2(24, 126+ k* 13)))
	var ayuda:= EstiloUI.nuevo_label("◀▶ página\n▲▼ Pokémon", 6, Vector2(8, 158), EstiloUI.TENUE)
	datos_izq.add_child(ayuda)
	_limpiar(contenido)
	match pagina:
		0:
			_pagina_info(p)
		1:
			_pagina_stats(p)
		2:
			_pagina_movimientos(p)

func _fila(texto: String, valor: String, y: float, color: Color= EstiloUI.TEXTO) -> Label:
	var t:= EstiloUI.nuevo_label(texto, 8, Vector2(4, y), EstiloUI.TENUE)
	EstiloUI.fuente_batalla(t)
	contenido.add_child(t)
	var v:= EstiloUI.nuevo_label(valor, 8, Vector2(50, y), color)
	EstiloUI.fuente_batalla(v)
	v.size= Vector2(78, 11)
	v.horizontal_alignment =HORIZONTAL_ALIGNMENT_RIGHT
	contenido.add_child(v)
	return v

func _barra(pos: Vector2, ancho: float, frac: float, color: Color) -> void:
	var fondo:= ColorRect.new()
	fondo.position= pos
	fondo.size =Vector2(ancho, 4)
	fondo.color= Color(0, 0, 0, 0.55)
	contenido.add_child(fondo)
	var lleno:= ColorRect.new()
	lleno.position =pos+ Vector2(1, 1)
	lleno.size= Vector2(maxf(0.0, (ancho- 2.0)* clampf(frac, 0.0, 1.0)), 2)
	lleno.color =color
	contenido.add_child(lleno)

func _pagina_info(p: PokemonInstancia) -> void:
	var e:= p.especie
	_fila("N.º Pokédex", "%03d" % e.numero, 2)
	_fila("Especie", e.nombre, 16)
	_fila("Naturaleza", Naturalezas.nombre(p.naturaleza), 30)
	var ball:= BaseDatos.objeto(p.ball)
	_fila("Capturado en", ball.nombre if ball!= null else "-", 44)
	var unicos:= {}
	for id in p.trinkets:
		unicos[id]= true
	_fila("Trinkets", "%d (%d huecos)" % [p.trinkets.size(), unicos.size()] if not p.trinkets.is_empty() else "Ninguno", 58)
	_fila("Puntos EXP", str(p.experiencia), 80)
	var maximo:= p.nivel>= PokemonInstancia.NIVEL_MAX
	var falta:= 0 if maximo else maxi(0, p.exp_siguiente_nivel()- p.experiencia)
	_fila("Para Nv. %d" % mini(p.nivel+ 1, PokemonInstancia.NIVEL_MAX), str(falta), 94)
	var base:= Crecimiento.exp_para_nivel(e.crecimiento, p.nivel)
	var sig:= p.exp_siguiente_nivel()
	_barra(Vector2(4, 110), 124, 1.0 if maximo else float(p.experiencia- base)/ maxf(1.0, sig- base), Color("58a8f8"))

func _pagina_stats(p: PokemonInstancia) -> void:
	var y:= 2.0
	var mayor:= 1
	for s in PokemonInstancia.STATS:
		mayor= maxi(mayor, p.ps_max() if s== "ps" else p.stat(s))
	for s in PokemonInstancia.STATS:
		var valor:= "%d/%d" % [p.ps_actuales, p.ps_max()] if s== "ps" else str(p.stat(s))
		var pct:= Naturalezas.porcentaje(p.naturaleza, s)
		var marca:= " ▲" if pct> 100 else (" ▼" if pct< 100 else "")
		var color:= SUBE if pct> 100 else (BAJA if pct< 100 else EstiloUI.TEXTO)
		_fila(NOMBRES_STAT[s]+ marca, valor, y, color)
		var num:= float(p.ps_actuales if s== "ps" else p.stat(s))
		_barra(Vector2(4, y+ 11), 124, num/ float(mayor), COLORES_STAT[s])
		y+= 20
	var nota:= EstiloUI.nuevo_label("▲ sube / ▼ baja por naturaleza", 6, Vector2(4, 124), EstiloUI.TENUE)
	contenido.add_child(nota)

func _pagina_movimientos(p: PokemonInstancia) -> void:
	var y:= 2.0
	for i in p.movimientos.size():
		var m:= p.movimientos[i]
		var b:= NinePatchRect.new()
		b.texture= load(BOTONES_TIPO+ "%s.png" % m.tipo)
		b.patch_margin_left =2
		b.patch_margin_right= 2
		b.patch_margin_top =3
		b.patch_margin_bottom= 4
		b.position =Vector2(0, y)
		b.size= Vector2(106, 16)
		contenido.add_child(b)
		var ic:= TextureRect.new()
		ic.texture= load(UI+ "tipos/%s.png" % m.tipo)
		ic.position =Vector2(3, 2)
		b.add_child(ic)
		var n:= EstiloUI.nuevo_label(m.nombre, 9, Vector2(16, 0), Color.WHITE)
		EstiloUI.fuente_batalla(n)
		n.size= Vector2(88, 16)
		n.vertical_alignment =VERTICAL_ALIGNMENT_CENTER
		n.text_overrun_behavior= TextServer.OVERRUN_TRIM_ELLIPSIS
		b.add_child(n)
		var cat:= TextureRect.new()
		cat.texture= load(UI+ "categoria_%s.png" % m.categoria)
		cat.position =Vector2(108, y+ 3)
		contenido.add_child(cat)
		var pot:= str(m.poder) if m.categoria!= "estado" and m.poder> 0 else "-"
		var prec:= str(m.precision) if m.precision> 0 else "-"
		var d:= EstiloUI.nuevo_label("PP %d/%d  Pot %s  Prec %s" % [p.pp[i], m.pp, pot, prec], 8, Vector2(4, y+ 16), EstiloUI.TENUE)
		EstiloUI.fuente_batalla(d)
		contenido.add_child(d)
		y+= 36
