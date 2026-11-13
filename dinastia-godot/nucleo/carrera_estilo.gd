class_name CarreraEstilo
extends RefCounted
## TU ESTILO, TU CURVA Y TU FORMA (13-11-2026; el dueño pidió inspirarse en el modo
## jugador del FC 27: clases de jugador, perfiles de crecimiento y una media que
## se mueve con la forma. Esta es la versión propia de Dinastía).
##
##   - ESTILO: tres por línea. Sube dos atributos al nacer y tiene una jugada
##     favorita en «Los Momentos»: sale siempre y su zona es un 25 % más ancha.
##   - CURVA: precoz (crece rápido hasta los 21 y luego se frena; techo −2),
##     constante, o tardía (al revés; techo +2).
##   - FORMA: de −3 a +3 según tus últimas notas, tu ánimo y tu energía. Se suma
##     a tu media «de hoy»: ensancha o estrecha la zona de Los Momentos y mueve
##     tu nota cuando el partido se simula.
## Estado: `ruta["estilo"]` y `ruta["curva"]`.

## línea -> {id: [nombre, qué hace, {atributo: puntos}, jugada favorita]}
const ESTILOS := {
	"DEL": {
		"rematador": ["Rematador", "Vive del gol: +4 de tiro y +2 de físico. Su jugada: el remate en el área.", {"tir": 4, "fis": 2}, "remate"],
		"regateador": ["Regateador", "Encara y se va: +4 de regate y +2 de velocidad. Su jugada: el mano a mano.", {"reg": 4, "rit": 2}, "mano"],
		"cabeceador": ["Cabeceador", "Manda por arriba: +4 de físico y +2 de tiro. Su jugada: el cabezazo en el córner.", {"fis": 4, "tir": 2}, "cabezazo"],
	},
	"MED": {
		"organizador": ["Organizador", "El equipo pasa por él: +4 de pase y +2 de regate. Su jugada: el pase filtrado.", {"pas": 4, "reg": 2}, "pase"],
		"llegador": ["Llegador", "Pisa el área rival: +3 de tiro y +3 de velocidad. Su jugada: el remate en el área.", {"tir": 3, "rit": 3}, "remate"],
		"recuperador": ["Recuperador", "Roba y sale: +4 de defensa y +2 de físico. Su jugada: el robo en el medio.", {"def": 4, "fis": 2}, "robo"],
	},
	"DEF": {
		"muro": ["Muro", "Por ahí no pasa nadie: +4 de defensa y +2 de físico. Su jugada: la última entrada.", {"def": 4, "fis": 2}, "entrada"],
		"carrilero": ["Carrilero", "Toda la banda es suya: +4 de velocidad y +2 de pase. Su jugada: el centro desde la banda.", {"rit": 4, "pas": 2}, "centro"],
		"salida_limpia": ["Salida limpia", "Empieza la jugada: +4 de pase y +2 de defensa. Su jugada: el pase filtrado.", {"pas": 4, "def": 2}, "pase"],
	},
	"POR": {
		"felino": ["Felino", "Reflejos de gato: +4 de reflejos y +2 de estirada. Su jugada: el mano a mano del rival.", {"ref": 4, "div": 2}, "parada"],
		"dueno_del_area": ["Dueño del área", "Todo lo que cuelga es suyo: +4 de colocación y +2 de blocaje. Su jugada: el centro al área.", {"pos": 4, "par": 2}, "salida"],
		"libero": ["Portero líbero", "Juega como uno más: +4 de saque y +2 de velocidad. Su jugada: la salida con los pies.", {"saq": 4, "vel": 2}, "pies"],
	},
}
## id -> [nombre, qué hace, cambio del techo]
const CURVAS := {
	"precoz": ["Precoz", "Crece muy rápido hasta los 21 años y después se frena. Techo 2 puntos más bajo.", -2],
	"constante": ["Constante", "Crece al mismo paso toda la carrera.", 0],
	"tardia": ["Tardía", "Le cuesta arrancar, pero desde los 22 crece más que nadie. Techo 2 puntos más alto.", 2],
}
const ZONA_FAVORITA := 1.25

