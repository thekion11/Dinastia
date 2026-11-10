class_name Olimpicos
extends RefCounted
## EL FÚTBOL DE LOS JUEGOS OLÍMPICOS (10-11, encargo del dueño «selecciones y torneos»): cada cuatro años (2028 Los Ángeles, 2032 Brisbane…),
## 16 selecciones SUB-23 con hasta 3 mayores (`SeleccionEquipo.club_de` con `max_edad`), por cupos de confederación como en la realidad
## (Europa 4, Conmebol 2, Concacaf 3, Asia 3, África 3, Oceanía 1; si una no llega, el cupo pasa al mejor resto del escalafón). Grupos de 4 y
## eliminatorias (`TorneoSelecciones`) con azar aislado: no cambia ningún sorteo del resto del juego. Es un torneo de las sub-23, no de tu
## selección absoluta (no cuenta como seleccionador). Se guarda en `Selecciones.olimpicos` y sale en el palmarés del mundo.
const NOMBRE := "Juegos Olímpicos"
const EDAD_MAX := 23
const MAYORES := 3
const PLAZAS := 16
const CUPOS := {"ucl": 4, "conmebol": 2, "conc": 3, "asia": 3, "afr": 3, "oce": 1}
const BAJA_FUERZA := 8   ## un equipo olímpico rinde por debajo de su absoluta

static func toca(anio: int) -> bool:
	return anio >= 2028 and (anio - 2028) % 4 == 0

## Las selecciones de la confederación (Conmebol = las de la Copa América que no son de la Concacaf).
static func _lista(clave: String) -> Array:
	if clave == "conmebol":
		var conc: Array = SeleccionesTorneos.POR_CONFED["conc"]
		return (SeleccionesTorneos.POR_CONFED["lib"] as Array).filter(func(n: String) -> bool: return not conc.has(n))
	return SeleccionesTorneos.POR_CONFED.get(clave, [])

## Las 16 selecciones del torneo (por fuerza dentro de cada cupo; sin repetir).
static func participantes(sel: Selecciones) -> Array[String]:
	var out: Array[String] = []
	for clave: String in CUPOS:
		for n: String in _mejores(sel, _lista(clave), out, int(CUPOS[clave])):
			out.append(n)
	if out.size() < PLAZAS:
		for n2: String in _mejores(sel, CargoSeleccion.todas(), out, PLAZAS - out.size()):
			out.append(n2)
	return out

## Las `cuantas` más fuertes de `lista` que no estén en `fuera` (empate: por nombre).
static func _mejores(sel: Selecciones, lista: Array, fuera: Array, cuantas: int) -> Array:
	var filas: Array = []
	for n: String in lista:
		if not fuera.has(n):
			filas.append([sel.fuerza(n), n])
	filas.sort_custom(_mas_fuerte)
	var out: Array = []
	for f: Array in filas.slice(0, cuantas):
		out.append(f[1])
	return out

static func _mas_fuerte(a: Array, b: Array) -> bool:
	return int(a[0]) > int(b[0]) if int(a[0]) != int(b[0]) else String(a[1]) < String(b[1])

## El equipo olímpico de `nombre`.
static func equipo(sel: Selecciones, m: Mundo, nombre: String, anio: int) -> Club:
	var c := SeleccionEquipo.club_de(m, nombre, maxi(40, sel.fuerza(nombre) - BAJA_FUERZA), anio, [], EDAD_MAX, MAYORES)
	c.nombre = "%s Sub-%d" % [nombre, EDAD_MAX]
	return c

## Juega el torneo olímpico de `anio` si toca y no se jugó. Devuelve {anio, oro, plata, final} o {}.
static func jugar(sel: Selecciones, m: Mundo, anio: int) -> Dictionary:
	if sel == null or m == null or not toca(anio):
		return {}
	for f: Dictionary in sel.olimpicos:
		if int(f.get("anio", 0)) == anio:
			return {}
	var equipos: Array[Club] = []
	for n: String in participantes(sel):
		equipos.append(equipo(sel, m, n, anio))
	var t := TorneoSelecciones.crear(NOMBRE, anio, equipos)
	t.jugar_entero()
	if t.campeon == null:
		return {}
	var final: Dictionary = t.resultados[t.resultados.size() - 1]
	var plata: Club = final["visita"] if final["local"] == t.campeon else final["local"]
	var fila := {"anio": anio, "oro": t.campeon.nombre, "plata": plata.nombre,
		"final": "%s %d-%d %s" % [(final["local"] as Club).nombre, int(final["gl"]), int(final["gv"]), (final["visita"] as Club).nombre]}
	var pen: Array = final.get("penales", [])
	if not pen.is_empty():
		fila["final"] += " (penaltis %d-%d)" % [int(pen[0]), int(pen[1])]
	sel.olimpicos.push_front(fila)
	sel.noticia.emit("🥇 %s %d: oro para %s" % [NOMBRE, anio, fila["oro"]], "Final olímpica: %s. Plata para %s." % [fila["final"], fila["plata"]])
	return fila
