class_name CarreraMisiones
extends RefCounted
## LAS MISIONES DE CADA CAPÍTULO DE «LA RUTA» (13-11-2026): tres metas por
## capítulo que dicen hacia dónde ir. Al cumplir las tres de un capítulo: un
## punto de talento extra y experiencia. Se cobran una vez
## (`ruta["misiones_hechas"]`), al cerrar la semana.

const XP_CAPITULO := 100
## capítulo -> [[tipo, meta] × 3]
const MISIONES := {
	"Promesa": [["pj", 5], ["media", 62], ["seguidores", 1000]],
	"Revelación": [["pj", 25], ["aporte", 5], ["fama", 20]],
	"Indiscutible": [["pj", 60], ["media", 70], ["premios", 1]],
	"Figura": [["aporte", 40], ["fama", 45], ["duelos", 1]],
	"Estrella": [["pj", 150], ["media", 80], ["caps", 1]],
	"Ídolo": [["aporte", 120], ["fama", 80], ["premios", 6]],
	"Leyenda": [["pj", 350], ["caps", 30], ["media", 88]],
}
const TEXTOS := {
	"pj": "Juega %d partidos como profesional",
	"media": "Llega a una media de %d",
	"seguidores": "Consigue %d seguidores",
	"aporte": "Suma %d goles y asistencias",
	"aporte_por": "Deja %d porterías a cero",
	"fama": "Alcanza %d de fama",
	"premios": "Gana %d premios de fin de temporada",
	"duelos": "Gana %d duelos de temporada a tu rival",
	"caps": "Juega %d partidos con tu selección",
}
const TEXTOS_UNO := {   ## cuando la meta es 1
	"premios": "Gana %d premio de fin de temporada",
	"duelos": "Gana %d duelo de temporada a tu rival",
	"caps": "Juega %d partido con tu selección",
}

static func _es_portero(c: CarreraJugador, m: Mundo) -> bool:
	var j := c.jugador(m)
	return j != null and j.es_portero()

## Lo que llevas de una misión.
static func valor(c: CarreraJugador, m: Mundo, tipo: String) -> int:
	var j := c.jugador(m)
	var r := CarreraRuta.asegurar(c)
	match tipo:
		"pj": return c.pj_carrera
		"media": return j.ovr if j != null else 0
		"seguidores": return c.seguidores
		"fama": return c.fama
		"caps": return c.caps
		"duelos": return int(r["duelos_ganados"])
		"premios": return (r["premios"] as Array).size() if r.get("premios") is Array else 0
		"aporte":
			if _es_portero(c, m):
				return c.vallas_invictas
			var asist := int(c.stats_temp["asist"])
			for t: Variant in c.temporadas:
				if t is Dictionary:
					asist += int((t as Dictionary).get("asist", 0))
			return c.goles_carrera + asist
	return 0

## El portero no vive de goles: la meta de «aporte» baja a un tercio.
static func meta(c: CarreraJugador, m: Mundo, mision: Array) -> int:
	if String(mision[0]) == "aporte" and _es_portero(c, m):
		return maxi(2, int(int(mision[1]) / 3.0))
	## Un defensa marca y asiste poco (sonda: 5 entre goles y asistencias le costó cinco temporadas): la mitad.
	var j := c.jugador(m)
	if String(mision[0]) == "aporte" and j != null and j.pos == "DEF":
		return maxi(2, int(int(mision[1]) / 2.0))
	return int(mision[1])

static func texto(c: CarreraJugador, m: Mundo, mision: Array) -> String:
	var clave := String(mision[0])
	if clave == "aporte" and _es_portero(c, m):
		clave = "aporte_por"
	var cuanto := meta(c, m, mision)
	return Idiomas.t(String((TEXTOS_UNO if cuanto == 1 and TEXTOS_UNO.has(clave) else TEXTOS)[clave])) % cuanto

static func cumplida(c: CarreraJugador, m: Mundo, mision: Array) -> bool:
	return valor(c, m, String(mision[0])) >= meta(c, m, mision)

static func _hechas(c: CarreraJugador) -> Dictionary:
	var r := CarreraRuta.asegurar(c)
	if not r.get("misiones_hechas") is Dictionary:
		r["misiones_hechas"] = {}
	return r["misiones_hechas"]

static func cobrada(c: CarreraJugador, capitulo: String) -> bool:
	return _hechas(c).has(capitulo)

## El capítulo cuyas misiones se enseñan: el más antiguo sin cobrar de los
## que ya alcanzaste (o el actual si están todos cobrados).
static func capitulo_en_curso(c: CarreraJugador) -> String:
	var nivel := CarreraRuta.nivel(c)
	for cap: Array in CarreraRuta.CAPITULOS:
		if nivel >= int(cap[0]) and not cobrada(c, String(cap[1])):
			return String(cap[1])
	return String(CarreraRuta.capitulo(c)[1])

## Cobra los capítulos alcanzados con sus tres misiones cumplidas. Devuelve
## los nombres de los cobrados ahora.
static func revisar(c: CarreraJugador, m: Mundo) -> Array:
	var out: Array = []
	var nivel := CarreraRuta.nivel(c)
	for cap: Array in CarreraRuta.CAPITULOS:
		var nombre := String(cap[1])
		if nivel < int(cap[0]) or cobrada(c, nombre):
			continue
		var todas := true
		for mi: Array in MISIONES[nombre]:
			if not cumplida(c, m, mi):
				todas = false
		if todas:
			_hechas(c)[nombre] = true
			var r := CarreraRuta.asegurar(c)
			r["puntos"] = int(r["puntos"]) + 1
			CarreraRuta.sumar_xp(c, XP_CAPITULO)
			CarreraRuta._grada(c, "🏅", "Misiones de «%s» cumplidas: un punto de talento extra.", [Idiomas.t(nombre)])
			out.append(nombre)
	return out
