class_name CarreraPremios
extends RefCounted
## EL CIERRE DE TEMPORADA DE «LA RUTA» (13-11-2026): tu año en una página y los
## premios que te ganaste, cada uno con su experiencia y su fama. Se guarda en
## `ruta["temporada"]` (el último cierre, para enseñarlo una vez) y en
## `ruta["premios"]` (el palmarés personal de toda la carrera).

## id -> [nombre, por qué, experiencia, fama]
const PREMIOS := {
	"revelacion": ["Revelación del año", "Tu primera temporada completa, y a buen nivel.", 120, 4],
	"goleador_club": ["Goleador del equipo", "Nadie marcó más que tú en tu club.", 100, 3],
	"mejor_club": ["Jugador del año del club", "La mejor nota media de la plantilla (6,8 o más).", 100, 3],
	"once_ideal": ["Once ideal de la liga", "Nota media de 7,3 o más en 20 partidos.", 150, 5],
	"muro": ["Guante de la liga", "Diez porterías a cero o más.", 120, 4],
	"hierro": ["Hombre de hierro", "Jugaste 30 partidos o más.", 60, 1],
	"duelo": ["Ganador del duelo", "Le ganaste la temporada a tu rival.", 0, 0],
	"salto": ["Gran salto", "Tu media subió 4 puntos o más en un año.", 80, 2],
	## (13-11 noche, dueño) Los premios de la liga, de las copas y el mundial.
	"goleador_liga": ["Máximo goleador de la liga", "Nadie marcó más que tú en tu liga.", 180, 5],
	"asistidor_liga": ["Máximo asistidor de la liga", "Nadie dio más asistencias que tú en tu liga.", 150, 4],
	"portero_liga": ["Mejor portero de la liga", "El portero con mejor nota media de tu liga.", 170, 5],
	"mvp_liga": ["Mejor jugador de la liga", "La mejor nota media de toda tu liga.", 220, 6],
	"mvp_copa": ["Mejor jugador de la copa", "Tu club ganó la copa y fuiste su mejor jugador.", 160, 4],
	"mvp_continental": ["Mejor jugador del torneo continental", "Tu club ganó el torneo continental y fuiste su mejor jugador.", 260, 7],
	"mundial": ["Mejor jugador del mundo", "Nadie en el planeta hizo una temporada como la tuya.", 400, 10],
}
## Experiencia y fama por cada TROFEO que gana tu club: [liga, copa, continental, otro].
const XP_TROFEO := {"liga": [200, 4], "copa": [150, 3], "continental": [300, 6], "otro": [120, 2]}
## El bono de experiencia al alcanzar una racha de partidos con nota 7 o más.
const BONO_RACHA := {3: 30, 5: 60, 8: 100, 12: 160}
const ANIOS_CAPITAN := 3
const MEJORES_CAPITAN := 3
const PROB_CAPITAN := 0.30           ## por temporada, siendo apto
const PROB_CAPITAN_TALENTO := 0.45   ## lo que suma el talento «Brazalete»

static func _nota_de(o: Jugador) -> float:
	if o.notas.size() < 10:
		return 0.0
	var s := 0.0
	for n: float in o.notas:
		s += n
	return s / float(o.notas.size())

## Los premios que te tocan esta temporada (ids). No cambia nada.
static func ganados(c: CarreraJugador, m: Mundo, gano_duelo: bool) -> Array:
	var j := c.jugador(m)
	var club := c.club(m)
	var out: Array = []
	if j == null or club == null:
		return out
	var s: Dictionary = c.stats_temp
	var pj := int(s["pj"])
	var nota := c.nota_media()
	if c.temporadas.is_empty() and pj >= 15 and nota >= 6.6:
		out.append("revelacion")
	var mas_goles := true
	var mejor_nota := pj >= 10 and nota >= 6.8
	for o: Jugador in club.plantilla:
		if o == j:
			continue
		if o.goles >= int(s["goles"]):
			mas_goles = false
		if _nota_de(o) >= nota:
			mejor_nota = false
	if mas_goles and int(s["goles"]) >= 5:
		out.append("goleador_club")
	if mejor_nota:
		out.append("mejor_club")
	if pj >= 20 and nota >= 7.3:
		out.append("once_ideal")
	if j.es_portero() and c.vallas_invictas >= 10:
		out.append("muro")
	if pj >= 30:
		out.append("hierro")
	if gano_duelo:
		out.append("duelo")
	if c.ovr_inicio >= 0 and j.ovr - c.ovr_inicio >= 4:
		out.append("salto")
	out.append_array(_de_la_liga(c, m, j, club, mejor_nota))
	return out

