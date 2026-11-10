class_name SeleccionEquipo
extends RefCounted
## LA SELECCIÓN COMO EQUIPO DE VERDAD (encargo del dueño del 10-11, punto 2: «aceptar una selección y poder jugar los torneos de selecciones»).
## Antes una selección era un nombre con una fuerza (`Selecciones.fuerza`) y el Mundial se decidía sumando fuerza y ruido, sin partidos. Aquí
## cada selección es un `Club` con plantilla: los MEJORES jugadores de esa nacionalidad que haya en todo el mundo del juego (clubes y libres), por
## puesto (2 porteros, 8 defensas, 8 medios y 5 delanteros = 23), como COPIAS (los goles y las notas de la selección no se suman a su liga). Si no
## llegan (una selección sin liga en el juego, p. ej. Senegal), se completa con jugadores generados del nivel de esa selección, siempre los
## mismos para la misma selección y temporada. Los colores y el país salen de `COLORES` y de `PAIS_SELECCION`. Solo lectura del mundo.
const CUPOS := {"POR": 2, "DEF": 8, "MED": 8, "DEL": 5}
const DEMARCACIONES := {"POR": ["POR"], "DEF": ["DFC", "DFC", "LD", "LI"], "MED": ["MCD", "MC", "MCO", "MD", "MI"], "DEL": ["DC", "ED", "EI", "SD"]}
## Colores de cada selección (camiseta, detalle). Los que falten: un tono estable por su nombre.
const COLORES := {
	"Chile": ["#d52b1e", "#ffffff"], "Argentina": ["#75aadb", "#ffffff"], "Brasil": ["#f7d117", "#1e7b3a"], "Uruguay": ["#5aa7e0", "#ffffff"],
	"Colombia": ["#fcd116", "#003893"], "Perú": ["#ffffff", "#d91023"], "Ecuador": ["#ffd100", "#034ea2"], "Paraguay": ["#d52b1e", "#ffffff"],
	"Bolivia": ["#007934", "#ffffff"], "Venezuela": ["#7b1e2b", "#ffffff"], "España": ["#c60b1e", "#ffc400"], "Inglaterra": ["#ffffff", "#1d2c5e"],
	"Italia": ["#1f5fbf", "#ffffff"], "Alemania": ["#ffffff", "#000000"], "Francia": ["#1d3a8a", "#ffffff"], "Portugal": ["#a41d23", "#046a38"],
	"Holanda": ["#f36c21", "#ffffff"], "Bélgica": ["#c8102e", "#000000"], "Croacia": ["#ffffff", "#e21c23"], "Dinamarca": ["#c8102e", "#ffffff"],
	"Marruecos": ["#c1272d", "#006233"], "Senegal": ["#ffffff", "#00853f"], "Nigeria": ["#008751", "#ffffff"], "Egipto": ["#ce1126", "#ffffff"],
	"Camerún": ["#007a5e", "#ce1126"], "Japón": ["#1c2a6b", "#ffffff"], "Corea": ["#c60c30", "#ffffff"], "Irán": ["#ffffff", "#239f40"],
	"Australia": ["#ffcd00", "#00843d"], "Arabia": ["#ffffff", "#006c35"], "México": ["#006847", "#ffffff"], "EE.UU.": ["#ffffff", "#0a3161"],
	"Costa Rica": ["#ce1126", "#002b7f"], "Canadá": ["#d80621", "#ffffff"], "N. Zelanda": ["#ffffff", "#000000"], "Catar": ["#8a1538", "#ffffff"],
	"Sudáfrica": ["#ffb81c", "#007749"], "Suiza": ["#d52b1e", "#ffffff"], "Austria": ["#ed2939", "#ffffff"], "Escocia": ["#1c2a6b", "#ffffff"],
	"Suecia": ["#fecc02", "#006aa7"], "Noruega": ["#ba0c2f", "#ffffff"], "Polonia": ["#ffffff", "#dc143c"], "Serbia": ["#c6363c", "#ffffff"],
	"Turquía": ["#e30a17", "#ffffff"], "Ucrania": ["#ffd500", "#005bbb"], "Gales": ["#c8102e", "#ffffff"], "Rep. Checa": ["#d7141a", "#ffffff"],
	"Hungría": ["#ce2939", "#ffffff"], "Grecia": ["#0d5eaf", "#ffffff"], "Irlanda": ["#169b62", "#ffffff"], "Ghana": ["#ffffff", "#006b3f"],
	"Costa de Marfil": ["#f77f00", "#009e60"], "Argelia": ["#ffffff", "#006233"], "Túnez": ["#e70013", "#ffffff"], "Malí": ["#fcd116", "#14b53a"],
	"Uzbekistán": ["#ffffff", "#0099b5"], "Jordania": ["#ffffff", "#ce1126"], "Irak": ["#ffffff", "#007a3d"], "Emiratos": ["#ffffff", "#00732f"],
	"Panamá": ["#d21034", "#ffffff"], "Jamaica": ["#fed100", "#009b3a"], "Honduras": ["#ffffff", "#0073cf"],
}

## El código de país de una selección por su nombre («España» → «ESP»), o "" si no tiene liga en el juego.
static func codigo_de(nombre: String) -> String:
	var t: Variant = Datos.tabla("PAIS_SELECCION")
	if t is Dictionary:
		for cod: String in t:
			if Nombres.limpiar(String(t[cod])) == Nombres.limpiar(nombre):
				return cod
	return ""

