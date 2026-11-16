extends Node2D

const OFRENDAS:= "1234"
const REJAS :="pqrs"
const SOLIDOS:= "#|TF"
const NINGUNA :=Vector2i(-1, -1)
const ARTE:= "res://Assets/Overworld/Gimnasios/Galerias/"
const GUION_ANIMA :=preload("res://Scripts/anima.gd")
const GUION_REJA:= preload("res://Scripts/reja_velo.gd")
const GUION_CAMPANILLA :=preload("res://Scripts/campanilla.gd")

@export var clave: String= ""
@export var filas: Array[String] =[]

var sala: Dictionary= {}
var e: Dictionary ={}
var origen:= Vector2i.ZERO
var anima: Node2D
var rejas: Dictionary= {}
var puerta: StaticBody2D
var losa_j: Sprite2D
var losa_a :Sprite2D
var ofrendas: Dictionary= {}
var campanas: Dictionary ={}
var jugador: Node
var hecha:= false

static func leer(filas_sala: Array) -> Dictionary:
	var s:= {"alto": filas_sala.size(), "ancho": 0, "muros": {}, "campanas": {}, "ofrendas": {}, "rejas": {}, "lapidas": [], "cercos": [],
		"campanilla": NINGUNA, "salida": NINGUNA, "entrada": NINGUNA, "inicio_a": NINGUNA, "losa_j": NINGUNA, "losa_a": NINGUNA}
	for y in filas_sala.size():
		var fila: String= str(filas_sala[y])
		s["ancho"]= maxi(int(s["ancho"]), fila.length())
		for x in fila.length():
			var ch:= fila[x]
			var c :=Vector2i(x, y)
			if SOLIDOS.contains(ch):
				s["muros"][c]= true
				if ch== "T":
					s["lapidas"].append(c)
				elif ch =="F":
					s["cercos"].append(c)
			elif ch== "B":
				s["muros"][c] =true
				s["campanilla"]= c
			elif ch== "S":
				s["muros"][c]= true
				s["salida"] =c
			elif ch== "E":
				s["entrada"]= c
			elif ch== "A":
				s["inicio_a"]= c
			elif ch =="j":
				s["losa_j"]= c
			elif ch== "a":
				s["losa_a"] =c
			elif ch== "c":
				s["campanas"][c]= true
			elif OFRENDAS.contains(ch):
				s["ofrendas"][OFRENDAS.find(ch)]= c
			elif REJAS.contains(ch):
				s["rejas"][REJAS.find(ch)] =c
	return s

static func dentro(s: Dictionary, c: Vector2i) -> bool:
	return c.x>= 0 and c.y>= 0 and c.x< int(s["ancho"]) and c.y< int(s["alto"])

static func libre(s: Dictionary, c: Vector2i, abiertas: Array) -> bool:
	if not dentro(s, c) or s["muros"].has(c):
		return false
	for k in s["rejas"]:
		if s["rejas"][k]== c and not abiertas.has(k):
			return false
	return true

static func rejas_de(s: Dictionary, j: Vector2i, a: Vector2i) -> Array:
	var abiertas:= []
	for k in s["rejas"]:
		var of: Vector2i= s["ofrendas"][k]
		var re: Vector2i =s["rejas"][k]
		if of== j or of== a or re== j or re ==a:
			abiertas.append(k)
	abiertas.sort()
	return abiertas

static func armar(s: Dictionary, j: Vector2i, a: Vector2i, modo_espejo: String) -> Dictionary:
	return {"j": j, "a": a, "modo": modo_espejo, "abiertas": rejas_de(s, j, a), "resuelta": j== s["losa_j"] and a== s["losa_a"]}

static func inicial(s: Dictionary, j:= NINGUNA) -> Dictionary:
	return armar(s, s["entrada"] if j== NINGUNA else j, s["inicio_a"], "h")

static func espejo(modo_espejo: String, dir: Vector2i) -> Vector2i:
	return Vector2i(-dir.x, dir.y) if modo_espejo== "h" else Vector2i(dir.x, -dir.y)

static func siguiente(s: Dictionary, est: Dictionary, dir: Vector2i) -> Dictionary:
	var j: Vector2i= est["j"]
	var a: Vector2i =est["a"]
	var modo_espejo: String= est["modo"]
	var abiertas: Array= est["abiertas"]
	var nj:= j+ dir
	if not libre(s, nj, abiertas):
		return est
	var na:= a+ espejo(modo_espejo, dir)
	var movio:= libre(s, na, abiertas)
	if not movio:
		na= a
	if s["campanas"].has(nj):
		modo_espejo= "v" if modo_espejo== "h" else "h"
	if movio and s["campanas"].has(na):
		modo_espejo ="v" if modo_espejo== "h" else "h"
	return armar(s, nj, na, modo_espejo)

func _ready() -> void:
	y_sort_enabled= true
	sala= leer(filas)
	origen =Rejilla.celda(self)
	hecha= Estado.tiene(clave)
	e= inicial(sala)
	_armar()
	_conectar.call_deferred()

func lugar(c: Vector2i) -> Vector2:
	return to_local(Rejilla.centro(self, origen+ c))

func _figura(padre: Node, nombre: String, c: Vector2i) -> Sprite2D:
	var s:= Sprite2D.new()
	s.texture= load(ARTE+ nombre+ ".png")
	s.hframes =2
	s.position= lugar(c)
	padre.add_child(s)
	return s

