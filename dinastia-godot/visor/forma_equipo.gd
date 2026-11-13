class_name FormaEquipo
extends RefCounted
## LO QUE `_forma` CALCULA POR EQUIPO, UNA VEZ POR PASO (13-11-2026, rendimiento). `_forma(p, en_posesion)` mezclaba para CADA jugador valores que solo dependen del equipo y de si ataca
## (el balón con retardo, los pesos, la línea, la mentalidad con urgencia, la amplitud y el desvío al lado fuerte del rival): ~10 llamadas por jugador y paso. Mientras dura `_ia_equipos`
## (`abrir` … `cerrar`) nada de lo que leen cambia (pizarras, marcador, reloj, balón y los estados de colocación y adaptación se actualizan ANTES, en `paso`), así que el resultado es
## el mismo y se calcula una vez por equipo y estado de posesión. Fuera de esa fase (`vivo` = false) se calcula siempre, como antes.

static var vivo := false
static var _c := {}   ## 2 × (0 local / 1 visita) + en_posesion → [balón con retardo, pesos, línea, mentalidad, amplitud, desvío x]

static func abrir() -> void:
	_c.clear()
	vivo = true

static func cerrar() -> void:
	vivo = false

static func de(m: MotorJugable, loc: bool, en_posesion: bool) -> Array:
	var k := (0 if loc else 2) + (1 if en_posesion else 0)
	if vivo and _c.has(k):
		return _c[k]
	var r := [MotorColocacion.balon_lento(m, loc), MotorColocacion.pesos(m, loc, en_posesion),
		float(m._tac(loc, "linea") - 1) + MotorTacticaViva.f(m, loc, "linea"),   ## + estilo del club (U8)
		float(m._tac(loc, "mentalidad") - 1) + MotorTacticaViva.urgencia(m, loc),   ## + marcador y reloj (U2, 01-11)
		float(m._tac(loc, "amplitud") - 1) + MotorTacticaViva.f(m, loc, "amplitud"),
		MotorAdaptacion.desvio_x(m, loc, en_posesion)]   ## cubre el lado fuerte del rival (3-11)
	if vivo:
		_c[k] = r
	return r
