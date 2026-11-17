class_name CarreraTalentos
extends RefCounted
## LOS PUNTOS DE TALENTO DE «LA RUTA»: aprender un talento (en cadena dentro de
## su rama) o pulir un atributo. Los talentos y su efecto: `CarreraRuta.TALENTOS`.

## ¿Se puede comprar? Hay punto libre y está comprado el anterior de su rama.
static func puede_aprender(c: CarreraJugador, talento: String) -> bool:
	if not CarreraRuta.TALENTOS.has(talento) or CarreraRuta.tiene(c, talento) or int(CarreraRuta.asegurar(c)["puntos"]) <= 0:
		return false
	var t: Array = CarreraRuta.TALENTOS[talento]
	for otro: String in CarreraRuta.TALENTOS:
		var o: Array = CarreraRuta.TALENTOS[otro]
		if String(o[0]) == String(t[0]) and int(o[1]) < int(t[1]) and not CarreraRuta.tiene(c, otro):
			return false
	return true

static func aprender(c: CarreraJugador, m: Mundo, talento: String) -> bool:
	if not puede_aprender(c, talento):
		return false
	var r := CarreraRuta.asegurar(c)
	r["puntos"] = int(r["puntos"]) - 1
	(r["talentos"] as Dictionary)[talento] = true
	if talento == "brazalete":
		pass   ## (13-11) el talento ya no da el brazalete: sube la posibilidad (`CarreraPremios.prob_capitan`)
		var j := c.jugador(m)
		if j != null and j.moral < 70:
			j.moral = 70
	return true

## PULIR: un punto de talento también vale, cuando ya aprendiste lo que querías, por los puntos de habilidad de un
## nivel gastados en esa zona (a su precio de hoy; lo que sobre queda como puntos de habilidad). (16-11, informe R-08)
## Antes daba +2 a la zona sin coste creciente: a nivel alto valía diez niveles de puntos de habilidad.
static func puede_pulir(c: CarreraJugador, m: Mundo, attr: String) -> bool:
	var j := c.jugador(m)
	return j != null and int(CarreraRuta.asegurar(c)["puntos"]) > 0 and j.atributos.has(attr) and int(j.atributos[attr]) < 99

static func pulir(c: CarreraJugador, m: Mundo, attr: String) -> bool:
	if not puede_pulir(c, m, attr):
		return false
	var r := CarreraRuta.asegurar(c)
	r["puntos"] = int(r["puntos"]) - 1
	r["hab"] = CarreraHabilidad.puntos(c) + CarreraHabilidad.PUNTOS_POR_NIVEL
	var j := c.jugador(m)
	var presupuesto := CarreraHabilidad.PUNTOS_POR_NIVEL
	while presupuesto > 0:
		var mejor := ""
		for par: Array in CarreraHabilidad.de_zona(attr):
			var h := String(par[0])
			if CarreraHabilidad.valor(c, j, h) < 99 and (mejor == "" or CarreraHabilidad.coste(c, j, h) < CarreraHabilidad.coste(c, j, mejor)):
				mejor = h
		if mejor == "" or CarreraHabilidad.coste(c, j, mejor) > presupuesto:
			break
		presupuesto -= CarreraHabilidad.coste(c, j, mejor)
		CarreraHabilidad.subir(c, m, mejor)
	return true
