class_name LigasActivas
extends RefCounted
## LIGAS ACTIVAS (10-11-2026, encargo del dueño «como Football Manager»): qué países se cargan en la partida. El resto NO se genera (ahorra memoria y tiempo, sobre todo en móvil).
## `Mundo.generar(paises)` ya acepta la lista; esto añade: la lista por defecto (PC: todos; móvil: tu país y los cinco grandes), cuáles están activas (`de`, guardada con la partida) y
## AÑADIR países a mitad de partida (`agregar`, al cerrar la temporada; no se quitan). Los cupos continentales de los países no activos los reparte `PlazasConti` entre los que sí lo están.
const GRANDES: Array[String] = ["ENG", "ESP", "ITA", "GER", "FRA"]
const PAIS_MOVIL := "CHI"   ## el país por defecto cuando el dispositivo no dice uno con liga
const MOVIL_FIJOS: Array[String] = ["ENG", "ESP", "ITA", "GER"]   ## móvil: el país del dispositivo y estos cuatro grandes
const PC_PRINCIPALES: Array[String] = ["ENG", "ESP", "ITA", "GER", "FRA", "POR", "NED", "BRA", "ARG", "MEX", "USA", "TUR", "BEL"]   ## PC: estos 13 + el país del dispositivo + Chile, hasta 15
const PC_RELLENO: Array[String] = ["JPN", "COL", "SCO", "URU", "KSA", "SUI", "AUT"]   ## si el país del dispositivo ya estaba entre los 13, se completa hasta 15
const MS_POR_CLUB_SEMANA := 1.1   ## coste medido por la sesión 5 (coste_mundo_2026-11-10.md): ms por club y semana en PC; en móvil ×3
const MB_POR_CLUB := 1.25   ## ≈1,8-2 GB de pico con los 1.541 clubes
## País del dispositivo (ISO 3166 → código del juego), solo los que tienen liga.
const ISO_A_JUEGO := {"CL": "CHI", "AR": "ARG", "BR": "BRA", "UY": "URU", "PY": "PAR", "CO": "COL", "PE": "PER", "EC": "ECU", "BO": "BOL", "VE": "VEN", "MX": "MEX", "US": "USA", "ES": "ESP", "GB": "ENG",
	"IT": "ITA", "DE": "GER", "FR": "FRA", "PT": "POR", "NL": "NED", "BE": "BEL", "HR": "CRO", "DK": "DEN", "CH": "SUI", "AT": "AUT", "GR": "GRE", "SE": "SWE", "NO": "NOR", "PL": "POL", "CZ": "CZE",
	"RO": "ROU", "RS": "SRB", "UA": "UKR", "BG": "BUL", "HU": "HUN", "IL": "ISR", "RU": "RUS", "SK": "SVK", "TR": "TUR", "SA": "KSA", "JP": "JPN", "KR": "KOR", "CN": "CHN", "AU": "AUS", "EG": "EGY",
	"MA": "MAR", "ZA": "RSA", "QA": "QAT", "AE": "UAE", "IR": "IRN", "NG": "NGA", "GH": "GHA", "SN": "SEN", "CI": "CIV", "DZ": "ALG", "TN": "TUN", "CM": "CMR", "CA": "CAN", "CR": "CRC", "IE": "IRL",
	"JO": "JOR", "CY": "CYP", "IQ": "IRQ", "UZ": "UZB", "FI": "FIN", "SI": "SVN", "JM": "JAM", "HN": "HON", "PA": "PAN", "NZ": "NZL", "ML": "MLI", "BA": "BIH", "ME": "MNE", "IS": "ISL", "EE": "EST",
	"KZ": "KAZ", "AZ": "AZE", "BY": "BLR", "LV": "LVA", "AL": "ALB", "MK": "MKD", "GE": "GEO", "LT": "LTU", "LU": "LUX"}
