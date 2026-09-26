class_name Politica
extends RefCounted
## POLÍTICA Y ESTADO (26-9-2026, plan maestro C15). Pedido: *"elecciones según
## la estructura de cada país, con el mentor que explica"* y gobiernos que
## influyen en el fútbol y la ciudad.
##
## REGLA DE ESTE MÓDULO: todos los partidos y todas las personas son FICTICIOS,
## y las posturas son NEUTRAS y solo sobre lo que toca al club (obras, seguridad
## en los estadios, impuestos, deporte base). Nada de izquierdas ni derechas,
## nada de partidos reales: el juego se publica y es terreno sensible.
##
## Lo que SÍ es real es la ESTRUCTURA del Estado de cada país: si es república
## presidencial o parlamentaria, monarquía parlamentaria o absoluta, y cada
## cuántos años se vota. Eso es lo que el mentor explica la primera vez.
##
## Cómo funciona:
##   - cada país tiene un gobierno con una postura; la postura se nota en el club
##     cada cuatro semanas (una subvención, una tasa, una rebaja...);
##   - cuando toca, hay elecciones: aviso de campaña dos semanas antes, resultado
##     la semana de la votación y el gobierno nuevo trae su postura;
##   - en Arabia Saudí no hay elecciones nacionales (monarquía absoluta): el
##     mentor lo explica y el gobierno no cambia por votación.
## Sorteos por hash: no se consume `Azar`.

signal noticia(titulo: String, cuerpo: String)
signal movimiento(concepto: String, monto: int)
signal mentor(titulo: String, texto: String)

## pais -> [sistema, años de mandato, cargo que se elige, jefe de Estado]
const ESTRUCTURA := {
	"CHI": ["presidencial", 4, "presidente de la República", "el presidente"],
	"ARG": ["presidencial", 4, "presidente de la Nación", "el presidente"],
	"URU": ["presidencial", 5, "presidente de la República", "el presidente"],
	"PAR": ["presidencial", 5, "presidente de la República", "el presidente"],
	"BRA": ["presidencial", 4, "presidente de la República", "el presidente"],
	"BOL": ["presidencial", 5, "presidente del Estado", "el presidente"],
	"PER": ["presidencial", 5, "presidente de la República", "el presidente"],
	"ECU": ["presidencial", 4, "presidente de la República", "el presidente"],
	"COL": ["presidencial", 4, "presidente de la República", "el presidente"],
	"VEN": ["presidencial", 6, "presidente de la República", "el presidente"],
	"MEX": ["presidencial", 6, "presidente de la República", "el presidente"],
	"USA": ["presidencial", 4, "presidente", "el presidente"],
	"KOR": ["presidencial", 5, "presidente", "el presidente"],
	"FRA": ["semipresidencial", 5, "presidente de la República", "el presidente"],
	"EGY": ["semipresidencial", 6, "presidente", "el presidente"],
	"ESP": ["monarquia_parlamentaria", 4, "Congreso (y con él, el presidente del Gobierno)", "el rey"],
	"ENG": ["monarquia_parlamentaria", 5, "Parlamento (y con él, el primer ministro)", "el rey"],
	"JPN": ["monarquia_parlamentaria", 4, "Dieta (y con ella, el primer ministro)", "el emperador"],
	"AUS": ["monarquia_parlamentaria", 3, "Parlamento (y con él, el primer ministro)", "el monarca británico, representado por un gobernador general"],
	"MAR": ["monarquia_constitucional", 5, "Parlamento (y con él, el jefe de Gobierno)", "el rey, que conserva mucho poder"],
	"ITA": ["republica_parlamentaria", 5, "Parlamento (y con él, el presidente del Consejo)", "el presidente de la República, elegido por el Parlamento"],
	"GER": ["republica_parlamentaria", 4, "Bundestag (y con él, el canciller)", "el presidente federal, elegido por una asamblea"],
	"RSA": ["republica_parlamentaria", 5, "Parlamento (que elige al presidente)", "el presidente, elegido por el Parlamento"],
	"KSA": ["monarquia_absoluta", 0, "", "el rey"],
}

const EXPLICA := {
	"presidencial": "Aquí la gente vota directamente al presidente, que es a la vez jefe de Estado y de Gobierno. El Congreso se elige aparte y hace las leyes.",
	"semipresidencial": "Hay un presidente elegido por votación y un primer ministro que responde ante el Parlamento. Se reparten el poder.",
	"monarquia_parlamentaria": "El jefe de Estado es un monarca, pero no gobierna: se vota al Parlamento y la mayoría forma gobierno.",
	"monarquia_constitucional": "Se vota al Parlamento y de él sale el gobierno, pero el rey mantiene poderes importantes.",
	"republica_parlamentaria": "Se vota al Parlamento, y la mayoría elige al jefe del Gobierno. El presidente del país tiene un papel más simbólico.",
	"monarquia_absoluta": "No hay elecciones nacionales: el rey concentra el poder y nombra al gobierno. Los cambios llegan por decreto.",
}

