class_name LogrosLargo
extends RefCounted
## LOS TREINTA LOGROS A LARGO PLAZO (26-10-2026, plan §10: «rejugabilidad: hay
## récords y legado, pero sin lista de logros»). Se suman a los veinte de la
## tabla LOGROS y a los diez ocultos, con dos diferencias a propósito:
##  · se VEN desde el primer día con su progreso («312 / 500 partidos»): son
##    metas de años, y una meta de años que no enseña cuánto falta no se persigue;
##  · solo dan reconocimiento (la señal `logro_desbloqueado` y la lista), no
##    puntos del árbol del DT: treinta puntos más cambiarían el equilibrio.
## Cada uno se mide con algo que el juego YA guarda (la memoria de `Logros`, el
## club, la directiva); ninguno inventa un sistema. Si un dato solo existe en
## los partidos dirigidos (goleadores, debuts), la descripción lo dice.
## La condición de cada uno la comprueba `pruebas/ideas/s6_logros.gd`.
##   LogrosLargo.valor(clave, logros) -> int   ·   LogrosLargo.CATALOGO

## Los que miden cómo ESTÁ el club y no lo que has hecho: si al llegar ya se
## cumplían (un grande con 90 de reputación), se apuntan como «heredados», sin
## aviso; si no, la primera revisión tras tu primer partido los regalaría.
const HEREDABLES := ["aforo", "socios", "rep", "caja", "once"]

## [clave, icono, título, descripción, meta]
const CATALOGO := [
	["anios_1", "📅", "Primer año", "Completa una temporada entera al mando.", 1],
	["anios_5", "🗓️", "Lustro", "Cinco temporadas en el mismo proyecto.", 5],
	["anios_15", "🏛️", "Toda una era", "Quince temporadas al mando.", 15],
	["anios_25", "💍", "Bodas de plata", "Veinticinco temporadas al mando.", 25],
	["pj_100", "🪑", "Cien en el banquillo", "Cien partidos oficiales al mando.", 100],
	["pj_500", "📋", "Quinientos", "Quinientos partidos oficiales al mando.", 500],
	["pj_1000", "🧱", "Mil partidos", "Mil partidos oficiales al mando.", 1000],
	["pg_50", "✌️", "Cincuenta victorias", "Gana cincuenta partidos oficiales.", 50],
	["pg_250", "💪", "Doscientas cincuenta", "Gana doscientos cincuenta partidos oficiales.", 250],
	["pg_500", "👑", "Quinientas victorias", "Gana quinientos partidos oficiales.", 500],
	["racha_10", "🔥", "Diez seguidas", "Diez victorias seguidas.", 10],
	["invicto_40", "🧗", "Imbatible", "Cuarenta partidos seguidos sin perder.", 40],
	["titulos_3", "🥉", "Tres en la vitrina", "Tres títulos en tu era.", 3],
	["titulos_5", "⭐", "Cinco estrellas", "Cinco títulos en tu era.", 5],
	["titulos_50", "🏆", "Medio centenar", "Cincuenta títulos en tu era.", 50],
	["cantera_5", "🌱", "Primeros brotes", "Cinco canteranos debutan en partidos que diriges.", 5],
	["cantera_40", "🌳", "Semillero", "Cuarenta canteranos debutan en partidos que diriges.", 40],
	["goleador_50", "🎯", "Ídolo de la grada", "Un jugador marca cincuenta goles en partidos que diriges.", 50],
	["goleador_150", "⚽", "Leyenda del área", "Un jugador marca ciento cincuenta goles en partidos que diriges.", 150],
	["fiel_200", "🤝", "Un club, una vida", "Un jugador juega doscientos partidos contigo.", 200],
	["publico_50k", "🏟️", "Lleno histórico", "Cincuenta mil personas en un partido de tu equipo.", 50000],
	["aforo_90k", "🗼", "Coloso", "Un estadio de noventa mil localidades.", 90000],
	["caja_10m", "💶", "Cuentas sanas", "Diez millones en caja.", 10],
	["caja_500m", "🏦", "Banco central", "Quinientos millones en caja.", 500],
	["socios_50k", "🎫", "Masa social", "Cincuenta mil socios.", 50000],
	["rep_90", "🌍", "Grande de verdad", "Lleva la reputación del club a 90.", 90],
	["once_80", "💎", "Once de élite", "Un once titular con media de 80 o más.", 80],
	["dt_3", "🎙️", "Entrenador del año ×3", "Tres premios al mejor entrenador en la gala de fin de temporada.", 3],
	["fairplay_1", "🕊️", "Juego limpio", "El premio Fair Play de la gala de fin de temporada.", 1],
	["ideal_5", "🧩", "Medio equipo ideal", "Cinco de los tuyos en el equipo ideal de una misma gala.", 5],
]

## La fila de una clave (vacía si no existe).
static func fila(clave: String) -> Array:
	for f: Array in CATALOGO:
		if String(f[0]) == clave:
			return f
	return []

## Lo que lleva hoy hacia la meta, en las unidades de la meta (millones en los
## de caja). Nunca baja de 0.
static func valor(clave: String, lg: Logros) -> int:
	if lg == null or lg.mundo == null:
		return 0
	var m: Mundo = lg.mundo
	var c := m.mi_club()
	if c == null:
		return 0
	var pre := clave.split("_")[0]
	match pre:
		"anios":
			return maxi(0, m.anio - lg.anio_inicio)
		"pj":
			return int(lg.carrera.get("pj", 0))
		"pg":
			return int(lg.carrera.get("pg", 0))
		"racha":
			return int(lg.rachas.get("ganando_max", 0))
		"invicto":
			return int(lg.rachas.get("invicto_max", 0))
		"titulos":
			return m.directiva.trofeos.size() if m.directiva != null else lg.muro.size()
		"cantera":
			return lg.canteranos_debutados.size()
		"goleador":
			return _maximo_de(lg.rec.get("goles", {}))
		"fiel":
			return _maximo_de(lg.rec.get("pj", {}))
		"publico":
			return int(lg.rec["mas_publico"]["n"]) if lg.rec.has("mas_publico") else 0
		"aforo":
			return c.estadio_aforo
		"caja":
			return maxi(0, int(float(c.saldo) * Eco.ECO / 1000000.0))
		"socios":
			return c.socios
		"rep":
			return c.rep
		"once":
			return _media_once(c)
		"dt":
			return _galas(lg, "dt_es_mio")
		"fairplay":
			return _galas(lg, "fairplay_es_mio")
		"ideal":
			var mejor := 0
			for a: Dictionary in lg.premios:
				mejor = maxi(mejor, int(a.get("ideal_mios", 0)))
			return mejor
	return 0

## El mayor valor de un registro: los goles van {nombre: n} y los partidos
## {id: {"nombre", "n"}} (así los guarda `Logros._anotar_participaciones`).
static func _maximo_de(registro: Dictionary) -> int:
	var mejor := 0
	for k in registro:
		var r: Variant = registro[k]
		mejor = maxi(mejor, int((r as Dictionary).get("n", 0)) if r is Dictionary else int(r))
	return mejor

static func _media_once(c: Club) -> int:
	var once := c.once()
	if once.size() < 11:
		return 0
	var s := 0
	for j: Jugador in once:
		s += j.ovr
	return int(floor(float(s) / float(once.size())))

## Cuántas galas guardadas tienen la marca a favor de tu club.
static func _galas(lg: Logros, campo: String) -> int:
	var n := 0
	for a: Dictionary in lg.premios:
		if bool(a.get(campo, false)):
			n += 1
	return n
