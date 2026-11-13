class_name CarreraPatrocinio
extends RefCounted
## EL CONTRATO DE BOTAS DE «LA RUTA» (13-11-2026): al ganar fama una marca
## (ficticia) te ofrece contrato y eliges con cuál firmar. Cada una premia una
## forma de jugar con experiencia y seguidores extra en cada partido; el
## contrato sube de categoría con la fama (15, 40 y 70).
## Se guarda en `ruta["patro"]` = {marca, nivel}.

const FAMA := [15, 40, 70]
## marca -> [nombre, lo que premia]
const MARCAS := {
	"rayo": ["Rayo", "Premia el gol: experiencia y seguidores por cada gol o asistencia (portero: por cada portería a cero)."],
	"roca": ["Roca", "Premia la regularidad: experiencia y seguidores por cada partido con nota 7 o más."],
}
const TITULOS := ["Una marca de botas llama a tu puerta", "Te mejoran el contrato de botas", "Contrato de botas de estrella"]
const TEXTOS := [
	"Dos marcas quieren calzarte. Rayo paga por lo que brilla; Roca, por no fallar nunca. Solo puedes firmar con una.",
	"Tu nombre ya vende. Las dos marcas suben la oferta: los premios por partido valen un 50 % más.",
	"Eres imagen de portada. Las dos marcas ponen sobre la mesa su mejor contrato: los premios por partido valen el doble.",
]

static func _estado(c: CarreraJugador) -> Dictionary:
	var r := CarreraRuta.asegurar(c)
	if not r.get("patro") is Dictionary:
		r["patro"] = {}
	return r["patro"]

static func marca(c: CarreraJugador) -> String:
	var m := String(_estado(c).get("marca", ""))
	return m if MARCAS.has(m) else ""

static func nivel(c: CarreraJugador) -> int:
	return clampi(int(_estado(c).get("nivel", 0)), 0, FAMA.size()) if marca(c) != "" else 0

## «Rayo II»: lo que se enseña en tu cromo ("" sin contrato).
static func etiqueta(c: CarreraJugador) -> String:
	if marca(c) == "":
		return ""
	return "👟 %s %s" % [String(MARCAS[marca(c)][0]), ["I", "II", "III"][nivel(c) - 1]]

## La oferta que toca (un evento único por categoría), si tu fama da para ella.
static func eventos(c: CarreraJugador) -> Array:
	var sig := nivel(c)
	if sig >= FAMA.size() or c.fama < int(FAMA[sig]) or c.hitos.has("patro_%d" % (sig + 1)):
		return []
	return [c._ev("patro_%d" % (sig + 1), String(TITULOS[sig]), String(TEXTOS[sig]),
		[c._op("Firmas con Rayo (premia goles y asistencias).", {"patro": "rayo", "seguidores": 300, "fama": 1}),
		c._op("Firmas con Roca (premia los partidos de 7 o más).", {"patro": "roca", "seguidores": 300, "fama": 1})], true)]

## Lo llama `CarreraJugador.resolver` al elegir una opción con «patro».
static func firmar(c: CarreraJugador, que_marca: String) -> void:
	if not MARCAS.has(que_marca):
		return
	var e := _estado(c)
	e["nivel"] = mini(FAMA.size(), nivel(c) + 1)
	e["marca"] = que_marca

## Lo que paga el contrato por un partido: [experiencia, seguidores].
static func premio(c: CarreraJugador, d: Dictionary, es_portero: bool) -> Array:
	var n := nivel(c)
	if n <= 0:
		return [0, 0]
	var veces := 0
	if marca(c) == "rayo":
		veces = int(d.get("goles", 0)) + int(d.get("asist", 0))
		if es_portero and d.has("encajados") and int(d["encajados"]) == 0 and int(d.get("minutos", 90)) >= 60:
			veces += 1
	elif float(d.get("nota", 0.0)) >= 7.0:
		veces = 1
	var mult := 1.0 + 0.5 * float(n - 1)
	var base_xp := 20 if marca(c) == "rayo" else 25
	return [int(float(veces * base_xp) * mult), int(float(veces * 90) * mult)]
