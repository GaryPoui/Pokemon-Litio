extends Node

signal cambiado

const MAXIMO:= 6

var miembros: Array[PokemonInstancia]= []
var caja: Array[PokemonInstancia] =[]

func agregar(p: PokemonInstancia) -> bool:
	if esta_lleno():
		return false
	miembros.append(p)
	Estado.capturar(p.especie.id)
	cambiado.emit()
	return true

func recibir(p: PokemonInstancia) -> String:
	if agregar(p):
		return "equipo"
	a_caja(p)
	return "caja"

func a_caja(p: PokemonInstancia) -> void:
	p.curar()
	caja.append(p)
	Estado.capturar(p.especie.id)
	cambiado.emit()

func puede_depositar(i: int) -> String:
	if i< 0 or i>= miembros.size():
		return "No hay ningún Pokémon ahí."
	if miembros.size()<= 1:
		return "¡No puedes dejar a tu último Pokémon!"
	var otros:= miembros.filter(func(q): return q!= miembros[i] and not q.esta_debilitado())
	if otros.is_empty():
		return "¡Necesitas al menos un Pokémon que pueda luchar en el equipo!"
	return ""

func depositar(i: int) -> bool:
	if puede_depositar(i)!= "":
		return false
	var p:= miembros[i]
	miembros.remove_at(i)
	p.curar()
	caja.append(p)
	cambiado.emit()
	return true

func retirar(i: int) -> bool:
	if esta_lleno() or i< 0 or i>= caja.size():
		return false
	miembros.append(caja[i])
	caja.remove_at(i)
	cambiado.emit()
	return true

func reiniciar() -> void:
	miembros.clear()
	caja.clear()
	cambiado.emit()

func esta_lleno() -> bool:
	return miembros.size()>= MAXIMO

func primero_util() -> PokemonInstancia:
	for p in miembros:
		if not p.esta_debilitado():
			return p
	return null

func todos_debilitados() -> bool:
	return primero_util()== null

func curar_todo() -> void:
	for p in miembros:
		p.curar()
	cambiado.emit()

func intercambiar(a: int, b: int) -> void:
	var tmp:= miembros[a]
	miembros[a] =miembros[b]
	miembros[b]= tmp
	cambiado.emit()

func a_lista() -> Array:
	var lista:= []
	for p in miembros:
		lista.append(p.a_diccionario())
	return lista

func caja_a_lista() -> Array:
	return caja.map(func(p): return p.a_diccionario())

func caja_desde_lista(lista: Array) -> void:
	caja.clear()
	for d in lista:
		caja.append(PokemonInstancia.desde_diccionario(d))

func desde_lista(lista: Array) -> void:
	miembros.clear()
	for d in lista:
		miembros.append(PokemonInstancia.desde_diccionario(d))
	cambiado.emit()
