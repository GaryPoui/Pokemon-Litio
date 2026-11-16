extends RefCounted

const A:= preload("res://Scripts/batalla/animador.gd")
const LISTA :={
	"shadow_ball": "bola_sombra",
	"will_o_wisp": "fuego_fatuo",
	"hex": "infortunio",
	"gust": "tornado",
	"ominous_wind": "viento_aciago",
	"curse": "maldicion",
	"protect": "proteccion",
	"pain_split": "divide_dolor",
	"confuse_ray": "rayo_confuso",
	"psybeam": "psicorrayo",
	"icy_wind": "viento_hielo",
	"ice_shard": "canto_helado",
	"destiny_bond": "mismo_destino",
	"night_shade": "tinieblas",
	"shadow_sneak": "sombra_vil",
	"astonish": "impresionar",
	"lick": "lenguetazo",
	"shadow_punch": "puno_sombra",
	"ember": "ascuas",
	"mud_slap": "bofeton_lodo",
}
const VIOLETA:= Color(0.72, 0.5, 1.0)
const AZUL_FATUO :=Color(0.6, 0.7, 1.0)
const ROJO:= Color(1.0, 0.45, 0.45)
const OSCURO :=Color(0.45, 0.32, 0.6)
const CELESTE:= Color(0.62, 0.86, 1.0)
const ROSA :=Color(1.0, 0.62, 0.9)
const BLANCO:= Color(1.6, 1.6, 1.6)

static func bola_sombra(b: Node, de: String, a: String) -> void:
	var origen:= A.centro(b, de)
	var destino :=A.centro(b, a)
	var bola:= A.figura(b, "bola_sombra", origen, 6)
	A.sonido(b, "farol", 0.7)
	await A.cuadros(b, bola, 0.24, 0, 3)
	A.ciclo(b, bola, 3, 5, 14.0, 0.34)
	await A.mover(b, bola, destino, 0.32, Tween.TRANS_QUAD, Tween.EASE_IN)
	bola.queue_free()
	var golpe:= A.figura(b, "impacto_sombra", destino, 4)
	A.sonido(b, "choque", 0.8)
	A.destello(b, A.sprite(b, a), VIOLETA, 0.26)
	await A.cuadros(b, golpe, 0.26)

static func fuego_fatuo(b: Node, de: String, a: String) -> void:
	var o:= A.centro(b, de)
	var d :=A.centro(b, a)
	var llamas: Array= []
	for k in 3:
		var l:= A.figura(b, "llama_fatua", o, 4)
		A.ciclo(b, l, 0, 3, 10.0, 1.1)
		llamas.append(l)
	A.sonido(b, "farol", 1.25)
	var viaje:= func(u: float) -> void:
		for k in llamas.size():
			var fase:= clampf(u* 1.3- k* 0.15, 0.0, 1.0)
			var ang:= fase* TAU* 1.5+ k* TAU/ 3.0
			var p: Vector2= o.lerp(d, fase)+ Vector2(cos(ang), sin(ang)* 0.6)* 14.0* sin(fase* PI)
			llamas[k].position= p.round()
	await A.recorrer(b, viaje, 0.55)
	var orbita:= func(u: float) -> void:
		for k in llamas.size():
			var ang:= u* TAU+ k* TAU/ 3.0
			var r:= 18.0* (1.0- u)
			llamas[k].position =(d+ Vector2(cos(ang)* r, sin(ang)* r* 0.6)).round()
	orbita.call(0.0)
	A.sonido(b, "chispa", 0.8)
	await A.recorrer(b, orbita, 0.32)
	await A.destello(b, A.sprite(b, a), AZUL_FATUO, 0.2)

static func infortunio(b: Node, _de: String, a: String) -> void:
	var d:= A.centro(b, a)
	var blanco:= A.sprite(b, a)
	var ojo:= A.figura(b, "ojo_infortunio", d+ Vector2(0, -4), 5)
	A.sonido(b, "estatua", 0.8)
	await A.cuadros(b, ojo, 0.26, 0, 3)
	A.ciclo(b, ojo, 3, 4, 9.0, 0.36)
	A.sacudir(b, blanco, 2.0, 0.34)
	await A.destello(b, blanco, VIOLETA, 0.36)
	await A.cuadros(b, ojo, 0.14, 3, 0)

