class_name Finalissima
extends RefCounted
## LA FINALISSIMA (10-11, encargo del dueño «selecciones y torneos»): el año en que se juegan la Eurocopa y la Copa América (los mismos años,
## `Calendario.toca_continental_selecciones`), sus dos campeones se enfrentan a partido único en sede neutral (empate: penaltis), como la de 2022.
## Usa el torneo que ya se jugó si lo hay (el de tu selección o el que dirigiste); si no, juega el otro continental con azar aislado
## (`CopasMundo._aislado` dentro de `TorneoSelecciones`): no cambia ningún sorteo del resto del juego. Se guarda en `Selecciones.finalissimas`
## y, si una de las dos es la selección que diriges, cuenta en tu historial de seleccionador (título = prestigio, como los demás).
const NOMBRE := "Finalissima"
const CLAVES := ["ucl", "lib"]

## ¿Toca este año? (los dos torneos el mismo año).
static func toca(anio: int) -> bool:
	return Calendario.toca_continental_selecciones("ucl", anio) and Calendario.toca_continental_selecciones("lib", anio)

## El campeón del continental `clave` de `anio` (jugándolo si hace falta), o null.
static func _campeon(sel: Selecciones, m: Mundo, clave: String, anio: int) -> Club:
	var nom := String(Selecciones.TORNEO_POR_CONFED.get(clave, ""))
	var t: TorneoSelecciones = sel.cargo.listo(nom, anio)
	if t == null and sel.ultimo_torneo != null and sel.ultimo_torneo.nombre == nom and sel.ultimo_torneo.anio == anio:
		t = sel.ultimo_torneo
	if t == null:
		t = SeleccionesTorneos.continental(sel, m, clave, nom, anio)
	if t.equipos.size() < 2:
		return null
	return t.jugar_entero()

## La final entre `a` y `b`, lista para jugarse (`jugar_fecha` / `jugar_entero`).
static func final_de(a: Club, b: Club, anio: int) -> TorneoSelecciones:
	var t := TorneoSelecciones.new()
	t.nombre = NOMBRE
	t.anio = anio
	t.equipos = [a, b]
	t.en_grupos = false
	t.vivos = [a, b]
	for c: Club in t.equipos:
		t.tabla[c.id] = {"pts": 0, "gf": 0, "gc": 0, "pj": 0}
	return t

## La final de `anio` montada y SIN jugar (para jugarla en directo: `JornadaSeleccion`), o null si no toca o ya se jugó.
static func preparar(sel: Selecciones, m: Mundo, anio: int) -> TorneoSelecciones:
	if sel == null or m == null or not toca(anio):
		return null
	for f: Dictionary in sel.finalissimas:
		if int(f.get("anio", 0)) == anio:
			return null
	var europa := _campeon(sel, m, "ucl", anio)
	var america := _campeon(sel, m, "lib", anio)
	if europa == null or america == null or europa == america:
		return null
	return final_de(europa, america, anio)

## Apunta la final `t` ya jugada (palmarés, historial del seleccionador y noticia). Devuelve {anio, campeon, rival, gl, gv, local, penales}.
static func registrar(sel: Selecciones, m: Mundo, t: TorneoSelecciones) -> Dictionary:
	if t == null or t.campeon == null or t.resultados.is_empty():
		return {}
	var r: Dictionary = t.resultados[0]
	var rival: Club = r["visita"] if t.campeon == r["local"] else r["local"]
	var pen: Array = r.get("penales", [])
	var fila := {"anio": t.anio, "campeon": t.campeon.nombre, "rival": rival.nombre, "gl": int(r["gl"]), "gv": int(r["gv"]),
		"local": (r["local"] as Club).nombre, "penales": pen.duplicate()}
	sel.finalissimas.push_front(fila)
	## El título del seleccionador (prestigio, logros) y la noticia pueden sortear cosas (cuando la ganó TU selección): con el azar aislado no mueven ningún sorteo del resto del juego.
	CopasMundo._aislado("finalissima_registro%d" % t.anio, func() -> void: sel.cargo.anotar(m, t))
	var marcador := "%s %d-%d %s" % [fila["local"], fila["gl"], fila["gv"], (r["visita"] as Club).nombre]
	if not pen.is_empty():
		marcador += " (penaltis %d-%d)" % [int(pen[0]), int(pen[1])]
	CopasMundo._aislado("finalissima_noticia%d" % t.anio, func() -> void:
		sel.noticia.emit("🏆 %s %d: campeón %s" % [NOMBRE, t.anio, fila["campeon"]],
			"El campeón de Europa y el de América, frente a frente en sede neutral: %s." % marcador))
	return fila

## Juega (simulada) la Finalissima de `anio` si toca y no se jugó ya. Devuelve la fila de `registrar` o {}.
static func jugar(sel: Selecciones, m: Mundo, anio: int) -> Dictionary:
	var t := preparar(sel, m, anio)
	if t == null:
		return {}
	t.jugar_entero()
	return registrar(sel, m, t)
