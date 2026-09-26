extends CanvasLayer

signal elegido(indice: int)
signal continuar

@export var letras_por_segundo: float= 60.0

const COLOR_TEXTO:= Color("383838")
const COLOR_SOMBRA :=Color("d0d0c8")
const ABREV:= {"que": "QUE", "env": "ENV", "par": "PAR", "dor": "DOR", "con": "CON"}

@onready var velo: ColorRect= $Velo
@onready var sprite_rival: Sprite2D =$PokemonRival
@onready var sprite_jugador: Sprite2D= $PokemonJugador
@onready var ball: Sprite2D =$Ball
@onready var caja_rival: TextureRect= $CajaRival
@onready var caja_jugador: TextureRect =$CajaJugador
@onready var caja: Panel= $Caja
@onready var mensaje: Label =$Caja/Mensaje
@onready var menu: Panel= $Menu
@onready var info_mov: Panel =$InfoMov
@onready var info_texto: Label= $InfoMov/Texto
@onready var lista: Panel =$Lista
@onready var titulo_lista: Label= $Lista/Titulo
@onready var items_lista: Control =$Lista/Items

var logica: LogicaCombate
var etiquetas: Array[Label]= []
var textos_menu: Array= []
var cursor:= 0
var columnas :=1
var eligiendo:= false
var cancelable :=false
var esperando:= false
var tipeando :=false
var saltar:= false
var al_mover: Callable
var auto_avanzar:= false
var flecha_menu: Label
var vista: Dictionary= {"rival": {}, "jugador": {}}

func _ready() -> void:
	layer= 50
	for p in [caja, menu, lista, info_mov]:
		p.add_theme_stylebox_override("panel", _estilo_panel())
	for l in [mensaje, info_texto, titulo_lista]:
		_estilo_label(l, 9)
	for ruta in ["CajaRival/Nombre", "CajaRival/Nivel", "CajaJugador/Nombre", "CajaJugador/Nivel", "CajaJugador/PSActual", "CajaJugador/PSMax", "CajaRival/Estado", "CajaJugador/Estado"]:
		_estilo_label(get_node(ruta), 8)
		EstiloUI.fuente_batalla(get_node(ruta))
	for ruta in ["CajaRival/Estado", "CajaJugador/Estado"]:
		get_node(ruta).add_theme_color_override("font_color", Color("c03028"))
	menu.visible= false
	lista.visible =false
	info_mov.visible= false
	ball.visible =false
	caja_rival.visible= false
	caja_jugador.visible =false
	sprite_rival.visible= false
	sprite_jugador.visible =false
	velo.color= Color.BLACK
	mensaje.text =""

func _estilo_panel() -> StyleBoxFlat:
	var e:= StyleBoxFlat.new()
	e.bg_color= Color("f8f8f8")
	e.set_border_width_all(2)
	e.border_color =Color("3a4a6a")
	e.set_corner_radius_all(3)
	return e

func _estilo_label(l: Label, tam: int) -> void:
	EstiloUI.label(l, tam)

func empezar(rivales: Array[PokemonInstancia], salvaje: bool, entrenador: String) -> String:
	logica= LogicaCombate.new(Equipo.miembros, rivales, salvaje, entrenador)
	logica.inventario =Inventario
	logica.equipo= Equipo
	await _entrada()
	await _reproducir(logica.iniciar())
	while not logica.terminado:
		var accion:= await _elegir_accion()
		await _reproducir(logica.turno(accion))
		while logica.esperando_reemplazo and not logica.terminado:
			var i:= await _elegir_pokemon(true, false)
			await _reproducir(logica.reemplazar(i))
	await _salida()
	return logica.resultado

func _entrada() -> void:
	velo.modulate.a= 1.0
	var t:= create_tween()
	t.tween_property(velo, "modulate:a", 0.0, 0.4)
	await t.finished

func _salida() -> void:
	var t:= create_tween()
	t.tween_property(velo, "modulate:a", 1.0, 0.4)
	await t.finished

