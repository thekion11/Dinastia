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
	"mejor_club": ["Jugador del año del club", "La mejor nota media de la plantilla.", 100, 3],
	"once_ideal": ["Once ideal de la liga", "Nota media de 7,3 o más en 20 partidos.", 150, 5],
	"muro": ["Guante de la liga", "Diez porterías a cero o más.", 120, 4],
	"hierro": ["Hombre de hierro", "Jugaste 30 partidos o más.", 60, 1],
	"duelo": ["Ganador del duelo", "Le ganaste la temporada a tu rival.", 0, 0],
	"salto": ["Gran salto", "Tu media subió 4 puntos o más en un año.", 80, 2],
}

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
	var mejor_nota := pj >= 10
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
	return out

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
	if not r.get("premios") is Array:
		r["premios"] = []
	for id2: String in ids:
		(r["premios"] as Array).append({"anio": m.anio, "id": id2})
	var s: Dictionary = c.stats_temp
	var resumen := {"anio": m.anio, "club": club.nombre if club != null else "", "pj": int(s["pj"]), "goles": int(s["goles"]),
		"asist": int(s["asist"]), "nota": snappedf(c.nota_media(), 0.01), "ovr": j.ovr if j != null else 0,
		"sube": (j.ovr - c.ovr_inicio) if j != null and c.ovr_inicio >= 0 else 0, "premios": ids,
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
