class_name CarreraRuta
extends RefCounted
## «LA RUTA» (13-11-2026, mega misión del dueño: revolucionar el modo jugador).
## Lo que hace que la carrera de jugador se JUEGUE y no solo se lea:
##
##   - EXPERIENCIA Y NIVEL: cada partido, entreno y reto cumplido da experiencia;
##     cada nivel da un punto de TALENTO.
##   - TALENTOS: tres ramas (Crack, Ídolo, Líder) de tres talentos en cadena, con
##     efecto real en la carrera.
##   - RETOS DEL PARTIDO: tres por semana, según tu puesto, que pagan experiencia.
##   - RACHA: partidos seguidos con nota 7 o más; multiplica la experiencia.
##   - TU RIVAL: un joven de tu puesto y de tu liga; el duelo dura la temporada.
##   - EL TOQUE: el mini juego del entreno (lo juega la interfaz) decide si la
##     semana rinde: perfecto = mejora asegurada.
##   - CAPÍTULOS: de Promesa a Leyenda, según tu nivel.
##
## Todo el estado vive en `CarreraJugador.ruta` (un diccionario que se guarda
## con la partida). No usa el generador de la carrera ni `Azar`: sus sorteos
## salen de un generador propio sembrado con la semana, para no mover nada.

const RAMAS := {
	"crack": ["Crack", "⚽", "ffc93c"],
	"idolo": ["Ídolo", "⭐", "ff5a7a"],
	"lider": ["Líder", "🤝", "4ee6b0"],
}
## id -> [rama, orden en la rama, nombre, qué hace]
const TALENTOS := {
	"instinto": ["crack", 0, "Instinto", "Si el entreno no rinde, tienes una segunda oportunidad."],
	"pulmones": ["crack", 1, "Pulmones", "Los partidos te cansan un 30 % menos."],
	"sangre_fria": ["crack", 2, "Sangre fría", "Los retos del partido dan un 50 % más de experiencia."],
	"carisma": ["idolo", 0, "Carisma", "Ganas un 50 % más de seguidores por partido."],
	"portada": ["idolo", 1, "Portada", "+1 de fama cada partido con nota 7 o más."],
	"marca": ["idolo", 2, "Marca propia", "Las ofertas llegan con un 30 % más de sueldo."],
	"ejemplo": ["lider", 0, "Ejemplo", "+1 de relación con el DT cada semana."],
	"voz": ["lider", 1, "Voz del vestuario", "Ninguna decisión te quita más de 2 de relación con el DT."],
	"brazalete": ["lider", 2, "Brazalete", "Te dan el brazalete de capitán y el ánimo no te baja de 70."],
}
## [nivel mínimo, nombre, frase]
const CAPITULOS := [
	[1, "Promesa", "Nadie te conoce. Todavía."],
	[4, "Revelación", "Tu nombre empieza a sonar en la grada."],
	[8, "Titular", "El once se escribe contigo."],
	[13, "Figura", "Los rivales preparan el partido pensando en ti."],
	[19, "Estrella", "Tu camiseta es la que más se vende."],
	[26, "Ídolo", "Hay niños que llevan tu nombre a la espalda."],
	[34, "Leyenda", "El fútbol de tu país se cuenta contigo dentro."],
]
## id -> [texto, experiencia, líneas que lo pueden recibir]
const RETOS := {
	"minutos": ["Juega 60 minutos o más", 15, ["POR", "DEF", "MED", "DEL"]],
	"nota7": ["Termina con nota 7 o más", 25, ["POR", "DEF", "MED", "DEL"]],
	"nota8": ["Termina con nota 8 o más", 45, ["POR", "DEF", "MED", "DEL"]],
	"gol": ["Marca un gol", 40, ["MED", "DEL"]],
	"doblete": ["Marca dos goles", 80, ["DEL"]],
	"asist": ["Da una asistencia", 35, ["DEF", "MED", "DEL"]],
	"participa": ["Participa en un gol (gol o asistencia)", 30, ["MED", "DEL"]],
	"cero": ["Deja la portería a cero", 40, ["POR", "DEF"]],
	"paradas": ["Haz tres paradas", 35, ["POR"]],
}
const XP_ENTRENO := 6
## Lo máximo que un atributo puede pasar de tu media entrenándolo.
const TOPE_SOBRE_MEDIA := 14
const XP_DECISION := 5
const XP_DUELO := 80

