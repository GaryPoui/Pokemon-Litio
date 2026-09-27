class_name TablaEncuentros
extends Resource

@export_range(0.0, 1.0, 0.01) var tasa: float= 0.1
@export var entradas: Array[EncuentroEntrada]= []

func elegir(rng: RandomNumberGenerator, rareza: float= 0.0) -> EncuentroEntrada:
	var pesos:= pesos_efectivos(rareza)
	var total:= 0.0
	for w in pesos:
		total+= w
	if total<= 0.0:
		return null
	var tiro:= rng.randf()* total
	for k in entradas.size():
		tiro -=pesos[k]
		if tiro< 0.0:
			return entradas[k]
	return entradas.back()

func pesos_efectivos(rareza: float= 0.0) -> Array[float]:
	var lista: Array[float]= []
	for e in entradas:
		lista.append(pow(float(maxi(e.peso, 0)), 1.0- clampf(rareza, 0.0, 0.95)) if e.peso> 0 else 0.0)
	return lista