static func tornado(b: Node, de: String, a: String) -> void:
	var o:= A.pies(b, de)+ Vector2(0, -16)
	var d :=A.pies(b, a)+ Vector2(0, -16)
	var r:= A.figura(b, "remolino", o, 4)
	A.ciclo(b, r, 0, 3, 14.0, 0.95)
	A.sonido(b, "caida", 1.3)
	await A.mover(b, r, d, 0.42, Tween.TRANS_SINE, Tween.EASE_IN)
	A.rafaga(b, "rafaga_aire", 2, d+ Vector2(-18, 0), d+ Vector2(18, -10), 4, 0.36, Vector2(4, 12))
	await A.sacudir(b, A.sprite(b, a), 3.0, 0.4)

static func viento_aciago(b: Node, de: String, a: String) -> void:
	var o:= A.centro(b, de)
	var d :=A.centro(b, a)
	A.sonido(b, "caida", 0.75)
	A.rafaga(b, "hoja_seca", 2, o, d, 5, 0.62, Vector2(10, 18))
	await A.rafaga(b, "rafaga", 2, o, d, 8, 0.6, Vector2(8, 16))
	A.sacudir(b, A.sprite(b, a), 2.0, 0.22)
	await A.destello(b, A.sprite(b, a), VIOLETA, 0.22)

static func maldicion(b: Node, de: String, a: String) -> void:
	if not "fantasma" in A.luchador(b, de).tipos():
		await A.destello(b, A.sprite(b, de), OSCURO, 0.4)
		return
	var o:= A.centro(b, de)
	var usuario:= A.sprite(b, de)
	var c:= A.figura(b, "clavo", o+ Vector2(0, -44), 1)
	await A.mover(b, c, o+ Vector2(0, -8), 0.16, Tween.TRANS_QUAD, Tween.EASE_IN)
	A.sonido(b, "choque", 1.3)
	A.destello(b, usuario, ROJO, 0.24)
	await A.sacudir(b, usuario, 2.0, 0.24)
	c.queue_free()
	var s:= A.figura(b, "sombra_maldita", o, 4)
	A.cuadros(b, s, 0.3, 0, 2)
	A.sonido(b, "estatua", 0.6)
	await A.mover(b, s, A.centro(b, a), 0.38)
	s.frame= 3
	await A.destello(b, A.sprite(b, a), OSCURO, 0.3)

static func proteccion(b: Node, de: String, _a: String) -> void:
	var e:= A.figura(b, "escudo", A.centro(b, de), 4)
	A.sonido(b, "confirmar", 0.7)
	await A.cuadros(b, e, 0.24, 0, 2)
	await A.esperar(b, 0.22)
	e.frame= 3
	await A.esperar(b, 0.1)

static func divide_dolor(b: Node, de: String, a: String) -> void:
	var o:= A.centro(b, de)
	var d :=A.centro(b, a)
	var ida:= A.figura(b, "orbe_dolor", o, 2)
	var vuelta:= A.figura(b, "orbe_dolor", d, 2)
	A.ciclo(b, ida, 0, 1, 8.0, 0.7)
	A.ciclo(b, vuelta, 0, 1, 8.0, 0.7)
	A.sonido(b, "curar_ps", 0.8)
	var cruce:= func(u: float) -> void:
		var curva:= Vector2(0, -14)* sin(u* PI)
		ida.position= (o.lerp(d, u)+ curva).round()
		vuelta.position =(d.lerp(o, u)- curva).round()
	await A.recorrer(b, cruce, 0.6)
	ida.queue_free()
	vuelta.queue_free()
	A.destello(b, A.sprite(b, de), BLANCO, 0.26)
	await A.destello(b, A.sprite(b, a), BLANCO, 0.26)

