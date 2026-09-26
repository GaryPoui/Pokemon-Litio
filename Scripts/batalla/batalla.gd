extends CanvasLayer

signal elegido(indice: int)
signal continuar

@export var letras_por_segundo: float= 60.0

const ABREV:= {"que": "QUE", "env": "ENV", "par": "PAR", "dor": "DOR", "con": "CON"}
const UI :="res://Assets/Batalla/ui_nueva/"
const COMANDOS:= ["Luchar", "Mochila", "Pokémon", "Huir"]
const ESCENA_MOCHILA :="res://Escenas/UI/Mochila/Mochila.tscn"
const ESCENA_EQUIPO:= "res://Escenas/UI/PantallaEquipo.tscn"
const BALLS :="res://Assets/Batalla/balls/"
const EMPUJE_COMANDO :=6
const EMPUJE_MOVIMIENTO:= 28
const BOTONES_TIPO :="res://Assets/Botones/tipos/"
const APAGADO :=Color(0.8, 0.8, 0.8)
const X_COMANDOS:= 182
const X_MOVIMIENTOS :=168
const ESCALA_JUGADOR:= Vector2(1.75, 1.75)
const DESLIZ :=0.08

@onready var velo: ColorRect= $Velo
@onready var fondo_zona: TextureRect =$Fondo/FondoZona
@onready var sprite_rival: Sprite2D =$PokemonRival
@onready var sprite_jugador: Sprite2D= $PokemonJugador
@onready var ball: Sprite2D =$Ball
@onready var caja_rival: NinePatchRect= $PanelRival
@onready var caja_jugador: NinePatchRect =$PanelJugador
@onready var caja: Panel= $Caja
@onready var mensaje: Label =$Caja/Mensaje
@onready var comandos: Control= $Comandos
@onready var movimientos_ui: Control =$Movimientos
@onready var lista: Panel= $Lista
@onready var titulo_lista: Label =$Lista/Titulo
@onready var items_lista: Control= $Lista/Items

var logica: LogicaCombate
var etiquetas: Array[Label]= []
var cursor:= 0
var num_opciones :=0
var eligiendo:= false
var cancelable :=false
var esperando:= false
var tipeando :=false
var saltar:= false
var al_pintar: Callable
var auto_avanzar:= false
var flecha_menu: Label
var vista: Dictionary= {"rival": {}, "jugador": {}}
var modo_ps:= "porcentaje"
var mochila_combate: Node
var entrada_barras:= false
var ultimo_comando :=0
var pista:= "batalla_salvaje"
var musica_final :=false
var ultimo_movimiento:= 0

func _ready() -> void:
	layer= 50
	lista.add_theme_stylebox_override("panel", EstiloUI.panel())
	var translucido:= StyleBoxFlat.new()
	translucido.bg_color= Color(0.05, 0.07, 0.13, 0.62)
	translucido.set_border_width_all(1)
	translucido.border_color =Color(1, 1, 1, 0.45)
	translucido.set_corner_radius_all(3)
	caja.add_theme_stylebox_override("panel", translucido)
	EstiloUI.label(titulo_lista, 9)
	EstiloUI.fuente_batalla(titulo_lista)
	EstiloUI.label(mensaje, 9, Color.WHITE)
	EstiloUI.fuente_batalla(mensaje)
	for panel in [caja_rival, caja_jugador]:
		EstiloUI.label(panel.get_node("Nombre"), 9)
		EstiloUI.fuente_batalla(panel.get_node("Nombre"))
		EstiloUI.label(panel.get_node("Genero"), 9)
		for n in ["Nivel", "Estado"]:
			EstiloUI.label(panel.get_node(n), 8)
			EstiloUI.fuente_batalla(panel.get_node(n))
		panel.get_node("Estado").add_theme_color_override("font_color", Color("c03028"))
		var ps: Label= panel.get_node("PS")
		EstiloUI.label(ps, 8, Color.WHITE)
		EstiloUI.fuente_batalla(ps)
		ps.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
		panel.visible= false
	for i in 4:
		var tc: Label= comandos.get_node("B%d/Texto" % i)
		EstiloUI.label(tc, 9, Color.WHITE)
		EstiloUI.fuente_batalla(tc)
		tc.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
		tc.text= COMANDOS[i]
		var t: Label= movimientos_ui.get_node("M%d/Texto" % i)
		EstiloUI.label(t, 9, Color.WHITE)
		EstiloUI.fuente_batalla(t)
		t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	EstiloUI.label(movimientos_ui.get_node("Info"), 6)
	movimientos_ui.get_node("Info").add_theme_color_override("font_color", Color.WHITE)
	movimientos_ui.get_node("Info").add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	comandos.visible= false
	movimientos_ui.visible =false
	lista.visible= false
	caja.visible =false
	ball.visible= false
	sprite_rival.visible =false
	sprite_jugador.visible= false
	velo.color =Color.BLACK
	mensaje.text= ""

