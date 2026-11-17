class_name CarreraTraspasos
extends RefCounted
## LOS CAMBIOS DE CLUB DE «LA RUTA» (16-11-2026, informe AAA cap. 7: R-06, R-10, R-14). A dónde te puedes ir (con
## sitio en el plantel y en el cupo de la liga), la cesión de verdad (con vuelta a final de temporada) y lo que se
## pierde al cambiar de club (el brazalete). Usa el generador de la carrera, nunca `Azar`.

## ¿Te puede fichar ese club? Con sitio en el plantel (`Cantera.TOPE_PLANTEL`) y en el cupo de su liga (`LeyesPais`).
static func destino_valido(m: Mundo, cl: Club, j: Jugador) -> bool:
	if cl == null or j == null or cl.id == j.club_id:
		return false
	return cl.plantilla.size() < Cantera.TOPE_PLANTEL and LeyesPais.motivo_fichaje(cl, j, m.clubes) == ""

## Los válidos de una lista, sin los clubes que ya te tienen una oferta encima de la mesa.
static func filtrar(c: CarreraJugador, m: Mundo, j: Jugador, lista: Array) -> Array:
	var ya := {}
	for o: Dictionary in c.ofertas:
		ya[String(o.get("club_id", ""))] = true
	return lista.filter(func(cl: Club) -> bool: return not ya.has(cl.id) and destino_valido(m, cl, j))

## Los clubes que te aceptarían cedido: de tu país, con 8-20 puntos menos de reputación y sitio para ti.
static func destinos_cesion(c: CarreraJugador, m: Mundo) -> Array:
	var j := c.jugador(m)
	var origen := c.club(m)
	var out: Array = []
	if j == null or origen == null or cedido(c):
		return out
	for cl: Club in m.clubes.values():
		if cl != origen and cl.pais == origen.pais and cl.rep <= origen.rep - 8 and cl.rep >= origen.rep - 20 and destino_valido(m, cl, j):
			out.append(cl)
	return out

static func cedido(c: CarreraJugador) -> bool:
	return c.ruta.get("cesion") is Dictionary and not (c.ruta["cesion"] as Dictionary).is_empty()

## La cesión «a préstamo hasta final de temporada»: se anota de dónde vienes para volver al cerrar el año.
static func ceder(c: CarreraJugador, m: Mundo) -> bool:
	var candidatos := destinos_cesion(c, m)
	if candidatos.is_empty():
		return false
	var j := c.jugador(m)
	var origen := c.club(m)
	var destino: Club = candidatos[c._rng.randi() % candidatos.size()]
	c.ruta["cesion"] = {"de": origen.id, "club": destino.id, "anio": m.anio}
	_mover(c, m, j, origen, destino, 62)
	c.historial.append({"anio": m.anio, "semana": m.semana, "titulo": "Cesión", "eleccion": "Cedido a %s", "eleccion_datos": [destino.nombre]})
	return true

## Fin de temporada: el cedido vuelve a su club (si sigue existiendo y le cabe; si no, se queda donde está).
static func volver_de_cesion(c: CarreraJugador, m: Mundo) -> bool:
	if not cedido(c):
		return false
	var ces: Dictionary = c.ruta["cesion"]
	c.ruta.erase("cesion")
	var j := c.jugador(m)
	var casa: Club = m.clubes.get(String(ces.get("de", "")))
	var donde := c.club(m)
	if j == null or casa == null or donde == null or donde == casa or casa.plantilla.size() >= Cantera.TOPE_PLANTEL:
		return false
	_mover(c, m, j, donde, casa, 55)
	c.historial.append({"anio": m.anio, "semana": m.semana, "titulo": "Vuelta de la cesión", "eleccion": "Vuelves a %s", "eleccion_datos": [casa.nombre]})
	return true

## El cambio de club en sí: plantel, dorsal, relación con el DT nueva, sin brazalete (es de un club, R-10) y
## recién llegado (`asentado()` vuelve a contar desde aquí, R-06).
static func _mover(c: CarreraJugador, _m: Mundo, j: Jugador, origen: Club, destino: Club, relacion: int) -> void:
	origen.soltar(j)
	if not c.clubes_pasados.has(origen.nombre):
		c.clubes_pasados.append(origen.nombre)
	destino.fichar(j)
	j.dorsal = CarreraJugador._dorsal_libre(destino)
	c.relacion_dt = relacion
	c.capitan = false
	c.ruta["pj_llegada"] = c.pj_carrera
