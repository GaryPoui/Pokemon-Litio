extends CanvasLayer

signal opened
signal closed
signal elegido(resultado: Dictionary)

const P:= "res://Assets/Menus-Mochila/platino/"
const FILAS :=7
const ALTO_FILA:= 16
const ALTO_ACCION :=14
const ESCENA_EQUIPO :="res://Escenas/UI/PantallaEquipo.tscn"

var is_open: bool= false
var ocupado:= false
var en_combate :=false
var filtro_combate: Callable
var resultado_combate:= {}

@onready var inventory: Node= Inventario
@onready var pantalla: Control =$Pantalla
@onready var bolsa: TextureRect= $Pantalla/Bolsa
@onready var icono_bolsillo: TextureRect =$Pantalla/Placa/IconoSel
@onready var marco_bolsillo: TextureRect= $Pantalla/Placa/Marco
@onready var nombre_bolsillo: Label =$Pantalla/Placa/Nombre
@onready var marco: NinePatchRect= $Pantalla/Lista/Marco
@onready var icono: TextureRect =$Pantalla/Desc/Icono
@onready var footer_label: Label= $Pantalla/Desc/Texto
@onready var action_panel: Panel =$Pantalla/Acciones
@onready var action_list: ListaOpciones= $Pantalla/Acciones/Lista

var categories: Array[String]= []
var category_index: int =0
var item_index: int= 0
var scroll:= 0
var posiciones: Array[int] =[]
var current_items: Array[Dictionary]= []
var action_mode: bool =false
var acciones: Array[String]= []
var filas: Array[Control] =[]
var bolsa_y: float
var tween_bolsa: Tween

func _ready() -> void:
	layer= 100
	pantalla.visible =false
	action_panel.visible= false
	categories =inventory.get_categories()
	posiciones.resize(categories.size())
	for i in FILAS:
		var f: Control= get_node("Pantalla/Lista/F%d" % i)
		EstiloUI.label(f.get_node("Nombre"), 9)
		EstiloUI.label(f.get_node("Cantidad"), 9)
		filas.append(f)
	EstiloUI.label(nombre_bolsillo, 9)
	EstiloUI.label(footer_label, 9, Color.WHITE)
	action_panel.add_theme_stylebox_override("panel", EstiloUI.panel())
	bolsa_y= bolsa.position.y
	inventory.inventory_changed.connect(_on_inventory_changed)
	_refresh_items()

func _unhandled_input(event: InputEvent) -> void:
	if ocupado or not is_open or Dialogo.esta_abierto or GestorEscenas.en_transicion:
		return
	if Combate.activo and not en_combate:
		return
	if action_mode:
		_handle_action_input(event)
	else:
		_handle_bag_input(event)

func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func open() -> void:
	if is_open:
		return
	is_open= true
	ocupado =true
	await GestorEscenas.cubrir()
	pantalla.visible= true
	_close_action_menu()
	_refresh_items()
	opened.emit()
	await GestorEscenas.descubrir()
	ocupado= false

func close() -> void:
	if not is_open:
		return
	is_open =false
	ocupado= true
	await GestorEscenas.cubrir()
	_cerrar_cubierto()
	await GestorEscenas.descubrir()

func _cerrar_cubierto() -> void:
	is_open= false
	_close_action_menu()
	pantalla.visible =false
	ocupado =false
	closed.emit()
	if en_combate:
		en_combate= false
		elegido.emit(resultado_combate)

func elegir_en_combate(filtro: Callable) -> Dictionary:
	en_combate =true
	filtro_combate= filtro
	resultado_combate= {}
	open()
	var r: Dictionary= await elegido
	return r

func _handle_bag_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancelar") or event.is_action_pressed("menu"):
		close()
	elif event.is_action_pressed("izquierda"):
		_change_category(-1)
	elif event.is_action_pressed("derecha"):
		_change_category(1)
	elif event.is_action_pressed("arriba"):
		_change_item(-1)
	elif event.is_action_pressed("abajo"):
		_change_item(1)
	elif event.is_action_pressed("aceptar"):
		if not current_items.is_empty():
			_open_action_menu()
	else:
		return
	get_viewport().set_input_as_handled()

