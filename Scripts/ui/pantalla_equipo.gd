extends CanvasLayer

signal cerrado

const ESCENA_RESUMEN:= "res://Escenas/UI/Resumen.tscn"
const P :="res://Assets/Menus-Equipo/"
const ICONOS:= "res://Assets/Pokemones/iconos/"
const ICONO_Y :=-6.0
const CANCELAR:= 6
const COLOR_ESTADO :={"que": Color("e05030"), "env": Color("a040a0"), "par": Color("c8a018"), "dor": Color("808080"), "con": Color("48a8d8"), "deb": Color("c03028")}

@onready var tarjetas: Control= $Tarjetas
@onready var mensaje: Label =$Mensaje/Texto
@onready var submenu: Panel= $Submenu
@onready var lista: ListaOpciones =$Submenu/Lista
@onready var boton_cancelar: Panel =$Cancelar

var modo:= "ver"
var cursor :=0
var moviendo:= -1
var en_submenu :=false
var ocupado:= false
var resultado:= -1
var texto_base :=""
var validar: Callable
var puede_cancelar:= true
var paneles: Array[TextureRect]= []
var tiempo :=0.0

func _ready() -> void:
	layer= 105
	var caja:= StyleBoxFlat.new()
	caja.bg_color= Color("f8f8f8")
	caja.set_border_width_all(2)
	caja.border_color =Color("707888")
	caja.set_corner_radius_all(2)
	$Mensaje.add_theme_stylebox_override("panel", caja)
	submenu.add_theme_stylebox_override("panel", EstiloUI.panel())
	EstiloUI.label(mensaje, 9)
	submenu.visible =false
	for i in Equipo.MAXIMO:
		var p: TextureRect= tarjetas.get_node("S%d" % i)
		paneles.append(p)
		for n in ["Nombre", "PS"]:
			EstiloUI.label(p.get_node(n), 9, Color.WHITE)
		EstiloUI.label(p.get_node("Genero"), 9)
		var nivel: Label= p.get_node("Nivel")
		EstiloUI.label(nivel, 8, Color.WHITE)
		EstiloUI.fuente_batalla(nivel)
		var estado: Label =p.get_node("Estado")
		EstiloUI.label(estado, 6, Color.WHITE)
		EstiloUI.fuente_batalla(estado)
		estado.add_theme_constant_override("shadow_offset_x", 0)
		estado.add_theme_constant_override("shadow_offset_y", 0)
	EstiloUI.label($Cancelar/Texto, 9, Color.WHITE)
	EstiloUI.label($Cancelar/Cruz, 9, Color("f03830"))

func abrir(m: String= "ver", texto: String= "Elige un Pokémon.", validacion: Callable= Callable(), cancelable: bool= true) -> void:
	modo= m
	validar =validacion
	puede_cancelar= cancelable
	texto_base =texto
	mensaje.text= texto
	_construir()

func _construir() -> void:
	for i in paneles.size():
		var p:= paneles[i]
		var hay:= i< Equipo.miembros.size()
		for c in p.get_children():
			c.visible= hay
		if not hay:
			p.texture =load(P+ "vacio.png")
			continue
		var poke:= Equipo.miembros[i]
		var icono: Sprite2D= p.get_node("Icono")
		var ruta:= ICONOS+ "%s.png" % poke.especie.id
		if ResourceLoader.exists(ruta):
			icono.texture= load(ruta)
			icono.hframes =2
		else:
			icono.texture= EstiloUI.icono(poke.especie)
			icono.hframes =1
		icono.frame= 0
		icono.position.y =ICONO_Y
		(p.get_node("Nombre") as Label).text= poke.nombre()
		var genero: Label= p.get_node("Genero")
		genero.text =poke.simbolo_genero()
		genero.add_theme_color_override("font_color", poke.color_genero())
		(p.get_node("PS") as Label).text= "%d / %d" % [poke.ps_actuales, poke.ps_max()]
		(p.get_node("Nivel") as Label).text ="Nv%d" % poke.nivel
		p.get_node("Barra").poner(float(poke.ps_actuales)/ poke.ps_max())
		var objeto: TextureRect= p.get_node("Objeto")
		objeto.texture= load(P+ "objeto.png")
		objeto.visible =poke.objeto!= ""
		var clave:= "deb" if poke.esta_debilitado() else poke.estado
		var estado: Label= p.get_node("Estado")
		estado.visible =COLOR_ESTADO.has(clave)
		if estado.visible:
			estado.text= "DEB" if clave== "deb" else EstiloUI.ABREV_ESTADO[clave]
			var fondo:= StyleBoxFlat.new()
			fondo.bg_color =COLOR_ESTADO[clave]
			fondo.set_border_width_all(1)
			fondo.border_color= COLOR_ESTADO[clave].darkened(0.4)
			estado.add_theme_stylebox_override("normal", fondo)
	_pintar()

