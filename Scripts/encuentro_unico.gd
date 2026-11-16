extends "res://Scripts/npc.gd"

@export var especie_id: String= ""
@export var nivel :int= 5
@export var clave: String= ""
@export var requiere :String= ""
@export var quedarse:= false
@export_multiline var texto_inactivo: String =""
@export_multiline var texto_hecho :String= ""
@export var animacion_activa: String= ""

func _ready() -> void:
	super._ready()
	if hecho() and not quedarse:
		queue_free()
		return
	if activo() and animacion_activa!= "" and sprite.sprite_frames.has_animation(animacion_activa):
		sprite.play(animacion_activa)

func hecho() -> bool:
	return clave!= "" and Estado.tiene(clave)

func activo() -> bool:
	return not hecho() and (requiere== "" or Estado.tiene(requiere))

func _mirar(direccion: Vector2) -> void:
	if animacion_activa!= "" and activo():
		return
	super._mirar(direccion)

func interactuar(_jugador: Node) -> void:
	if hecho():
		if texto_hecho!= "":
			await Dialogo.mostrar(texto_hecho)
		return
	if not activo():
		if texto_inactivo!= "":
			await Dialogo.mostrar(texto_inactivo)
		return
	if texto!= "":
		await Dialogo.mostrar(texto)
	var zona:= str(get_tree().current_scene.get("zona_id"))
	await Combate.iniciar_safari(BaseDatos.especie(especie_id), nivel, zona)
	Estado.marcar(clave)
	if quedarse:
		if sprite.sprite_frames.has_animation(&"abajo"):
			sprite.play(&"abajo")
		return
	queue_free()
