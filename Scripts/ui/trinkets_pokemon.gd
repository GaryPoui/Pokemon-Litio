extends CanvasLayer

signal cerrado

const ICONOS:= "res://Assets/Pokemones/iconos/"
const FILAS_LISTA :=3
const COLUMNAS_GRILLA:= 3

@onready var icono_poke: Sprite2D= $Cabecera/Icono
@onready var nombre_poke: Label =$Cabecera/Nombre
@onready var cuenta: Label= $Cabecera/Cuenta
@onready var equipados: Panel =$Equipados
@onready var lista: Panel= $Lista
@onready var desc =$Desc
@onready var cursor_lbl: Label= $Cursor

var pokemon: PokemonInstancia
var columna:= 0
var fila :=0
var scroll:= 0
var ultimo_slot :=0
var libres: Array[String]= []

func _ready() -> void:
	layer= 107
	for p in [$Cabecera, equipados, lista]:
		p.add_theme_stylebox_override("panel", EstiloUI.panel())
	EstiloUI.label(nombre_poke, 9)
	EstiloUI.label(cuenta, 8)
	EstiloUI.fuente_batalla(cuenta)
	EstiloUI.label($Equipados/Titulo, 8)
	EstiloUI.fuente_batalla($Equipados/Titulo)
	EstiloUI.label($Lista/Titulo, 8)
	EstiloUI.fuente_batalla($Lista/Titulo)
	EstiloUI.label(cursor_lbl, 6)
	var seleccion: Label= $Equipados/Seleccion
	EstiloUI.label(seleccion, 8)
	for i in EfectosTrinket.MAX_POR_POKEMON:
		var c: Label= equipados.get_node("S%d/Cuenta" % i)
		EstiloUI.label(c, 8, Color.WHITE)
		EstiloUI.fuente_batalla(c)
		c.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	EstiloUI.fuente_batalla(seleccion)
	for i in EfectosTrinket.MAX_POR_POKEMON:
		var hueco:= StyleBoxFlat.new()
		hueco.bg_color= Color("2a3448")
		hueco.set_border_width_all(1)
		hueco.border_color =Color("5a6c90")
		hueco.set_corner_radius_all(3)
		equipados.get_node("S%d/Fondo" % i).add_theme_stylebox_override("panel", hueco)
	var marco:= StyleBoxFlat.new()
	marco.bg_color =Color(0, 0, 0, 0)
	marco.set_border_width_all(2)
	marco.border_color= Color("e05a30")
	marco.set_corner_radius_all(4)
	$Equipados/Marco.add_theme_stylebox_override("panel", marco)
	for i in FILAS_LISTA:
		for n in ["Nombre", "Cant"]:
			EstiloUI.label(lista.get_node("R%d/%s" % [i, n]), 8)
			EstiloUI.fuente_batalla(lista.get_node("R%d/%s" % [i, n]))

func abrir(p: PokemonInstancia) -> void:
	pokemon= p
	var ruta:= ICONOS+ "%s.png" % p.especie.id
	if ResourceLoader.exists(ruta):
		icono_poke.texture= load(ruta)
		icono_poke.hframes =2
	else:
		icono_poke.texture= EstiloUI.icono(p.especie)
		icono_poke.hframes =1
	nombre_poke.text= p.nombre()
	columna= 0 if not p.trinkets.is_empty() else 1
	fila =0
	_pintar()