static func rayo_confuso(b: Node, de: String, a: String) -> void:
	var o:= A.centro(b, de)
	var d :=A.centro(b, a)
	var orbe:= A.figura(b, "orbe_confuso", o, 4)
	A.ciclo(b, orbe, 0, 3, 12.0, 0.6)
	A.sonido(b, "chispa", 1.2)
	var normal:= (d- o).orthogonal().normalized()
	var zigzag:= func(u: float) -> void:
		orbe.position= (o.lerp(d, u)+ normal* sin(u* TAU* 2.5)* 9.0* (1.0- u* 0.5)).round()
	await A.recorrer(b, zigzag, 0.55)
	orbe.queue_free()
	var cabeza:= d+ Vector2(0, -14)
	var estrellas: Array= []
	for k in 3:
		var e:= A.figura(b, "estrella", cabeza, 2)
		e.frame= k% 2
		estrellas.append(e)
	var giro:= func(u: float) -> void:
		for k in estrellas.size():
			var ang:= u* TAU* 1.2+ k* TAU/ 3.0
			estrellas[k].position= (cabeza+ Vector2(cos(ang)* 13.0, sin(ang)* 4.0)).round()
	A.sonido(b, "estado_con")
	await A.recorrer(b, giro, 0.4)

static func psicorrayo(b: Node, de: String, a: String) -> void:
	var o:= A.centro(b, de)
	var d :=A.centro(b, a)
	A.sonido(b, "chispa", 0.7)
	await A.rafaga(b, "anillo_psi", 2, o, d, 7, 0.6, Vector2.ZERO)
	A.sacudir(b, A.sprite(b, a), 2.0, 0.2)
	await A.destello(b, A.sprite(b, a), ROSA, 0.2)

static func viento_hielo(b: Node, de: String, a: String) -> void:
	var o:= A.centro(b, de)
	var d :=A.centro(b, a)
	A.sonido(b, "caida", 1.0)
	A.rafaga(b, "copo", 2, o, d, 14, 0.7, Vector2(14, 24))
	await A.rafaga(b, "rafaga_hielo", 2, o, d, 11, 0.66, Vector2(10, 20))
	await A.destello(b, A.sprite(b, a), CELESTE, 0.24)

static func canto_helado(b: Node, de: String, a: String) -> void:
	var o:= A.centro(b, de)
	var d :=A.centro(b, a)
	A.sonido(b, "chispa", 1.5)
	await A.rafaga(b, "esquirla", 2, o, d, 3, 0.3, Vector2(6, 8), 0 if d.y< o.y else 1)
	var golpe:= A.figura(b, "impacto_hielo", d, 4)
	A.sonido(b, "choque", 1.4)
	A.destello(b, A.sprite(b, a), CELESTE, 0.22)
	await A.cuadros(b, golpe, 0.22)

static func mismo_destino(b: Node, de: String, a: String) -> void:
	var otro:= "rival" if de== "jugador" else "jugador"
	var o:= A.centro(b, de)
	var d :=A.centro(b, otro if a== de else a)
	var usuario:= A.sprite(b, de)
	var n:= 11
	var hilo: Array= []
	for k in n:
		var e:= A.figura(b, "eslabon", o.lerp(d, (k+ 1.0)/ (n+ 1.0)), 2)
		e.visible= false
		hilo.append(e)
	A.sonido(b, "estatua", 0.55)
	var tender:= func(u: float) -> void:
		for k in hilo.size():
			hilo[k].visible= u* n> k
	await A.recorrer(b, tender, 0.34)
	var t:= b.create_tween()
	t.tween_property(usuario, "modulate", OSCURO, 0.2)
	var latir:= func(u: float) -> void:
		for k in hilo.size():
			hilo[k].frame= (int(u* 6.0)+ k)% 2
	await A.recorrer(b, latir, 0.42)
	for e in hilo:
		e.visible= false
	await A.esperar(b, 0.08)

static func tinieblas(b: Node, _de: String, a: String) -> void:
	var blanco:= A.sprite(b, a)
	var col:= A.figura(b, "columna_sombra", A.pies(b, a)+ Vector2(0, -24), 4)
	A.sonido(b, "estatua", 0.7)
	A.destello(b, blanco, OSCURO, 0.6)
	await A.cuadros(b, col, 0.3, 0, 2)
	A.ciclo(b, col, 2, 3, 10.0, 0.26)
	await A.sacudir(b, blanco, 2.0, 0.26)
	await A.cuadros(b, col, 0.12, 2, 0)