func _reproducir(eventos: Array[Dictionary]) -> void:
	for e in eventos:
		match e["tipo"]:
			"texto":
				await _decir(e["texto"])
			"sale":
				vista[e["lado"]]= {"p": e["pokemon"], "ps": e["ps"], "max": e["max"], "nivel": e["nivel"], "estado": e["estado"], "exp": e["exp"]}
				await _sale(e["lado"], e["pokemon"])
			"retirar":
				await _retirar(e["lado"])
			"ps":
				await _animar_ps(e)
			"debilitado":
				await _debilitar(e["lado"])
			"estado":
				if not vista[e["lado"]].is_empty():
					vista[e["lado"]]["estado"]= e["estado"]
				_actualizar_cajas()
			"nivel":
				var vj: Dictionary= vista["jugador"]
				if not vj.is_empty() and vj["p"]== e["pokemon"]:
					vj["nivel"]= e["nivel"]
					vj["ps"] =e["ps"]
					vj["max"]= e["max"]
				_actualizar_cajas()
			"exp":
				await _animar_exp(e)
			"quiere_aprender":
				await _aprender(e["pokemon"], e["movimiento"])
			"captura":
				await _animar_captura(e)

func _decir(texto: String) -> void:
	mensaje.size.x= 240
	mensaje.text =texto
	mensaje.visible_characters= 0
	tipeando =true
	saltar= false
	var t:= 0.0
	var total:= mensaje.get_total_character_count()
	while mensaje.visible_characters< total and not saltar:
		await get_tree().process_frame
		t+= get_process_delta_time()
		mensaje.visible_characters= mini(total, int(t* letras_por_segundo))
	mensaje.visible_characters =-1
	tipeando= false
	await _esperar_confirmacion()

func _esperar_confirmacion() -> void:
	if auto_avanzar:
		await get_tree().create_timer(0.05).timeout
		return
	esperando= true
	await continuar
	esperando =false

func _mostrar(texto: String, ancho: float) -> void:
	mensaje.size.x= ancho
	mensaje.text =texto
	mensaje.visible_characters= -1

func _elegir(textos: Array, cols: int, puede_cancelar: bool, zona: Rect2, en_lista: bool, al_mover_cb: Callable= Callable()) -> int:
	var cont: Control= items_lista if en_lista else menu
	for c in cont.get_children():
		c.queue_free()
	etiquetas.clear()
	textos_menu= textos
	var ancho: float
	var alto: float
	if en_lista:
		lista.visible= true
		ancho =items_lista.size.x- 16
		alto= 12.0
	else:
		menu.position =zona.position
		menu.size= zona.size
		menu.visible =true
		var filas:= ceili(textos.size()/ float(cols))
		ancho= (zona.size.x- 12)/ cols
		alto =minf(14.0, (zona.size.y- 8)/ filas)
	for i in textos.size():
		var l:= Label.new()
		_estilo_label(l, 8 if en_lista else 9)
		l.position= Vector2(14+ (i% cols)* ancho, 4+ floori(i/ float(cols))* alto)
		l.text =str(textos[i])
		cont.add_child(l)
		etiquetas.append(l)
	flecha_menu= EstiloUI.nuevo_label("▶", 6, Vector2.ZERO)
	cont.add_child(flecha_menu)
	cursor= 0
	columnas =cols
	cancelable= puede_cancelar
	al_mover =al_mover_cb
	_pintar_cursor()
	eligiendo= true
	var res: int= await elegido
	eligiendo =false
	menu.visible= false
	lista.visible =false
	info_mov.visible= false
	return res

func _pintar_cursor() -> void:
	if flecha_menu!= null and cursor< etiquetas.size():
		var fila:= etiquetas[cursor]
		flecha_menu.position= Vector2(fila.position.x- 8, fila.position.y+ roundi((fila.get_combined_minimum_size().y- flecha_menu.get_combined_minimum_size().y)/ 2.0))
	if al_mover.is_valid():
		al_mover.call(cursor)

func _mover(d: int) -> void:
	var nuevo:= cursor+ d
	if nuevo>= 0 and nuevo< etiquetas.size():
		cursor= nuevo
		_pintar_cursor()

