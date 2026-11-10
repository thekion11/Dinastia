class_name LigasActivas
extends RefCounted
## LIGAS ACTIVAS (10-11-2026, encargo del dueño «como Football Manager»): qué países se cargan en la partida. El resto NO se genera (ahorra memoria y tiempo, sobre todo en móvil).
## `Mundo.generar(paises)` ya acepta la lista; esto añade: la lista por defecto (PC: todos; móvil: tu país y los cinco grandes), cuáles están activas (`de`, guardada con la partida) y
## AÑADIR países a mitad de partida (`agregar`, al cerrar la temporada; no se quitan). Los cupos continentales de los países no activos los reparte `PlazasConti` entre los que sí lo están.
const GRANDES: Array[String] = ["ENG", "ESP", "ITA", "GER", "FRA"]
const PAIS_MOVIL := "CHI"   ## el país del juego por defecto (hasta que el dueño decida otro criterio para «mi país» en móvil)
const META := "paises_activos"

## Todos los países con liga en las tablas (primera división), en el orden en que se generan.
static func todos() -> Array[String]:
	var l: Array[String] = ["CHI"]
	var pl: Variant = Datos.tabla("PAISES_LIGAS")
	if pl is Dictionary:
		for pais: String in pl:
			if not l.has(pais):
				l.append(pais)
	return l

## La selección por defecto: PC todas; móvil el país del juego y los cinco grandes.
static func por_defecto(movil: bool) -> Array[String]:
	if not movil:
		return todos()
	var l: Array[String] = [PAIS_MOVIL]
	for g: String in GRANDES:
		if not l.has(g) and todos().has(g):
			l.append(g)
	return l

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
