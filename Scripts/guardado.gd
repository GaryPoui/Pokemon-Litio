extends Node

const RUTA:= "user://partida.json"
const VERSION :=1

func existe() -> bool:
	return FileAccess.file_exists(RUTA)

func guardar() -> bool:
	var escena:= get_tree().current_scene
	if escena== null:
		return false
	var jugador= escena.get_node_or_null("Jugador")
	var pos:= Vector2.ZERO
	var dir :=Vector2.DOWN
	if jugador!= null:
		pos= jugador.position
		dir =jugador.last_direction
	var datos:= {
		"version": VERSION,
		"mapa": escena.scene_file_path,
		"posicion": [pos.x, pos.y],
		"direccion": [dir.x, dir.y],
		"inventario": Inventario.a_diccionario(),
		"banderas": Estado.banderas,
		"vistos": Estado.vistos,
		"capturados": Estado.capturados,
		"repelente": Estado.pasos_repelente,
		"equipo": Equipo.a_lista(),
	}
	var f:= FileAccess.open(RUTA, FileAccess.WRITE)
	if f== null:
		return false
	f.store_string(JSON.stringify(datos, "\t"))
	f.close()
	return true

func cargar() -> bool:
	if not existe():
		return false
	var datos= JSON.parse_string(FileAccess.get_file_as_string(RUTA))
	if typeof(datos)!= TYPE_DICTIONARY:
		return false
	Inventario.desde_diccionario(datos.get("inventario", {}))
	Estado.banderas =datos.get("banderas", {}).duplicate()
	Estado.vistos= datos.get("vistos", {}).duplicate()
	Estado.capturados =datos.get("capturados", {}).duplicate()
	Estado.pasos_repelente= int(datos.get("repelente", 0))
	Equipo.desde_lista(datos.get("equipo", []))
	var p: Array= datos.get("posicion", [0, 0])
	var d: Array =datos.get("direccion", [0, 1])
	GestorEscenas.cambiar_mapa_a(str(datos["mapa"]), Vector2(p[0], p[1]), Vector2(d[0], d[1]))
	return true