func _pintar() -> void:
	libres= Inventario.ids_trinkets()
	var huecos:= EfectosTrinket.huecos(pokemon)
	cuenta.text ="Huecos usados: %d/%d" % [huecos.size(), EfectosTrinket.MAX_POR_POKEMON]
	for i in EfectosTrinket.MAX_POR_POKEMON:
		var s: Control= equipados.get_node("S%d" % i)
		var hay:= i< huecos.size()
		var t:= BaseDatos.trinket(huecos[i]) if hay else null
		(s.get_node("Icono") as TextureRect).texture= EfectosTrinket.icono(t) if t!= null else null
		var n:= pokemon.trinkets.count(huecos[i]) if hay else 0
		(s.get_node("Cuenta") as Label).text= "×%d" % n if n> 1 else ""
	var n_lista:= maxi(1, libres.size())
	if columna== 1:
		fila= clampi(fila, 0, n_lista- 1)
		if fila< scroll:
			scroll =fila
		elif fila>= scroll+ FILAS_LISTA:
			scroll= fila- FILAS_LISTA+ 1
	for i in FILAS_LISTA:
		var r: Control= lista.get_node("R%d" % i)
		var k:= scroll+ i
		r.visible =k< libres.size()
		if r.visible:
			var t:= BaseDatos.trinket(libres[k])
			(r.get_node("Icono") as TextureRect).texture= EfectosTrinket.icono(t)
			(r.get_node("Nombre") as Label).text =t.nombre
			(r.get_node("Cant") as Label).text= "×%d" % Inventario.cantidad_trinket(libres[k])
	$Lista/Vacio.visible= libres.is_empty()
	var marco: Panel= $Equipados/Marco
	var seleccion: Label= $Equipados/Seleccion
	var slot:= clampi(fila if columna== 0 else ultimo_slot, 0, EfectosTrinket.MAX_POR_POKEMON- 1)
	var id_slot:= huecos[slot] if slot< huecos.size() else ""
	var apilados:= pokemon.trinkets.count(id_slot) if id_slot!= "" else 0
	seleccion.text= (BaseDatos.trinket(id_slot).nombre+ (" ×%d" % apilados if apilados> 1 else "")) if id_slot!= "" else "- vacío -"
	seleccion.modulate =Color.WHITE if id_slot!= "" else Color(1, 1, 1, 0.45)
	marco.position= equipados.get_node("S%d" % slot).position- Vector2(1, 1)
	marco.visible =columna== 0
	cursor_lbl.visible= columna== 1
	if columna== 0:
		fila= slot
		_describir(id_slot, true)
	else:
		var r: Control= lista.get_node("R%d" % (fila- scroll))
		cursor_lbl.position =lista.position+ r.position+ Vector2(-8, 6)
		_describir(libres[fila] if fila< libres.size() else "", false)

func _describir(id: String, equipado: bool) -> void:
	var t:= BaseDatos.trinket(id) if id!= "" else null
	if t== null:
		desc.mensaje("Espacio libre: elige un Trinket de la derecha para equiparlo." if equipado else "No tienes Trinkets sin equipar. Consíguelos en la Torre Desafío o en la tienda.")
		return
	var extra:= ""
	var copias:= pokemon.trinkets.count(id)
	if copias> 0 and t.alcance== "portador":
		extra= "Con %d en %s: %s." % [copias, pokemon.nombre(), EfectosTrinket.valor_texto(t, EfectosTrinket.apilar(t, copias))]
	desc.mostrar(t, extra)

func _unhandled_input(event: InputEvent) -> void:
	if GestorEscenas.en_transicion:
		return
	if event.is_action_pressed("cancelar") or event.is_action_pressed("menu"):
		Sonido.efecto("cancelar")
		cerrado.emit()
	elif event.is_action_pressed("izquierda") or event.is_action_pressed("derecha"):
		_mover_horizontal(1 if event.is_action_pressed("derecha") else -1)
	elif event.is_action_pressed("arriba"):
		if columna== 0:
			if fila>= COLUMNAS_GRILLA:
				fila -=COLUMNAS_GRILLA
		else:
			fila= maxi(0, fila- 1)
		Sonido.efecto("cursor")
	elif event.is_action_pressed("abajo"):
		if columna== 0:
			if fila< COLUMNAS_GRILLA:
				fila= mini(fila+ COLUMNAS_GRILLA, EfectosTrinket.MAX_POR_POKEMON- 1)
		else:
			fila+= 1
		Sonido.efecto("cursor")
	elif event.is_action_pressed("aceptar"):
		var aviso:= _aceptar()
		_pintar()
		if aviso!= "":
			desc.mensaje(aviso)
		get_viewport().set_input_as_handled()
		return
	else:
		return
	_pintar()
	get_viewport().set_input_as_handled()

func _mover_horizontal(paso: int) -> void:
	Sonido.efecto("cursor")
	if columna== 1:
		if paso< 0:
			columna= 0
			fila =ultimo_slot
		return
	var col:= fila% COLUMNAS_GRILLA
	if paso> 0 and (col== COLUMNAS_GRILLA- 1 or fila+ 1>= EfectosTrinket.MAX_POR_POKEMON):
		ultimo_slot= fila
		columna =1
		fila= 0
		scroll =0
		return
	if paso< 0 and col== 0:
		return
	fila+= paso

func _aceptar() -> String:
	if columna== 0:
		var huecos:= EfectosTrinket.huecos(pokemon)
		if fila>= huecos.size():
			Sonido.efecto("error")
			return ""
		var id:= huecos[fila]
		EfectosTrinket.quitar_uno(pokemon, id)
		Inventario.agregar_trinket(id)
		Sonido.efecto("confirmar")
		return ""
	if fila>= libres.size():
		Sonido.efecto("error")
		return ""
	var id2:= libres[fila]
	var motivo:= EfectosTrinket.puede_equipar(pokemon, id2)
	if motivo!= "":
		Sonido.efecto("error")
		return motivo
	if Inventario.quitar_trinket(id2):
		pokemon.trinkets.append(id2)
		Sonido.efecto("confirmar")
	return ""