func poner_fondo(textura: Texture2D) -> void:
	fondo_zona.texture= textura
	fondo_zona.visible =textura!= null

func empezar(rivales: Array[PokemonInstancia], salvaje: bool, entrenador: String) -> String:
	logica= LogicaCombate.new(Equipo.miembros, rivales, salvaje, entrenador)
	logica.inventario =Inventario
	logica.equipo= Equipo
	var inicio:= logica.iniciar()
	if salvaje:
		for e in inicio:
			if e["tipo"]== "sale" and e["lado"]== "rival":
				sprite_rival.mostrar(e["pokemon"].especie, false)
				sprite_rival.scale= Vector2.ONE
				break
	await _entrada()
	await _reproducir(inicio)
	while not logica.terminado:
		var accion:= await _elegir_accion()
		await _reproducir(logica.turno(accion))
		while logica.esperando_reemplazo and not logica.terminado:
			var i:= await _elegir_pokemon(true)
			await _reproducir(logica.reemplazar(i))
	await _salida()
	return logica.resultado

func _entrada() -> void:
	if entrada_barras:
		velo.modulate.a= 0.0
		await GestorEscenas.barras_descubrir()
		return
	velo.modulate.a= 1.0
	var t:= create_tween()
	t.tween_property(velo, "modulate:a", 0.0, 0.4)
	await t.finished

func _salida() -> void:
	caja.visible= false
	var t:= create_tween()
	t.tween_property(velo, "modulate:a", 1.0, 0.4)
	await t.finished

func _reproducir(eventos: Array[Dictionary]) -> void:
	modo_ps= "porcentaje"
	_actualizar_cajas()
	for k in eventos.size():
		var e: Dictionary= eventos[k]
		match e["tipo"]:
			"texto":
				await _decir(e["texto"])
			"sonido":
				Sonido.efecto(e["nombre"])
			"jingle":
				Sonido.jingle(e["nombre"])
			"etapa":
				Sonido.efecto("stat_sube" if int(e["cambio"])> 0 else "stat_baja")
				await _esperar(0.5)
			"sale":
				if e["lado"]== "jugador" and not vista["jugador"].is_empty() and vista["jugador"]["p"]!= e["pokemon"]:
					ultimo_movimiento= 0
				vista[e["lado"]]= {"p": e["pokemon"], "ps": e["ps"], "max": e["max"], "nivel": e["nivel"], "estado": e["estado"], "exp": e["exp"]}
				await _sale(e["lado"], e["pokemon"], str(e.get("ball", "pokeball")))
				_revisar_ps_bajo()
			"retirar":
				await _retirar(e["lado"], str(e.get("ball", "pokeball")))
			"ps":
				await _animar_ps(e)
				_revisar_ps_bajo()
			"debilitado":
				await _debilitar(e["lado"])
				if e["lado"]== "rival" and _ultimo_rival(eventos, k):
					_musica_victoria()
				_revisar_ps_bajo()
			"estado":
				if not vista[e["lado"]].is_empty():
					vista[e["lado"]]["estado"]= e["estado"]
				_actualizar_cajas()
				if str(e["estado"])!= "":
					Sonido.efecto("estado_%s" % e["estado"])
			"nivel":
				var vj: Dictionary= vista["jugador"]
				if not vj.is_empty() and vj["p"]== e["pokemon"]:
					vj["nivel"]= e["nivel"]
					vj["ps"] =e["ps"]
					vj["max"]= e["max"]
				_actualizar_cajas()
				_revisar_ps_bajo()
				Sonido.jingle("subir_nivel")
			"exp":
				await _animar_exp(e)
			"quiere_aprender":
				await _aprender(e["pokemon"], e["movimiento"])
			"captura":
				await _animar_captura(e)
	caja.visible= false

