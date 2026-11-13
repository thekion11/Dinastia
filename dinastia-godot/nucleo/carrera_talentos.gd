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

## PULIR: un punto de talento también vale por +2 en un atributo (cuando ya
## aprendiste lo que querías, los puntos siguen sirviendo).
static func puede_pulir(c: CarreraJugador, m: Mundo, attr: String) -> bool:
	var j := c.jugador(m)
	return j != null and int(CarreraRuta.asegurar(c)["puntos"]) > 0 and j.atributos.has(attr) and int(j.atributos[attr]) < 99

static func pulir(c: CarreraJugador, m: Mundo, attr: String) -> bool:
	if not puede_pulir(c, m, attr):
		return false
	var r := CarreraRuta.asegurar(c)
	var j := c.jugador(m)
	r["puntos"] = int(r["puntos"]) - 1
	var antes_attr := int(j.atributos[attr])
	j.atributos[attr] = mini(99, antes_attr + 2)
	if not r.get("pulidos") is Dictionary:
		r["pulidos"] = {}   ## cuánto llevas repartido en cada atributo (lo enseña «Tu juego»)
	(r["pulidos"] as Dictionary)[attr] = int((r["pulidos"] as Dictionary).get(attr, 0)) + int(j.atributos[attr]) - antes_attr
	var antes := j.ovr
	j.ovr = maxi(j.ovr, j.media_en(j.pos_e))
	if j.ovr != antes:
		j.tasar()
	return true
