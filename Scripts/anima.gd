extends Node2D

const TONO_H:= Color(0.8, 0.68, 1.0, 0.6)
const TONO_V :=Color(0.62, 0.88, 1.0, 0.6)
const ANIMS:= {Vector2i.DOWN: &"caminar_abajo", Vector2i.UP: &"caminar_arriba", Vector2i.LEFT: &"caminar_izquierda", Vector2i.RIGHT: &"caminar_derecha"}

var sprite: AnimatedSprite2D
var mov: Tween
var base_y:= 0.0
var reloj :=0.0
var quieto:= 1

func preparar(jugador: Node) -> void:
	var modelo: AnimatedSprite2D= jugador.get_node("AnimatedSprite2D")
	sprite= AnimatedSprite2D.new()
	sprite.sprite_frames= modelo.sprite_frames
	sprite.position =modelo.position
	sprite.offset= modelo.offset
	sprite.centered =modelo.centered
	sprite.scale= modelo.scale
	base_y= sprite.position.y
	quieto =int(jugador.idle_frame)
	add_child(sprite)
	tono("h")
	girar(Vector2i.UP)

func _process(delta: float) -> void:
	if sprite== null:
		return
	reloj+= delta
	sprite.position.y= base_y+ roundf(sin(reloj* 2.6)* 0.6)

func tono(modo: String) -> void:
	modulate= TONO_H if modo== "h" else TONO_V

func girar(dir: Vector2i) -> void:
	if sprite== null or not ANIMS.has(dir):
		return
	sprite.animation= ANIMS[dir]
	sprite.stop()
	sprite.frame =quieto

func colocar(pos: Vector2) -> void:
	if mov!= null:
		mov.kill()
	position= pos
	girar(Vector2i.UP)

func ir_a(pos: Vector2, dir: Vector2i, dur: float) -> void:
	if mov!= null:
		mov.kill()
	if ANIMS.has(dir):
		sprite.play(ANIMS[dir])
	mov= create_tween()
	mov.tween_property(self, "position", pos, dur)
	mov.tween_callback(girar.bind(dir))

func desvanecer() -> void:
	if mov!= null:
		mov.kill()
	set_process(false)
	var t:= create_tween()
	t.tween_property(self, "modulate", Color(1.6, 1.5, 1.2, 0.0), 0.6)
	t.tween_callback(queue_free)