## Las posturas: solo lo que toca al club, sin ideología.
## clave -> [nombre, descripción, efecto cada 4 semanas, valor base]
const POSTURAS := {
	"obras": ["Plan de obras públicas", "Invierte en accesos, transporte y estadios.", "subvencion_obras", 18000],
	"seguridad": ["Seguridad en los estadios", "Más policía en los partidos, pagada en parte por los clubes.", "tasa_seguridad", 9000],
	"austeridad": ["Cuentas ajustadas", "Baja los impuestos y recorta las ayudas.", "rebaja_impuestos", 7000],
	"deporte": ["Deporte para todos", "Subvenciona el deporte base y las canteras.", "subvencion_cantera", 12000],
}

## Partidos ficticios: nombres de objetos y paisaje, sin parecido con ninguno
## real. Cada país usa cuatro, elegidos por hash.
const PARTIDOS := ["Movimiento Faro", "Partido Cometa", "Unión Brújula", "Frente Colibrí",
	"Coalición Mirador", "Alianza Arce", "Partido Puente", "Movimiento Ancla", "Unión Horizonte",
	"Frente Veleta", "Partido Farol", "Coalición Glaciar"]

var gobiernos: Dictionary = {}   ## pais -> {partido, lider, postura, desde, proxima}
var explicado: Dictionary = {}   ## pais -> true
var campana: Dictionary = {}     ## pais -> [candidatos] durante la campaña

static func _h(t: String) -> int:
	return absi(t.hash())

static func partidos_de(pais: String) -> Array:
	var r: Array = []
	var h := _h("partidos|" + pais)
	var i := 0
	while r.size() < 4 and i < 40:
		var p: String = PARTIDOS[(h + i * 7) % PARTIDOS.size()]
		if not r.has(p):
			r.append(p)
		i += 1
	return r

## Un nombre ficticio del país, por hash y sin tocar `Azar`.
static func nombre_ficticio(pais: String, semilla: String) -> String:
	var n: Variant = Datos.tabla("NOMBRES")
	var a: Variant = Datos.tabla("APELLIDOS")
	var pools: Variant = Datos.tabla("POOLS_EU")
	if pools is Dictionary and (pools as Dictionary).has(pais):
		var par: Array = (pools as Dictionary)[pais]
		if par.size() >= 2 and not (par[0] as Array).is_empty():
			n = par[0]
			a = par[1]
	elif pais == "BRA" and Datos.tiene("NOMBRES_BRA"):
		n = Datos.tabla("NOMBRES_BRA")
		a = Datos.tabla("APELLIDOS_BRA")
	if not (n is Array) or (n as Array).is_empty():
		return "Candidato %d" % (_h(semilla) % 100)
	for k in 6:
		var h := _h("%s|%s|%d" % [pais, semilla, k])
		var nom := "%s %s" % [String(n[h % (n as Array).size()]), String(a[(h / 7) % (a as Array).size()])]
		if not Nombres.vetado(nom):
			return nom
	return "Candidato %d" % (_h(semilla) % 100)

static func sistema(pais: String) -> String:
	return String(ESTRUCTURA.get(pais, ["presidencial"])[0])

static func mandato(pais: String) -> int:
	return int(ESTRUCTURA.get(pais, ["", 4])[1])

## La semana de la votación (fija por país, entre la 30 y la 42).
static func semana_votacion(pais: String) -> int:
	return 30 + _h("voto|" + pais) % 13

## El gobierno de un país; si aún no existe, se crea (por hash).
func gobierno(pais: String, anio: int) -> Dictionary:
	if not gobiernos.has(pais):
		var ps := partidos_de(pais)
		var h := _h("gob|%s|%d" % [pais, anio])
		var m := mandato(pais)
		## Las elecciones anteriores fueron hace un número al azar (por hash) de
		## años: así no votan todos los países el mismo año.
		var hace := (h / 11) % maxi(m, 1)
		gobiernos[pais] = {
			"partido": ps[h % ps.size()],
			"lider": nombre_ficticio(pais, "lider%d" % (anio - hace)),
			"postura": String(POSTURAS.keys()[(h / 5) % POSTURAS.size()]),
			"desde": anio - hace,
			"proxima": (anio - hace + m) if m > 0 else 0,
		}
	return gobiernos[pais]