func _unhandled_input(event: InputEvent) -> void:
	var acepta:= event.is_action_pressed("aceptar")
	var cancela:= event.is_action_pressed("cancelar")
	if eligiendo:
		if acepta:
			elegido.emit(cursor)
		elif cancela and cancelable:
			elegido.emit(-1)
		elif event.is_action_pressed("derecha"):
			_mover(1)
		elif event.is_action_pressed("izquierda"):
			_mover(-1)
		elif event.is_action_pressed("abajo"):
			_mover(columnas)
		elif event.is_action_pressed("arriba"):
			_mover(-columnas)
		else:
			return
		get_viewport().set_input_as_handled()
	elif tipeando and (acepta or cancela):
		saltar= true
		get_viewport().set_input_as_handled()
	elif esperando and (acepta or cancela):
		get_viewport().set_input_as_handled()
		continuar.emit()

func _elegir_accion() -> Dictionary:
	while true:
		_mostrar("¿Qué debería hacer %s?" % logica.j.pokemon.nombre(), 120)
		var op:= await _elegir(["LUCHAR", "MOCHILA", "POKéMON", "HUIR"], 2, false, Rect2(132, 144, 124, 48), false)
		match op:
			0:
				var m:= await _elegir_movimiento()
				if m!= -2:
					return {"tipo": "movimiento", "indice": m}
			1:
				var acc:= await _elegir_objeto()
				if not acc.is_empty():
					return acc
			2:
				var i:= await _elegir_pokemon(false, false)
				if i>= 0:
					return {"tipo": "cambio", "indice": i}
			3:
				return {"tipo": "huir"}
	return {}

func _elegir_movimiento() -> int:
	var p:= logica.j.pokemon
	if p.pp.all(func(v): return v<= 0):
		return -1
	var nombres:= []
	for i in 4:
		nombres.append(p.movimientos[i].nombre if i< p.movimientos.size() else "-")
	while true:
		info_mov.visible= true
		var i:= await _elegir(nombres, 2, true, Rect2(0, 144, 176, 48), false, _info_movimiento)
		if i< 0:
			return -2
		if i>= p.movimientos.size():
			continue
		if p.pp[i]<= 0:
			await _decir("¡No quedan PP para este movimiento!")
			continue
		return i
	return -2

func _info_movimiento(i: int) -> void:
	var p:= logica.j.pokemon
	info_mov.visible= true
	if i>= p.movimientos.size():
		info_texto.text =""
		return
	var m:= p.movimientos[i]
	info_texto.text= "PP %d/%d\n%s" % [p.pp[i], m.pp, Tipos.nombre(m.tipo).to_upper()]

func _elegir_objeto() -> Dictionary:
	var ids:= []
	for id in Inventario.objetos:
		var o: Objeto= Inventario.objetos[id]
		if Inventario.cantidad_de(id)<= 0:
			continue
		if o.cura_ps> 0 or (o.ratio_captura> 0.0 and logica.salvaje):
			ids.append(id)
	if ids.is_empty():
		await _decir("No tienes objetos que puedas usar ahora.")
		return {}
	titulo_lista.text= "MOCHILA"
	var textos:= ids.map(func(id): return "%s  x%d" % [Inventario.get_item_name(id), Inventario.cantidad_de(id)])
	var i:= await _elegir(textos, 1, true, Rect2(), true)
	if i< 0:
		return {}
	var o:= Inventario.get_objeto(ids[i])
	if o.cura_ps> 0:
		var k:= await _elegir_pokemon(false, true)
		if k< 0:
			return {}
		var p:= Equipo.miembros[k]
		if p.esta_debilitado() or p.ps_actuales>= p.ps_max():
			await _decir("No tendrá ningún efecto.")
			return {}
		return {"tipo": "objeto", "id": o.id, "objetivo": k}
	return {"tipo": "objeto", "id": o.id}

