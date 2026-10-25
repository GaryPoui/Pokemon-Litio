extends CanvasLayer

signal cerrado

const FILAS:= 7
const ALTO_FILA :=13
const MAX_CANTIDAD:= 99

var stock: Array[String]= []
var vender :=false
var fila:= 0
var arriba :=0
var cantidad:= 1
var eligiendo_cantidad :=false
var ocupado:= false
var titulo_tienda :="ALMACÉN"

var dinero_lbl: Label
var titulo_lbl: Label
var lista: Panel
var filas: Array= []
var cursor_lbl: Label
var desc: Panel
var icono: TextureRect
var desc_lbl: Label
var tenes_lbl: Label
var caja_cant: Panel
var cant_lbl: Label
var total_lbl: Label

func _ready() -> void:
	layer= 107
	var fondo:= ColorRect.new()
	fondo.color= Color(0.05, 0.06, 0.1, 0.85)
	fondo.size =Vector2(256, 192)
	add_child(fondo)
	var cabecera:= _panel(Rect2(4, 4, 248, 18))
	titulo_lbl= EstiloUI.nuevo_label("", 9, Vector2(6, 2))
	cabecera.add_child(titulo_lbl)
	dinero_lbl =EstiloUI.nuevo_label("", 9, Vector2(150, 2))
	dinero_lbl.size.x= 92
	dinero_lbl.horizontal_alignment= HORIZONTAL_ALIGNMENT_RIGHT
	cabecera.add_child(dinero_lbl)
	lista= _panel(Rect2(4, 25, 248, FILAS* ALTO_FILA+ 6))
	for i in FILAS:
		var nombre:= EstiloUI.nuevo_label("", 8, Vector2(14, 2+ i* ALTO_FILA))
		var precio:= EstiloUI.nuevo_label("", 8, Vector2(150, 2+ i* ALTO_FILA))
		precio.size.x= 90
		precio.horizontal_alignment= HORIZONTAL_ALIGNMENT_RIGHT
		for l in [nombre, precio]:
			EstiloUI.fuente_batalla(l)
			lista.add_child(l)
		filas.append([nombre, precio])
	cursor_lbl= EstiloUI.nuevo_label("▶", 6, Vector2(5, 4))
	lista.add_child(cursor_lbl)
	desc= _panel(Rect2(4, 128, 248, 60))
	icono =TextureRect.new()
	icono.position= Vector2(4, 4)
	icono.size =Vector2(30, 30)
	desc.add_child(icono)
	desc_lbl= EstiloUI.nuevo_label("", 8, Vector2(38, 3))
	desc_lbl.size= Vector2(204, 40)
	desc_lbl.autowrap_mode= TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_constant_override("line_spacing", -3)
	desc.add_child(desc_lbl)
	tenes_lbl= EstiloUI.nuevo_label("", 8, Vector2(6, 44), EstiloUI.TENUE)
	desc.add_child(tenes_lbl)
	caja_cant= _panel(Rect2(150, 96, 100, 30))
	cant_lbl= EstiloUI.nuevo_label("", 9, Vector2(6, 2))
	total_lbl= EstiloUI.nuevo_label("", 9, Vector2(6, 15))
	total_lbl.size.x= 88
	total_lbl.horizontal_alignment= HORIZONTAL_ALIGNMENT_RIGHT
	caja_cant.add_child(cant_lbl)
	caja_cant.add_child(total_lbl)
	caja_cant.visible= false
	_pintar()

func _panel(r: Rect2) -> Panel:
	var p:= Panel.new()
	p.position= r.position
	p.size =r.size
	p.add_theme_stylebox_override("panel", EstiloUI.panel())
	add_child(p)
	return p

func abrir(titulo: String, ids: Array, modo_vender: bool) -> void:
	titulo_tienda= titulo
	vender =modo_vender
	stock.assign(ids)
	if vender:
		_stock_venta()
	fila= 0
	arriba =0
	_pintar()

func _stock_venta() -> void:
	stock.clear()
	for id in Inventario.cantidades:
		var o:= Inventario.get_objeto(str(id))
		if o!= null and Inventario.cantidad_de(str(id))> 0 and o.precio> 0 and not o.categoria in ["CLAVE", "MT / MO"]:
			stock.append(str(id))
	stock.sort()

func precio(o: Objeto) -> int:
	if vender:
		return o.precio/ 2
	var d:= EfectosTrinket.total("descuento", null, Equipo.miembros)
	return maxi(1, roundi(o.precio* (1.0- d)/ 10.0)* 10)