# ---------------------------------------------------------------- estado

## El estado con todas sus claves (una partida vieja o rota no las trae).
static func asegurar(c: CarreraJugador) -> Dictionary:
	var r: Dictionary = c.ruta
	for par: Array in [["xp", 0], ["nivel", 1], ["puntos", 0], ["racha", 0], ["mejor_racha", 0],
			["toque", -1.0], ["toque_semana", -1], ["retos_semana", -1], ["duelos_ganados", 0]]:
		if typeof(r.get(par[0])) not in [TYPE_INT, TYPE_FLOAT]:
			r[par[0]] = par[1]
	for par2: Array in [["talentos", {}], ["rival", {}], ["ultimo", {}]]:
		if not r.get(par2[0]) is Dictionary:
			r[par2[0]] = {}
	for clave: String in ["retos", "grada"]:
		if not r.get(clave) is Array:
			r[clave] = []
	return r

static func nivel(c: CarreraJugador) -> int:
	return int(asegurar(c)["nivel"])

## Experiencia que pide pasar del nivel `n` al siguiente.
static func xp_para(n: int) -> int:
	return 150 + 60 * n

static func capitulo(c: CarreraJugador) -> Array:
	var cap: Array = CAPITULOS[0]
	for x: Array in CAPITULOS:
		if nivel(c) >= int(x[0]):
			cap = x
	return cap

static func capitulo_siguiente(c: CarreraJugador) -> Array:
	for x: Array in CAPITULOS:
		if nivel(c) < int(x[0]):
			return x
	return []

static func tiene(c: CarreraJugador, talento: String) -> bool:
	return (asegurar(c)["talentos"] as Dictionary).has(talento)

## Suma experiencia; devuelve cuántos niveles subió.
static func sumar_xp(c: CarreraJugador, cuanta: int) -> int:
	var r := asegurar(c)
	var antes := String(capitulo(c)[1])
	r["xp"] = int(r["xp"]) + maxi(0, cuanta)
	var subidas := 0
	while int(r["xp"]) >= xp_para(int(r["nivel"])):
		r["xp"] = int(r["xp"]) - xp_para(int(r["nivel"]))
		r["nivel"] = int(r["nivel"]) + 1
		r["puntos"] = int(r["puntos"]) + 1
		subidas += 1
	if subidas > 0 and String(capitulo(c)[1]) != antes:
		_grada(c, "📣", "Capítulo nuevo: %s.", [Idiomas.t(String(capitulo(c)[1]))])
	return subidas

# ---------------------------------------------------------------- talentos

## ¿Se puede comprar? Hay punto libre y está comprado el anterior de su rama.
static func puede_aprender(c: CarreraJugador, talento: String) -> bool:
	if not TALENTOS.has(talento) or tiene(c, talento) or int(asegurar(c)["puntos"]) <= 0:
		return false
	var t: Array = TALENTOS[talento]
	for otro: String in TALENTOS:
		var o: Array = TALENTOS[otro]
		if String(o[0]) == String(t[0]) and int(o[1]) < int(t[1]) and not tiene(c, otro):
			return false
	return true

static func aprender(c: CarreraJugador, m: Mundo, talento: String) -> bool:
	if not puede_aprender(c, talento):
		return false
	var r := asegurar(c)
	r["puntos"] = int(r["puntos"]) - 1
	(r["talentos"] as Dictionary)[talento] = true
	if talento == "brazalete":
		c.capitan = true
		var j := c.jugador(m)
		if j != null and j.moral < 70:
			j.moral = 70
	return true

# ---------------------------------------------------------------- retos

