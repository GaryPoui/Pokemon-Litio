extends CanvasLayer

signal cerrado

const FONDO:= preload("res://Assets/Fondos/pokedex.png")
const ICONOS :="res://Assets/Pokemones/iconos/%s.png"
const POR_PAGINA:= 10

var paginas: Array= []
var pagina:= 0
var cuerpo: Control
var titulo: Label
var nota :Label
var pie: Label
var listo_para:= false

func _ready() -> void:
	layer= 107

static func calcular(tabla: TablaEncuentros, rareza: float= 0.0) -> Array:
	var filas:= []
	if tabla== null:
		return filas
	var pesos:= tabla.pesos_efectivos(rareza)
	var total:= 0.0
	for w in pesos:
		total+= w
	if total<= 0.0:
		return filas
	var por_especie:= {}
	for k in tabla.entradas.size():
		var e:= tabla.entradas[k]
		if e.especie== null or pesos[k]<= 0.0:
			continue
		var id:= e.especie.id
		if not por_especie.has(id):
			por_especie[id]= {"especie": e.especie, "pct": 0.0, "min": e.nivel_min, "max": e.nivel_max}
			filas.append(por_especie[id])
		var f: Dictionary= por_especie[id]
		f["pct"]= float(f["pct"])+ 100.0* pesos[k]/ total
		f["min"]= mini(int(f["min"]), e.nivel_min)
		f["max"]= maxi(int(f["max"]), e.nivel_max)
	filas.sort_custom(func(a, b): return float(a["pct"])> float(b["pct"]))
	return filas

func armar(mapa: Node) -> void:
	var hay_hierba:= false
	var deco:= mapa.get_node_or_null("Decoracion") as TileMapLayer
	if deco!= null and mapa.has_method("es_hierba"):
		for c in deco.get_used_cells():
			if mapa.es_hierba(c):
				hay_hierba= true
				break
	var suelo:= "Hierba alta" if hay_hierba else "Escombros"
	var tabla: TablaEncuentros= mapa.get("encuentros")
	var raros: TablaEncuentros= mapa.get("encuentros_raros")
	var rareza:= EfectosTrinket.total("rareza", null, Equipo.miembros)
	if tabla!= null:
		var nota_t:= "%d%% de encuentro por paso" % roundi(tabla.tasa* 100.0)
		if rareza> 0.0:
			nota_t+= " · con tus Trinkets"
		_paginar(suelo, nota_t, calcular(tabla, rareza))
	if raros!= null:
		_paginar(suelo+ " que se mueve", "Siempre sale uno al pisarla", calcular(raros))
	var fondo:= TextureRect.new()
	fondo.texture= FONDO
	add_child(fondo)
	var cab:= Panel.new()
	cab.position= Vector2(6, 4)
	cab.size =Vector2(244, 26)
	cab.add_theme_stylebox_override("panel", EstiloUI.panel())
	add_child(cab)
	var zona: String= str(mapa.get("zona_nombre")) if "zona_nombre" in mapa else ""
	var sub: String= str(mapa.get("zona_subtitulo")) if "zona_subtitulo" in mapa else ""
	var zl:= EstiloUI.nuevo_label(zona+ (" · "+ sub if sub!= "" else ""), 8, Vector2(6, 1), EstiloUI.TENUE)
	EstiloUI.fuente_batalla(zl)
	cab.add_child(zl)
	titulo= EstiloUI.nuevo_label("", 9, Vector2(6, 11))
	EstiloUI.fuente_batalla(titulo)
	titulo.name= "Titulo"
	cab.add_child(titulo)
	cuerpo= Control.new()
	cuerpo.name= "Cuerpo"
	cuerpo.position= Vector2(6, 33)
	add_child(cuerpo)
	var abajo:= Panel.new()
	abajo.position= Vector2(6, 173)
	abajo.size =Vector2(244, 16)
	abajo.add_theme_stylebox_override("panel", EstiloUI.panel())
	add_child(abajo)
	nota= EstiloUI.nuevo_label("", 6, Vector2(5, 4), EstiloUI.TENUE)
	nota.name= "Nota"
	abajo.add_child(nota)
	pie= EstiloUI.nuevo_label("", 6, Vector2(120, 4), EstiloUI.TENUE)
	pie.size= Vector2(119, 12)
	pie.horizontal_alignment= HORIZONTAL_ALIGNMENT_RIGHT
	abajo.add_child(pie)
	_pintar()

