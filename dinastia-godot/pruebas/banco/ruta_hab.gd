extends RefCounted
## [Banco · grupo «ruta», ayudante] LOS PUNTOS DE HABILIDAD de La Ruta (reglas del dueño, 13-11):
## cada zona es el promedio de sus habilidades; el coste sube con el valor, con el nivel y con
## lo poco que pese la zona en tu puesto; y se puede entrenar otro puesto. Deja al jugador como estaba.

static func probar(b: Variant, c: CarreraJugador, m: Mundo, j: Jugador) -> void:
	var guardado := {"hab": c.ruta.get("hab", 0), "hab_nivel": c.ruta.get("hab_nivel", 1), "nivel": int(c.ruta["nivel"]), "attrs": j.atributos.duplicate(),
		"ovr": j.ovr, "pos_e": j.pos_e, "pos": j.pos, "sec": j.pos_sec.duplicate(), "adapt": j.adapt, "pulidos": (c.ruta.get("pulidos", {}) as Dictionary).duplicate()}
	c.ruta["nivel"] = 3
	c.ruta["hab_nivel"] = 1
	c.ruta["hab"] = 0
	c.ruta.erase("detalle")
	b._comprobar(CarreraHabilidad.puntos(c) == 2 * CarreraHabilidad.PUNTOS_POR_NIVEL and CarreraHabilidad.puntos(c) == 2 * CarreraHabilidad.PUNTOS_POR_NIVEL, "  cada nivel da %d puntos de habilidad, una sola vez" % CarreraHabilidad.PUNTOS_POR_NIVEL)
	## El detalle: cada zona es el promedio de sus habilidades.
	var d := CarreraHabilidad.detalle(c, j)
	var cuadra := true
	for zona: String in j.atributos:
		cuadra = cuadra and CarreraHabilidad._promedio(d, CarreraHabilidad.de_zona(zona)) == int(j.atributos[zona])
	b._comprobar(cuadra and d.size() >= j.atributos.size(), "  cada zona es el promedio de sus habilidades (%d habilidades)" % d.size())
	var zona_p: String = j.atributos.keys()[0]
	j.atributos[zona_p] = int(j.atributos[zona_p]) + 2
	b._comprobar(CarreraHabilidad._promedio(CarreraHabilidad.detalle(c, j), CarreraHabilidad.de_zona(zona_p)) == int(j.atributos[zona_p]), "  si el entreno sube una zona, sus habilidades la siguen")
	var clave := ""
	var ajena := ""
	for z: String in j.atributos:
		if CarreraHabilidad.clase(j, z) == "clave" and clave == "":
			clave = String(CarreraHabilidad.de_zona(z)[0][0])
		if CarreraHabilidad.clase(j, z) == "ajena" and ajena == "":
			ajena = String(CarreraHabilidad.de_zona(z)[0][0])
	b._comprobar(clave != "" and ajena != "", "  en su puesto (%s) hay zonas clave y zonas que pesan poco" % j.pos_e)
	if clave != "" and ajena != "":
		_poner_zona(c, j, CarreraHabilidad.zona_de(clave), 65)
		_poner_zona(c, j, CarreraHabilidad.zona_de(ajena), 65)
		b._comprobar(CarreraHabilidad.coste(c, j, ajena) > CarreraHabilidad.coste(c, j, clave), "  lo que pesa poco en tu puesto cuesta más (%d frente a %d)" % [CarreraHabilidad.coste(c, j, ajena), CarreraHabilidad.coste(c, j, clave)])
		var barato := CarreraHabilidad.coste(c, j, clave)
		_poner_zona(c, j, CarreraHabilidad.zona_de(clave), 85)
		b._comprobar(CarreraHabilidad.coste(c, j, clave) > barato, "  cuanto más alta la habilidad, más cuesta el siguiente punto")
		var a_nivel3 := CarreraHabilidad.coste(c, j, clave)
		c.ruta["nivel"] = 30
		c.ruta["hab_nivel"] = 30
		b._comprobar(CarreraHabilidad.coste(c, j, clave) > a_nivel3, "  y cuanto más nivel tiene el personaje, más cuesta")
		c.ruta["nivel"] = 3
		c.ruta["hab_nivel"] = 3
		## Subir: se cobra, sube la habilidad y la zona pasa a ser el promedio nuevo.
		var zona_c := CarreraHabilidad.zona_de(clave)
		_poner_zona(c, j, zona_c, 65)
		c.ruta["hab"] = 200
		var antes := CarreraHabilidad.puntos(c)
		b._comprobar(CarreraHabilidad.subir(c, m, clave) and CarreraHabilidad.valor(c, j, clave) == 66 and CarreraHabilidad.puntos(c) == antes - barato, "  subir un punto lo cobra y sube la habilidad")
		for par2: Array in CarreraHabilidad.de_zona(zona_c):
			while CarreraHabilidad.valor(c, j, String(par2[0])) < 67:
				CarreraHabilidad.subir(c, m, String(par2[0]))
		b._comprobar(int(j.atributos[zona_c]) == 67, "  con todas sus habilidades a 67, la zona vale 67 (%d)" % int(j.atributos[zona_c]))
		c.ruta["hab"] = 0
		b._comprobar(not CarreraHabilidad.subir(c, m, clave), "  sin puntos no se sube")
	## El puesto: la media sale de las habilidades y del puesto; entrenar otro cuesta más si es de otra línea.
	var otros: Array = CarreraHabilidad.puestos(j)
	var medias := {}
	for pe: String in otros:
		medias[CarreraHabilidad.media_en(j, pe)] = true
	b._comprobar(otros.size() >= 2 or j.es_portero(), "  hay otros puestos que entrenar (%d)" % otros.size())
	b._comprobar(medias.size() >= 2 or j.es_portero(), "  con las mismas habilidades la media cambia según el puesto (%d medias distintas)" % medias.size())
	var misma := ""
	var otra := ""
	for pe2: String in otros:
		if pe2 != j.pos_e and CarreraHabilidad._linea(pe2) == j.pos and misma == "" and not j.pos_sec.has(pe2):
			misma = pe2
		if CarreraHabilidad._linea(pe2) != j.pos and otra == "" and not j.pos_sec.has(pe2):
			otra = pe2
	if misma != "" and otra != "":
		b._comprobar(CarreraHabilidad.coste_puesto(c, j, otra) > CarreraHabilidad.coste_puesto(c, j, misma), "  entrenar un puesto de otra línea cuesta más que uno de la tuya")
	if otra != "":
		c.ruta["hab"] = 0
		b._comprobar(CarreraHabilidad.cambiar(c, m, otra).is_empty() and j.pos_e == String(guardado["pos_e"]), "  sin puntos no se cambia de puesto")
		c.ruta["hab"] = 99
		var res := CarreraHabilidad.cambiar(c, m, otra)
		b._comprobar(not res.is_empty() and j.pos_e == otra and CarreraHabilidad.puntos(c) < 99, "  con puntos, pasa a jugar de %s (media %d → %d)" % [otra, int(res.get("antes", 0)), int(res.get("despues", 0))])
	j.atributos = guardado["attrs"]
	j.ovr = int(guardado["ovr"]); j.pos_e = String(guardado["pos_e"]); j.pos = String(guardado["pos"]); j.pos_sec = guardado["sec"]; j.adapt = int(guardado["adapt"])
	j.tasar()
	c.ruta["nivel"] = int(guardado["nivel"]); c.ruta["hab"] = guardado["hab"]; c.ruta["hab_nivel"] = guardado["hab_nivel"]; c.ruta["pulidos"] = guardado["pulidos"]
	c.ruta.erase("detalle")

## Deja una zona entera (ella y todas sus habilidades) en un valor.
static func _poner_zona(c: CarreraJugador, j: Jugador, zona: String, valor: int) -> void:
	var d := CarreraHabilidad.detalle(c, j)
	for par: Array in CarreraHabilidad.de_zona(zona):
		d[String(par[0])] = valor
	j.atributos[zona] = valor