static func _azar(c: CarreraJugador, m: Mundo, sal: int) -> RandomNumberGenerator:
	var g := RandomNumberGenerator.new()
	g.seed = hash("%s|%d|%d" % [c.jugador_id, m.anio * 60 + m.semana, sal])
	return g

## Los tres retos de esta semana (se sortean una vez por semana).
static func retos(c: CarreraJugador, m: Mundo) -> Array:
	var r := asegurar(c)
	var ahora := m.anio * 60 + m.semana
	if int(r["retos_semana"]) == ahora:
		return r["retos"]
	var j := c.jugador(m)
	var linea := j.pos if j != null else "MED"
	var ids: Array = []
	for id: String in RETOS:
		if (RETOS[id][2] as Array).has(linea):
			ids.append(id)
	var g := _azar(c, m, 1)
	var elegidos: Array = []
	while elegidos.size() < 3 and not ids.is_empty():
		var id2: String = ids[g.randi() % ids.size()]
		ids.erase(id2)
		## Dos retos de nota o de gol a la vez serían el mismo reto dos veces.
		if (id2 == "nota8" and elegidos.has("nota7")) or (id2 == "nota7" and elegidos.has("nota8")) \
				or (id2 == "doblete" and elegidos.has("gol")) or (id2 == "gol" and elegidos.has("doblete")):
			continue
		elegidos.append(id2)
	var lista: Array = []
	for id3: String in elegidos:
		lista.append({"id": id3, "hecho": false})
	r["retos"] = lista
	r["retos_semana"] = ahora
	return lista

static func _cumple(id: String, d: Dictionary) -> bool:
	var g := int(d.get("goles", 0))
	var a := int(d.get("asist", 0))
	match id:
		"minutos": return int(d.get("minutos", 90)) >= 60
		"nota7": return float(d.get("nota", 0.0)) >= 7.0
		"nota8": return float(d.get("nota", 0.0)) >= 8.0
		"gol": return g >= 1
		"doblete": return g >= 2
		"asist": return a >= 1
		"participa": return g + a >= 1
		"cero": return d.has("encajados") and int(d["encajados"]) == 0 and int(d.get("minutos", 90)) >= 60
		"paradas": return int(d.get("paradas", 0)) >= 3
	return false

# ---------------------------------------------------------------- partido

## Lo que deja un partido en la ruta: experiencia, retos, racha y la grada.
## `d` es el mismo resumen que recibe `CarreraJugador.tras_partido`.
static func tras_partido(c: CarreraJugador, m: Mundo, d: Dictionary) -> void:
	var r := asegurar(c)
	var minutos := int(d.get("minutos", 90))
	if minutos <= 0:
		return
	var nota := float(d.get("nota", 6.0))
	var goles := int(d.get("goles", 0))
	var asist := int(d.get("asist", 0))
	r["racha"] = int(r["racha"]) + 1 if nota >= 7.0 else 0
	r["mejor_racha"] = maxi(int(r["mejor_racha"]), int(r["racha"]))
	var base := int(float(minutos) / 6.0) + int(maxf(0.0, nota - 6.0) * 12.0) + goles * 15 + asist * 10
	var hechos: Array = []
	var extra := 0
	for reto: Dictionary in retos(c, m):
		var ok := not bool(reto.get("hecho", false)) and _cumple(String(reto["id"]), d)
		var premio := int(RETOS[String(reto["id"])][1])
		if tiene(c, "sangre_fria"):
			premio = int(float(premio) * 1.5)
		if ok:
			reto["hecho"] = true
			extra += premio
		hechos.append({"id": String(reto["id"]), "hecho": ok, "xp": premio})
	var mult := 1.0 + float(mini(int(r["racha"]), 5)) * 0.1
	var total := int(float(base + extra) * mult)
	var nivel_antes := int(r["nivel"])
	sumar_xp(c, total)
	## Talentos de la rama Ídolo.
	var fans := 0
	if tiene(c, "carisma"):
		fans = goles * 60 + int(maxf(0.0, nota - 6.5) * 80.0)
		c.seguidores += fans
	if tiene(c, "portada") and nota >= 7.0:
		c.fama = mini(100, c.fama + 1)
	if tiene(c, "pulmones"):
		c.energia = mini(CarreraJugador.ENERGIA_MAX, c.energia + int(float(minutos) / 10.0))
	r["ultimo"] = {"nota": nota, "goles": goles, "asist": asist, "minutos": minutos, "xp": total,
		"racha": int(r["racha"]), "retos": hechos, "niveles": int(r["nivel"]) - nivel_antes,
		"semana": m.anio * 60 + m.semana}
	_grada_del_partido(c, nota, goles)