func _handle_action_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancelar") or event.is_action_pressed("menu"):
		_close_action_menu()
	elif event.is_action_pressed("aceptar"):
		_execute_selected_action()
	elif not action_list.mover_con_evento(event):
		return
	get_viewport().set_input_as_handled()

func _change_category(delta: int) -> void:
	category_index= wrapi(category_index+ delta, 0, categories.size())
	item_index =posiciones[category_index]
	scroll= 0
	_refresh_items()
	_saltar_bolsa()

func _change_item(delta: int) -> void:
	if current_items.is_empty():
		return
	item_index =wrapi(item_index +delta, 0, current_items.size())
	_refresh_selection()

func _saltar_bolsa() -> void:
	if tween_bolsa:
		tween_bolsa.kill()
	bolsa.position.y= bolsa_y
	tween_bolsa =create_tween()
	tween_bolsa.tween_property(bolsa, "position:y", bolsa_y- 4, 0.06).set_ease(Tween.EASE_OUT)
	tween_bolsa.tween_property(bolsa, "position:y", bolsa_y, 0.06).set_ease(Tween.EASE_IN)
	tween_bolsa.tween_property(bolsa, "position:y", bolsa_y- 1, 0.04)
	tween_bolsa.tween_property(bolsa, "position:y", bolsa_y, 0.04)

func _refresh_items() -> void:
	if categories.is_empty():
		return
	current_items =inventory.get_items_for_category(categories[category_index])
	item_index= clampi(item_index, 0, maxi(0, current_items.size()- 1))
	_refresh_selection()

func _refresh_selection() -> void:
	posiciones[category_index]= item_index
	if item_index< scroll:
		scroll =item_index
	elif item_index>= scroll+ FILAS:
		scroll= item_index- FILAS +1
	scroll =clampi(scroll, 0, maxi(0, current_items.size()- FILAS))
	for i in FILAS:
		var k:= scroll+ i
		var f:= filas[i]
		f.visible= k< current_items.size()
		if not f.visible:
			continue
		var item: Dictionary =current_items[k]
		(f.get_node("Nombre") as Label).text= str(item.get("name", ""))
		(f.get_node("Cantidad") as Label).text ="" if item.get("category", "")== "CLAVE" else "×%d" % int(item.get("quantity", 0))
	marco.visible= not current_items.is_empty()
	marco.position.y =filas[0].position.y+ (item_index- scroll)* ALTO_FILA
	nombre_bolsillo.text= inventory.nombre_bolsillo(categories[category_index])
	bolsa.texture =load(P+ "bolsa_m_%d.png" % category_index)
	icono_bolsillo.texture= load(P +"icono_%d_0.png" % category_index)
	icono_bolsillo.position.x= 6+ 11* category_index
	marco_bolsillo.position.x =5 +11* category_index
	if current_items.is_empty():
		icono.texture= null
		footer_label.text ="Este bolsillo está vacío."
		return
	var actual: Dictionary= current_items[item_index]
	icono.texture= actual.get("icon")
	footer_label.text =str(actual.get("description", ""))

func _open_action_menu() -> void:
	if current_items.is_empty():
		return
	var item: Dictionary= current_items[item_index]
	acciones= []
	if en_combate:
		acciones.append_array(["USAR", "CANCELAR"])
	else:
		if bool(item.get("usable", false)):
			acciones.append("USAR")
		acciones.append("DAR")
		if item.get("category", "")== "CLAVE":
			acciones.append("REGISTRAR")
		if bool(item.get("can_toss", true)):
			acciones.append("TIRAR")
		acciones.append("CANCELAR")
	action_list.size.y= acciones.size()* ALTO_ACCION
	action_panel.size.y =action_list.size.y+ 8
	action_panel.position.y= 139- action_panel.size.y
	action_list.alto_fila= ALTO_ACCION
	action_list.poner(acciones)
	action_mode =true
	action_panel.visible= true

func _close_action_menu() -> void:
	action_mode= false
	action_panel.visible =false

