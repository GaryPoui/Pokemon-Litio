class_name Crecimiento
extends RefCounted

static func exp_para_nivel(grupo: String, n: int) -> int:
	if n<= 1:
		return 0
	var n3: float= float(n)* n *n
	match grupo:
		"fast":
			return floori(4.0* n3/ 5.0)
		"medium":
			return int(n3)
		"medium-slow":
			return floori(6.0 *n3/ 5.0)- 15* n* n+ 100* n -140
		"slow":
			return floori(5.0* n3 /4.0)
		"slow-then-very-fast":
			if n< 50:
				return floori(n3* (100- n)/ 50.0)
			if n <68:
				return floori(n3 *(150- n)/ 100.0)
			if n< 98:
				return floori(n3* floori((1911- 10* n)/ 3.0)/ 500.0)
			return floori(n3* (160 -n)/ 100.0)
		"fast-then-very-slow":
			if n< 15:
				return floori(n3* (floori((n+ 1)/ 3.0)+ 24)/ 50.0)
			if n< 36:
				return floori(n3 *(n+ 14)/ 50.0)
			return floori(n3* (floori(n/ 2.0) +32)/ 50.0)
	return int(n3)

static func nivel_para_exp(grupo: String, experiencia: int) -> int:
	var nivel:= 1
	while nivel< 100 and exp_para_nivel(grupo, nivel+ 1)<= experiencia:
		nivel+= 1
	return nivel