## La grada opina (las últimas ocho frases; se traducen al mostrarlas).
static func _grada(c: CarreraJugador, icono: String, plantilla: String, datos: Array = []) -> void:
	var g: Array = asegurar(c)["grada"]
	## La misma frase dos veces seguidas no es noticia.
	if not g.is_empty() and String((g[-1] as Dictionary).get("texto", "")) == plantilla and datos.is_empty():
		return
	g.append({"icono": icono, "texto": plantilla, "datos": datos})
	while g.size() > 8:
		g.remove_at(0)

static func texto_grada(linea: Dictionary) -> String:
	var t := Idiomas.t(String(linea.get("texto", "")))
	var datos: Array = linea.get("datos", []) if linea.get("datos") is Array else []
	return t % datos if not datos.is_empty() and t.count("%") == datos.size() else t

static func _grada_del_partido(c: CarreraJugador, nota: float, goles: int) -> void:
	var racha := int(asegurar(c)["racha"])
	if goles >= 2:
		_grada(c, "🔥", "¡%d goles! La grada corea tu nombre.", [goles])
	elif racha >= 3:
		_grada(c, "🔥", "%d partidos seguidos a gran nivel: estás en racha.", [racha])
	elif goles == 1:
		_grada(c, "⚽", "Gol tuyo. Tu camiseta ya se ve en la tribuna.")
	elif nota >= 8.0:
		_grada(c, "👏", "Partidazo: te fuiste ovacionado.")
	elif nota >= 7.0:
		_grada(c, "👍", "Buen partido. El DT asintió al verte salir.")
	elif nota < 5.5:
		_grada(c, "😬", "Tarde para olvidar. Hubo murmullos en la grada.")
	else:
		_grada(c, "💬", "Partido correcto, sin más. Toca apretar.")

# ---------------------------------------------------------------- entreno

## La interfaz anota aquí cómo salió el mini juego (0 = fallo, 1 = perfecto).
## Una vez por semana: no se puede repetir hasta acertar.
static func anotar_toque(c: CarreraJugador, m: Mundo, calidad: float) -> bool:
	var r := asegurar(c)
	var ahora := m.anio * 60 + m.semana
	if int(r["toque_semana"]) == ahora:
		return false
	r["toque"] = clampf(calidad, 0.0, 1.0)
	r["toque_semana"] = ahora
	return true

static func toque_de_la_semana(c: CarreraJugador, m: Mundo) -> float:
	var r := asegurar(c)
	return float(r["toque"]) if int(r["toque_semana"]) == m.anio * 60 + m.semana else -1.0

## Tras el entreno de siempre (`mejoro` = si ya subió un atributo): el toque
## perfecto asegura la mejora y el talento Instinto da otra oportunidad.
## Devuelve la frase que hay que añadir al aviso (o "").
static func tras_entreno(c: CarreraJugador, m: Mundo, attr: String, mejoro: bool) -> String:
	var j := c.jugador(m)
	if j == null or attr == "" or not j.atributos.has(attr):
		return ""
	var toque := toque_de_la_semana(c, m)
	sumar_xp(c, XP_ENTRENO + (10 if toque >= 0.85 else (5 if toque >= 0.5 else 0)))
	if mejoro or int(j.atributos[attr]) >= 99:
		return ""
	var motivo := ""
	if toque >= 0.85:
		motivo = "Toque perfecto en el entreno: mejora asegurada."
	elif tiene(c, "instinto") and _azar(c, m, 2).randf() < 0.35:
		motivo = "Tu instinto le saca partido a la semana."
	if motivo == "":
		return ""
	j.atributos[attr] = int(j.atributos[attr]) + 1
	var antes := j.ovr
	j.ovr = maxi(j.ovr, j.media_en(j.pos_e))
	if j.ovr != antes:
		j.tasar()
	return Idiomas.t(motivo)