static func _copia(j: Jugador, sel: Club) -> Jugador:
	var c := Jugador.new()
	for campo: String in ["id", "nombre", "pais", "region", "pos", "pos_e", "edad", "ovr", "pot", "rasgo", "look", "dorsal", "forma", "moral", "real"]:
		c.set(campo, j.get(campo))
	c.pos_sec = j.pos_sec.duplicate()
	c.atributos = j.atributos.duplicate()
	c.club_id = sel.id
	c.fisico = 100
	return c

## Los jugadores de la nacionalidad de `nombre` en todo el mundo del juego (clubes y libres), del mejor al peor (hasta `tope`).
static func candidatos(m: Mundo, nombre: String, tope: int = 0) -> Array[Jugador]:
	var out: Array[Jugador] = []
	var pais := codigo_de(nombre)
	if pais == "" or m == null:
		return out
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			if j.pais == pais and j.disponible():
				out.append(j)
	for j2: Jugador in m.libres:
		if j2.pais == pais and j2.disponible():
			out.append(j2)
	out.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr if a.ovr != b.ovr else a.id < b.id)
	if tope > 0 and out.size() > tope:
		out.resize(tope)
	return out

## Lo mínimo por puesto cuando la lista la eliges tú (`elegidos`): si falta, se completa con generados.
const MINIMOS := {"POR": 2, "DEF": 6, "MED": 6, "DEL": 3}
const MAX_CONVOCADOS := 26

## La selección `nombre` como club. Sin `elegidos`: 23 convocados, los mejores por puesto. Con `elegidos` (ids, la convocatoria del seleccionador):
## esos (hasta 26) y, si algún puesto queda por debajo de `MINIMOS`, generados. `fuerza` (la de `Selecciones.fuerza`) fija la reputación y el nivel.
## (10-11) `max_edad` > 0: equipo olímpico (solo jugadores de hasta esa edad y `mayores` de más, los mejores).
static func club_de(m: Mundo, nombre: String, fuerza: int, anio: int, elegidos: Array = [], max_edad: int = 0, mayores: int = 0) -> Club:
	var sel := Club.new()
	sel.id = "sel_" + Nombres.limpiar(nombre).to_lower().replace(" ", "_").replace(".", "")
	if max_edad > 0:
		sel.id += "_sub%d" % max_edad   ## el olímpico no comparte generados ni id con la absoluta
	sel.nombre = nombre
	sel.pais = codigo_de(nombre)
	sel.rep = clampi(fuerza, 40, 95)
	var col: Array = COLORES.get(nombre, ["#%06x" % (absi(hash(nombre)) % 0xffffff), "#ffffff"])
	sel.color1 = String(col[0])
	sel.color2 = String(col[1])
	sel.estadio_aforo = 60000
	var por_grupo := {}
	var cupos: Dictionary = CUPOS if elegidos.is_empty() else MINIMOS
	var mayores_usados := 0
	for j3: Jugador in candidatos(m, nombre):
		var g := j3.pos
		if max_edad > 0 and j3.edad > max_edad:
			if mayores_usados >= mayores or (por_grupo.get(g, []) as Array).size() >= int(CUPOS.get(g, 0)):
				continue
			mayores_usados += 1
		if not por_grupo.has(g):
			por_grupo[g] = []
		if elegidos.is_empty():
			if (por_grupo[g] as Array).size() < int(CUPOS.get(g, 0)):
				(por_grupo[g] as Array).append(_copia(j3, sel))
		elif elegidos.has(j3.id) and _total(por_grupo) < MAX_CONVOCADOS:
			(por_grupo[g] as Array).append(_copia(j3, sel))
	_completar(m, sel, por_grupo, fuerza, anio, cupos)
	for g2: String in ["POR", "DEF", "MED", "DEL"]:
		for j4: Jugador in por_grupo.get(g2, []):
			sel.plantilla.append(j4)
	return sel

static func _total(por_grupo: Dictionary) -> int:
	var n := 0
	for g: String in por_grupo:
		n += (por_grupo[g] as Array).size()
	return n

## Completa los huecos con jugadores generados del nivel de la selección, con azar aislado (siempre los mismos para esa selección y año) y sin
## gastar números de jugador del mundo.
static var _generados := {}   ## «sel_id/año/grupo/i» -> Jugador: los generados se reutilizan (el nombrador no repite nombres, y deben ser siempre los mismos)

static func _completar(m: Mundo, sel: Club, por_grupo: Dictionary, fuerza: int, anio: int, cupos: Dictionary = CUPOS) -> void:
	var faltan := false
	for g: String in cupos:
		faltan = faltan or (por_grupo.get(g, []) as Array).size() < int(cupos[g])
	if not faltan:
		return
	var seq: int = m._seq_jugador
	CopasMundo._aislado("sel%s%d" % [sel.id, anio], func() -> void:
		for g: String in cupos:
			if not por_grupo.has(g):
				por_grupo[g] = []
			var lista: Array = por_grupo[g]
			var k := 0
			while lista.size() < int(cupos[g]):
				var clave := "%s/%d/%s/%d" % [sel.id, anio, g, lista.size()]
				if not _generados.has(clave):
					var dem: Array = DEMARCACIONES[g]
					var j := m.crear_jugador(sel, g, String(dem[k % dem.size()]), Azar.ent(21, 33), clampi(fuerza - 6 + Azar.ent(-4, 4) - lista.size(), 45, 92))
					j.id = "%s_%s%d" % [sel.id, g, lista.size()]
					_generados[clave] = j
				lista.append(_generados[clave])
				k += 1)
	m._seq_jugador = seq
