class_name SorteoLigaConti
extends RefCounted
## EL SORTEO DE LA FASE DE LIGA (Champions, Europa League, Conference, Asia Elite). 10-11.
##
## Cuatro bombos por reputación; cada club juega contra DOS rivales de cada bombo (el suyo incluido), uno en casa y
## otro fuera: son 8 partidos, repartidos en 8 fechas en las que nadie juega dos veces. El sorteo es real: dentro
## de cada bombo el orden se baraja con el azar del mundo, y de ahí salen los rivales.
##
## Cómo se arma (para que SIEMPRE salga, y no por ensayo y error):
##  - Seis fechas «cruzadas»: los bombos se emparejan de los tres modos posibles ((0-1,2-3), (0-2,1-3), (0-3,1-2)) y, en
##    cada emparejamiento, cada club de un bombo juega con uno del otro (un desplazamiento circular distinto en la ida
##    y en la vuelta; local un bombo en la primera, el otro en la segunda).
##  - Dos fechas «de bombo»: cada bombo juega contra sí mismo. Si el bombo es par, un ciclo cerrado se parte en dos
##    fechas. Si es impar (9 clubes, la Champions) no hay forma de que los 9 jueguen a la vez, así que el bombo forma un
##    CAMINO: el primero y el último descansan una de esas dos fechas, y esos cuatro clubes (uno por bombo) se enfrentan
##    entre sí en la fecha libre. Es la única desviación de la regla «dos de cada bombo»: afecta a 8 de los 36 clubes.

const FECHAS := 8

## Devuelve las 8 fechas: Array de fechas, cada una un Array de [local, visita].
## `clubes` llega ordenado de mejor a peor (el sembrado) y tiene un múltiplo de 4 de clubes (mínimo 12).
static func armar(clubes: Array) -> Array:
	var n := clubes.size()
	if n < 12 or n % 4 != 0:
		return []
	var m := n / 4
	for intento in 80:
		var f := _intentar(clubes, m)
		if not f.is_empty():
			return f
	return []

static func _intentar(clubes: Array, m: int) -> Array:
	var bombos: Array = []
	for p in 4:
		var b: Array = clubes.slice(p * m, (p + 1) * m)
		Azar.barajar(b)
		bombos.append(b)
	var dias: Array = []
	for d in FECHAS:
		dias.append([])
	var visto := {}
	## Fechas cruzadas: 0,1,2 (ida) y 4,5,6 (vuelta, con los campos cambiados).
	var emparejamientos := [[[0, 1], [2, 3]], [[0, 2], [1, 3]], [[0, 3], [1, 2]]]
	for c in 3:
		for par: Array in emparejamientos[c]:
			var o1 := Azar.ent(0, m - 1)
			var o2 := (o1 + Azar.ent(1, m - 1)) % m
			var pa: Array = bombos[par[0]]
			var pb: Array = bombos[par[1]]
			for i in m:
				var a: Club = pa[i]
				var b1: Club = pb[(i + o1) % m]
				var b2: Club = pb[(i + o2) % m]
				dias[c].append([a, b1])
				dias[4 + c].append([b2, a])
				visto[_k(a, b1)] = true
				visto[_k(a, b2)] = true
	## Fechas de bombo: 3 y 7.
	var libres_a: Array = []
	var libres_b: Array = []
	for p in 4:
		var b: Array = bombos[p]
		if m % 2 == 0:
			for i in m:
				dias[3 if i % 2 == 0 else 7].append([b[i], b[(i + 1) % m]])
		else:
			for i in m - 1:
				dias[7 if i % 2 == 0 else 3].append([b[i], b[i + 1]])
			libres_a.append(b[0])        ## descansa la fecha 3
			libres_b.append(b[m - 1])    ## descansa la fecha 7
	if m % 2 == 1:
		var pa3 := _cuatro_en_dos(libres_a, visto)
		var pb7 := _cuatro_en_dos(libres_b, visto)
		if pa3.is_empty() or pb7.is_empty():
			return []
		dias[3].append_array(pa3)
		dias[7].append_array(pb7)
	return dias

## Empareja cuatro clubes en dos partidos que no se hayan jugado ya. Vacío si ninguna de las tres combinaciones vale.
static func _cuatro_en_dos(l: Array, visto: Dictionary) -> Array:
	for combo: Array in [[[0, 1], [2, 3]], [[0, 2], [1, 3]], [[0, 3], [1, 2]]]:
		var ok := true
		for par: Array in combo:
			if visto.has(_k(l[par[0]], l[par[1]])):
				ok = false
		if ok:
			var salida: Array = []
			for par: Array in combo:
				visto[_k(l[par[0]], l[par[1]])] = true
				salida.append([l[par[0]], l[par[1]]])
			return salida
	return []

static func _k(a: Club, b: Club) -> String:
	return "%s|%s" % [a.id, b.id] if a.id < b.id else "%s|%s" % [b.id, a.id]