func _ultimo_rival(eventos: Array[Dictionary], desde: int) -> bool:
	if logica.resultado!= "victoria":
		return false
	for k in range(desde+ 1, eventos.size()):
		if eventos[k]["tipo"]== "sale" and eventos[k]["lado"]== "rival":
			return false
	return true

func _musica_victoria() -> void:
	musica_final= true
	Sonido.musica("victoria_salvaje" if logica.salvaje else "victoria_entrenador", 0.2)

func _revisar_ps_bajo() -> void:
	if musica_final:
		return
	var vj: Dictionary= vista["jugador"]
	var bajo:= not vj.is_empty() and int(vj["ps"])> 0 and float(vj["ps"])/ maxf(1.0, float(vj["max"]))<= 0.2
	if bajo and Sonido.musica_actual!= "ps_bajo":
		Sonido.musica("ps_bajo", 0.15)
	elif not bajo and Sonido.musica_actual== "ps_bajo":
		Sonido.musica(pista, 0.3, true)

func _decir(texto: String) -> void:
	caja.visible= true
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

func _elegir_opcion(n: int, puede_cancelar: bool, pintar: Callable, inicio: int= 0) -> int:
	num_opciones= n
	cursor =clampi(inicio, 0, maxi(0, n- 1))
	cancelable= puede_cancelar
	al_pintar =pintar
	al_pintar.call(cursor)
	eligiendo= true
	var res: int= await elegido
	eligiendo =false
	return res

func _elegir_en_lista(textos: Array, puede_cancelar: bool) -> int:
	for c in items_lista.get_children():
		c.queue_free()
	etiquetas.clear()
	lista.visible= true
	for i in textos.size():
		var l:= EstiloUI.nuevo_label(str(textos[i]), 8, Vector2(14, 4+ i* 12))
		EstiloUI.fuente_batalla(l)
		items_lista.add_child(l)
		etiquetas.append(l)
	flecha_menu= EstiloUI.nuevo_label("▶", 6, Vector2.ZERO)
	items_lista.add_child(flecha_menu)
	var r:= await _elegir_opcion(textos.size(), puede_cancelar, _pintar_lista)
	lista.visible =false
	return r

func _pintar_lista(i: int) -> void:
	if i< etiquetas.size():
		var fila:= etiquetas[i]
		flecha_menu.position= Vector2(fila.position.x- 8, fila.position.y+ roundi((fila.get_combined_minimum_size().y- flecha_menu.get_combined_minimum_size().y)/ 2.0))

func _unhandled_input(event: InputEvent) -> void:
	if GestorEscenas.en_transicion:
		return
	var acepta:= event.is_action_pressed("aceptar")
	var cancela:= event.is_action_pressed("cancelar")
	if eligiendo:
		if acepta:
			Sonido.efecto("confirmar")
			elegido.emit(cursor)
		elif cancela and cancelable:
			Sonido.efecto("cancelar")
			elegido.emit(-1)
		elif event.is_action_pressed("abajo") or event.is_action_pressed("derecha"):
			_mover(1)
		elif event.is_action_pressed("arriba") or event.is_action_pressed("izquierda"):
			_mover(-1)
		else:
			return
		get_viewport().set_input_as_handled()
	elif tipeando and (acepta or cancela):
		saltar= true
		get_viewport().set_input_as_handled()
	elif esperando and (acepta or cancela):
		get_viewport().set_input_as_handled()
		continuar.emit()

func _mover(d: int) -> void:
	var nuevo:= cursor+ d
	if nuevo>= 0 and nuevo< num_opciones:
		cursor= nuevo
		al_pintar.call(cursor)
		Sonido.efecto("cursor")

func _elegir_accion() -> Dictionary:
	while true:
		caja.visible= false
		modo_ps ="porcentaje"
		_actualizar_cajas()
		comandos.visible= true
		var op:= await _elegir_opcion(4, false, _pintar_comandos, ultimo_comando)
		comandos.visible =false
		ultimo_comando= op
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
				var i:= await _elegir_pokemon(false)
				if i>= 0:
					return {"tipo": "cambio", "indice": i}
			3:
				return {"tipo": "huir"}
	return {}

