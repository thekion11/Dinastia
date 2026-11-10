class_name EstiloClub
extends RefCounted
## LA FORMACIÓN Y EL ESTILO DE CADA CLUB, COMO EN LA VIDA REAL (orden del dueño, 10-11). Hasta ahora los 466 clubes nacían con la
## misma táctica (4-3-3 y todas las perillas en «medio»): todos los rivales jugaban igual. Aquí cada club recibe su formación y un
## ESTILO (un arquetipo que fija las perillas de `Tactica`) desde `datos/estilos_clubes.json` ({nombre del juego: [formación, estilo]}),
## sacado de cómo juega el club real. Si un club no está en la tabla, se deduce de la tradición de su país y de su reputación.
## Sin azar: el mismo club juega siempre igual (y no cambia ningún sorteo del resto del juego).
const RUTA := "res://datos/estilos_clubes.json"

## Perillas de cada estilo: [mentalidad, presion, ritmo, linea, amplitud, verticalidad, tras_perdida, salida_corta, tiro_lejano]
## (mentalidad 0 defensiva, 1 equilibrada, 2 ofensiva; el resto 0 bajo, 1 medio, 2 alto).
const ESTILOS := {
	"posesion": [1, 2, 1, 2, 1, 0, 2, true, false],
	"presion": [2, 2, 2, 2, 1, 2, 2, false, false],
	"vertical": [1, 1, 2, 1, 1, 2, 1, false, false],
	"contra": [0, 0, 2, 0, 1, 2, 0, false, false],
	"bloque": [0, 1, 1, 1, 0, 1, 1, false, false],
	"bandas": [1, 1, 1, 1, 2, 1, 1, false, false],
	"directo": [1, 1, 1, 1, 1, 2, 0, false, true],
	"equilibrado": [1, 1, 1, 1, 1, 1, 1, false, false],
	"ofensivo": [2, 1, 2, 2, 2, 1, 1, true, false],
	"garra": [1, 2, 2, 1, 0, 2, 2, false, false],
}
## Cómo se llama cada estilo en la interfaz.
const NOMBRES := {
	"posesion": "Juego de posición", "presion": "Presión alta", "vertical": "Transiciones rápidas", "contra": "Bloque bajo y contra",
	"bloque": "Bloque medio", "bandas": "Juego por bandas", "directo": "Juego directo", "equilibrado": "Equilibrado",
	"ofensivo": "Ataque total", "garra": "Intensidad y garra",
}
## Cuando un club no está en la tabla: el estilo y la formación de su país para un grande y para un modesto.
const POR_PAIS := {
	"ESP": [["4-3-3", "posesion"], ["4-4-2", "bloque"]], "ENG": [["4-2-3-1", "presion"], ["4-4-2", "directo"]],
	"ITA": [["3-5-2", "bloque"], ["3-5-2", "contra"]], "GER": [["4-2-3-1", "presion"], ["4-4-2", "vertical"]],
	"FRA": [["4-3-3", "vertical"], ["4-4-2", "bloque"]], "POR": [["4-3-3", "posesion"], ["4-4-2", "bloque"]],
	"NED": [["4-3-3", "ofensivo"], ["4-3-3", "equilibrado"]], "BRA": [["4-2-3-1", "ofensivo"], ["4-4-2", "garra"]],
	"ARG": [["4-3-3", "garra"], ["4-4-2", "garra"]], "URU": [["4-4-2", "garra"], ["4-4-2", "contra"]],
	"MEX": [["4-3-3", "bandas"], ["4-4-2", "equilibrado"]], "USA": [["4-2-3-1", "vertical"], ["4-4-2", "directo"]],
}

static var _tabla: Dictionary = {}
static var _cargada := false

static func tabla() -> Dictionary:
	if not _cargada:
		_cargada = true
		if FileAccess.file_exists(RUTA):
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
			if d is Dictionary:
				_tabla = d
	return _tabla

## [formación, estilo] del club (por su nombre en la tabla de ligas; `rep` y `pais` para el respaldo).
static func de(nombre_tabla: String, pais: String, rep: int) -> Array:
	var t := tabla()
	if t.has(nombre_tabla):
		var f: Array = t[nombre_tabla]
		if f.size() >= 2 and ESTILOS.has(String(f[1])):
			return [String(f[0]), String(f[1])]
	var par: Array = POR_PAIS.get(pais, [["4-3-3", "equilibrado"], ["4-4-2", "bloque"]])
	return (par[0] if rep >= 80 else par[1]).duplicate()

## Pone en `c` la formación y el estilo de la vida real.
static func aplicar(c: Club, nombre_tabla: String) -> void:
	var fe := de(nombre_tabla, c.pais, c.rep)
	poner(c.tactica, String(fe[0]), String(fe[1]))
	c.set_meta("estilo", String(fe[1]))

static func poner(t: Tactica, formacion: String, estilo: String) -> void:
	var forms: Variant = Datos.tabla("FORMS")
	t.formacion = formacion if forms is Dictionary and (forms as Dictionary).has(formacion) else "4-3-3"
	var p: Array = ESTILOS.get(estilo, ESTILOS["equilibrado"])
	t.mentalidad = int(p[0])
	t.presion = int(p[1])
	t.ritmo = int(p[2])
	t.linea = int(p[3])
	t.amplitud = int(p[4])
	t.verticalidad = int(p[5])
	t.tras_perdida = int(p[6])
	t.salida_corta = bool(p[7])
	t.tiro_lejano = bool(p[8])

## Para partidas viejas: solo si el club sigue con la táctica con la que nacían todos (4-3-3 y todo en «medio»).
static func aplicar_si_de_fabrica(c: Club) -> void:
	var t := c.tactica
	if t.formacion == "4-3-3" and t.mentalidad == 1 and t.presion == 1 and t.ritmo == 1 and t.linea == 1 and t.amplitud == 1 \
			and t.verticalidad == 1 and t.tras_perdida == 1 and not t.salida_corta and not t.tiro_lejano:
		aplicar(c, c.nombre)

## El estilo de un club ya creado («equilibrado» si no se sabe).
static func estilo_de(c: Club) -> String:
	return String(c.get_meta("estilo", "equilibrado")) if c != null else "equilibrado"
