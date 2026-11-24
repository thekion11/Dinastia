class_name CarreraRuta
extends "res://nucleo/carrera_ruta_p1.gd"
## (Parte 2 de 2 de `carrera_ruta.gd`.)

## Fin de temporada: si ganaste el duelo, experiencia y fama. Devuelve si ganaste.
static func cerrar_duelo(c: CarreraJugador, m: Mundo) -> bool:
	var r := asegurar(c)
	var d := duelo(c, m)
	var o := rival(c, m)
	var doble := CarreraEventosRuta.tiene_marca(c, "duelo_doble")
	CarreraEventosRuta.quitar_marca(c, "duelo_doble")   ## (16-11, informe R-11) la marca es de ESTA temporada, haya duelo o no
	if o == null or int(c.stats_temp["pj"]) == 0:
		CarreraDuelo.cierre(c, false)
		return false
	var gane := int(d[0]) > int(d[1])
	if gane:
		r["duelos_ganados"] = int(r["duelos_ganados"]) + 1
		CarreraPremios.fama_entera(c, 3)
		sumar_xp(c, XP_DUELO * (2 if doble else 1) + CarreraDuelo.cierre(c, true))
		_grada(c, "🏆", "Le ganaste el duelo de la temporada a %s.", [o.nombre])
		## A rival vencido, rival nuevo (y más fuerte).
		(r["rival"] as Dictionary).clear()
	else:
		_grada(c, "🥊", "%s te ganó el duelo de la temporada. Habrá revancha.", [o.nombre])
	CarreraDuelo.cierre(c, false)
	return gane
