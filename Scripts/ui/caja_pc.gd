extends CanvasLayer

signal cerrado

const ICONOS:= "res://Assets/Pokemones/iconos/"
const COLS_EQUIPO:= 2
const COLS_CAJA :=3
const FILAS_CAJA:= 3
const TAM_CELDA :=Vector2(34, 30)
const ICONO_Y:= 15

@onready var panel_equipo: Panel= $Equipo
@onready var panel_caja: Panel =$Caja
@onready var marco: Panel= $Marco
@onready var nombre: Label =$Info/Nombre
@onready var datos: Label= $Info/Datos
@onready var ayuda: Label =$Info/Ayuda
@onready var tipos: Control= $Info/Tipos
@onready var cuenta: Label =$Cabecera/Cuenta

var lado:= 0
var indice :=0
var scroll:= 0
var celdas_equipo: Array= []
var celdas_caja: Array =[]
var tiempo:= 0.0
var ocupado :=false

func _ready() -> void:
	layer= 107
	for p in [$Cabecera, panel_equipo, panel_caja, $Info]:
		p.add_theme_stylebox_override("panel", EstiloUI.panel())
	EstiloUI.label($Cabecera/Titulo, 9)
	$Cabecera/Titulo.text= "CAJA DEL PC"
	for l in [cuenta, $Equipo/Titulo, $Caja/Titulo, datos]:
		EstiloUI.label(l, 8)
		EstiloUI.fuente_batalla(l)
	$Equipo/Titulo.text= "EQUIPO"
	$Caja/Titulo.text ="CAJA"
	EstiloUI.label(nombre, 9)
	EstiloUI.label(ayuda, 6, EstiloUI.TENUE)
	EstiloUI.label($Caja/Flechas, 6, EstiloUI.TENUE)
	var m:= StyleBoxFlat.new()
	m.bg_color= Color(0, 0, 0, 0)
	m.set_border_width_all(2)
	m.border_color =Color("e05a30")
	m.set_corner_radius_all(4)
	marco.add_theme_stylebox_override("panel", m)
	for i in Equipo.MAXIMO:
		celdas_equipo.append(_hueco(panel_equipo, Vector2(12+ (i% COLS_EQUIPO)* 44, 16+ (i/ COLS_EQUIPO)* 33)))
	for i in COLS_CAJA* FILAS_CAJA:
		celdas_caja.append(_hueco(panel_caja, Vector2(10+ (i% COLS_CAJA)* 40, 16+ (i/ COLS_CAJA)* 33)))
	_pintar()

func _hueco(padre: Panel, pos: Vector2) -> Panel:
	var h:= Panel.new()
	h.position= pos
	h.size =TAM_CELDA
	var st:= StyleBoxFlat.new()
	st.bg_color= Color("2a3448")
	st.set_border_width_all(1)
	st.border_color =Color("5a6c90")
	st.set_corner_radius_all(3)
	h.add_theme_stylebox_override("panel", st)
	var ic:= Sprite2D.new()
	ic.name= "Icono"
	ic.position =Vector2(TAM_CELDA.x/ 2.0, ICONO_Y)
	h.add_child(ic)
	padre.add_child(h)
	return h

func _poner_icono(h: Panel, p: PokemonInstancia) -> void:
	var ic: Sprite2D= h.get_node("Icono")
	ic.visible= p!= null
	if p== null:
		return
	var ruta:= ICONOS+ "%s.png" % p.especie.id
	if ResourceLoader.exists(ruta):
		ic.texture= load(ruta)
		ic.hframes =2
	else:
		ic.texture= EstiloUI.icono(p.especie)
		ic.hframes =1

func seleccionado() -> PokemonInstancia:
	if lado== 0:
		return Equipo.miembros[indice] if indice< Equipo.miembros.size() else null
	return Equipo.caja[indice] if indice< Equipo.caja.size() else null