func _pintar() -> void:
	if titulo_lbl== null:
		return
	titulo_lbl.text= "%s · %s" % [titulo_tienda, "VENDER" if vender else "COMPRAR"]
	dinero_lbl.text ="%d$" % Estado.dinero
	fila= clampi(fila, 0, maxi(0, stock.size()))
	if fila< arriba:
		arriba= fila
	elif fila>= arriba+ FILAS:
		arriba =fila- FILAS+ 1
	for i in FILAS:
		var k:= arriba+ i
		var n: Label= filas[i][0]
		var pr: Label =filas[i][1]
		if k< stock.size():
			var o:= Inventario.get_objeto(stock[k])
			n.text= o.nombre if not vender else "%s x%d" % [o.nombre, Inventario.cantidad_de(o.id)]
			pr.text ="%d$" % precio(o)
		elif k== stock.size():
			n.text= "SALIR"
			pr.text =""
		else:
			n.text= ""
			pr.text =""
	cursor_lbl.position.y= 4+ (fila- arriba)* ALTO_FILA
	if fila< stock.size():
		var o:= Inventario.get_objeto(stock[fila])
		icono.texture= o.icono
		desc_lbl.text =o.descripcion
		tenes_lbl.text= "En la mochila: %d" % Inventario.cantidad_de(o.id)
	else:
		icono.texture= null
		desc_lbl.text ="Volver al mostrador."
		tenes_lbl.text= ""
	caja_cant.visible= eligiendo_cantidad
	if eligiendo_cantidad and fila< stock.size():
		var o:= Inventario.get_objeto(stock[fila])
		cant_lbl.text= "× %02d" % cantidad
		total_lbl.text ="%d$" % (precio(o)* cantidad)

func _maximo(o: Objeto) -> int:
	if vender:
		return Inventario.cantidad_de(o.id)
	var p:= precio(o)
	return clampi(Estado.dinero/ maxi(1, p), 0, MAX_CANTIDAD)

func _unhandled_input(event: InputEvent) -> void:
	if GestorEscenas.en_transicion or ocupado or Dialogo.esta_abierto:
		return
	if eligiendo_cantidad:
		_input_cantidad(event)
		return
	if event.is_action_pressed("cancelar") or event.is_action_pressed("menu"):
		Sonido.efecto("cancelar")
		cerrado.emit()
	elif event.is_action_pressed("arriba"):
		fila= maxi(0, fila- 1)
		Sonido.efecto("cursor")
	elif event.is_action_pressed("abajo"):
		fila =mini(stock.size(), fila+ 1)
		Sonido.efecto("cursor")
	elif event.is_action_pressed("aceptar"):
		if fila>= stock.size():
			Sonido.efecto("confirmar")
			cerrado.emit()
			return
		var o:= Inventario.get_objeto(stock[fila])
		if _maximo(o)<= 0:
			Sonido.efecto("error")
			desc_lbl.text= "No te alcanza la plata." if not vender else "No te queda."
			get_viewport().set_input_as_handled()
			return
		Sonido.efecto("confirmar")
		cantidad= 1
		eligiendo_cantidad =true
	else:
		return
	get_viewport().set_input_as_handled()
	_pintar()

func _input_cantidad(event: InputEvent) -> void:
	var o:= Inventario.get_objeto(stock[fila])
	var maximo:= _maximo(o)
	if event.is_action_pressed("cancelar"):
		Sonido.efecto("cancelar")
		eligiendo_cantidad= false
	elif event.is_action_pressed("arriba"):
		cantidad= 1 if cantidad>= maximo else cantidad+ 1
		Sonido.efecto("cursor")
	elif event.is_action_pressed("abajo"):
		cantidad =maximo if cantidad<= 1 else cantidad- 1
		Sonido.efecto("cursor")
	elif event.is_action_pressed("derecha"):
		cantidad= mini(maximo, cantidad+ 10)
		Sonido.efecto("cursor")
	elif event.is_action_pressed("izquierda"):
		cantidad =maxi(1, cantidad- 10)
		Sonido.efecto("cursor")
	elif event.is_action_pressed("aceptar"):
		eligiendo_cantidad= false
		comprar_o_vender(o, cantidad)
	else:
		return
	get_viewport().set_input_as_handled()
	_pintar()

func comprar_o_vender(o: Objeto, n: int) -> bool:
	var total:= precio(o)* n
	if vender:
		if Inventario.cantidad_de(o.id)< n:
			return false
		for k in n:
			Inventario.consumir(o.id)
		Estado.sumar_dinero(total)
		Sonido.efecto("confirmar")
		desc_lbl.text= "Vendiste %s x%d por %d$." % [o.nombre, n, total]
		_stock_venta()
		return true
	if Estado.dinero< total:
		Sonido.efecto("error")
		return false
	Estado.sumar_dinero(-total)
	Inventario.add_item(o.id, n)
	Sonido.jingle("objeto")
	desc_lbl.text= "¡Compraste %s x%d!" % [o.nombre, n]
	if o.id== "pokeball" and n>= 10:
		Inventario.add_item("pokeball", n/ 10)
		desc_lbl.text+= " Te regalamos %d Poké Ball de yapa." % (n/ 10)
	return true