func _execute_selected_action() -> void:
	if acciones.is_empty() or current_items.is_empty():
		return
	var action:= acciones[action_list.cursor]
	var item: Dictionary= current_items[item_index]
	var item_id:= str(item.get("id", ""))
	_close_action_menu()
	match action:
		"USAR":
			if en_combate:
				_usar_en_combate(item_id)
			else:
				_usar(item_id)
		"DAR":
			_dar(item_id)
		"REGISTRAR":
			_show_status("%s registrado." % str(item.get("name", "El objeto")))
		"TIRAR":
			if inventory.toss_item(item_id):
				_show_status("Tiraste una unidad.")
			else:
				_show_status("Este objeto no se puede tirar.")

func _usar_en_combate(item_id: String) -> void:
	var o:= Inventario.get_objeto(item_id)
	if o== null or not bool(filtro_combate.call(o)):
		_show_status("¡No es momento de usar esto!")
		return
	if o.cura_ps<= 0:
		resultado_combate= {"id": item_id}
		close()
		return
	var sin_efecto:= func(i: int) -> String:
		var p:= Equipo.miembros[i]
		return "No tendrá ningún efecto." if p.esta_debilitado() or p.ps_actuales>= p.ps_max() else ""
	ocupado= true
	var pantalla_equipo= await _abrir_equipo("¿En qué Pokémon usar %s?" % o.nombre, sin_efecto)
	await pantalla_equipo.cerrado
	var r: int= pantalla_equipo.resultado
	await GestorEscenas.cubrir()
	pantalla_equipo.queue_free()
	if r< 0:
		await GestorEscenas.descubrir()
		ocupado= false
		return
	resultado_combate= {"id": item_id, "objetivo": r}
	_cerrar_cubierto()
	await GestorEscenas.descubrir()

func _abrir_equipo(texto: String, validacion: Callable= Callable()) -> Node:
	var p= load(ESCENA_EQUIPO).instantiate()
	await GestorEscenas.fundido(func():
		add_child(p)
		p.abrir("elegir", texto, validacion))
	return p

func _elegir_pokemon(texto: String) -> int:
	if Equipo.miembros.is_empty():
		_show_status("No tienes ningún Pokémon.")
		return -1
	ocupado= true
	var p= await _abrir_equipo(texto)
	await p.cerrado
	var r: int= p.resultado
	await GestorEscenas.fundido(func(): p.queue_free())
	ocupado =false
	return r

func _usar(item_id: String) -> void:
	var o:= Inventario.get_objeto(item_id)
	if o== null or Inventario.cantidad_de(item_id)<= 0:
		return
	if o.cura_ps> 0:
		var i:= await _elegir_pokemon("¿En qué Pokémon usar %s?" % o.nombre)
		if i< 0:
			return
		var p:= Equipo.miembros[i]
		if p.esta_debilitado() or p.ps_actuales>= p.ps_max():
			_show_status("No tendrá ningún efecto.")
			return
		Inventario.consumir(item_id)
		_show_status("%s recuperó %d PS." % [p.nombre(), p.curar_ps(o.cura_ps)])
	elif item_id== "repel":
		Inventario.consumir(item_id)
		Estado.pasos_repelente= 100
		_show_status("Usaste Repelente. Los Pokémon débiles no aparecerán.")
	else:
		_show_status("¡No es momento de usar esto!")

func _dar(item_id: String) -> void:
	var o:= Inventario.get_objeto(item_id)
	if o== null or o.categoria in ["CLAVE", "MT / MO"]:
		_show_status("Este objeto no se puede dar.")
		return
	var i:= await _elegir_pokemon("¿A quién le das %s?" % o.nombre)
	if i< 0:
		return
	var p:= Equipo.miembros[i]
	var previo:= p.objeto
	Inventario.consumir(item_id)
	p.objeto= item_id
	if previo!= "":
		Inventario.add_item(previo)
		_show_status("%s dejó %s y ahora lleva %s." % [p.nombre(), Inventario.get_item_name(previo), o.nombre])
	else:
		_show_status("%s ahora lleva %s." % [p.nombre(), o.nombre])

func _show_status(message: String) -> void:
	footer_label.text= message

func _on_inventory_changed() -> void:
	_refresh_items()
