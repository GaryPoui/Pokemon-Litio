extends "res://Scripts/npc.gd"

const CLAVES:= ["anima_flores", "anima_cancion", "anima_medallon"]
const PREMIO :="siempreviva"
const CLAVE_PREMIO:= "premio_animas"

@export_group("Ánima")
@export var clave: String= ""
@export var objeto_pedido :String= ""
@export var movimientos_pedidos: Array[String]= []
@export_multiline var texto_pide: String= ""
@export_multiline var texto_falta :String= ""
@export_multiline var texto_gracias: String= ""
@export_multiline var texto_despues :String= ""
@export_multiline var texto_premio: String= "Las tres ánimas de la Chacarita ya descansan. Donde estaba parada quedó una flor que no se marchita."

var oida:= false

func _ready() -> void:
	super._ready()
	modulate= Color(1.0, 1.0, 1.0, 0.82)

func cumple() -> bool:
	if objeto_pedido!= "":
		return Inventario.cantidad_de(objeto_pedido)> 0
	for p in Equipo.miembros:
		for m in p.movimientos:
			if movimientos_pedidos.has(m.id):
				return true
	return false

func interactuar(jugador: Node) -> void:
	_mirar(-jugador.last_direction)
	if Estado.tiene(clave):
		await Dialogo.mostrar(texto_despues)
		return
	if not oida:
		oida= true
		await Dialogo.mostrar(texto_pide)
		if not cumple():
			return
	elif not cumple():
		await Dialogo.mostrar(texto_falta if texto_falta!= "" else texto_pide)
		return
	if objeto_pedido!= "":
		Inventario.consumir(objeto_pedido)
	Estado.marcar(clave)
	Sonido.efecto("curar_estado")
	await Dialogo.mostrar(texto_gracias)
	if Estado.tiene(CLAVE_PREMIO) or not CLAVES.all(func(c): return Estado.tiene(c)):
		return
	Estado.marcar(CLAVE_PREMIO)
	await Dialogo.mostrar(texto_premio)
	Inventario.agregar_trinket(PREMIO)
	Sonido.jingle("objeto_clave")
	var t:= BaseDatos.trinket(PREMIO)
	await Dialogo.mostrar("¡Recibiste el Trinket %s!" % (t.nombre if t!= null else PREMIO))
	Sonido.cortar_jingle()
