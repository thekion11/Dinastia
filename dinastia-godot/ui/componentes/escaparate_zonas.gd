class_name EscaparateZonas
extends RefCounted
## LAS ZONAS DE LA TABLA DE POSICIONES (17-11-2026, orden del dueño): primero en DORADO, plazas continentales con el color de cada competición, descenso en ROJO. Todo sale de DATOS: las plazas de cada
## país en cada torneo son los `cupos` de `FormatosConti` (Europa y Sudamérica) o el reparto a partes iguales de su confederación (las demás, como en `PlazasConti`), y el descenso es
## `Liga.plazas_descenso`. También el símbolo recreado de la liga (círculo con sus iniciales) y el color de fondo propio de cada liga (a partir de su nombre).

const COPAS := ["ucl", "uel", "uecl", "lib", "sud", "asia", "afr", "afr2", "conc", "oce"]
const COLOR := {"ucl": Color("2f6bff"), "uel": Color("ff8a1f"), "uecl": Color("3fbf6f"), "lib": Color("9b59ff"), "sud": Color("1fb5c9"),
	"asia": Color("e0558a"), "afr": Color("c9b037"), "afr2": Color("a89030"), "conc": Color("5b8def"), "oce": Color("4db6a4")}
const NOMBRE := {"ucl": "Champions League", "uel": "Europa League", "uecl": "Conference League", "lib": "Libertadores", "sud": "Sudamericana",
	"asia": "Champions asiática", "afr": "Champions africana", "afr2": "Copa africana", "conc": "Concacaf", "oce": "Oceanía"}
const CORTO := {"ucl": "UCL", "uel": "UEL", "uecl": "UECL", "lib": "LIB", "sud": "SUD", "asia": "ACL", "afr": "CAF", "afr2": "CAF2", "conc": "CON", "oce": "OFC"}
const ORO := Color("f3cf5a")
const ROJO := Color("e5484d")

## Cuántas plazas tiene el país `pais` en el torneo `k` (los cupos escritos, o el reparto a partes iguales de su confederación).
static func cupo(k: String, pais: String) -> int:
	if not FormatosConti.existe(k):
		return 0
	var escritos := 0
	var hay_cupos := false
	for fila: Array in FormatosConti.cupos(k):
		hay_cupos = true
		if String(fila[0]) == pais:
			escritos += int(fila[1])
	if hay_cupos:
		return escritos
	var paises := FormatosConti.paises_de(k)
	if not paises.has(pais):
		return 0
	var n := FormatosConti.plazas(k)
	return n if paises.size() <= 1 else ceili(float(n) / float(paises.size()))

## La zona de cada puesto (0-based) de la primera división de `liga`: [{"clave": "ucl"|"descenso"|"", "color": Color}]. Las copas se reparten en orden (la grande primero).
static func de(liga: Liga, n: int) -> Array:
	var zonas: Array = []
	for i in n:
		zonas.append({"clave": "", "color": Color(0, 0, 0, 0)})
	if liga == null:
		return zonas
	if liga.division() == 1:
		var i := 0
		for k: String in COPAS:
			for _j in cupo(k, liga.pais):
				if i < n:
					zonas[i] = {"clave": k, "color": COLOR[k]}
					i += 1
	for j in liga.plazas_descenso:
		if n - 1 - j >= 0:
			zonas[n - 1 - j] = {"clave": "descenso", "color": ROJO}
	return zonas

## La leyenda mínima: una entrada por zona que de verdad aparece [{color, nombre}].
static func leyenda(zonas: Array) -> Array:
	var vistos := {}
	var salida: Array = []
	for z: Dictionary in zonas:
		var k := String(z["clave"])
		if k == "" or vistos.has(k):
			continue
		vistos[k] = true
		salida.append({"color": z["color"], "nombre": Idiomas.t("Descenso") if k == "descenso" else String(CORTO.get(k, k)), "largo": Idiomas.t("Descenso") if k == "descenso" else String(NOMBRE.get(k, k))})
	return salida

## El color de fondo propio de la liga (un tono estable por su nombre, oscuro: sirve de fondo de la tarjeta).
static func color_liga(liga: Liga) -> Color:
	var h := float(absi(hash("liga|" + (liga.nombre if liga != null else "")) % 360)) / 360.0
	return Color.from_hsv(h, 0.55, 0.30)

## El símbolo recreado de la liga: un círculo del color de la liga con un aro y las iniciales de su nombre (no es el escudo real de ninguna competición).
class Simbolo extends Control:
	var texto := ""
	var color := Color.WHITE
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		draw_circle(c, r, color.lightened(0.15))
		draw_arc(c, r - 1.5, 0, TAU, 28, Color(1, 1, 1, 0.9), 2.0)
		draw_circle(c, r * 0.66, color.darkened(0.25))
		var f := ThemeDB.fallback_font
		var s := f.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 0.9))
		draw_string(f, Vector2(c.x - s.x * 0.5, c.y + r * 0.3), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 0.9), Color.WHITE)

static func simbolo(liga: Liga, lado: float) -> Control:
	var s := Simbolo.new()
	var ini := ""
	for w in (liga.nombre if liga != null else "").split(" ", false):
		if ini.length() < 2 and not ["de", "del", "la", "el"].has(String(w).to_lower()):
			ini += String(w).substr(0, 1).to_upper()
	s.texto = ini
	s.color = color_liga(liga).lightened(0.25)
	s.custom_minimum_size = Vector2(lado, lado)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return s