func _reja(nombre: String, c: Vector2i, textura: String, alto: int) -> StaticBody2D:
	var r:= StaticBody2D.new()
	r.set_script(GUION_REJA)
	r.name= nombre
	r.position =lugar(c)
	add_child(r)
	r.preparar(load(ARTE+ textura+ ".png"), alto)
	return r

func _armar() -> void:
	var piso:= Node2D.new()
	piso.name= "Piso"
	piso.z_index =-1
	add_child(piso)
	losa_j= _figura(piso, "losa_jugador", sala["losa_j"])
	losa_a =_figura(piso, "losa_anima", sala["losa_a"])
	for k in sala["ofrendas"]:
		ofrendas[k]= _figura(piso, "ofrenda", sala["ofrendas"][k])
	for c in sala["campanas"]:
		campanas[c] =_figura(piso, "campana_piso", c)
	for k in sala["rejas"]:
		var c: Vector2i= sala["rejas"][k]
		var horizontal: bool= sala["muros"].has(c+ Vector2i.LEFT) or sala["muros"].has(c+ Vector2i.RIGHT)
		rejas[k]= _reja("Reja%d" % k, c, "reja_velo_h" if horizontal else "reja_velo_v", 24)
	puerta= _reja("PuertaNorte", sala["salida"], "puerta_velo", 32)
	var camp:= StaticBody2D.new()
	camp.set_script(GUION_CAMPANILLA)
	camp.name= "Campanilla"
	camp.position =lugar(sala["campanilla"])
	add_child(camp)
	if hecha:
		_abrir_todo(false)

func _conectar() -> void:
	jugador= get_parent().get_node_or_null("Jugador")
	if jugador== null:
		return
	jugador.paso_iniciado.connect(_al_iniciar)
	jugador.paso_terminado.connect(_al_terminar)
	if hecha:
		return
	anima= Node2D.new()
	anima.set_script(GUION_ANIMA)
	anima.name= "Anima"
	add_child(anima)
	anima.preparar(jugador)
	reiniciar()

func celda_jugador() -> Vector2i:
	if jugador== null:
		return sala["entrada"]
	var c: Vector2i= jugador.celda()- origen
	return c if dentro(sala, c) else sala["entrada"]

func reiniciar() -> void:
	if hecha:
		return
	e= armar(sala, celda_jugador(), sala["inicio_a"], "h")
	if is_instance_valid(anima):
		anima.colocar(lugar(e["a"]))
	_pintar(false)

func _al_iniciar(destino: Vector2i, direccion: Vector2) -> void:
	if hecha:
		return
	var d:= Vector2i(direccion)
	var hasta:= destino- origen
	var desde :=hasta- d
	if not dentro(sala, hasta) or not dentro(sala, desde):
		return
	if e["j"]!= desde:
		e= armar(sala, desde, e["a"], e["modo"])
	var n:= siguiente(sala, e, d)
	if n["j"]!= hasta:
		n= armar(sala, hasta, e["a"], e["modo"])
	if is_instance_valid(anima):
		var corre: bool= jugador.is_running
		var dur: float= 1.0/ (float(jugador.move_speed)* (float(jugador.run_multiplier) if corre else 1.0))
		if n["a"]!= e["a"]:
			anima.ir_a(lugar(n["a"]), n["a"]- e["a"], dur)
		else:
			anima.girar(espejo(e["modo"], d))
	var cambio: bool= n["modo"]!= e["modo"]
	e= n
	_pintar(true)
	if cambio:
		Sonido.efecto("campanada_sala", 1.35)

func _al_terminar(c: Vector2i) -> void:
	if not hecha and bool(e.get("resuelta", false)) and c- origen== e["j"]:
		_resolver()

func _pintar(sonar: bool) -> void:
	var abiertas: Array= e["abiertas"]
	for k in rejas:
		var debe: bool= abiertas.has(k)
		if rejas[k].abierta!= debe:
			if debe:
				rejas[k].abrir()
			else:
				rejas[k].cerrar()
			if sonar:
				Sonido.efecto("reja")
	for k in ofrendas:
		var c: Vector2i= sala["ofrendas"][k]
		ofrendas[k].frame= 1 if (c== e["j"] or c== e["a"]) else 0
	for c in campanas:
		campanas[c].frame =1 if e["modo"]== "v" else 0
	losa_j.frame= 1 if e["j"]== sala["losa_j"] else 0
	losa_a.frame =1 if e["a"]== sala["losa_a"] else 0
	if is_instance_valid(anima):
		anima.tono(e["modo"])

func _abrir_todo(sonar: bool) -> void:
	for k in rejas:
		rejas[k].abrir()
	puerta.abrir()
	losa_j.frame= 1
	losa_a.frame =1
	if sonar:
		Sonido.efecto("reja")

func _resolver() -> void:
	hecha= true
	Estado.marcar(clave)
	Sonido.efecto("campanada_sala")
	if is_instance_valid(anima):
		anima.desvanecer()
	anima= null
	_abrir_todo(true)

func estado() -> Dictionary:
	return e.duplicate(true)

func resuelta() -> bool:
	return hecha

func modo() -> String:
	return str(e.get("modo", "h"))

func puede_pisar(c: Vector2i) -> bool:
	return libre(sala, c- origen, e["abiertas"])