func _pintar_comandos(sel: int) -> void:
	for i in 4:
		var b: NinePatchRect= comandos.get_node("B%d" % i)
		b.self_modulate= Color.WHITE if i== sel else APAGADO
		_deslizar(b, Vector2(X_COMANDOS- (EMPUJE_COMANDO if i== sel else 0), b.position.y))
	var cur: TextureRect= comandos.get_node("Cursor")
	var bs: NinePatchRect= comandos.get_node("B%d" % sel)
	_deslizar(cur, Vector2(X_COMANDOS- EMPUJE_COMANDO- cur.size.x- 2, bs.position.y+ roundi((bs.size.y- cur.size.y)/ 2.0)))

func _deslizar(n: Control, destino: Vector2) -> void:
	if n.has_meta("desliz"):
		var previo= n.get_meta("desliz")
		if previo is Tween and previo.is_valid():
			previo.kill()
	if not n.is_visible_in_tree():
		n.position= destino
		return
	var t:= create_tween()
	t.tween_property(n, "position", destino, DESLIZ).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	n.set_meta("desliz", t)

func _elegir_movimiento() -> int:
	var p:= logica.j.pokemon
	if p.pp.all(func(v): return v<= 0):
		return -1
	modo_ps= "valores"
	_actualizar_cajas()
	for i in 4:
		var b: NinePatchRect= movimientos_ui.get_node("M%d" % i)
		var hay:= i< p.movimientos.size()
		b.visible= hay
		if not hay:
			continue
		var m:= p.movimientos[i]
		b.get_node("Texto").text= m.nombre
		b.get_node("Tipo").texture =load(UI+ "tipos/%s.png" % m.tipo)
		b.texture= load(BOTONES_TIPO+ "%s.png" % m.tipo)
		b.set_meta("sin_pp", p.pp[i]<= 0)
	ultimo_movimiento= clampi(ultimo_movimiento, 0, p.movimientos.size()- 1)
	while true:
		caja.visible= false
		movimientos_ui.visible= true
		var i:= await _elegir_opcion(p.movimientos.size(), true, _pintar_movimientos, ultimo_movimiento)
		movimientos_ui.visible =false
		if i< 0:
			modo_ps= "porcentaje"
			_actualizar_cajas()
			return -2
		ultimo_movimiento= i
		if p.pp[i]<= 0:
			Sonido.efecto("error")
			await _decir("¡No quedan PP para este movimiento!")
			continue
		modo_ps ="porcentaje"
		return i
	return -2

func _pintar_movimientos(sel: int) -> void:
	var p:= logica.j.pokemon
	for i in 4:
		var b: NinePatchRect= movimientos_ui.get_node("M%d" % i)
		_deslizar(b, Vector2(X_MOVIMIENTOS- (EMPUJE_MOVIMIENTO if i== sel else 0), b.position.y))
		var base:= Color.WHITE if i== sel else APAGADO
		b.self_modulate =base.darkened(0.45) if b.get_meta("sin_pp", false) else base
	var m:= p.movimientos[sel]
	var bs: NinePatchRect= movimientos_ui.get_node("M%d" % sel)
	var cat: TextureRect= movimientos_ui.get_node("Categoria")
	cat.texture= load(UI+ "categoria_%s.png" % m.categoria)
	cat.position =Vector2(X_MOVIMIENTOS- EMPUJE_MOVIMIENTO+ bs.size.x+ 2, bs.position.y+ roundi((bs.size.y- cat.size.y)/ 2.0))
	cat.modulate.a= 0.0
	var aparece:= create_tween()
	aparece.tween_property(cat, "modulate:a", 1.0, DESLIZ* 1.5)
	var pot:= str(m.poder) if m.categoria!= "estado" and m.poder> 0 else "-"
	var prec:= str(m.precision) if m.precision> 0 else "-"
	movimientos_ui.get_node("Info").text= "Pot %s  Prec %s  PP %d/%d" % [pot, prec, p.pp[sel], m.pp]

func _elegir_objeto() -> Dictionary:
	if mochila_combate== null:
		mochila_combate= load(ESCENA_MOCHILA).instantiate()
		mochila_combate.name= "Mochila"
		add_child(mochila_combate)
	var r: Dictionary= await mochila_combate.elegir_en_combate(func(o: Objeto): return o.cura_ps> 0 or (o.ratio_captura> 0.0 and logica.salvaje))
	if r.is_empty():
		return {}
	var acc:= {"tipo": "objeto", "id": r["id"]}
	if r.has("objetivo"):
		acc["objetivo"]= r["objetivo"]
	return acc

