class_name CarreraSemana
extends RefCounted
## LA SEMANA SIMULADA DE «LA RUTA» EN UN SOLO SITIO (16-11-2026, informe AAA cap. 7: R-05 y R-09). La usan la pantalla
## (`CarreraJugadorUI._cerrar_semana`), la sonda del ritmo y el banco, para que los tres jueguen la semana IGUAL.
##
##  - R-05: si la carrera te da titular, el once del club te lleva dentro (`once_para_partido`, como en el partido
##    jugable); y lo que el simulado ya anotó en tu ficha del mundo (goles, asistencias, partido, nota) no se repite.
##  - R-09: la copa y los continentales a medias se cierran ANTES de cerrar tu temporada (premios y trofeos los ven).

## Si eres titular y el once automático no te lleva, el club sale esta semana con `once_para_partido`. Devuelve el
## once elegido de antes (para `soltar_once`) o null si no hizo falta tocar nada.
static func meter_en_el_once(c: CarreraJugador, m: Mundo) -> Variant:
	var cl := c.club(m)
	var j := c.jugador(m)
	if cl == null or j == null or not c.es_titular(m) or cl.once().has(j):
		return null
	var previo: Array[String] = cl.once_elegido.duplicate()
	var ids: Array[String] = []
	for o: Jugador in c.once_para_partido(m):
		ids.append(o.id)
	cl.once_elegido = ids
	return previo

static func soltar_once(c: CarreraJugador, m: Mundo, previo: Variant) -> void:
	var cl := c.club(m)
	if cl != null and previo is Array:
		cl.once_elegido.assign(previo)

## Lo que dejó el simulado en tu ficha desde la foto `antes` ({goles, asist, pj}): {goles, asist, en_mundo}.
static func foto(j: Jugador) -> Dictionary:
	return {"goles": j.goles, "asist": j.asistencias, "pj": j.partidos} if j != null else {"goles": 0, "asist": 0, "pj": 0}

static func lo_del_mundo(j: Jugador, antes: Dictionary) -> Dictionary:
	if j == null:
		return {"goles": 0, "asist": 0, "en_mundo": false}
	return {"goles": j.goles - int(antes["goles"]), "asist": j.asistencias - int(antes["asist"]), "en_mundo": j.partidos > int(antes["pj"])}

## Fin de la temporada de tu futbolista: primero lo que quedó a medias del mundo (idempotente), luego tu cierre.
static func cerrar_temporada(c: CarreraJugador, m: Mundo) -> void:
	CierreTorneos.cerrar_pendientes(m)
	c.fin_de_temporada(m)