const META := "paises_activos"
const RUTA_ELECCION := "user://ligas_activas.cfg"
## Lo que eligió el jugador en la pantalla «Ligas activas» (vacío = no eligió: PC todas, móvil la selección por defecto).
static var elegidas: Array[String] = []

## La lista que se le pasa a `Mundo.generar`: la elegida, o la de la plataforma (en PC, `[]` = todas). Los cuatro sitios que crean un mundo la usan.
static func para_generar() -> Array[String]:
	if not elegidas.is_empty():
		return elegidas.duplicate()
	var l: Array[String] = []
	if OS.has_feature("mobile"):
		l.assign(por_defecto(true))
	return l

## La última elección guardada en esta máquina (o la de la plataforma si no hay).
static func cargar_eleccion() -> Array[String]:
	var cf := ConfigFile.new()
	var l: Array[String] = []
	if cf.load(RUTA_ELECCION) == OK and cf.has_section_key("ligas", "paises"):
		for p: Variant in cf.get_value("ligas", "paises") as Array:
			if todos().has(String(p)):
				l.append(String(p))
	return l if not l.is_empty() else por_defecto(OS.has_feature("mobile"))

static func guardar_eleccion(lista: Array) -> void:
	elegidas.assign(lista)
	var cf := ConfigFile.new()
	cf.set_value("ligas", "paises", lista)
	cf.save(RUTA_ELECCION)

## Cuántos clubes trae un país (primera y segunda división).
static func clubes_de(pais: String) -> int:
	if pais == "CHI":
		var a: Variant = Datos.tabla("DATA_P1")
		var b: Variant = Datos.tabla("DATA_P2")
		return (a as Array).size() + (b as Array).size() if a is Array and b is Array else 0
	var pl: Variant = Datos.tabla("PAISES_LIGAS")
	if not (pl is Dictionary) or not (pl as Dictionary).has(pais):
		return 0
	var d: Dictionary = (pl as Dictionary)[pais]
	var n := (d.get("clubes", []) as Array).size()
	if d.get("segunda") is Dictionary:
		n += ((d["segunda"] as Dictionary).get("clubes", []) as Array).size()
	return n

## Los países agrupados por confederación para la pantalla: [[clave, [códigos]], …] (los sin confederación, en «otros»).
static func por_confederacion() -> Array:
	var conf: Dictionary = Datos.tabla("CONFED") as Dictionary
	var grupos := [["ucl", []], ["lib", []], ["conc", []], ["afr", []], ["asia", []], ["oce", []], ["otros", []]]
	for p: String in todos():
		var puesto := grupos.size() - 1
		for i in grupos.size() - 1:
			var k := String(grupos[i][0])
			if conf.has(k) and ((conf[k] as Dictionary).get("paises", []) as Array).has(p):
				puesto = i
				break
		(grupos[puesto][1] as Array).append(p)
	return grupos.filter(func(g: Array) -> bool: return not (g[1] as Array).is_empty())

## Todos los países con liga en las tablas (primera división), en el orden en que se generan.
static func todos() -> Array[String]:
	var l: Array[String] = ["CHI"]
	var pl: Variant = Datos.tabla("PAISES_LIGAS")
	if pl is Dictionary:
		for pais: String in pl:
			if not l.has(pais):
				l.append(pais)
	return l

## El país del dispositivo (`OS.get_locale()`, p. ej. «es_CL») si tiene liga; si no, el país del juego (Chile).
static func pais_del_dispositivo() -> String:
	var iso := OS.get_locale().get_slice("_", 1).get_slice(".", 0).to_upper()
	var cod := String(ISO_A_JUEGO.get(iso, ""))
	return cod if cod != "" and todos().has(cod) else PAIS_MOVIL