func _elegir_pokemon(forzado: bool, para_objeto: bool) -> int:
	while true:
		titulo_lista.text= "POKéMON"
		var textos:= Equipo.miembros.map(func(p): return "%s  Nv%d  %d/%d PS%s" % [p.nombre(), p.nivel, p.ps_actuales, p.ps_max(), "  " +ABREV[p.estado] if ABREV.has(p.estado) else ""])
		var i:= await _elegir(textos, 1, not forzado, Rect2(), true)
		if i< 0:
			return -1
		var p:= Equipo.miembros[i]
		if para_objeto:
			return i
		if p.esta_debilitado():
			await _decir("¡%s no puede luchar!" % p.nombre())
			continue
		if p== logica.j.pokemon:
			await _decir("¡%s ya está luchando!" % p.nombre())
			continue
		return i
	return -1

func _sale(lado: String, p: PokemonInstancia) -> void:
	var spr: Sprite2D= sprite_rival if lado== "rival" else sprite_jugador
	if lado== "rival":
		Estado.ver(p.especie.id)
	spr.mostrar(p.especie, lado== "jugador")
	spr.scale= Vector2(2, 2) if lado== "jugador" else Vector2.ONE
	spr.modulate.a =0.0
	var destino: Vector2= spr.pos_base
	spr.position= destino+ Vector2(48 if lado== "rival" else -48, 0)
	var t:= create_tween().set_parallel()
	t.tween_property(spr, "position", destino, 0.3)
	t.tween_property(spr, "modulate:a", 1.0, 0.3)
	await t.finished
	_actualizar_cajas()
	_caja(lado).visible= true

func _caja(lado: String) -> TextureRect:
	return caja_rival if lado== "rival" else caja_jugador

func _retirar(lado: String) -> void:
	var spr: Sprite2D= sprite_rival if lado== "rival" else sprite_jugador
	var t:= create_tween()
	t.tween_property(spr, "modulate:a", 0.0, 0.25)
	await t.finished
	spr.visible= false
	_caja(lado).visible =false

func _animar_ps(e: Dictionary) -> void:
	var lado: String= e["lado"]
	var barra= caja_rival.get_node("Barra") if lado== "rival" else caja_jugador.get_node("Barra")
	var spr: Sprite2D =sprite_rival if lado== "rival" else sprite_jugador
	var maximo: float= maxf(1.0, e["max"])
	if int(e["hasta"])< int(e["desde"]):
		for k in 3:
			spr.visible= false
			await get_tree().create_timer(0.06).timeout
			spr.visible =true
			await get_tree().create_timer(0.06).timeout
	if not vista[lado].is_empty():
		vista[lado]["max"]= int(e["max"])
	var dur:= 0.2+ 0.8* absf(float(e["hasta"])- float(e["desde"]))/ maximo
	var paso:= func(v: float) -> void:
		barra.poner(v/ maximo)
		if lado== "jugador":
			caja_jugador.get_node("PSActual").text= "%d / %d" % [roundi(v), roundi(maximo)]
	var t:= create_tween()
	t.tween_method(paso, float(e["desde"]), float(e["hasta"]), dur)
	await t.finished
	if not vista[lado].is_empty():
		vista[lado]["ps"]= int(e["hasta"])
	_actualizar_cajas()

func _debilitar(lado: String) -> void:
	var spr: Sprite2D= sprite_rival if lado== "rival" else sprite_jugador
	var t:= create_tween().set_parallel()
	t.tween_property(spr, "position", spr.position+ Vector2(0, 24), 0.35)
	t.tween_property(spr, "modulate:a", 0.0, 0.35)
	await t.finished
	spr.visible= false
	_caja(lado).visible =false

func _ratio_exp(g: String, nivel: int, experiencia: int) -> float:
	if nivel>= PokemonInstancia.NIVEL_MAX:
		return 1.0
	var base:= Crecimiento.exp_para_nivel(g, nivel)
	var sig:= Crecimiento.exp_para_nivel(g, nivel+ 1)
	return clampf(float(experiencia- base)/ maxf(1.0, sig- base), 0.0, 1.0)

