extends CanvasLayer

signal cerrado

const PAGINAS:= ["INFO", "ESTADÍSTICAS", "MOVIMIENTOS"]
const NOMBRES_STAT :={"ps": "PS", "ataque": "Ataque", "defensa": "Defensa", "at_esp": "At. Esp.", "def_esp": "Def. Esp.", "velocidad": "Velocidad"}

@onready var sprite: Sprite2D= $Sprite
@onready var titulo: Label =$Titulo
@onready var contenido: Control= $Contenido
@onready var datos_izq: Control =$DatosIzq

var indice:= 0
var pagina :=0

func _ready() -> void:
	layer= 108
	$Izq.add_theme_stylebox_override("panel", EstiloUI.panel())
	$Der.add_theme_stylebox_override("panel", EstiloUI.panel())
	EstiloUI.label(titulo, 9, Color("3a4a6a"))

func abrir(i: int) -> void:
	indice= i
	_mostrar()

func _unhandled_input(event: InputEvent) -> void:
	if GestorEscenas.en_transicion:
		return
	if event.is_action_pressed("cancelar") or event.is_action_pressed("menu"):
		cerrado.emit()
	elif event.is_action_pressed("derecha"):
		pagina= (pagina+ 1)% PAGINAS.size()
		_mostrar()
	elif event.is_action_pressed("izquierda"):
		pagina =(pagina+ PAGINAS.size()- 1)% PAGINAS.size()
		_mostrar()
	elif event.is_action_pressed("abajo") and indice+ 1< Equipo.miembros.size():
		indice+= 1
		_mostrar()
	elif event.is_action_pressed("arriba") and indice> 0:
		indice -=1
		_mostrar()
	else:
		return
	get_viewport().set_input_as_handled()

func _limpiar(c: Control) -> void:
	for h in c.get_children():
		h.queue_free()

func _mostrar() -> void:
	var p:= Equipo.miembros[indice]
	titulo.text= "◀ %s ▶" % PAGINAS[pagina]
	sprite.mostrar(p.especie, false)
	_limpiar(datos_izq)
	datos_izq.add_child(EstiloUI.nuevo_label(p.nombre(), 9, Vector2(4, 0)))
	datos_izq.add_child(EstiloUI.nuevo_label("Nv. %d" % p.nivel, 8, Vector2(4, 17)))
	if EstiloUI.ABREV_ESTADO.has(p.estado):
		datos_izq.add_child(EstiloUI.nuevo_label(EstiloUI.ABREV_ESTADO[p.estado], 8, Vector2(60, 17), Color("c03028")))
	_limpiar(contenido)
	match pagina:
		0:
			_pagina_info(p)
		1:
			_pagina_stats(p)
		2:
			_pagina_movimientos(p)

func _fila(texto: String, valor: String, y: float, color: Color= EstiloUI.TEXTO) -> void:
	contenido.add_child(EstiloUI.nuevo_label(texto, 8, Vector2(6, y)))
	var v:= EstiloUI.nuevo_label(valor, 8, Vector2(64, y), color)
	v.size= Vector2(76, 11)
	v.horizontal_alignment =HORIZONTAL_ALIGNMENT_RIGHT
	contenido.add_child(v)

func _pagina_info(p: PokemonInstancia) -> void:
	var e:= p.especie
	_fila("Núm. Pokédex", "%03d" % e.numero, 2)
	_fila("Especie", e.nombre, 16)
	contenido.add_child(EstiloUI.nuevo_label("Tipo", 8, Vector2(6, 30)))
	for k in e.tipos.size():
		contenido.add_child(EstiloUI.insignia_tipo(e.tipos[k], Vector2(44+ k* (EstiloUI.ANCHO_INSIGNIA+ 4), 31)))
	_fila("Naturaleza", Naturalezas.nombre(p.naturaleza), 44)
	var obj: Objeto= BaseDatos.objeto(p.objeto) if p.objeto!= "" else null
	_fila("Objeto", obj.nombre if obj!= null else "Ninguno", 58)
	_fila("Puntos EXP", str(p.experiencia), 80)
	var falta:= maxi(0, p.exp_siguiente_nivel()- p.experiencia) if p.nivel< PokemonInstancia.NIVEL_MAX else 0
	_fila("Para Nv. %d" % mini(p.nivel+ 1, PokemonInstancia.NIVEL_MAX), str(falta), 94)

func _pagina_stats(p: PokemonInstancia) -> void:
	var y:= 2.0
	for s in PokemonInstancia.STATS:
		var valor:= "%d/%d" % [p.ps_actuales, p.ps_max()] if s== "ps" else str(p.stat(s))
		var color:= EstiloUI.TEXTO
		var pct:= Naturalezas.porcentaje(p.naturaleza, s)
		if pct> 100:
			color= Color("d03020")
		elif pct< 100:
			color =Color("2050c0")
		_fila(NOMBRES_STAT[s], valor, y, color)
		y+= 16
	contenido.add_child(EstiloUI.nuevo_label("Rojo: sube por naturaleza", 6, Vector2(6, 104), Color("d03020")))
	contenido.add_child(EstiloUI.nuevo_label("Azul: baja por naturaleza", 6, Vector2(6, 114), Color("2050c0")))

func _pagina_movimientos(p: PokemonInstancia) -> void:
	var y:= 2.0
	for i in p.movimientos.size():
		var m:= p.movimientos[i]
		contenido.add_child(EstiloUI.insignia_tipo(m.tipo, Vector2(4, y+ 1)))
		contenido.add_child(EstiloUI.nuevo_label(m.nombre, 8, Vector2(EstiloUI.ANCHO_INSIGNIA+ 8, y- 2)))
		var detalle:= "PP %d/%d" % [p.pp[i], m.pp]
		if m.categoria!= "estado":
			detalle+= "  Pot. %s" % (str(m.poder) if m.poder> 0 else "-")
		contenido.add_child(EstiloUI.nuevo_label(detalle, 6, Vector2(EstiloUI.ANCHO_INSIGNIA+ 8, y+ 13)))
		y+= 30