# ---------------------------------------------------------------- semana

## Lo que la ruta hace al cerrar cada semana.
static func semana(c: CarreraJugador, m: Mundo) -> void:
	asegurar(c)
	if tiene(c, "ejemplo"):
		c.relacion_dt = mini(100, c.relacion_dt + 1)
	var j := c.jugador(m)
	if tiene(c, "brazalete") and j != null and j.moral < 70:
		j.moral = 70
	rival(c, m)
	CarreraMisiones.revisar(c, m)

# ---------------------------------------------------------------- el rival

static func _buscar(m: Mundo, id: String) -> Jugador:
	for cl: Club in m.clubes.values():
		for o: Jugador in cl.plantilla:
			if o.id == id:
				return o
	return null

static func _liga_de(m: Mundo, cl: Club) -> Liga:
	for l: Liga in m.ligas:
		if l.clubes.has(cl):
			return l
	return null

## Tu rival: un joven de tu línea en tu liga, de otro club y de media parecida.
## Se conserva mientras siga en tu liga; si no, se busca otro.
static func rival(c: CarreraJugador, m: Mundo) -> Jugador:
	var r := asegurar(c)
	var j := c.jugador(m)
	var mio := c.club(m)
	if j == null or mio == null:
		return null
	var liga := _liga_de(m, mio)
	if liga == null:
		return null
	var actual := _buscar(m, String((r["rival"] as Dictionary).get("id", "")))
	if actual != null and actual.club_id != mio.id and liga.clubes.has(m.clubes.get(actual.club_id)):
		return actual
	var mejor: Jugador = null
	var mejor_dist := 9999.0
	for cl: Club in liga.clubes:
		if cl == mio:
			continue
		for o: Jugador in cl.plantilla:
			if o.pos != j.pos:
				continue
			var dist := absf(float(o.ovr - j.ovr - 3)) + maxf(0.0, float(o.edad - 23)) * 2.0
			if dist < mejor_dist:
				mejor_dist = dist
				mejor = o
	r["rival"] = {"id": mejor.id, "nombre": mejor.nombre} if mejor != null else {}
	return mejor

## Los puntos del duelo de esta temporada: [los tuyos, los de tu rival].
static func duelo(c: CarreraJugador, m: Mundo) -> Array:
	var o := rival(c, m)
	var s: Dictionary = c.stats_temp
	var mios := int(s["goles"]) * 3 + int(s["asist"]) * 2 + int(c.nota_media() * 2.0)
	if o == null:
		return [mios, 0]
	var notas := 0.0
	for n: float in o.notas:
		notas += n
	var media := notas / float(o.notas.size()) if not o.notas.is_empty() else 0.0
	return [mios, o.goles * 3 + o.asistencias * 2 + int(media * 2.0)]

## Fin de temporada: si ganaste el duelo, experiencia y fama. Devuelve si ganaste.
static func cerrar_duelo(c: CarreraJugador, m: Mundo) -> bool:
	var r := asegurar(c)
	var d := duelo(c, m)
	var o := rival(c, m)
	if o == null or int(c.stats_temp["pj"]) == 0:
		return false
	var gane := int(d[0]) > int(d[1])
	if gane:
		r["duelos_ganados"] = int(r["duelos_ganados"]) + 1
		c.fama = mini(100, c.fama + 3)
		sumar_xp(c, XP_DUELO)
		_grada(c, "🏆", "Le ganaste el duelo de la temporada a %s.", [o.nombre])
	else:
		_grada(c, "🥊", "%s te ganó el duelo de la temporada. Habrá revancha.", [o.nombre])
	return gane
