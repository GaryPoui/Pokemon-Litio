class_name LogicaSafari
extends LogicaCombate

const BALL:= "safariball"
const CEBO :="alfajor"
const BARRO:= "barro"
const MULT_ENOJADO :=2.0
const MULT_COMIENDO:= 0.5

var comiendo:= 0
var enojado :=0
var velocidad:= 1
var ruta_id :=""

func _init(jugador: Array[PokemonInstancia], rival: Array[PokemonInstancia], ruta: String= "") -> void:
	super._init(jugador, rival, true, "")
	ruta_id= ruta

func iniciar() -> Array[Dictionary]:
	r= Luchador.new(equipo_r[0])
	participantes= []
	velocidad =maxi(1, r.pokemon.stat("velocidad"))
	_ev_sale("rival", r.pokemon)
	_texto("¡Un %s salvaje apareció!" % r.pokemon.nombre())
	return _tomar()

func humor() -> String:
	if comiendo> 0:
		return "comiendo"
	if enojado> 0:
		return "enojado"
	return "atento"

func umbral_huida() -> int:
	if velocidad>= 128 and comiendo<= 0:
		return 256
	var u:= velocidad* 2
	if comiendo> 0:
		u= velocidad/ 2
	elif enojado> 0:
		u =velocidad* 4
	return mini(u, 256)

func multiplicador() -> float:
	if enojado> 0:
		return MULT_ENOJADO
	if comiendo> 0:
		return MULT_COMIENDO
	return 1.0

func turno(accion: Dictionary) -> Array[Dictionary]:
	if terminado:
		return _tomar()
	var que: String= accion.get("safari", "")
	var n:= r.pokemon.nombre()
	var recien:= false
	match que:
		"ball":
			if inventario.cantidad_de(BALL)<= 0:
				_texto("¡No te quedan Safari Balls!")
				return _tomar()
			turnos+= 1
			inventario.consumir(BALL)
			_texto("¡Lanzaste una Safari Ball!")
			var res:= capturar(BaseDatos.objeto(BALL).ratio_captura, multiplicador())
			_ev({"tipo": "captura", "objeto": BALL, "sacudidas": res["sacudidas"], "exito": res["exito"], "critica": res["critica"]})
			if res["exito"]:
				_capturado(BALL)
				return _tomar()
			_texto(TEXTO_SACUDIDAS[res["sacudidas"]])
			if inventario.cantidad_de(BALL)<= 0:
				_texto("¡Se terminaron tus Safari Balls!")
				_texto("%s se alejó tranquilo." % n)
				_terminar("sin_balls")
				return _tomar()
		"alfajor":
			if inventario.cantidad_de(CEBO)<= 0:
				_texto("¡No te quedan Alfajores!")
				return _tomar()
			turnos+= 1
			inventario.consumir(CEBO)
			_texto("¡Le tiraste un Alfajor a %s!" % n)
			_ev({"tipo": "lanzar", "objeto": CEBO})
			comiendo= rng.randi_range(1, 5)
			enojado =0
			recien= true
			_texto("¡%s se puso a comer!" % n)
		"barro":
			if inventario.cantidad_de(BARRO)<= 0:
				_texto("¡No te queda Barro!")
				return _tomar()
			turnos+= 1
			inventario.consumir(BARRO)
			_texto("¡Le tiraste Barro a %s!" % n)
			_ev({"tipo": "lanzar", "objeto": BARRO})
			enojado= rng.randi_range(1, 5)
			comiendo =0
			recien =true
			_texto("¡%s se enojó!" % n)
		"huir":
			_ev({"tipo": "sonido", "nombre": "huir"})
			_texto("¡Escapaste sin problemas!")
			_terminar("huida")
			return _tomar()
		_:
			return _tomar()
	if rng.randi_range(0, 255)< umbral_huida():
		_texto("¡%s huyó!" % n)
		_terminar("escapo")
		return _tomar()
	if not recien:
		_pasar_turno(n)
	_ev({"tipo": "humor", "humor": humor()})
	return _tomar()

func _pasar_turno(n: String) -> void:
	if comiendo> 0:
		comiendo-= 1
		_texto("%s sigue comiendo." % n if comiendo> 0 else "%s terminó de comer." % n)
	elif enojado> 0:
		enojado -=1
		_texto("%s sigue enojado." % n if enojado> 0 else "%s se calmó." % n)
	else:
		_texto("%s te observa atento." % n)
