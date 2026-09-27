extends CanvasLayer

signal cerrado

const FILAS:= 4
const TAMANO_STOCK :=4
const PESOS_TIER:= {1: 50, 2: 35, 3: 15}

@onready var dinero_lbl: Label= $Cabecera/Dinero
@onready var lista: Panel =$Lista
@onready var desc= $Desc
@onready var cursor_lbl: Label =$Cursor

var fila:= 0
var ocupado :=false
var rng:= RandomNumberGenerator.new()

func _ready() -> void:
	layer= 107
	rng.randomize()
	for p in [$Cabecera, lista]:
		p.add_theme_stylebox_override("panel", EstiloUI.panel())
	EstiloUI.label($Cabecera/Titulo, 9)
	EstiloUI.label(dinero_lbl, 9)
	EstiloUI.label(cursor_lbl, 6)
	EstiloUI.label($Lista/Vacio, 8)
	EstiloUI.fuente_batalla($Lista/Vacio)
	for i in FILAS:
		for n in ["Nombre", "Tier", "Precio"]:
			EstiloUI.label(lista.get_node("R%d/%s" % [i, n]), 8)
			EstiloUI.fuente_batalla(lista.get_node("R%d/%s" % [i, n]))
	if Estado.stock_tienda.is_empty():
		reponer(rng)
	_pintar()

func abrir() -> void:
	_pintar()

static func reponer(r: RandomNumberGenerator) -> void:
	var elegidos: Array[String]= []
	var intentos:= 0
	while elegidos.size()< TAMANO_STOCK and intentos< 60:
		intentos+= 1
		var tiro:= r.randi_range(1, 100)
		var tier:= 1 if tiro<= PESOS_TIER[1] else (2 if tiro<= PESOS_TIER[1]+ PESOS_TIER[2] else 3)
		var t:= EfectosTrinket.al_azar(tier, r)
		if t!= null and not elegidos.has(t.id):
			elegidos.append(t.id)
	Estado.stock_tienda.assign(elegidos)

static func precio(t: Trinket) -> int:
	var desc_total:= EfectosTrinket.total("descuento", null, Equipo.miembros)
	return maxi(1, roundi(t.precio* (1.0- desc_total)/ 10.0)* 10)

func _pintar() -> void:
	dinero_lbl.text= "%d$" % Estado.dinero
	var stock:= Estado.stock_tienda
	fila =clampi(fila, 0, maxi(0, stock.size()- 1))
	for i in FILAS:
		var r: Control= lista.get_node("R%d" % i)
		r.visible= i< stock.size()
		if not r.visible:
			continue
		var t:= BaseDatos.trinket(stock[i])
		(r.get_node("Icono") as TextureRect).texture= EfectosTrinket.icono(t)
		(r.get_node("Nombre") as Label).text =t.nombre
		var tl: Label= r.get_node("Tier")
		tl.text= EfectosTrinket.NOMBRES_TIER[t.tier]
		tl.add_theme_color_override("font_color", EfectosTrinket.color_tier(t.tier).darkened(0.25))
		var pl: Label= r.get_node("Precio")
		pl.text ="%d$" % precio(t)
		pl.add_theme_color_override("font_color", EstiloUI.TEXTO if precio(t)<= Estado.dinero else Color("c03028"))
	$Lista/Vacio.visible= stock.is_empty()
	cursor_lbl.visible =not stock.is_empty()
	if stock.is_empty():
		desc.mensaje("¡Todo vendido! Vuelve después de superar la Torre Desafío.")
		return
	var rf: Control= lista.get_node("R%d" % fila)
	cursor_lbl.position= lista.position+ rf.position+ Vector2(-8, 5)
	var sel:= BaseDatos.trinket(stock[fila])
	var tiene: int= Inventario.cantidad_trinket(sel.id)+ int(Equipo.miembros.reduce(func(a, p): return a+ p.trinkets.count(sel.id), 0))
	desc.mostrar(sel, "Ya tienes %d." % tiene if tiene> 0 else "")

func _unhandled_input(event: InputEvent) -> void:
	if GestorEscenas.en_transicion or ocupado or Dialogo.esta_abierto:
		return
	if event.is_action_pressed("cancelar") or event.is_action_pressed("menu"):
		Sonido.efecto("cancelar")
		cerrado.emit()
	elif event.is_action_pressed("arriba"):
		fila= maxi(0, fila- 1)
		Sonido.efecto("cursor")
	elif event.is_action_pressed("abajo"):
		fila =mini(maxi(0, Estado.stock_tienda.size()- 1), fila+ 1)
		Sonido.efecto("cursor")
	elif event.is_action_pressed("aceptar"):
		get_viewport().set_input_as_handled()
		_comprar()
		return
	else:
		return
	_pintar()
	get_viewport().set_input_as_handled()

func _comprar() -> void:
	if Estado.stock_tienda.is_empty():
		Sonido.efecto("error")
		return
	var t:= BaseDatos.trinket(Estado.stock_tienda[fila])
	var p:= precio(t)
	if p> Estado.dinero:
		Sonido.efecto("error")
		desc.mensaje("No tienes suficiente dinero para %s." % t.nombre)
		return
	ocupado= true
	Sonido.efecto("confirmar")
	var r: int= await Dialogo.preguntar("¿Comprar %s por %d$?" % [t.nombre, p])
	if r== 0:
		Estado.sumar_dinero(-p)
		Inventario.agregar_trinket(t.id)
		Estado.stock_tienda.remove_at(fila)
		Sonido.efecto("guardar")
		await Dialogo.mostrar("¡Compraste %s! Equípalo desde el menú POKéMON → TRINKETS." % t.nombre)
	ocupado =false
	_pintar()
