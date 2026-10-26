extends CanvasLayer

signal cerrado(ranura: int, nueva: bool)

const FONDO:= preload("res://Assets/Fondos/opciones.png")
const DIBUJO :=preload("res://Scripts/ui/dibujo_archivo.gd")
const ANCHO_CARTA:= 76
const ALTO_CARTA :=136
const X_CARTAS:= [7, 90, 173]
const Y_CARTA :=18
const ALZADA:= 3
const ICONOS_STAT :=["pokedex", "vistos", "tiempo", "pasos", "trinkets"]

var cursor:= 0
var cartas: Array[Panel]= []
var dibujos: Array= []
var lineas: Array= []
var iconos: Array= []
var titulos: Array[Label]= []
var resumenes: Array[Dictionary]= []
var marco: Panel
var detalle :Label
var ayuda: Label
var ocupado:= false

func _ready() -> void:
	layer= 104
	var fondo:= TextureRect.new()
	fondo.texture= FONDO
	add_child(fondo)
	add_child(EstiloUI.nuevo_label("ELEGÍ UN ARCHIVO", 9, Vector2(8, 3)))
	for i in Guardado.RANURAS:
		var c:= Panel.new()
		c.size= Vector2(ANCHO_CARTA, ALTO_CARTA)
		c.add_theme_stylebox_override("panel", EstiloUI.madera())
		add_child(c)
		cartas.append(c)
		var t:= EstiloUI.nuevo_label("ARCHIVO %d" % (i+ 1), 8, Vector2(5, 2))
		c.add_child(t)
		titulos.append(t)
		var d= DIBUJO.new()
		d.position= Vector2(4, 13)
		c.add_child(d)
		dibujos.append(d)
		var hoja:= Panel.new()
		hoja.position= Vector2(4, 72)
		hoja.size =Vector2(68, 60)
		hoja.add_theme_stylebox_override("panel", EstiloUI.hoja())
		c.add_child(hoja)
		var ls:= []
		var ics:= []
		for k in 5:
			var ic:= TextureRect.new()
			ic.texture= load("res://Assets/UI/Archivos/stat_%s.png" % ICONOS_STAT[k])
			ic.position =Vector2(3, 3+ k* 11)
			ic.texture_filter= CanvasItem.TEXTURE_FILTER_NEAREST
			hoja.add_child(ic)
			ics.append(ic)
			var l:= EstiloUI.nuevo_label("", 8, Vector2(13, 1+ k* 11))
			hoja.add_child(l)
			ls.append(l)
		lineas.append(ls)
		iconos.append(ics)
	marco= Panel.new()
	marco.size= Vector2(ANCHO_CARTA+ 4, ALTO_CARTA+ 4)
	marco.add_theme_stylebox_override("panel", EstiloUI.panel(Color(0, 0, 0, 0), Color("ffd84a")))
	marco.mouse_filter= Control.MOUSE_FILTER_IGNORE
	add_child(marco)
	var info:= Panel.new()
	info.position= Vector2(6, 158)
	info.size =Vector2(244, 32)
	info.add_theme_stylebox_override("panel", EstiloUI.panel())
	add_child(info)
	detalle= EstiloUI.nuevo_label("", 8, Vector2(6, 2))
	ayuda =EstiloUI.nuevo_label("", 6, Vector2(6, 18), EstiloUI.TENUE)
	info.add_child(detalle)
	info.add_child(ayuda)
	refrescar()

func abrir() -> void:
	refrescar()

func refrescar() -> void:
	resumenes.clear()
	for i in Guardado.RANURAS:
		var r:= Guardado.resumen(i+ 1)
		resumenes.append(r)
		dibujos[i].mostrar(r)
		var ls: Array= lineas[i]
		for ic in iconos[i]:
			ic.visible= not r.is_empty()
		if r.is_empty():
			var textos:= ["", "NUEVA", "PARTIDA", "", ""]
			for k in 5:
				ls[k].text= textos[k]
				ls[k].position.x =14
		else:
			ls[0].text= "%d/%d" % [r["capturados"], r["total"]]
			ls[1].text ="%d" % r["vistos"]
			ls[2].text= texto_tiempo(float(r["tiempo"]))
			ls[3].text ="%d" % r["pasos"]
			ls[4].text= "%d/%d" % [r["trinkets"], r["total_trinkets"]]
			for l in ls:
				l.position.x= 13
	_pintar()