## La selección por defecto. Móvil: el país del dispositivo y ENG, ESP, ITA, GER. PC: los 13 principales + el país del dispositivo + Chile, hasta 15 sin repetir.
static func por_defecto(movil: bool) -> Array[String]:
	var mio := pais_del_dispositivo()
	var l: Array[String] = [mio]
	if movil:
		for g: String in MOVIL_FIJOS:
			if not l.has(g) and todos().has(g):
				l.append(g)
		return l
	for g: String in PC_PRINCIPALES + [PAIS_MOVIL] + PC_RELLENO:
		if l.size() >= 15:
			break
		if not l.has(g) and todos().has(g):
			l.append(g)
	return l

## ¿Esta lista es el mundo entero (todos los países con liga)?
static func es_entero(lista: Array) -> bool:
	return lista.size() >= todos().size()

## Estimación de coste de una lista de países: {"clubes", "s_semana", "gb"} (PC; en móvil ×3 el tiempo).
static func coste(lista: Array, movil: bool) -> Dictionary:
	var clubes := 0
	for p: Variant in lista:
		clubes += clubes_de(String(p))
	var ms := float(clubes) * MS_POR_CLUB_SEMANA * (3.0 if movil else 1.0)
	return {"clubes": clubes, "s_semana": ms / 1000.0, "gb": float(clubes) * MB_POR_CLUB / 1000.0}

## Los países cargados en este mundo (guardado en la partida). Sin lista guardada (partidas viejas), los que tienen liga.
static func de(m: Mundo) -> Array[String]:
	var l: Array[String] = []
	if m.has_meta(META):
		l.assign(m.get_meta(META) as Array)
		return l
	return _de_las_ligas(m)

static func _de_las_ligas(m: Mundo) -> Array[String]:
	var l: Array[String] = []
	for liga: Liga in m.ligas:
		if not l.has(liga.pais):
			l.append(liga.pais)
	return l

## Fija la lista desde las ligas presentes (al generar) o desde una lista guardada (al cargar).
static func registrar(m: Mundo) -> void:
	m.set_meta(META, _de_las_ligas(m))

static func fijar(m: Mundo, lista: Array) -> void:
	m.set_meta(META, lista.duplicate())

## Países con liga que todavía NO están cargados (los que se pueden añadir).
static func faltan(m: Mundo) -> Array[String]:
	var activos := de(m)
	var l: Array[String] = []
	for p: String in todos():
		if not activos.has(p):
			l.append(p)
	return l

## AÑADE países a un mundo ya creado (al cerrar la temporada, con la nueva ya abierta): sus ligas y clubes se crean AL FINAL (los ids de club y jugador siguen la secuencia: no mueven los que ya
## existen), con sus plantillas reales, y se vuelven a montar las copas y los continentales de la temporada. Devuelve {"paises": [...], "clubes": n}. No se quitan.
static func agregar(m: Mundo, paises: Array) -> Dictionary:
	var nuevos: Array[String] = []
	var activos := de(m)
	for p: Variant in paises:
		if todos().has(String(p)) and not activos.has(String(p)) and not nuevos.has(String(p)):
			nuevos.append(String(p))
	if nuevos.is_empty():
		return {"paises": nuevos, "clubes": 0}
	var antes := m.clubes.size()
	var creados: Array = []
	for f: Dictionary in m._fuentes_de_liga(nuevos):
		var liga: Liga = m._crear_liga_completa(f)
		creados.append_array(liga.clubes)
	Reales.aplicar_a(m, creados)
	for c: Club in creados:
		m._capitan_si_falta(c)
	LeyesPais.clubes_mundo = m.clubes
	registrar(m)
	## Copas y continentales de la temporada con los países nuevos; los torneos de la FIFA que ya se armaron (Mundial de Clubes, Intercontinental) se conservan.
	CopasMundo.montar(m)
	var viejos := m.continentales
	m.continentales = Continental.sortear(m.clubes.values(), m.ligas, m.copa.campeon if m.copa != null else null)
	for k: String in ["mundial", "interc"]:
		if viejos.has(k):
			m.continentales[k] = viejos[k]
	return {"paises": nuevos, "clubes": m.clubes.size() - antes}
