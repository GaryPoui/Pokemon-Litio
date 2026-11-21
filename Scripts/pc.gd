extends Node2D

const ESCENA_CAJA:= "res://Escenas/UI/CajaPC.tscn"
const ESCENA_INICIALES :="res://Escenas/UI/InicialesPC.tscn"
const OPCIONES:= ["CAJA DE POKÉMON", "INICIALES", "APAGAR"]
const CODIGO :="testing"
const TECLADO:= preload("res://Scripts/ui/teclado_mote.gd")

func _ready() -> void:
	add_to_group("interactuable")

func celda() -> Vector2i:
	return Rejilla.celda(self)

func interactuar(_jugador: Node) -> void:
	Sonido.efecto("pc_encender")
	await Dialogo.mostrar("Encendiste el PC.")
	while true:
		var r: int= await Dialogo.preguntar("¿Qué quieres hacer?", OPCIONES)
		if r== 0:
			Sonido.efecto("pc_acceder")
			await _abrir(ESCENA_CAJA)
		elif r== 1:
			if not Estado.tiene("pc_iniciales") and not await _pedir_codigo():
				continue
			Sonido.efecto("pc_acceder")
			await _abrir(ESCENA_INICIALES)
		else:
			break
	Sonido.efecto("pc_apagar")

func _abrir(ruta: String) -> void:
	var p= load(ruta).instantiate()
	await GestorEscenas.fundido(func(): get_tree().current_scene.add_child(p))
	await p.cerrado
	await GestorEscenas.fundido(func(): p.queue_free())

func _pedir_codigo() -> bool:
	await Dialogo.mostrar("Ingresá el código de acceso.")
	var t= TECLADO.new()
	await GestorEscenas.fundido(func():
		get_tree().current_scene.add_child(t)
		t.armar_texto("Código"))
	var c: String= await t.esperar()
	await GestorEscenas.fundido(func(): t.queue_free())
	if c.to_lower()== CODIGO:
		Estado.marcar("pc_iniciales")
		Sonido.efecto("confirmar")
		await Dialogo.mostrar("¡Acceso concedido!")
		return true
	await Dialogo.mostrar("El código no es correcto.")
	return false