static func texto_tiempo(s: float) -> String:
	var m:= floori(s/ 60.0)
	return "%d:%02d" % [floori(m/ 60.0), m% 60]

func _pintar() -> void:
	for i in cartas.size():
		var sel:= i== cursor
		cartas[i].position= Vector2(X_CARTAS[i], Y_CARTA- (ALZADA if sel else 0))
		cartas[i].modulate= Color.WHITE if sel else Color(0.78, 0.78, 0.82)
	marco.position= cartas[cursor].position- Vector2(2, 2)
	var r: Dictionary= resumenes[cursor]
	if r.is_empty():
		detalle.text= "Archivo %d vacío" % (cursor+ 1)
		ayuda.text ="A: empezar partida nueva    B: volver"
	else:
		detalle.text= "%s · Safari %d/%d · $%d" % [r["lugar"], r["registros"], r["total_registros"], r["dinero"]]
		ayuda.text ="A: jugar    B: volver    MENÚ: copiar o borrar"

func _unhandled_input(event: InputEvent) -> void:
	if ocupado or GestorEscenas.en_transicion:
		return
	if event.is_action_pressed("izquierda"):
		cursor= wrapi(cursor- 1, 0, cartas.size())
		Sonido.efecto("cursor")
		_pintar()
	elif event.is_action_pressed("derecha"):
		cursor =wrapi(cursor+ 1, 0, cartas.size())
		Sonido.efecto("cursor")
		_pintar()
	elif event.is_action_pressed("aceptar"):
		Sonido.efecto("confirmar")
		_elegir()
	elif event.is_action_pressed("cancelar"):
		Sonido.efecto("cancelar")
		cerrado.emit(0, false)
	elif event.is_action_pressed("menu"):
		Sonido.efecto("confirmar")
		_opciones()
	else:
		return
	get_viewport().set_input_as_handled()

func _elegir() -> void:
	var n:= cursor+ 1
	if not resumenes[cursor].is_empty():
		cerrado.emit(n, false)
		return
	ocupado= true
	var r: int= await Dialogo.preguntar("¿Empezar una partida nueva en el Archivo %d?" % n)
	ocupado =false
	if r== 0:
		cerrado.emit(n, true)

func _opciones() -> void:
	var n:= cursor+ 1
	if resumenes[cursor].is_empty():
		return
	ocupado= true
	var r: int= await Dialogo.preguntar("Archivo %d" % n, ["COPIAR", "BORRAR", "CANCELAR"])
	if r== 0:
		await _copiar(n)
	elif r== 1:
		await _borrar(n)
	ocupado =false

func _copiar(n: int) -> void:
	var libres: Array[int]= []
	for i in Guardado.RANURAS:
		if not Guardado.existe(i+ 1):
			libres.append(i+ 1)
	if libres.is_empty():
		await Dialogo.mostrar("No hay archivos libres. Borrá uno para poder copiar.")
		return
	var destino:= libres[0]
	if libres.size()> 1:
		var ops:= libres.map(func(x): return "ARCHIVO %d" % x)
		ops.append("CANCELAR")
		var r: int= await Dialogo.preguntar("¿A qué archivo copiar el Archivo %d?" % n, ops)
		if r>= libres.size():
			return
		destino= libres[r]
	else:
		var r: int= await Dialogo.preguntar("¿Copiar el Archivo %d al Archivo %d?" % [n, destino])
		if r!= 0:
			return
	if Guardado.copiar(n, destino):
		Sonido.efecto("guardar")
		refrescar()
		await Dialogo.mostrar("El Archivo %d se copió al Archivo %d." % [n, destino])
	else:
		await Dialogo.mostrar("No se pudo copiar el archivo.")

func _borrar(n: int) -> void:
	var r: int= await Dialogo.preguntar("¿Borrar el Archivo %d? Se pierde todo su progreso." % n)
	if r!= 0:
		return
	r= await Dialogo.preguntar("¿Seguro? Esto no se puede deshacer.")
	if r!= 0:
		return
	if Guardado.borrar(n):
		Sonido.efecto("guardar")
		refrescar()
		await Dialogo.mostrar("El Archivo %d se borró." % n)
	else:
		await Dialogo.mostrar("No se pudo borrar el archivo.")