static func de_linea(linea: String) -> Dictionary:
	return ESTILOS.get(linea, ESTILOS["MED"])

static func estilo(c: CarreraJugador) -> String:
	return String(CarreraRuta.asegurar(c).get("estilo", ""))

static func curva(c: CarreraJugador) -> String:
	var k := String(CarreraRuta.asegurar(c).get("curva", "constante"))
	return k if CURVAS.has(k) else "constante"

## La ficha del estilo de `c` ([] si no eligió: carreras de antes del 13-11).
static func ficha(c: CarreraJugador, m: Mundo) -> Array:
	var j := c.jugador(m)
	return (de_linea(j.pos).get(estilo(c), []) as Array) if j != null else []

static func favorita(c: CarreraJugador, m: Mundo) -> String:
	var f := ficha(c, m)
	return String(f[3]) if f.size() >= 4 else ""

## Al nacer: los puntos del estilo y el techo de la curva. Una sola vez.
static func aplicar(c: CarreraJugador, m: Mundo, id_estilo: String, id_curva: String) -> void:
	var j := c.jugador(m)
	var r := CarreraRuta.asegurar(c)
	if j == null or String(r.get("estilo", "")) != "":
		return
	var linea := de_linea(j.pos)
	if not linea.has(id_estilo):
		id_estilo = String(linea.keys()[0])
	r["estilo"] = id_estilo
	r["curva"] = id_curva if CURVAS.has(id_curva) else "constante"
	for k: String in (linea[id_estilo][2] as Dictionary):
		if j.atributos.has(k):
			j.atributos[k] = mini(99, int(j.atributos[k]) + int(linea[id_estilo][2][k]))
	j.pot = clampi(j.pot + int(CURVAS[String(r["curva"])][2]), 60, 99)
	r["techo"] = j.pot
	j.ovr = j.media_en(j.pos_e)
	j.ovr_al_empezar = j.ovr
	j.tasar()

# ---------------------------------------------------------------- la curva

## ¿Edad en la que tu curva EMPUJA? (precoz: hasta los 21; tardía: desde los 22)
static func _empuja(c: CarreraJugador, j: Jugador) -> bool:
	return (curva(c) == "precoz" and j.edad <= 21) or (curva(c) == "tardia" and j.edad >= 22)

static func _frena(c: CarreraJugador, j: Jugador) -> bool:
	return (curva(c) == "precoz" and j.edad >= 22) or (curva(c) == "tardia" and j.edad <= 21)

## Semana en que la curva te deja sin mejora (una de cada cuatro cuando frena).
static func semana_floja(c: CarreraJugador, m: Mundo) -> bool:
	var j := c.jugador(m)
	return j != null and _frena(c, j) and CarreraRuta._azar(c, m, 11).randf() < 0.25

## Segunda oportunidad si el entreno no rindió (una de cada tres cuando empuja).
static func empujon(c: CarreraJugador, m: Mundo) -> bool:
	var j := c.jugador(m)
	return j != null and _empuja(c, j) and CarreraRuta._azar(c, m, 12).randf() < 0.34

# ---------------------------------------------------------------- la forma

## De −3 a +3: tus tres últimas notas, tu ánimo y tu energía.
static func forma(c: CarreraJugador, j: Jugador) -> int:
	if j == null:
		return 0
	var f := 0
	var notas: Array = c.stats_temp["notas"]
	if notas.size() >= 2:
		var s := 0.0
		var ultimas: Array = notas.slice(maxi(0, notas.size() - 3))
		for n: float in ultimas:
			s += n
		var media := s / float(ultimas.size())
		f += 2 if media >= 7.6 else (1 if media >= 7.0 else (-1 if media < 6.0 else 0))
	f += 1 if j.moral >= 85 else (-1 if j.moral < 45 else 0)
	f += -2 if c.energia < 30 else (-1 if c.energia < 50 else 0)
	return clampi(f, -3, 3)

## Tu media de hoy: la de siempre más la forma.
static func media_de_hoy(c: CarreraJugador, j: Jugador) -> int:
	return clampi(j.ovr + forma(c, j), 1, 99) if j != null else 0
