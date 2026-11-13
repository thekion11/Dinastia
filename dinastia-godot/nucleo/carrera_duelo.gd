class_name CarreraDuelo
extends RefCounted
## EL CORTE DEL DUELO (13-11-2026): a mitad de temporada se mira cómo va el duelo
## con tu rival. Si mandas, premio pequeño; si vas por detrás, nace el objetivo
## de REMONTARLO: ganarlo al final vale más. Usa las marcas de `CarreraEventosRuta`.

const XP_LIDER := 40
const XP_REMONTADA := 60
const MIN_PARTIDOS := 4
const CADUCA := 45   ## semanas: un corte más viejo es de otra temporada

## Se llama tras cada partido tuyo; hace el corte una sola vez por temporada.
static func corte(c: CarreraJugador, m: Mundo) -> void:
	var hace := CarreraEventosRuta.semanas_desde(c, m, "corte")
	if hace >= 0 and hace < CADUCA:
		return
	CarreraEventosRuta.quitar_marca(c, "remontada")   ## un corte viejo que nadie cerró (te quedaste sin rival)
	var o := CarreraRuta.rival(c, m)
	var liga := CarreraRuta._liga_de(m, c.club(m))
	if o == null or liga == null or int(c.stats_temp["pj"]) < maxi(MIN_PARTIDOS, int(liga.jornadas() / 2.0)):
		return
	var d := CarreraRuta.duelo(c, m)
	CarreraEventosRuta.aplicar(c, m, {"ruta_marca": "corte"})
	if int(d[0]) > int(d[1]):
		CarreraRuta.sumar_xp(c, XP_LIDER)
		CarreraRuta._grada(c, "🥊", "A mitad de temporada mandas en el duelo con %s: %d a %d.", [o.nombre, int(d[0]), int(d[1])])
	else:
		CarreraEventosRuta.aplicar(c, m, {"ruta_marca": "remontada"})
		CarreraRuta._grada(c, "🥊", "%s manda en el duelo a mitad de temporada: %d a %d. Si lo remontas, vale más.", [o.nombre, int(d[1]), int(d[0])])

## ¿Hay un duelo por remontar esta temporada?
static func por_remontar(c: CarreraJugador) -> bool:
	return CarreraEventosRuta.tiene_marca(c, "remontada")

## Al cerrar el duelo: la experiencia extra por remontarlo, y se limpia el corte.
static func cierre(c: CarreraJugador, gane: bool) -> int:
	var extra := XP_REMONTADA if gane and por_remontar(c) else 0
	if extra > 0:
		CarreraLogros.sumar(c, "remontadas")
	CarreraEventosRuta.quitar_marca(c, "corte")
	CarreraEventosRuta.quitar_marca(c, "remontada")
	return extra
