extends Node

signal cambiado

const MAXIMO:= 6

var miembros: Array[PokemonInstancia]= []

func agregar(p: PokemonInstancia) -> bool:
	if esta_lleno():
		return false
	miembros.append(p)
	cambiado.emit()
	return true

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

func desde_lista(lista: Array) -> void:
	miembros.clear()
	for d in lista:
		miembros.append(PokemonInstancia.desde_diccionario(d))
	cambiado.emit()
