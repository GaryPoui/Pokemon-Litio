extends CanvasLayer

const SILUETA:= preload("res://Recursos/silueta.gdshader")
const CAMBIOS :=16
const ESCENA_APRENDER:= "res://Escenas/UI/AprenderMovimiento.tscn"

@onready var sprite: Sprite2D= $Pokemon
@onready var brillo: ColorRect =$Brillo

var cancelable:= false
var cancelado :=false
var mat:= ShaderMaterial.new()

func _ready() -> void:
	layer= 106
	brillo.modulate.a= 0.0
	mat.shader= SILUETA
	sprite.material =mat

func _unhandled_input(event: InputEvent) -> void:
	if cancelable and event.is_action_pressed("cancelar"):
		cancelado= true
		get_viewport().set_input_as_handled()

func _blanco(v: float) -> void:
	mat.set_shader_parameter("blanco", v)

func _esperar(t: float) -> void:
	await get_tree().create_timer(t).timeout

func evolucionar(p: PokemonInstancia, destino:= "") -> bool:
	var vieja:= p.especie
	var por_objeto:= destino!= ""
	if destino== "":
		destino= Evoluciones.por_nivel(p, Equipo.miembros)
	var nueva:= BaseDatos.especie(destino)
	if nueva== null:
		return false
	var muda:= Evoluciones.muda(p) if not por_objeto else ""
	var nombre_viejo:= p.nombre()
	sprite.mostrar(vieja, false)
	Sonido.detener_musica(0.3)
	await _esperar(0.4)
	Sonido.grito(vieja.numero)
	await Dialogo.mostrar("¿Qué? ¡%s está evolucionando!" % nombre_viejo)
	Sonido.musica("evolucion", 0.0)
	cancelado= false
	cancelable =not por_objeto
	var t:= create_tween()
	t.tween_method(_blanco, 0.0, 1.0, 0.8)
	await t.finished
	for k in CAMBIOS:
		if cancelado:
			break
		var d:= lerpf(0.5, 0.06, k/ float(CAMBIOS- 1))
		sprite.mostrar(nueva if k% 2== 0 else vieja, false)
		sprite.scale =Vector2(0.85, 0.85)
		var pulso:= create_tween()
		pulso.tween_property(sprite, "scale", Vector2.ONE, d* 0.8)
		await _esperar(d)
	cancelable= false
	if cancelado:
		sprite.mostrar(vieja, false)
		var vuelta:= create_tween()
		vuelta.tween_method(_blanco, 1.0, 0.0, 0.4)
		await vuelta.finished
		Sonido.detener_musica(0.3)
		await Dialogo.mostrar("¿Eh? ¡%s ha dejado de evolucionar!" % nombre_viejo)
		return false
	sprite.mostrar(nueva, false)
	var destello:= create_tween()
	destello.tween_property(brillo, "modulate:a", 1.0, 0.15)
	destello.tween_property(brillo, "modulate:a", 0.0, 0.5)
	destello.parallel().tween_method(_blanco, 1.0, 0.0, 0.6)
	await destello.finished
	p.evolucionar(nueva)
	Estado.capturar(nueva.id)
	Sonido.detener_musica(0.1)
	var dur: float= Sonido.grito(nueva.numero)
	await _esperar(minf(dur, 1.2))
	Sonido.jingle("evolucion_fin")
	await Dialogo.mostrar("¡Enhorabuena! ¡Tu %s ha evolucionado a %s!" % [nombre_viejo, nueva.nombre])
	Sonido.cortar_jingle()
	await _aprender(p, nueva.movimientos_en(p.nivel))
	if muda!= "" and not Equipo.esta_lleno() and Inventario.cantidad_de("pokeball")> 0:
		var esp_muda:= BaseDatos.especie(muda)
		if esp_muda!= null:
			Inventario.consumir("pokeball")
			var nuevo:= PokemonInstancia.crear(esp_muda, p.nivel)
			nuevo.ivs= p.ivs.duplicate()
			nuevo.evs =p.evs.duplicate()
			nuevo.naturaleza= p.naturaleza
			nuevo.movimientos.assign(p.movimientos.duplicate())
			nuevo.pp.assign(nuevo.movimientos.map(func(m): return m.pp))
			nuevo.genero= ""
			nuevo.ps_actuales= nuevo.ps_max()
			Equipo.agregar(nuevo)
			Estado.capturar(esp_muda.id)
			Sonido.jingle("captura")
			await Dialogo.mostrar("¡En la Poké Ball apareció %s!" % esp_muda.nombre)
			Sonido.cortar_jingle()
	return true

func _aprender(p: PokemonInstancia, lista: Array[Movimiento]) -> void:
	for m in lista:
		if p.movimientos.has(m):
			continue
		if p.aprender(m):
			Sonido.jingle("aprender")
			await Dialogo.mostrar("¡%s aprendió %s!" % [p.nombre(), m.nombre])
			Sonido.cortar_jingle()
			continue
		await Dialogo.mostrar("%s quiere aprender %s, pero ya conoce cuatro movimientos." % [p.nombre(), m.nombre])
		var panel= load(ESCENA_APRENDER).instantiate()
		add_child(panel)
		var i: int= await panel.elegir(p, m)
		panel.queue_free()
		if i>= 0 and i< p.movimientos.size():
			var viejo:= p.movimientos[i].nombre
			p.reemplazar_movimiento(i, m)
			Sonido.jingle("olvidar")
			await Dialogo.mostrar("1, 2 y... ¡Tachán! %s olvidó %s..." % [p.nombre(), viejo])
			Sonido.jingle("aprender")
			await Dialogo.mostrar("...¡y aprendió %s!" % m.nombre)
			Sonido.cortar_jingle()
			continue
		await Dialogo.mostrar("%s no aprendió %s." % [p.nombre(), m.nombre])
