class_name FifaClubes
extends RefCounted
## LOS TORNEOS DE LA FIFA: MUNDIAL DE CLUBES Y COPA INTERCONTINENTAL (sesión 6, 10-11).
##
## Se arman al sortear los continentales de la temporada nueva (`Mundo._sortear_continentales`), con los campeones y los
## mejor clasificados de los continentales del año que acaba de cerrarse, y se juegan en las primeras semanas del año
## (ver `FormatosConti`, «mundial» e «interc»). Viven en `Mundo.continentales` junto a los demás: tienen su calendario, se
## guardan igual, y si tu club participa dirigirás sus partidos en directo.
##
## Plazas del Mundial de Clubes (el reparto de la FIFA, de 32): Europa 12, Sudamérica 6, Asia 4, África 4, Norte y Centro 4,
## Oceanía 1 y el anfitrión (el mejor club del país donde diriges). Si una confederación no tiene sitio para tantos, las plazas
## que sobran las ocupan los siguientes de las demás, por orden de la tabla.
const PLAZAS_MUNDIAL := {"ucl": 12, "lib": 6, "asia": 4, "afr": 4, "conc": 4, "oce": 1}
const ORDEN_INTERC := ["asia", "afr", "lib", "conc", "ucl"]

## Los clubes del Mundial de Clubes con los continentales cerrados `previos`.
static func convocados_mundial(m: Mundo, previos: Dictionary) -> Array[Club]:
	var elegidos: Array[Club] = []
	var vistos := {}
	var sobrantes: Array[Club] = []
	for k: String in PLAZAS_MUNDIAL:
		var t: Continental = previos.get(k)
		if t == null or t.campeon == null:
			continue
		var cupo := int(PLAZAS_MUNDIAL[k])
		var tomados := 0
		for c: Club in t.puestos():
			if vistos.has(c.id):
				continue
			if tomados < cupo:
				elegidos.append(c)
				vistos[c.id] = true
				tomados += 1
			else:
				sobrantes.append(c)
	## El anfitrión: el mejor club del país donde diriges que no esté ya.
	var mio := m.mi_club() if m != null else null
	if mio != null and not elegidos.is_empty():
		var anfitrion: Club = null
		for c: Club in m.clubes.values():
			if c.pais == mio.pais and c.division == 1 and not vistos.has(c.id) and (anfitrion == null or PlazasConti.mas_reputado(c, anfitrion)):
				anfitrion = c
		if anfitrion != null:
			elegidos.append(anfitrion)
			vistos[anfitrion.id] = true
	## Los huecos que quedan hasta 32, con los siguientes de cada confederación.
	for c: Club in sobrantes:
		if elegidos.size() >= FormatosConti.plazas("mundial"):
			break
		if not vistos.has(c.id):
			elegidos.append(c)
			vistos[c.id] = true
	return elegidos

## Los cinco de la Copa Intercontinental en el orden de su cuadro (Europa, al final: espera la final); si falta una confederación, salen menos.
static func campeones_interc(previos: Dictionary) -> Array[Club]:
	var salida: Array[Club] = []
	for k: String in ORDEN_INTERC:
		var t: Continental = previos.get(k)
		if t != null and t.campeon != null:
			salida.append(t.campeon)
	return salida

## Arma los dos torneos con los continentales del año anterior y los suma a los de esta temporada. Sin campeones (el primer
## año, o un mundo sin torneos), no hay torneos de la FIFA.
static func sumar(m: Mundo, previos: Dictionary) -> void:
	if previos.is_empty():
		return
	## El sorteo de los grupos es de la FIFA y no mueve el azar del resto del juego (ver `CopasMundo._aislado`).
	CopasMundo._aislado("fifa%d" % m.anio, func() -> void:
		var elegidos := convocados_mundial(m, previos)
		if elegidos.size() >= 2:
			var mundial := Continental.crear("mundial")
			mundial.preparar(elegidos)
			m.continentales["mundial"] = mundial
		var cinco := campeones_interc(previos)
		if cinco.size() == ORDEN_INTERC.size():   ## sin los cinco campeones no hay Challenger Cup ni Derbi de las Américas
			var interc := Continental.crear("interc")
			interc.preparar(cinco)
			m.continentales["interc"] = interc)

## El camino de un club en un torneo, una línea por partido: «Octavos de final: A 2-1 B (pen 4-3)».
static func relato(t: Continental, club: Club) -> Array[String]:
	var lineas: Array[String] = []
	for h: Dictionary in t.historial:
		for r: Dictionary in h["resultados"]:
			if r["local"] != club and r["visita"] != club:
				continue
			var penales: Array = r.get("penales", [])
			lineas.append("%s: %s %d-%d %s%s" % [
				r["ronda"], (r["local"] as Club).nombre, int(r["gl"]), int(r["gv"]), (r["visita"] as Club).nombre,
				(" (pen %d-%d)" % [int(penales[0]), int(penales[1])]) if penales.size() == 2 else ""])
	return lineas

## Lo que pasa cuando un torneo de la FIFA se corona (el semana a semana y el cierre de temporada lo llaman igual).
static func coronar(m: Mundo, t: Continental) -> void:
	if m == null or t == null or t.campeon == null:
		return
	var gana := t.campeon
	var mio := gana == m.mi_club()
	if t.clave == "mundial":
		if m.selecciones != null:
			m.selecciones.registrar_mundial(t, m.anio)
		return
	CopasMundo.anotar(m, gana.pais, Continental.nombre_conti(t.clave), gana)
	if mio:
		if m.logros != null:
			m.logros.celebrar_titulo(Continental.nombre_conti(t.clave))
		if m.roles != null:
			m.roles.sumar_trofeo("Copa Intercontinental")
	if m.prensa != null:
		m.prensa.noticia.emit("🌍 Copa Intercontinental %d" % m.anio, "Lo ganó %s (%s)." % [gana.nombre, gana.pais])