func _elegir_pokemon(forzado: bool) -> int:
	var validar:= func(i: int) -> String:
		var p:= Equipo.miembros[i]
		if p.esta_debilitado():
			return "¡%s no puede luchar!" % p.nombre()
		if p== logica.j.pokemon:
			return "¡%s ya está luchando!" % p.nombre()
		return ""
	var pe= load(ESCENA_EQUIPO).instantiate()
	pe.name= "PantallaEquipo"
	await GestorEscenas.fundido(func():
		add_child(pe)
		pe.abrir("elegir", "Elige un Pokémon.", validar, not forzado))
	await pe.cerrado
	var r: int= pe.resultado
	await GestorEscenas.fundido(func(): pe.queue_free())
	return r

func _sale(lado: String, p: PokemonInstancia, tipo_ball: String) -> void:
	var spr: Sprite2D= sprite_rival if lado== "rival" else sprite_jugador
	var escala:= ESCALA_JUGADOR if lado== "jugador" else Vector2.ONE
	if lado== "rival":
		Estado.ver(p.especie.id)
	if lado== "rival" and logica.salvaje:
		if not spr.visible:
			spr.mostrar(p.especie, false)
			spr.scale= escala
		Sonido.grito(p.especie.numero)
	else:
		spr.mostrar(p.especie, lado== "jugador")
		spr.visible= false
		await _soltar_de_ball(spr, escala, tipo_ball, lado)
	_actualizar_cajas()
	_caja(lado).visible= true

func _punto_ball(lado: String) -> Vector2:
	var spr: Sprite2D= sprite_rival if lado== "rival" else sprite_jugador
	return spr.pos_base+ Vector2(0, -30 if lado== "rival" else -44)

func _preparar_ball(tipo_ball: String) -> void:
	var ruta:= BALLS+ "%s.png" % tipo_ball
	ball.texture= load(ruta) if ResourceLoader.exists(ruta) else load(BALLS+ "pokeball.png")
	ball.hframes =17
	ball.frame= 0
	ball.flip_h =false
	ball.modulate= Color.WHITE
	ball.visible =true

