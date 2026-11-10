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
	"Sudáfrica": ["#ffb81c", "#007749"],
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

## La selección `nombre` como club, con 23 convocados. `fuerza` (la de `Selecciones.fuerza`) fija la reputación y el nivel de los que se generen.
static func club_de(m: Mundo, nombre: String, fuerza: int, anio: int) -> Club:
	var sel := Club.new()
	sel.id = "sel_" + Nombres.limpiar(nombre).to_lower().replace(" ", "_").replace(".", "")
	sel.nombre = nombre
	sel.pais = codigo_de(nombre)
	sel.rep = clampi(fuerza, 40, 95)
	var col: Array = COLORES.get(nombre, ["#%06x" % (absi(hash(nombre)) % 0xffffff), "#ffffff"])
	sel.color1 = String(col[0])
	sel.color2 = String(col[1])
	sel.estadio_aforo = 60000
	var por_grupo := {}
	if sel.pais != "":
		var candidatos: Array[Jugador] = []
		for c: Club in m.clubes.values():
			for j: Jugador in c.plantilla:
				if j.pais == sel.pais and j.disponible():
					candidatos.append(j)
		for j2: Jugador in m.libres:
			if j2.pais == sel.pais and j2.disponible():
				candidatos.append(j2)
		candidatos.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr if a.ovr != b.ovr else a.id < b.id)
		for j3: Jugador in candidatos:
			var g := j3.pos
			if not por_grupo.has(g):
				por_grupo[g] = []
			if (por_grupo[g] as Array).size() < int(CUPOS.get(g, 0)):
				(por_grupo[g] as Array).append(_copia(j3, sel))
	_completar(m, sel, por_grupo, fuerza, anio)
	for g2: String in ["POR", "DEF", "MED", "DEL"]:
		for j4: Jugador in por_grupo.get(g2, []):
			sel.plantilla.append(j4)
	return sel

## Completa los huecos con jugadores generados del nivel de la selección, con azar aislado (siempre los mismos para esa selección y año) y sin
## gastar números de jugador del mundo.
static var _generados := {}   ## «sel_id/año/grupo/i» -> Jugador: los generados se reutilizan (el nombrador no repite nombres, y deben ser siempre los mismos)

static func _completar(m: Mundo, sel: Club, por_grupo: Dictionary, fuerza: int, anio: int) -> void:
	var faltan := false
	for g: String in CUPOS:
		faltan = faltan or (por_grupo.get(g, []) as Array).size() < int(CUPOS[g])
	if not faltan:
		return
	var seq: int = m._seq_jugador
	CopasMundo._aislado("sel%s%d" % [sel.id, anio], func() -> void:
		for g: String in CUPOS:
			if not por_grupo.has(g):
				por_grupo[g] = []
			var lista: Array = por_grupo[g]
			var k := 0
			while lista.size() < int(CUPOS[g]):
				var clave := "%s/%d/%s/%d" % [sel.id, anio, g, lista.size()]
				if not _generados.has(clave):
					var dem: Array = DEMARCACIONES[g]
					var j := m.crear_jugador(sel, g, String(dem[k % dem.size()]), Azar.ent(21, 33), clampi(fuerza - 6 + Azar.ent(-4, 4) - lista.size(), 45, 92))
					j.id = "%s_%s%d" % [sel.id, g, lista.size()]
					_generados[clave] = j
				lista.append(_generados[clave])
				k += 1)
	m._seq_jugador = seq