## El texto del mentor sobre el Estado de un país.
static func explicacion(pais: String) -> String:
	var e: Array = ESTRUCTURA.get(pais, ["presidencial", 4, "presidente", "el presidente"])
	var t := String(EXPLICA.get(String(e[0]), ""))
	if int(e[1]) > 0:
		t += " Se vota cada %d años: se elige %s. El jefe de Estado es %s." % [int(e[1]), String(e[2]), String(e[3])]
	t += " Los partidos y políticos del juego son inventados."
	return t

## Una vez por semana, para el país del club.
func semana(c: Club, anio: int, sem: int, prensa: Prensa) -> void:
	if c == null:
		return
	var pais := c.pais
	var g := gobierno(pais, anio)
	## Si el gobierno se creó con la votación del año ya pasada, se vota el
	## año que viene (nunca se queda un mandato sin elecciones).
	if mandato(pais) > 0 and int(g["proxima"]) < anio:
		g["proxima"] = anio
	if not explicado.has(pais):
		explicado[pais] = true
		mentor.emit("Cómo se gobierna %s" % pais, explicacion(pais))
	var sv := semana_votacion(pais)
	if int(g["proxima"]) == anio and mandato(pais) > 0:
		if sem == sv - 2:
			var ps := partidos_de(pais)
			var cands: Array = []
			for i in 3:
				var p: String = ps[(_h("cand|%s|%d" % [pais, anio]) + i) % ps.size()]
				cands.append({"partido": p, "lider": nombre_ficticio(pais, "cand%d|%d" % [anio, i]) if p != String(g["partido"]) else String(g["lider"]),
					"postura": String(POSTURAS.keys()[_h("post|%s|%s|%d" % [pais, p, anio]) % POSTURAS.size()])})
			campana[pais] = cands
			var lineas: Array[String] = []
			for x: Dictionary in cands:
				lineas.append("%s (%s): %s" % [String(x["lider"]), String(x["partido"]), String(POSTURAS[String(x["postura"])][0]).to_lower()])
			noticia.emit("🗳️ Campaña electoral", "En dos semanas se vota en %s. Candidatos: %s." % [pais, "; ".join(lineas)])
		elif sem == sv:
			var cands: Array = campana.get(pais, [])
			if cands.is_empty():
				cands = [{"partido": String(g["partido"]), "lider": String(g["lider"]), "postura": String(g["postura"])}]
			var gana: Dictionary = cands[_h("gana|%s|%d" % [pais, anio]) % cands.size()]
			var sigue := String(gana["partido"]) == String(g["partido"])
			gobiernos[pais] = {"partido": String(gana["partido"]), "lider": String(gana["lider"]),
				"postura": String(gana["postura"]), "desde": anio, "proxima": anio + mandato(pais)}
			campana.erase(pais)
			var pos: Array = POSTURAS[String(gana["postura"])]
			noticia.emit("🗳️ Elecciones en %s" % pais, "%s. Gobierna %s (%s). Su prioridad: %s — %s" % [
				"Repite el mismo partido" if sigue else "Cambio de gobierno", String(gana["lider"]),
				String(gana["partido"]), String(pos[0]).to_lower(), String(pos[1])])
	## El efecto de la postura, cada cuatro semanas.
	if sem % 4 == 0:
		_efecto(c, String(gobiernos[pais]["postura"]), prensa)

func _efecto(c: Club, postura: String, prensa: Prensa) -> void:
	var p: Array = POSTURAS.get(postura, [])
	if p.is_empty():
		return
	var monto := Eco.escalar(float(int(p[3])), float(c.rep))
	match String(p[2]):
		"subvencion_obras":
			c.mover_saldo(monto)
			movimiento.emit("Plan de obras del gobierno (accesos al estadio)", monto)
		"tasa_seguridad":
			c.mover_saldo(-monto)
			movimiento.emit("Tasa de seguridad en los estadios", -monto)
			if prensa != null:
				prensa.mover_animo(1)
		"rebaja_impuestos":
			c.mover_saldo(monto)
			movimiento.emit("Rebaja de impuestos", monto)
		"subvencion_cantera":
			c.mover_saldo(monto)
			movimiento.emit("Subvención al deporte base", monto)

func a_dic() -> Dictionary:
	return {"gob": gobiernos, "exp": explicado.keys(), "camp": campana}

func desde_dic(d: Dictionary) -> void:
	gobiernos = (d.get("gob", {}) as Dictionary).duplicate(true)
	explicado = {}
	for k: Variant in d.get("exp", []):
		explicado[String(k)] = true
	campana = (d.get("camp", {}) as Dictionary).duplicate(true)