func _pintar() -> void:
	var filas_totales:= maxi(FILAS_CAJA, ceili((Equipo.caja.size()+ 1)/ float(COLS_CAJA)))
	if lado== 1:
		var f:= indice/ COLS_CAJA
		if f< scroll:
			scroll= f
		elif f>= scroll+ FILAS_CAJA:
			scroll =f- FILAS_CAJA+ 1
	scroll= clampi(scroll, 0, maxi(0, filas_totales- FILAS_CAJA))
	for i in celdas_equipo.size():
		_poner_icono(celdas_equipo[i], Equipo.miembros[i] if i< Equipo.miembros.size() else null)
	for i in celdas_caja.size():
		var k:= scroll* COLS_CAJA+ i
		_poner_icono(celdas_caja[i], Equipo.caja[k] if k< Equipo.caja.size() else null)
	cuenta.text= "%d en la caja" % Equipo.caja.size()
	cuenta.horizontal_alignment =HORIZONTAL_ALIGNMENT_RIGHT
	$Caja/Flechas.text= ("▲" if scroll> 0 else " ")+ "\n\n\n"+ ("▼" if scroll+ FILAS_CAJA< filas_totales else " ")
	var celda: Panel= celdas_equipo[indice] if lado== 0 else celdas_caja[indice- scroll* COLS_CAJA]
	marco.global_position= celda.global_position- Vector2(2, 2)
	marco.size =TAM_CELDA+ Vector2(4, 4)
	var p:= seleccionado()
	for h in tipos.get_children():
		h.queue_free()
	if p== null:
		nombre.text= "- vacío -"
		datos.text =""
		ayuda.text= "B: SALIR"
		return
	nombre.text= "%s  Nv. %d" % [p.nombre(), p.nivel]
	datos.text ="PS %d/%d" % [p.ps_actuales, p.ps_max()]
	ayuda.text= ("A: DEJAR" if lado== 0 else "A: SACAR")+ "   B: SALIR"
	for i in p.especie.tipos.size():
		tipos.add_child(EstiloUI.insignia_tipo(p.especie.tipos[i], Vector2(i* 52, 0)))

func _process(delta: float) -> void:
	tiempo+= delta
	var todas:= celdas_equipo+ celdas_caja
	for i in todas.size():
		var ic: Sprite2D= todas[i].get_node("Icono")
		if not ic.visible or ic.hframes< 2:
			continue
		var elegido:= (lado== 0 and i== indice) or (lado== 1 and i- celdas_equipo.size()== indice- scroll* COLS_CAJA)
		var fase:= int(tiempo/ (0.14 if elegido else 0.3))% 2
		ic.frame= fase
		ic.position.y =ICONO_Y- fase* (2 if elegido else 0)

func _unhandled_input(event: InputEvent) -> void:
	if ocupado or GestorEscenas.en_transicion or Dialogo.esta_abierto:
		return
	if event.is_action_pressed("cancelar") or event.is_action_pressed("menu"):
		Sonido.efecto("cancelar")
		cerrado.emit()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("aceptar"):
		get_viewport().set_input_as_handled()
		_accion()
		return
	var antes:= [lado, indice]
	if event.is_action_pressed("izquierda"):
		_horizontal(-1)
	elif event.is_action_pressed("derecha"):
		_horizontal(1)
	elif event.is_action_pressed("arriba"):
		var cols:= COLS_EQUIPO if lado== 0 else COLS_CAJA
		if indice- cols>= 0:
			indice-= cols
	elif event.is_action_pressed("abajo"):
		if lado== 0:
			if indice+ COLS_EQUIPO< Equipo.MAXIMO:
				indice+= COLS_EQUIPO
		elif indice+ COLS_CAJA<= Equipo.caja.size():
			indice+= COLS_CAJA
	else:
		return
	if antes!= [lado, indice]:
		Sonido.efecto("cursor")
	_pintar()
	get_viewport().set_input_as_handled()

func _horizontal(d: int) -> void:
	if lado== 0:
		var c:= indice% COLS_EQUIPO
		if d> 0 and c== COLS_EQUIPO- 1:
			var f:= mini(indice/ COLS_EQUIPO, FILAS_CAJA- 1)
			lado= 1
			indice =(scroll+ f)* COLS_CAJA
		elif (d< 0 and c> 0) or (d> 0 and c< COLS_EQUIPO- 1):
			indice+= d
	else:
		var c2:= indice% COLS_CAJA
		if d< 0 and c2== 0:
			var f2:= indice/ COLS_CAJA- scroll
			lado= 0
			indice =mini(f2, Equipo.MAXIMO/ COLS_EQUIPO- 1)* COLS_EQUIPO+ COLS_EQUIPO- 1
		elif (d< 0 and c2> 0) or (d> 0 and c2< COLS_CAJA- 1):
			indice+= d

func _accion() -> void:
	var p:= seleccionado()
	if p== null:
		Sonido.efecto("error")
		return
	ocupado= true
	if lado== 0:
		var motivo:= Equipo.puede_depositar(indice)
		if motivo!= "":
			Sonido.efecto("error")
			await Dialogo.mostrar(motivo)
		elif await Dialogo.preguntar("¿Dejar a %s en la Caja?" % p.nombre())== 0:
			Equipo.depositar(indice)
			Sonido.efecto("guardar")
			indice= mini(indice, maxi(0, Equipo.miembros.size()- 1))
	else:
		if Equipo.esta_lleno():
			Sonido.efecto("error")
			await Dialogo.mostrar("Tu equipo está lleno. Deja primero a un Pokémon en la Caja.")
		elif await Dialogo.preguntar("¿Sacar a %s de la Caja?" % p.nombre())== 0:
			Equipo.retirar(indice)
			Sonido.efecto("guardar")
			indice= mini(indice, maxi(0, Equipo.caja.size()- 1))
	ocupado =false
	_pintar()
