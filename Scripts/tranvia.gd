class_name Tranvia
extends Node2D

const COCHE:= preload("res://Assets/Overworld/Rutas8/tranvia_funebre.png")
const INTERIOR :="res://Escenas/Rutas/TranviaFunebre.tscn"

static var pendiente: Dictionary= {}

@export var destino:= ""
@export var llegada :String= ""
@export var boleto:= ""
@export var requiere: String= ""
@export var clave_viaje:= ""
@export var de_vuelta :=false
@export var fila_via:= -1
@export_multiline var texto_sin_requisito: String= "Un cartel viejo: «TRANVÍA FÚNEBRE · A LA CHACARITA». Dicen que solo pasa a medianoche…"
@export_multiline var texto_sin_boleto :String= "El tranvía fúnebre no lleva a nadie sin boleto. Hay que conseguir uno."
@export_multiline var texto_pregunta: String= "El tranvía fúnebre frenó frente a la parada. Las cortinas se mueven solas… ¿Subís?"

var coche: Node2D

func _ready() -> void:
	add_to_group("interactuable")

func celda() -> Vector2i:
	return Rejilla.celda(self)

func puede() -> bool:
	if de_vuelta:
		return clave_viaje!= "" and Estado.tiene(clave_viaje)
	if requiere!= "" and not Estado.tiene(requiere):
		return false
	return boleto== "" or Inventario.cantidad_de(boleto)> 0

func _motivo() -> String:
	if not de_vuelta and requiere!= "" and not Estado.tiene(requiere):
		return texto_sin_requisito
	return texto_sin_boleto

func interactuar(_jugador: Node) -> void:
	if not puede():
		await Dialogo.mostrar(_motivo())
		return
	await _llegar()
	var r: int= await Dialogo.preguntar(texto_pregunta)
	if r!= 0:
		await _irse()
		return
	if clave_viaje!= "":
		Estado.marcar(clave_viaje)
	pendiente= {"destino": destino, "llegada": llegada}
	GestorEscenas.cambiar_mapa(INTERIOR, "Asiento", Vector2.UP)

func _cuadros() -> SpriteFrames:
	var sf:= SpriteFrames.new()
	sf.add_animation(&"anda")
	sf.set_animation_speed(&"anda", 8.0)
	for k in 2:
		var a:= AtlasTexture.new()
		a.atlas= COCHE
		a.region =Rect2(80* k, 0, 80, 48)
		sf.add_frame(&"anda", a)
	return sf

func _llegar() -> void:
	if is_instance_valid(coche):
		return
	var fila:= fila_via if fila_via>= 0 else celda().y+ 2
	coche= Node2D.new()
	coche.name= "CocheFunebre"
	var s:= AnimatedSprite2D.new()
	s.sprite_frames= _cuadros()
	s.centered =false
	s.offset= Vector2(-40, -46)
	coche.add_child(s)
	var y:= fila* Rejilla.tam(self).y+ Rejilla.tam(self).y- 2
	var cam:= get_viewport().get_camera_2d()
	var izq:= (cam.get_screen_center_position().x- 128.0) if cam!= null else position.x- 160.0
	coche.position= Vector2(izq- 60.0, y)
	get_parent().add_child(coche)
	s.play(&"anda")
	Sonido.efecto("bocina_tranvia")
	var t:= create_tween()
	t.tween_property(coche, "position:x", position.x, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t.finished
	s.stop()
	s.frame= 0

func _irse() -> void:
	if not is_instance_valid(coche):
		return
	var s: AnimatedSprite2D= coche.get_child(0)
	s.play(&"anda")
	var t:= create_tween()
	t.tween_property(coche, "position:x", coche.position.x+ 320.0, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	coche.queue_free()
	coche= null