## Los premios que se deciden contra toda tu liga, las copas que ganó tu club y el mundial.
static func _de_la_liga(c: CarreraJugador, m: Mundo, j: Jugador, club: Club, mejor_del_club: bool) -> Array:
	var out: Array = []
	var s: Dictionary = c.stats_temp
	var pj := int(s["pj"])
	var nota := c.nota_media()
	var liga := CarreraRuta._liga_de(m, club)
	if liga != null and pj >= 15:
		var mas_goles := int(s["goles"]) >= 8
		var mas_asist := int(s["asist"]) >= 6
		var mejor_nota := nota >= 7.0
		var mejor_portero := j.es_portero() and nota >= 6.7
		for cl: Club in liga.clubes:
			for o: Jugador in cl.plantilla:
				if o == j:
					continue
				mas_goles = mas_goles and o.goles < int(s["goles"])
				mas_asist = mas_asist and o.asistencias < int(s["asist"])
				mejor_nota = mejor_nota and _nota_de(o) < nota
				mejor_portero = mejor_portero and not (o.es_portero() and _nota_de(o) >= nota)
		for par: Array in [["goleador_liga", mas_goles], ["asistidor_liga", mas_asist], ["portero_liga", mejor_portero], ["mvp_liga", mejor_nota]]:
			if bool(par[1]):
				out.append(String(par[0]))
	var clases := {}
	for t: Dictionary in trofeos(m, club):
		clases[String(t["clase"])] = true
	if mejor_del_club and clases.has("copa"):
		out.append("mvp_copa")
	if mejor_del_club and clases.has("continental"):
		out.append("mvp_continental")
	if pj >= 25 and nota >= 7.5 and j.ovr >= 84 and _mejor_del_mundo(m, j, _puntos_mundial(nota, int(s["goles"]), int(s["asist"]), clases.size())):
		out.append("mundial")
	return out

static func _puntos_mundial(nota: float, goles: int, asist: int, titulos: int) -> float:
	return nota * 10.0 + float(goles + asist) * 0.3 + float(titulos) * 3.0

static func _mejor_del_mundo(m: Mundo, j: Jugador, mios: float) -> bool:
	for cl: Club in m.clubes.values():
		for o: Jugador in cl.plantilla:
			if o != j and o.notas.size() >= 20 and _puntos_mundial(_nota_de(o), o.goles, o.asistencias, 0) >= mios:
				return false
	return true

## Los trofeos que ganó ESTE AÑO el club: [{nombre, clase}] (clase: liga, copa, continental u otro).
static func trofeos(m: Mundo, club: Club) -> Array:
	var out: Array = []
	if club == null:
		return out
	var vistos := {}
	var liga := CarreraRuta._liga_de(m, club)
	if liga != null:
		var t: Array = liga.tabla()
		if not t.is_empty() and t[0]["club"] == club and liga.jornada_actual >= liga.jornadas():
			out.append({"nombre": liga.nombre, "clase": "liga"})
			vistos[liga.nombre] = true
	if m.copa != null and m.copa.campeon == club:
		out.append({"nombre": m.copa.nombre, "clase": "copa"})
		vistos[m.copa.nombre] = true
	for k: Variant in m.continentales:
		var ct: Variant = m.continentales[k]
		if ct != null and ct.get("campeon") == club:
			out.append({"nombre": String(ct.get("nombre")) if ct.get("nombre") != null else str(k), "clase": "continental"})
			vistos[String(out[-1]["nombre"])] = true
	for p: Dictionary in m.palmares_mundo:
		if int(p.get("anio", 0)) == m.anio and String(p.get("club", "")) == club.id and not vistos.has(String(p.get("torneo", ""))):
			out.append({"nombre": String(p["torneo"]), "clase": "otro"})
			vistos[String(p["torneo"])] = true
	return out

## El bono por RACHA: al llegar a 3, 5, 8 y 12 partidos seguidos con nota 7 o más. Devuelve la experiencia dada.
static func bono_racha(c: CarreraJugador) -> int:
	var r := CarreraRuta.asegurar(c)
	var bono := int(BONO_RACHA.get(int(r["racha"]), 0))
	if bono > 0:
		CarreraRuta.sumar_xp(c, bono)
		CarreraRuta._grada(c, "🔥", "Racha de %d partidos a gran nivel.", [int(r["racha"])])
		if r.get("ultimo") is Dictionary:
			(r["ultimo"] as Dictionary)["bono_racha"] = bono
	return bono