func _animar_exp(e: Dictionary) -> void:
	var p: PokemonInstancia= e["pokemon"]
	var vj: Dictionary= vista["jugador"]
	if vj.is_empty() or p!= vj["p"]:
		return
	var g:= p.especie.crecimiento
	var barra= caja_jugador.get_node("Exp")
	var nivel: int= e["nivel_desde"]
	var desde: int =e["desde"]
	while nivel< int(e["nivel_hasta"]):
		var fin:= Crecimiento.exp_para_nivel(g, nivel+ 1)
		await _tween_barra(barra, _ratio_exp(g, nivel, desde), 1.0)
		nivel+= 1
		desde= fin
		vj["nivel"]= nivel
		vj["exp"] =fin
		caja_jugador.get_node("Nivel").text =str(nivel)
		barra.poner(0.0)
	await _tween_barra(barra, _ratio_exp(g, nivel, desde), _ratio_exp(g, nivel, int(e["hasta"])))
	vj["exp"]= int(e["hasta"])

func _tween_barra(barra: Control, a: float, b: float) -> void:
	var t:= create_tween()
	t.tween_method(barra.poner, a, b, 0.1+ 0.6* absf(b- a))
	await t.finished

func _aprender(p: PokemonInstancia, m: Movimiento) -> void:
	await _decir("%s quiere aprender %s." % [p.nombre(), m.nombre])
	await _decir("Pero %s ya conoce cuatro movimientos." % p.nombre())
	titulo_lista.text= "¿Qué movimiento olvidar?"
	var textos:= p.movimientos.map(func(x): return x.nombre)
	textos.append("No aprender %s" % m.nombre)
	var i:= await _elegir(textos, 1, true, Rect2(), true)
	if i< 0 or i>= p.movimientos.size():
		await _decir("%s no aprendió %s." % [p.nombre(), m.nombre])
		return
	var viejo:= p.movimientos[i].nombre
	p.reemplazar_movimiento(i, m)
	await _decir("1, 2 y... ¡Tachán!")
	await _decir("%s olvidó %s y aprendió %s." % [p.nombre(), viejo, m.nombre])

func _animar_captura(e: Dictionary) -> void:
	ball.position= sprite_rival.pos_base+ Vector2(0, -12)
	ball.rotation =0.0
	ball.visible= true
	var t:= create_tween().set_parallel()
	t.tween_property(sprite_rival, "scale", Vector2(0.1, 0.1), 0.3)
	t.tween_property(sprite_rival, "modulate:a", 0.0, 0.3)
	await t.finished
	sprite_rival.visible= false
	for k in int(e["sacudidas"]):
		await get_tree().create_timer(0.3).timeout
		var s:= create_tween()
		s.tween_property(ball, "rotation", -0.35, 0.1)
		s.tween_property(ball, "rotation", 0.35, 0.15)
		s.tween_property(ball, "rotation", 0.0, 0.1)
		await s.finished
	await get_tree().create_timer(0.3).timeout
	if e["exito"]:
		ball.modulate= Color(0.7, 0.7, 0.7)
		return
	ball.visible= false
	sprite_rival.visible =true
	sprite_rival.scale= Vector2.ONE
	var v:= create_tween()
	v.tween_property(sprite_rival, "modulate:a", 1.0, 0.2)
	await v.finished

func _actualizar_cajas() -> void:
	var vr: Dictionary= vista["rival"]
	if not vr.is_empty():
		caja_rival.get_node("Nombre").text= vr["p"].nombre()
		caja_rival.get_node("Nivel").text =str(vr["nivel"])
		caja_rival.get_node("Estado").text= ABREV.get(vr["estado"], "")
		caja_rival.get_node("Barra").poner(float(vr["ps"])/ maxf(1.0, vr["max"]))
	var vj: Dictionary =vista["jugador"]
	if not vj.is_empty():
		var pj: PokemonInstancia= vj["p"]
		caja_jugador.get_node("Nombre").text =pj.nombre()
		caja_jugador.get_node("Nivel").text= str(vj["nivel"])
		caja_jugador.get_node("Estado").text =ABREV.get(vj["estado"], "")
		caja_jugador.get_node("Barra").poner(float(vj["ps"])/ maxf(1.0, vj["max"]))
		caja_jugador.get_node("PSActual").text= "%d / %d" % [vj["ps"], vj["max"]]
		caja_jugador.get_node("PSMax").text =""
		caja_jugador.get_node("Exp").poner(_ratio_exp(pj.especie.crecimiento, vj["nivel"], vj["exp"]))
