extends Control

const MAPA_INICIAL:= "res://Escenas/Mapa.tscn"

@onready var lista: ListaOpciones= $Opciones/Lista
@onready var sprite: Sprite2D =$Sprite

var opciones: Array= []
var ocupado:= false

const ESCENA_OPCIONES :="res://Escenas/UI/Opciones.tscn"

func _ready() -> void:
	$Opciones.add_theme_stylebox_override("panel", EstiloUI.panel())
	EstiloUI.label($Logo, 20, Color("f8d030"))
	$Logo.add_theme_color_override("font_shadow_color", Color("2a3a7a"))
	$Logo.add_theme_constant_override("shadow_offset_x", 2)
	$Logo.add_theme_constant_override("shadow_offset_y", 2)
	EstiloUI.label($Sub, 9, Color.WHITE)
	EstiloUI.label($Pie, 6, Color(1, 1, 1, 0.7))
	$Pie.text= "Fan game no oficial. Pokémon es de Nintendo / Game Freak.\nFuente de Gen 5: bonzairob @ 3dPE"
	$Pie.position= Vector2(0, 166)
	$Pie.size =Vector2(256, 24)
	var ids:= BaseDatos.ids(BaseDatos.ESPECIES)
	if not ids.is_empty():
		sprite.mostrar(BaseDatos.especie(ids[randi_range(0, ids.size()- 1)]), false)
	opciones= []
	if Guardado.existe():
		opciones.append("CONTINUAR")
	opciones.append("NUEVA PARTIDA")
	opciones.append("OPCIONES")
	$Opciones.size.y =10+ opciones.size()* 14
	lista.poner(opciones)
	Sonido.musica("titulo")

func _unhandled_input(event: InputEvent) -> void:
	if GestorEscenas.en_transicion or ocupado:
		return
	if event.is_action_pressed("aceptar"):
		Sonido.efecto("confirmar")
		match opciones[lista.cursor]:
			"CONTINUAR":
				Guardado.cargar()
			"NUEVA PARTIDA":
				Inventario.reiniciar()
				Estado.reiniciar()
				Equipo.reiniciar()
				GestorEscenas.cambiar_mapa(MAPA_INICIAL, "", Vector2.DOWN)
			"OPCIONES":
				_opciones()
	elif not lista.mover_con_evento(event):
		return
	get_viewport().set_input_as_handled()

func _opciones() -> void:
	ocupado= true
	var p= load(ESCENA_OPCIONES).instantiate()
	await GestorEscenas.fundido(func(): add_child(p))
	await p.cerrado
	await GestorEscenas.fundido(func(): p.queue_free())
	ocupado =false