static func sombra_vil(b: Node, de: String, a: String) -> void:
	var o:= A.pies(b, de)+ Vector2(0, -3)
	var d :=A.pies(b, a)+ Vector2(0, -3)
	var n:= 8
	var rastro: Array= []
	for k in n:
		var m:= A.figura(b, "sombra_piso", o.lerp(d, (k+ 1.0)/ n), 2)
		m.visible= false
		m.frame =k% 2
		rastro.append(m)
	A.sonido(b, "caida", 0.6)
	var estirar:= func(u: float) -> void:
		for k in rastro.size():
			rastro[k].visible= u* n> k
	await A.recorrer(b, estirar, 0.26)
	var pico:= A.figura(b, "pico_sombra", d+ Vector2(0, -11), 4)
	A.sonido(b, "choque", 0.9)
	A.destello(b, A.sprite(b, a), VIOLETA, 0.24)
	await A.cuadros(b, pico, 0.2, 0, 2)
	await A.cuadros(b, pico, 0.1, 3, 0)

static func impresionar(b: Node, de: String, a: String) -> void:
	var usuario:= A.sprite(b, de)
	var blanco :=A.sprite(b, a)
	var hacia:= (A.centro(b, a)- A.centro(b, de)).normalized()* 8.0
	var base:= usuario.position
	var t:= b.create_tween()
	t.tween_property(usuario, "position", base+ hacia, 0.08)
	t.tween_property(usuario, "position", base, 0.12)
	A.sonido(b, "salto", 1.4)
	await t.finished
	var s:= A.figura(b, "susto", A.centro(b, a)+ Vector2(0, -26), 2)
	A.ciclo(b, s, 0, 1, 12.0, 0.36)
	await A.sacudir(b, blanco, 3.0, 0.34, true)

static func lenguetazo(b: Node, _de: String, a: String) -> void:
	var l:= A.figura(b, "lengua", A.centro(b, a)+ Vector2(-2, 2), 4)
	A.sonido(b, "chapoteo", 1.3)
	await A.cuadros(b, l, 0.24, 0, 2)
	A.sacudir(b, A.sprite(b, a), 2.0, 0.2)
	await A.destello(b, A.sprite(b, a), ROSA, 0.2)
	await A.cuadros(b, l, 0.12, 3, 0)

static func puno_sombra(b: Node, de: String, a: String) -> void:
	var o:= A.centro(b, de)
	var d :=A.centro(b, a)
	var p:= A.figura(b, "puno_sombra", o.lerp(d, 0.55), 3)
	A.sonido(b, "caida", 0.9)
	A.cuadros(b, p, 0.2, 0, 2)
	await A.mover(b, p, d, 0.22, Tween.TRANS_BACK, Tween.EASE_IN)
	p.queue_free()
	var golpe:= A.figura(b, "impacto_sombra", d, 4)
	A.sonido(b, "choque", 0.75)
	A.sacudir(b, A.sprite(b, a), 3.0, 0.22)
	await A.cuadros(b, golpe, 0.24)

static func ascuas(b: Node, de: String, a: String) -> void:
	var o:= A.centro(b, de)
	var d :=A.centro(b, a)
	A.sonido(b, "farol", 1.4)
	await A.rafaga(b, "ascua", 2, o, d, 6, 0.5, Vector2(6, 9))
	var f:= A.figura(b, "estallido_fuego", d, 3)
	A.sonido(b, "chispa", 0.9)
	A.destello(b, A.sprite(b, a), Color(1.0, 0.62, 0.4), 0.24)
	await A.cuadros(b, f, 0.24)

static func bofeton_lodo(b: Node, de: String, a: String) -> void:
	var o:= A.pies(b, de)+ Vector2(0, -8)
	var d :=A.centro(b, a)+ Vector2(0, -8)
	A.sonido(b, "chapoteo", 0.8)
	await A.rafaga(b, "barro", 2, o, d, 6, 0.45, Vector2(5, 7))
	var s:= A.figura(b, "salpicadura", d+ Vector2(0, -4), 3)
	A.sonido(b, "chapoteo", 1.1)
	A.destello(b, A.sprite(b, a), Color(0.75, 0.62, 0.48), 0.26)
	await A.cuadros(b, s, 0.26)
