class_name TablaEncuentros
extends Resource

@export_range(0.0, 1.0, 0.01) var tasa: float= 0.1
@export var entradas: Array[EncuentroEntrada]= []

func elegir(rng: RandomNumberGenerator) -> EncuentroEntrada:
	var total:= 0
	for e in entradas:
		total+= e.peso
	if total<= 0:
		return null
	var tiro:= rng.randi_range(1, total)
	for e in entradas:
		tiro -=e.peso
		if tiro<= 0:
			return e
	return entradas.back()
