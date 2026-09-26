extends CanvasLayer

signal cerrado

const ESCENA_EQUIPO:= "res://Escenas/UI/PantallaEquipo.tscn"
const ESCENA_POKEDEX :="res://Escenas/UI/Pokedex.tscn"

@onready var caja: Panel= $Caja
@onready var lista: ListaOpciones =$Caja/Lista
@onready var jugador= get_parent()
@onready var mochila= get_parent().get_node_or_null("Mochila")

var is_open:= false
var ocupado :=false
var opciones: Array= []

func _ready() -> void:
	layer= 95
	caja.add_theme_stylebox_override("panel", EstiloUI.panel())
	caja.visible =false

func _unhandled_input(event: InputEvent) -> void:
	if ocupado or Dialogo.esta_abierto or GestorEscenas.en_transicion or Combate.activo:
		return
	if mochila!= null and mochila.is_open:
		return
	if not is_open:
		if event.is_action_pressed("menu") and not jugador.is_moving:
			abrir()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("cancelar"):
		cerrar()
	elif event.is_action_pressed("aceptar"):
		_elegir(opciones[lista.cursor])
	elif not lista.mover_con_evento(event):
		return
	get_viewport().set_input_as_handled()

func abrir() -> void:
	opciones= ["POKéDEX"]
	if not Equipo.miembros.is_empty():
		opciones.append("POKéMON")
	opciones.append_array(["MOCHILA", "GUARDAR", "SALIR"])
	lista.poner(opciones, mini(lista.cursor, opciones.size()- 1))
	caja.size.y =10+ opciones.size()* 14
	caja.visible= true
	is_open =true

func cerrar() -> void:
	caja.visible= false
	is_open =false
	cerrado.emit()

func _elegir(op: String) -> void:
	match op:
		"POKéDEX":
			await _pantalla(ESCENA_POKEDEX, [])
		"POKéMON":
			await _pantalla(ESCENA_EQUIPO, ["ver", "Elige un Pokémon."])
		"MOCHILA":
			ocupado= true
			caja.visible =false
			mochila.open()
			await mochila.closed
			caja.visible= true
			ocupado =false
		"GUARDAR":
			ocupado= true
			var r: int= await Dialogo.preguntar("¿Quieres guardar la partida?")
			if r== 0:
				if Guardado.guardar():
					await Dialogo.mostrar("Guardaste la partida.")
				else:
					await Dialogo.mostrar("No se pudo guardar la partida.")
			ocupado =false
		"SALIR":
			cerrar()

func _pantalla(ruta: String, args: Array) -> void:
	ocupado= true
	caja.visible =false
	var p= load(ruta).instantiate()
	add_child(p)
	p.callv("abrir", args)
	await p.cerrado
	p.queue_free()
	caja.visible= true
	ocupado =false