## Temporadas completas seguidas en tu club de hoy.
static func anios_en_club(c: CarreraJugador, m: Mundo) -> int:
	var club := c.club(m)
	var n := 0
	for i in range(c.temporadas.size() - 1, -1, -1):
		if club == null or String((c.temporadas[i] as Dictionary).get("club", "")) != club.nombre:
			break
		n += 1
	return n

## La posibilidad de que te den el brazalete al cerrar una temporada en la que ya eres apto.
static func prob_capitan(c: CarreraJugador) -> float:
	return clampf(PROB_CAPITAN + (PROB_CAPITAN_TALENTO if CarreraRuta.tiene(c, "brazalete") else 0.0) + float(c.relacion_dt - 50) * 0.002, 0.05, 0.95)

## (13-11 noche, dueño) El brazalete pide tres años en el club y estar entre los tres de más media de la plantilla.
static func apto_capitan(c: CarreraJugador, m: Mundo) -> bool:
	var j := c.jugador(m)
	var club := c.club(m)
	if j == null or club == null or anios_en_club(c, m) < ANIOS_CAPITAN:
		return false
	var mejores := 0
	for o: Jugador in club.plantilla:
		if o != j and o.ovr > j.ovr:
			mejores += 1
	return mejores < MEJORES_CAPITAN

## Cierra el año ANTES de que la carrera borre sus números: reparte premios y
## deja el resumen para la pantalla. Devuelve el resumen.
static func cerrar(c: CarreraJugador, m: Mundo) -> Dictionary:
	var r := CarreraRuta.asegurar(c)
	var j := c.jugador(m)
	var club := c.club(m)
	var rival := CarreraRuta.rival(c, m)
	var marcador := CarreraRuta.duelo(c, m)
	var gano := CarreraRuta.cerrar_duelo(c, m)
	var ids := ganados(c, m, gano)
	var nivel_antes := CarreraRuta.nivel(c)
	for id: String in ids:
		CarreraRuta.sumar_xp(c, int(PREMIOS[id][2]))
		c.fama = mini(100, c.fama + int(PREMIOS[id][3]))
	## Los trofeos del club dan experiencia y fama si jugaste al menos cinco partidos.
	var copas: Array = trofeos(m, club) if int(c.stats_temp["pj"]) >= 5 else []
	for t: Dictionary in copas:
		t["xp"] = int(XP_TROFEO[String(t["clase"])][0])
		CarreraRuta.sumar_xp(c, int(t["xp"]))
		c.fama = mini(100, c.fama + int(XP_TROFEO[String(t["clase"])][1]))
	## El brazalete: cumpliendo lo que pide el club, cada fin de temporada hay una posibilidad; el talento la sube mucho.
	if not c.capitan and apto_capitan(c, m) and c._rng.randf() < prob_capitan(c):
		c.capitan = true
		CarreraRuta._grada(c, "©", "El vestuario te elige capitán.")
	if not r.get("premios") is Array:
		r["premios"] = []
	for id2: String in ids:
		(r["premios"] as Array).append({"anio": m.anio, "id": id2})
	var s: Dictionary = c.stats_temp
	var resumen := {"anio": m.anio, "club": club.nombre if club != null else "", "pj": int(s["pj"]), "goles": int(s["goles"]),
		"asist": int(s["asist"]), "nota": snappedf(c.nota_media(), 0.01), "ovr": j.ovr if j != null else 0,
		"sube": (j.ovr - c.ovr_inicio) if j != null and c.ovr_inicio >= 0 else 0, "premios": ids, "trofeos": copas,
		"rival": rival.nombre if rival != null else "", "duelo": marcador, "gano_duelo": gano,
		"niveles": CarreraRuta.nivel(c) - nivel_antes, "visto": false}
	r["temporada"] = resumen
	return resumen

## ¿Hay un cierre de temporada sin enseñar?
static func pendiente(c: CarreraJugador) -> bool:
	var t: Variant = CarreraRuta.asegurar(c).get("temporada")
	return t is Dictionary and not (t as Dictionary).is_empty() and not bool((t as Dictionary).get("visto", true))

## Cuántas veces ganaste cada premio en tu carrera: {id: veces}.
static func palmares(c: CarreraJugador) -> Dictionary:
	var out := {}
	var lista: Variant = CarreraRuta.asegurar(c).get("premios")
	if lista is Array:
		for p: Variant in lista:
			if p is Dictionary and PREMIOS.has(String((p as Dictionary).get("id", ""))):
				out[String(p["id"])] = int(out.get(String(p["id"]), 0)) + 1
	return out
