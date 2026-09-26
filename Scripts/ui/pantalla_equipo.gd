extends CanvasLayer

signal cerrado

const ESCENA_RESUMEN:= "res://Escenas/UI/Resumen.tscn"
const BARRA :=preload("res://Scripts/batalla/barra_ps.gd")

@onready var tarjetas: Control= $Tarjetas
@onready var mensaje: Label =$Mensaje/Texto
@onready var submenu: Panel= $Submenu
@onready var lista: ListaOpciones =$Submenu/Lista

var modo:= "ver"
var cursor :=0
var moviendo:= -1
var en_submenu :=false
var ocupado:= false
var resultado:= -1
var texto_base :=""
var validar: Callable
var puede_cancelar:= true
var paneles: Array[Panel]= []

func _ready() -> void:
	layer= 105
	$Mensaje.add_theme_stylebox_override("panel", EstiloUI.panel())
	submenu.add_theme_stylebox_override("panel", EstiloUI.panel())
	EstiloUI.label(mensaje, 9)
	submenu.visible =false

func abrir(m: String= "ver", texto: String= "Elige un Pokémon.", validacion: Callable= Callable(), cancelable: bool= true) -> void:
	modo= m
	validar =validacion
	puede_cancelar= cancelable
	texto_base =texto
	mensaje.text= texto
	_construir()

func _construir() -> void:
	for p in paneles:
		p.queue_free()
	paneles.clear()
	for i in Equipo.MAXIMO:
		var col:= i% 2
		var fila:= floori(i/ 2.0)
		var p:= Panel.new()
		p.position= Vector2(4+ col* 126, 4+ fila* 52)
		p.size =Vector2(122, 48)
		tarjetas.add_child(p)
		paneles.append(p)
		if i< Equipo.miembros.size():
			_llenar(p, Equipo.miembros[i])
	_pintar()

func _llenar(p: Panel, poke: PokemonInstancia) -> void:
	var icono:= TextureRect.new()
	icono.texture= EstiloUI.icono(poke.especie)
	icono.position =Vector2(2, 4)
	icono.size= Vector2(40, 40)
	icono.expand_mode =TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode= TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p.add_child(icono)
	p.add_child(EstiloUI.nuevo_label(poke.nombre()+ (" ◆" if poke.objeto!= "" else ""), 8, Vector2(44, 0)))
	p.add_child(EstiloUI.nuevo_label("Nv%d" % poke.nivel, 7, Vector2(44, 13)))
	if EstiloUI.ABREV_ESTADO.has(poke.estado):
		p.add_child(EstiloUI.nuevo_label(EstiloUI.ABREV_ESTADO[poke.estado], 7, Vector2(78, 13), Color("c03028")))
	elif poke.esta_debilitado():
		p.add_child(EstiloUI.nuevo_label("DEB", 7, Vector2(78, 13), Color("c03028")))
	var fondo:= ColorRect.new()
	fondo.color= Color("505050")
	fondo.position =Vector2(43, 29)
	fondo.size= Vector2(74, 5)
	p.add_child(fondo)
	var vacio:= ColorRect.new()
	vacio.color =Color("fbfbfb")
	vacio.position= Vector2(44, 30)
	vacio.size =Vector2(72, 3)
	p.add_child(vacio)
	var barra:= Control.new()
	barra.set_script(BARRA)
	barra.position= Vector2(44, 30)
	barra.size =Vector2(72, 3)
	p.add_child(barra)
	barra.poner(float(poke.ps_actuales)/ poke.ps_max())
	var ps:= EstiloUI.nuevo_label("%d/%d" % [poke.ps_actuales, poke.ps_max()], 7, Vector2(44, 33))
	ps.size= Vector2(72, 10)
	ps.horizontal_alignment =HORIZONTAL_ALIGNMENT_RIGHT
	p.add_child(ps)

func _pintar() -> void:
	for i in paneles.size():
		var lleno:= i< Equipo.miembros.size()
		var fondo:= Color("f8f8f8") if lleno else Color(1, 1, 1, 0.25)
		var borde :=Color("3a4a6a")
		if i== moviendo:
			fondo= Color("c8e8ff")
		if i== cursor:
			fondo= Color("fff4b8") if lleno else fondo
			borde =Color("f08030")
		paneles[i].add_theme_stylebox_override("panel", EstiloUI.panel(fondo, borde))

func _unhandled_input(event: InputEvent) -> void:
	if ocupado or Dialogo.esta_abierto or GestorEscenas.en_transicion:
		return
	if en_submenu:
		_input_submenu(event)
		return
	var n:= Equipo.miembros.size()
	if event.is_action_pressed("cancelar") or event.is_action_pressed("menu"):
		if moviendo>= 0:
			moviendo= -1
			mensaje.text =texto_base
			_pintar()
		elif puede_cancelar:
			resultado= -1
			cerrado.emit()
	elif event.is_action_pressed("aceptar") and cursor< n:
		_aceptar()
	elif event.is_action_pressed("derecha") and cursor% 2== 0 and cursor+ 1< n:
		cursor+= 1
	elif event.is_action_pressed("izquierda") and cursor% 2 ==1:
		cursor -=1
	elif event.is_action_pressed("abajo") and cursor+ 2< n:
		cursor+= 2
	elif event.is_action_pressed("arriba") and cursor- 2>= 0:
		cursor -=2
	else:
		return
	_pintar()
	get_viewport().set_input_as_handled()

func _aceptar() -> void:
	if moviendo>= 0:
		if moviendo!= cursor:
			Equipo.intercambiar(moviendo, cursor)
		moviendo= -1
		mensaje.text =texto_base
		_construir()
		return
	if modo== "elegir":
		var error: String= validar.call(cursor) if validar.is_valid() else ""
		if error!= "":
			mensaje.text= error
			return
		resultado= cursor
		cerrado.emit()
		return
	en_submenu= true
	lista.poner(["DATOS", "MOVER", "SALIR"])
	submenu.visible =true
	mensaje.text= "¿Qué hacer con %s?" % Equipo.miembros[cursor].nombre()

func _input_submenu(event: InputEvent) -> void:
	if event.is_action_pressed("cancelar"):
		_cerrar_submenu()
	elif event.is_action_pressed("aceptar"):
		var op: String= lista.opciones[lista.cursor]
		_cerrar_submenu()
		match op:
			"DATOS":
				_ver_datos()
			"MOVER":
				moviendo= cursor
				mensaje.text ="¿A dónde mover a %s?" % Equipo.miembros[cursor].nombre()
				_pintar()
	elif not lista.mover_con_evento(event):
		return
	get_viewport().set_input_as_handled()

func _cerrar_submenu() -> void:
	en_submenu= false
	submenu.visible =false
	mensaje.text= texto_base

func _ver_datos() -> void:
	ocupado= true
	var r= load(ESCENA_RESUMEN).instantiate()
	await GestorEscenas.fundido(func():
		add_child(r)
		r.abrir(cursor))
	await r.cerrado
	await GestorEscenas.fundido(func():
		cursor =r.indice
		r.queue_free()
		_construir())
	ocupado= false