func _pintar() -> void:
	for i in paneles.size():
		if i>= Equipo.miembros.size():
			continue
		var color:= "azul"
		if moviendo>= 0 and (i== moviendo or i== cursor):
			color= "verde"
		elif Equipo.miembros[i].esta_debilitado():
			color ="rojo"
		var patron:= "a" if i% 2== 0 else "b"
		paneles[i].texture= load(P+ "panel_%s_%s_%d.png" % [color, patron, 1 if i== cursor else 0])
	var estilo:= StyleBoxFlat.new()
	estilo.bg_color= Color("2a4868") if cursor== CANCELAR else Color("101820")
	estilo.set_border_width_all(2)
	estilo.border_color =Color("58e8f8") if cursor== CANCELAR else Color("8898a8")
	estilo.set_corner_radius_all(3)
	boton_cancelar.add_theme_stylebox_override("panel", estilo)
	boton_cancelar.visible= puede_cancelar

func _process(delta: float) -> void:
	tiempo+= delta
	for i in mini(paneles.size(), Equipo.miembros.size()):
		var icono: Sprite2D= paneles[i].get_node("Icono")
		if Equipo.miembros[i].esta_debilitado():
			icono.frame= 0
			icono.position.y =ICONO_Y
			continue
		var elegido:= i== cursor
		var fase:= int(tiempo/ (0.14 if elegido else 0.3))% 2
		if icono.hframes> 1:
			icono.frame= fase
		icono.position.y =ICONO_Y- fase* (3 if elegido else 1)

func _unhandled_input(event: InputEvent) -> void:
	if ocupado or Dialogo.esta_abierto or GestorEscenas.en_transicion:
		return
	if en_submenu:
		_input_submenu(event)
		return
	var n:= Equipo.miembros.size()
	if event.is_action_pressed("cancelar") or event.is_action_pressed("menu"):
		if moviendo>= 0:
			Sonido.efecto("cancelar")
			moviendo= -1
			mensaje.text =texto_base
			_pintar()
		elif puede_cancelar:
			Sonido.efecto("cancelar")
			resultado= -1
			cerrado.emit()
	elif event.is_action_pressed("aceptar"):
		if cursor== CANCELAR:
			if puede_cancelar and moviendo< 0:
				Sonido.efecto("cancelar")
				resultado= -1
				cerrado.emit()
		elif cursor< n:
			_aceptar()
	elif cursor== CANCELAR:
		if event.is_action_pressed("arriba"):
			cursor= n- 1
		else:
			return
	elif event.is_action_pressed("derecha") and cursor% 2== 0 and cursor+ 1< n:
		cursor+= 1
	elif event.is_action_pressed("izquierda") and cursor% 2 ==1:
		cursor -=1
	elif event.is_action_pressed("abajo"):
		if cursor+ 2< n:
			cursor+= 2
		elif puede_cancelar and moviendo< 0:
			cursor= CANCELAR
		else:
			return
	elif event.is_action_pressed("arriba") and cursor- 2>= 0:
		cursor -=2
	else:
		return
	if not event.is_action_pressed("aceptar") and not event.is_action_pressed("cancelar") and not event.is_action_pressed("menu"):
		Sonido.efecto("cursor")
	_pintar()
	get_viewport().set_input_as_handled()

func _aceptar() -> void:
	if moviendo>= 0:
		Sonido.efecto("confirmar")
		if moviendo!= cursor:
			Equipo.intercambiar(moviendo, cursor)
		moviendo= -1
		mensaje.text =texto_base
		_construir()
		return
	if modo== "elegir":
		var error: String= validar.call(cursor) if validar.is_valid() else ""
		if error!= "":
			Sonido.efecto("error")
			mensaje.text= error
			return
		Sonido.efecto("confirmar")
		resultado= cursor
		cerrado.emit()
		return
	Sonido.efecto("confirmar")
	en_submenu= true
	lista.poner(["DATOS", "MOVER", "SALIR"])
	submenu.visible =true
	mensaje.text= "¿Qué hacer con %s?" % Equipo.miembros[cursor].nombre()

func _input_submenu(event: InputEvent) -> void:
	if event.is_action_pressed("cancelar"):
		Sonido.efecto("cancelar")
		_cerrar_submenu()
	elif event.is_action_pressed("aceptar"):
		Sonido.efecto("confirmar")
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
