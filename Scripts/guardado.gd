extends Node

const RUTA_VIEJA:= "user://partida.json"
const VERSION :=2
const RANURAS:= 3
const CIUDADES :=["la_boca", "villa_31", "constitucion"]
const RUTAS_SAFARI:= ["reserva_costanera", "puerto_madero", "playa_retiro", "barrancas_retiro", "nueve_de_julio", "linea_c"]

var ranura:= 1

func _ready() -> void:
	migrar()

func ruta(n: int= -1) -> String:
	return "user://partida_%d.json" % (ranura if n< 1 else n)

func migrar() -> bool:
	if not FileAccess.file_exists(RUTA_VIEJA):
		return false
	for n in range(1, RANURAS+ 1):
		if FileAccess.file_exists(ruta(n)):
			return false
	var err:= DirAccess.rename_absolute(ProjectSettings.globalize_path(RUTA_VIEJA), ProjectSettings.globalize_path(ruta(1)))
	return err== OK

func existe(n: int= -1) -> bool:
	return FileAccess.file_exists(ruta(n))

func leer(n: int) -> Dictionary:
	if not existe(n):
		return {}
	var datos= JSON.parse_string(FileAccess.get_file_as_string(ruta(n)))
	return datos if typeof(datos)== TYPE_DICTIONARY else {}

func borrar(n: int) -> bool:
	if not existe(n):
		return false
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta(n)))== OK

func copiar(origen: int, destino: int) -> bool:
	if not existe(origen) or existe(destino) or origen== destino:
		return false
	return DirAccess.copy_absolute(ProjectSettings.globalize_path(ruta(origen)), ProjectSettings.globalize_path(ruta(destino)))== OK

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
	var lugar:= str(escena.get("zona_nombre")) if "zona_nombre" in escena else ""
	var datos:= {
		"version": VERSION,
		"mapa": escena.scene_file_path,
		"lugar": lugar,
		"zona_exterior_id": GestorEscenas.ultima_zona_exterior_id,
		"retorno": GestorEscenas.retorno,
		"posicion": [pos.x, pos.y],
		"direccion": [dir.x, dir.y],
		"inventario": Inventario.a_diccionario(),
		"banderas": Estado.banderas,
		"vistos": Estado.vistos,
		"capturados": Estado.capturados,
		"repelente": Estado.pasos_repelente,
		"dinero": Estado.dinero,
		"stock_tienda": Estado.stock_tienda.duplicate(),
		"safari": Estado.safari,
		"medallas": Estado.medallas.duplicate(),
		"fichas": Estado.fichas,
		"fichas_ciudades": Estado.fichas_ciudades,
		"estadisticas": Estado.estadisticas.duplicate(),
		"equipo": Equipo.a_lista(),
		"caja": Equipo.caja_a_lista(),
	}
	var f:= FileAccess.open(ruta(), FileAccess.WRITE)
	if f== null:
		return false
	f.store_string(JSON.stringify(datos, "\t"))
	f.close()
	return true

func cargar(n: int= -1) -> bool:
	if n>= 1:
		ranura= n
	if not existe():
		return false
	var datos:= leer(ranura)
	if datos.is_empty():
		return false
	Inventario.desde_diccionario(datos.get("inventario", {}))
	Estado.banderas =datos.get("banderas", {}).duplicate()
	Estado.vistos= datos.get("vistos", {}).duplicate()
	Estado.capturados =datos.get("capturados", {}).duplicate()
	Estado.pasos_repelente= int(datos.get("repelente", 0))
	Estado.dinero =int(datos.get("dinero", Estado.DINERO_INICIAL))
	Estado.stock_tienda.assign(Array(datos.get("stock_tienda", [])).map(func(x): return str(x)))
	Estado.safari= datos.get("safari", {}).duplicate(true)
	Estado.medallas.assign(Array(datos.get("medallas", [])).map(func(x): return str(x)))
	Estado.fichas =int(datos.get("fichas", 0))
	Estado.fichas_ciudades= datos.get("fichas_ciudades", {}).duplicate()
	Estado.estadisticas= Estado.estadisticas_nuevas()
	Estado.estadisticas.merge(datos.get("estadisticas", {}), true)
	Equipo.desde_lista(datos.get("equipo", []))
	Equipo.caja_desde_lista(datos.get("caja", []))
	if str(Estado.estadisticas.get("companero", ""))== "" and not Equipo.miembros.is_empty():
		Estado.estadisticas["companero"]= Equipo.miembros[0].especie.id
	GestorEscenas.restaurar_zona_exterior(str(datos.get("zona_exterior_id", "")))
	GestorEscenas.retorno =datos.get("retorno", {}).duplicate()
	var p: Array= datos.get("posicion", [0, 0])
	var d: Array =datos.get("direccion", [0, 1])
	GestorEscenas.cambiar_mapa_a(str(datos["mapa"]), Vector2(p[0], p[1]), Vector2(d[0], d[1]))
	return true

func resumen(n: int) -> Dictionary:
	var datos:= leer(n)
	if datos.is_empty():
		return {}
	return resumen_de(datos)

static func resumen_de(datos: Dictionary) -> Dictionary:
	var est: Dictionary= datos.get("estadisticas", {})
	var equipo: Array= datos.get("equipo", [])
	var caja: Array =datos.get("caja", [])
	var trinkets:= {}
	var inv: Dictionary= datos.get("inventario", {})
	for t in inv.get("__trinkets", {}):
		if int(inv["__trinkets"][t])> 0:
			trinkets[str(t)]= true
	for p in equipo+ caja:
		for t in p.get("trinkets", []):
			trinkets[str(t)]= true
	var banderas: Dictionary= datos.get("banderas", {})
	var registros:= 0
	for r in RUTAS_SAFARI:
		if banderas.get("premio_reserva_"+ r, false):
			registros+= 1
	var ciudad:= ""
	var visitadas: Dictionary= datos.get("fichas_ciudades", {})
	for c in CIUDADES:
		if visitadas.has(c):
			ciudad= c
	var companero:= str(est.get("companero", ""))
	if companero== "" and not equipo.is_empty():
		companero= str(equipo[0].get("especie", "")).get_file().get_basename()
	var lugar:= str(datos.get("lugar", ""))
	if lugar== "":
		lugar= str(datos.get("mapa", "")).get_file().get_basename()
	return {
		"capturados": Dictionary(datos.get("capturados", {})).size(),
		"vistos": Dictionary(datos.get("vistos", {})).size(),
		"total": BaseDatos.ids(BaseDatos.ESPECIES).size(),
		"tiempo": float(est.get("tiempo", 0.0)),
		"pasos": int(est.get("pasos", 0)),
		"trinkets": trinkets.size(),
		"total_trinkets": BaseDatos.ids(BaseDatos.TRINKETS).size(),
		"registros": registros,
		"total_registros": RUTAS_SAFARI.size(),
		"dinero": int(datos.get("dinero", 0)),
		"medallas": Array(datos.get("medallas", [])).map(func(x): return str(x)),
		"ciudad": ciudad,
		"companero": companero,
		"lugar": lugar,
	}
