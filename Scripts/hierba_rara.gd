extends Node2D

const HIERBA:= preload("res://Assets/Overworld/entorno_provisional.png")
const HOJA :=preload("res://Assets/Overworld/hierba_hoja.png")
const REGION:= Rect2(32, 0, 16, 16)

var mata: Sprite2D
var tiempo:= 0.0
var sacudidas :=0

func _ready() -> void:
	add_to_group("hierba_rara")
	mata= Sprite2D.new()
	mata.texture= HIERBA
	mata.region_enabled =true
	mata.region_rect= REGION
	mata.centered =false
	mata.position= Vector2(0, -8)
	position.y+= 8
	add_child(mata)

func _process(delta: float) -> void:
	tiempo+= delta
	if tiempo< 0.7:
		return
	tiempo= 0.0
	sacudidas +=1
	var t:= create_tween()
	for dx in [1.0, -1.0, 1.0, -1.0, 0.0]:
		t.tween_property(mata, "offset:x", dx, 0.05)
	_hoja(-1.0 if sacudidas% 2== 0 else 1.0)

func _hoja(lado: float) -> void:
	var h:= Sprite2D.new()
	h.texture= HOJA
	h.centered =false
	h.position= Vector2(lado* 3.0, -6.0)
	add_child(h)
	var t:= create_tween().set_parallel()
	t.tween_property(h, "position", h.position+ Vector2(lado* 5.0, -7.0), 0.3).set_ease(Tween.EASE_OUT)
	t.tween_property(h, "modulate:a", 0.0, 0.3).set_delay(0.1)
	t.chain().tween_callback(h.queue_free)
