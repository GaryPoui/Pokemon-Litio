class_name Evoluciones
extends RefCounted

const CORDON:= "linking_cord"

static func es_de_dia() -> bool:
	var h: int= Time.get_datetime_dict_from_system()["hour"]
	return h>= 6 and h< 20

static func _hora_ok(e: Dictionary) -> bool:
	match str(e.get("hora", "")):
		"dia":
			return es_de_dia()
		"noche", "tarde":
			return not es_de_dia()
	return true

static func _genero_ok(p: PokemonInstancia, e: Dictionary) -> bool:
	match str(e.get("genero", "")):
		"hembra":
			return p.genero== "F"
		"macho":
			return p.genero =="M"
	return true

static func _existe(id: String) -> bool:
	return BaseDatos.especie(id)!= null

static func _semilla(p: PokemonInstancia) -> int:
	var suma:= 0
	for s in PokemonInstancia.STATS:
		suma+= int(p.ivs.get(s, 0))* (PokemonInstancia.STATS.find(s)+ 3)
	return suma

static func por_nivel(p: PokemonInstancia, equipo: Array= []) -> String:
	if p.esta_debilitado():
		return ""
	var silcoon_cascoon:= []
	for e in p.especie.evoluciones:
		var destino: String= str(e.get("especie", ""))
		if destino== "" or not _existe(destino) or not _hora_ok(e) or not _genero_ok(p, e):
			continue
		match str(e.get("metodo", "")):
			"nivel":
				if p.nivel< int(e.get("nivel", 1)):
					continue
				if e.has("stats"):
					var at:= p.stat("ataque")
					var df:= p.stat("defensa")
					var rel:= signi(at- df)
					if rel!= int(e["stats"]):
						continue
				if p.especie.id== "wurmple":
					silcoon_cascoon.append(destino)
					continue
				return destino
			"amistad":
				if p.amistad>= int(e.get("amistad", 220)):
					return destino
			"movimiento":
				for m in p.movimientos:
					if m.id== str(e.get("movimiento", "")):
						return destino
			"tipo_movimiento":
				for m in p.movimientos:
					if m.tipo== str(e.get("tipo", "")):
						return destino
			"companero":
				for o in equipo:
					if o!= p and o is PokemonInstancia and o.especie.id== str(e.get("especie_equipo", "")):
						return destino
			"muda":
				if p.nivel>= int(e.get("nivel", 20)):
					continue
	if not silcoon_cascoon.is_empty():
		silcoon_cascoon.sort()
		return silcoon_cascoon[_semilla(p)% silcoon_cascoon.size()]
	return ""

static func muda(p: PokemonInstancia) -> String:
	for e in p.especie.evoluciones:
		if str(e.get("metodo", ""))== "muda" and _existe(str(e.get("especie", ""))):
			return str(e["especie"])
	return ""

static func por_objeto(p: PokemonInstancia, objeto_id: String) -> String:
	if p.esta_debilitado():
		return ""
	for e in p.especie.evoluciones:
		var destino: String= str(e.get("especie", ""))
		if not str(e.get("metodo", "")) in ["piedra", "objeto"] or str(e.get("objeto", ""))!= objeto_id:
			continue
		if _existe(destino) and _hora_ok(e) and _genero_ok(p, e):
			return destino
	return ""

static func por_cordon(p: PokemonInstancia, tiene_objeto: Callable= Callable()) -> Dictionary:
	if p.esta_debilitado():
		return {}
	for e in p.especie.evoluciones:
		var destino: String= str(e.get("especie", ""))
		if str(e.get("metodo", ""))!= "intercambio" or not _existe(destino):
			continue
		var obj: String= str(e.get("objeto", ""))
		if obj!= "" and (not tiene_objeto.is_valid() or not tiene_objeto.call(obj)):
			continue
		return {"especie": destino, "objeto": obj}
	return {}

static func objetos_que_sirven(p: PokemonInstancia) -> Array[String]:
	var lista: Array[String]= []
	for e in p.especie.evoluciones:
		if str(e.get("metodo", "")) in ["piedra", "objeto"] and not lista.has(str(e.get("objeto", ""))):
			lista.append(str(e.get("objeto", "")))
	return lista