func _soltar_de_ball(spr: Sprite2D, escala: Vector2, tipo_ball: String, lado: String) -> void:
	_preparar_ball(tipo_ball)
	var destino:= _punto_ball(lado)
	var inicio:= Vector2(-10, 160) if lado== "jugador" else Vector2(266, 24)
	ball.position= inicio
	Sonido.efecto("ball_lanzar")
	var arco:= func(v: float) -> void:
		var x:= lerpf(inicio.x, destino.x, v)
		var y:= lerpf(inicio.y, destino.y, v)- 34.0* sin(PI* v)
		ball.position= Vector2(roundf(x), roundf(y))
		ball.frame =int(v* 19.9)% 10
	var t:= create_tween()
	t.tween_method(arco, 0.0, 1.0, 0.45)
	await t.finished
	ball.frame= 10
	Sonido.efecto("ball_abrir")
	spr.visible =true
	spr.position= destino
	spr.scale =escala* 0.05
	spr.modulate= Color(6, 6, 6, 1)
	var crece:= create_tween().set_parallel()
	crece.tween_property(spr, "scale", escala, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	crece.tween_property(spr, "position", spr.pos_base, 0.25)
	crece.tween_property(ball, "modulate:a", 0.0, 0.2)
	await crece.finished
	ball.visible= false
	ball.modulate =Color.WHITE
	Sonido.grito(vista[lado]["p"].especie.numero if not vista[lado].is_empty() else 0)
	var color:= create_tween()
	color.tween_property(spr, "modulate", Color.WHITE, 0.2)
	await color.finished

func _caja(lado: String) -> NinePatchRect:
	return caja_rival if lado== "rival" else caja_jugador

func _retirar(lado: String, tipo_ball: String) -> void:
	var spr: Sprite2D= sprite_rival if lado== "rival" else sprite_jugador
	var destino:= _punto_ball(lado)
	_preparar_ball(tipo_ball)
	ball.frame= 10
	ball.position =destino
	Sonido.efecto("retirar")
	var brillo:= create_tween()
	brillo.tween_property(spr, "modulate", Color(6, 6, 6, 1), 0.12)
	await brillo.finished
	var encoge:= create_tween().set_parallel()
	encoge.tween_property(spr, "scale", spr.scale* 0.05, 0.25)
	encoge.tween_property(spr, "position", destino, 0.25)
	encoge.tween_property(spr, "modulate:a", 0.0, 0.25)
	await encoge.finished
	spr.visible= false
	spr.modulate =Color.WHITE
	_caja(lado).visible =false
	ball.frame= 0
	await _esperar(0.12)
	var vuelta:= Vector2(-10, 160) if lado== "jugador" else Vector2(266, 24)
	var sale:= create_tween().set_parallel()
	sale.tween_property(ball, "position", vuelta, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sale.tween_property(ball, "modulate:a", 0.0, 0.3)
	await sale.finished
	ball.visible= false
	ball.modulate =Color.WHITE

func _texto_ps(ps: float, maximo: float) -> String:
	if modo_ps== "valores":
		return "%d/%d" % [roundi(ps), roundi(maximo)]
	var pct:= 100.0* ps/ maxf(1.0, maximo)
	if ps> 0.0:
		pct= maxf(pct, 0.1)
	return "%.1f%%" % pct

func _animar_ps(e: Dictionary) -> void:
	var lado: String= e["lado"]
	var panel:= _caja(lado)
	var barra= panel.get_node("Barra")
	var etiqueta: Label= panel.get_node("PS")
	var spr: Sprite2D =sprite_rival if lado== "rival" else sprite_jugador
	var maximo: float= maxf(1.0, e["max"])
	if int(e["hasta"])> int(e["desde"]):
		Sonido.efecto("curar_ps")
	if int(e["hasta"])< int(e["desde"]):
		if str(e.get("sonido", ""))!= "":
			Sonido.efecto(e["sonido"])
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
		etiqueta.text= _texto_ps(v, maximo)
	var t:= create_tween()
	t.tween_method(paso, float(e["desde"]), float(e["hasta"]), dur)
	await t.finished
	if not vista[lado].is_empty():
		vista[lado]["ps"]= int(e["hasta"])
	_actualizar_cajas()

func _debilitar(lado: String) -> void:
	var spr: Sprite2D= sprite_rival if lado== "rival" else sprite_jugador
	if not vista[lado].is_empty():
		var dur: float= Sonido.grito(vista[lado]["p"].especie.numero)
		await _esperar(minf(dur, 1.2))
	Sonido.efecto("debilitado")
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
	Sonido.efecto("exp")
	var nivel: int= e["nivel_desde"]
	var desde: int =e["desde"]
	while nivel< int(e["nivel_hasta"]):
		var fin:= Crecimiento.exp_para_nivel(g, nivel+ 1)
		await _tween_barra(barra, _ratio_exp(g, nivel, desde), 1.0)
		nivel+= 1
		desde= fin
		vj["nivel"]= nivel
		vj["exp"] =fin
		caja_jugador.get_node("Nivel").text ="Nv%d" % nivel
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
	var i:= await _elegir_en_lista(textos, true)
	if i< 0 or i>= p.movimientos.size():
		await _decir("%s no aprendió %s." % [p.nombre(), m.nombre])
		return
	var viejo:= p.movimientos[i].nombre
	p.reemplazar_movimiento(i, m)
	Sonido.jingle("olvidar")
	await _decir("1, 2 y... ¡Tachán!")
	Sonido.jingle("aprender")
	await _decir("%s olvidó %s y aprendió %s." % [p.nombre(), viejo, m.nombre])

func _esperar(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _animar_captura(e: Dictionary) -> void:
	var ruta:= BALLS+ "%s.png" % str(e.get("objeto", "pokeball"))
	ball.texture= load(ruta) if ResourceLoader.exists(ruta) else load(BALLS+ "pokeball.png")
	ball.hframes =17
	ball.frame= 0
	ball.flip_h =false
	ball.modulate= Color.WHITE
	var inicio:= Vector2(20, 140)
	var arriba: Vector2= sprite_rival.pos_base+ Vector2(0, -26)
	var suelo: Vector2 =sprite_rival.pos_base+ Vector2(0, -4)
	ball.position= inicio
	ball.visible =true
	Sonido.efecto("ball_lanzar")
	var arco:= func(v: float) -> void:
		var x:= lerpf(inicio.x, arriba.x, v)
		var y:= lerpf(inicio.y, arriba.y, v)- 70.0* sin(PI* v)
		ball.position= Vector2(roundf(x), roundf(y))
		ball.frame =int(v* 29.9)% 10
	var t:= create_tween()
	t.tween_method(arco, 0.0, 1.0, 0.55)
	await t.finished
	ball.frame= 10
	Sonido.efecto("ball_abrir")
	var brillo:= create_tween()
	brillo.tween_property(sprite_rival, "modulate", Color(6, 6, 6, 1), 0.12)
	await brillo.finished
	Sonido.efecto("ball_absorber")
	var dentro:= create_tween().set_parallel()
	dentro.tween_property(sprite_rival, "scale", Vector2(0.05, 0.05), 0.25)
	dentro.tween_property(sprite_rival, "position", arriba+ Vector2(0, 4), 0.25)
	dentro.tween_property(sprite_rival, "modulate:a", 0.0, 0.25)
	await dentro.finished
	sprite_rival.visible= false
	ball.frame =0
	await _esperar(0.15)
	Sonido.efecto("ball_caer")
	var caida:= create_tween()
	caida.tween_property(ball, "position:y", suelo.y, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	caida.tween_property(ball, "position:y", suelo.y- 10, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	caida.tween_property(ball, "position:y", suelo.y, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	caida.tween_property(ball, "position:y", suelo.y- 3, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	caida.tween_property(ball, "position:y", suelo.y, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await caida.finished
	for k in int(e["sacudidas"]):
		await _esperar(0.45)
		Sonido.efecto("ball_sacudir")
		for paso in [[12, false, 1], [0, false, 0], [12, true, -1], [0, false, 0]]:
			ball.frame= paso[0]
			ball.flip_h =paso[1]
			ball.position.x= suelo.x+ paso[2]
			await _esperar(0.1)
	await _esperar(0.35)
	if e["exito"]:
		Sonido.efecto("ball_click")
		var cierre:= create_tween()
		cierre.tween_property(ball, "modulate", Color(0.55, 0.55, 0.62), 0.25)
		await cierre.finished
		musica_final= true
		Sonido.musica("victoria_salvaje", 0.0)
		Sonido.jingle("captura")
		return
	Sonido.efecto("ball_escape")
	ball.frame =10
	sprite_rival.visible= true
	sprite_rival.modulate= Color(6, 6, 6, 1)
	var fuera:= create_tween().set_parallel()
	fuera.tween_property(sprite_rival, "scale", Vector2.ONE, 0.2)
	fuera.tween_property(sprite_rival, "position", sprite_rival.pos_base, 0.2)
	fuera.tween_property(ball, "modulate:a", 0.0, 0.2)
	await fuera.finished
	var color:= create_tween()
	color.tween_property(sprite_rival, "modulate", Color.WHITE, 0.25)
	await color.finished
	ball.visible =false
	ball.modulate= Color.WHITE

func _llenar_panel(panel: NinePatchRect, v: Dictionary, con_exp: bool) -> void:
	var p: PokemonInstancia= v["p"]
	var nombre: Label= panel.get_node("Nombre")
	nombre.text= p.nombre()
	var genero: Label =panel.get_node("Genero")
	genero.text= p.simbolo_genero()
	genero.add_theme_color_override("font_color", p.color_genero())
	genero.position.x =nombre.position.x+ nombre.get_combined_minimum_size().x+ 1
	var tipos:= p.especie.tipos
	for k in 2:
		var icono: TextureRect= panel.get_node("Tipo%d" % (k+ 1))
		icono.visible= k< tipos.size()
		if k< tipos.size():
			icono.texture= load(UI+ "tipos/%s.png" % tipos[k])
	var nivel: Label= panel.get_node("Nivel")
	nivel.text= "Nv%d" % v["nivel"]
	var estado: Label =panel.get_node("Estado")
	estado.text= ABREV.get(v["estado"], "")
	estado.position= Vector2(genero.position.x+ genero.get_combined_minimum_size().x+ 3, 4)
	panel.get_node("Barra").poner(float(v["ps"])/ maxf(1.0, v["max"]))
	panel.get_node("PS").text= _texto_ps(v["ps"], v["max"])
	if con_exp:
		panel.get_node("Exp").poner(_ratio_exp(p.especie.crecimiento, v["nivel"], v["exp"]))

func _actualizar_cajas() -> void:
	if not vista["rival"].is_empty():
		_llenar_panel(caja_rival, vista["rival"], false)
	if not vista["jugador"].is_empty():
		_llenar_panel(caja_jugador, vista["jugador"], true)