func _paginar(nombre: String, texto_nota: String, filas: Array) -> void:
	var total:= maxi(1, ceili(filas.size()/ float(POR_PAGINA)))
	for k in total:
		paginas.append({"titulo": nombre+ (" (%d/%d)" % [k+ 1, total] if total> 1 else ""), "nota": texto_nota, "filas": filas.slice(k* POR_PAGINA, (k+ 1)* POR_PAGINA)})

func _pintar() -> void:
	for c in cuerpo.get_children():
		c.queue_free()
	if paginas.is_empty():
		titulo.text= "No hay Pokémon salvajes en esta zona"
		nota.text= ""
		pie.text ="B: salir"
		return
	var pg: Dictionary= paginas[pagina]
	titulo.text= pg["titulo"]
	nota.text =pg["nota"]
	pie.text= ("◀ ▶ página %d/%d   " % [pagina+ 1, paginas.size()] if paginas.size()> 1 else "")+ "B: salir"
	var filas: Array= pg["filas"]
	for k in filas.size():
		var f: Dictionary= filas[k]
		var celda:= Panel.new()
		celda.name= "Fila%d" % k
		celda.position= Vector2((k% 2)* 123, floori(k/ 2.0)* 28)
		celda.size =Vector2(121, 27)
		celda.add_theme_stylebox_override("panel", EstiloUI.pastilla(EstiloUI.FONDO, EstiloUI.BORDE.darkened(0.3)))
		cuerpo.add_child(celda)
		var e: EspeciePokemon= f["especie"]
		var ruta:= ICONOS % e.id
		if ResourceLoader.exists(ruta):
			var completo: Texture2D= load(ruta)
			var at:= AtlasTexture.new()
			at.atlas= completo
			at.region =Rect2(0, 0, 32, 32)
			var ic:= TextureRect.new()
			ic.name= "Icono"
			ic.texture= at
			ic.position =EstiloUI.posicion_icono(completo, 2, Vector2(18, 13.5), false)
			ic.texture_filter= CanvasItem.TEXTURE_FILTER_NEAREST
			celda.add_child(ic)
		var n:= EstiloUI.nuevo_label(e.nombre, 8, Vector2(36, 2))
		EstiloUI.fuente_batalla(n)
		n.name= "Nombre"
		celda.add_child(n)
		var pct:= float(f["pct"])
		var txt_pct:= ("%d%%" % roundi(pct)) if pct>= 1.0 else "<1%"
		var p:= EstiloUI.nuevo_label(txt_pct, 8, Vector2(86, 2), Color("ffd84a"))
		EstiloUI.fuente_batalla(p)
		p.size.x= 31
		p.horizontal_alignment= HORIZONTAL_ALIGNMENT_RIGHT
		p.name= "Porcentaje"
		celda.add_child(p)
		var nv:= "Nv. %d" % int(f["min"]) if int(f["min"])== int(f["max"]) else "Nv. %d-%d" % [int(f["min"]), int(f["max"])]
		celda.add_child(EstiloUI.nuevo_label(nv, 6, Vector2(36, 14), EstiloUI.TENUE))

func esperar() -> void:
	await get_tree().create_timer(0.2).timeout
	listo_para= true
	await cerrado

func _unhandled_input(event: InputEvent) -> void:
	if not listo_para:
		return
	if event.is_action_pressed("derecha") and paginas.size()> 1:
		pagina= (pagina+ 1)% paginas.size()
		Sonido.efecto("cursor")
		_pintar()
	elif event.is_action_pressed("izquierda") and paginas.size()> 1:
		pagina= posmod(pagina- 1, paginas.size())
		Sonido.efecto("cursor")
		_pintar()
	elif event.is_action_pressed("cancelar") or event.is_action_pressed("aceptar"):
		Sonido.efecto("cancelar")
		listo_para= false
		cerrado.emit()
	else:
		return
	get_viewport().set_input_as_handled()
