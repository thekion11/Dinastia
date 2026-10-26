class_name CompeticionInfo
extends RefCounted
## QUÉ ES CADA COMPETICIÓN Y CÓMO SE LLAMA EN PANTALLA (26-10, pedido del dueño).
##
## El núcleo guarda las competiciones por su nombre de siempre («Copa del
## Mundo», «Mundial de Clubes», «Copa Cóndor», «Liga Argentina»...). Esta clase
## no cambia esos nombres -los usan las partidas guardadas, los logros y la
## narración generada- sino que decide:
##   - el TIPO (liga, copa, supercopa, continental, segunda continental,
##     mundial de clubes, mundial de selecciones, torneo de selecciones), del
##     que salen el logo (`LogoCompeticion`) y el trofeo (`Trofeo3D`);
##   - el NOMBRE VISIBLE: con la base ficticia, los torneos que en el núcleo
##     aún tienen el nombre real pasan a uno inventado que lo evoca (tabla en
##     `docs/05_referencia/competiciones.md`); con el pack real
##     (`Datos.base_real`), el nombre tal cual. Siempre por `Idiomas.t`.

## Nombre del núcleo -> nombre ficticio (solo con la base ficticia).
const FICTICIOS := {
	"Copa del Mundo": "Copa Mundial de Naciones",
	"Eurocopa": "Copa de Naciones del Viejo Continente",
	"Copa América": "Copa de Naciones del Sur",
	"Copa de Asia": "Copa Asiática de Naciones",
	"Copa África": "Copa de Naciones del Sol",
	"Copa Oro": "Copa de Naciones del Norte",
	"Copa de Oceanía": "Copa de Naciones del Pacífico",
	"Mundial de Clubes": "Copa Intercontinental de Campeones",
}
const SELECCIONES := ["Copa del Mundo", "Eurocopa", "Copa América", "Copa de Asia", "Copa África", "Copa Oro", "Copa de Oceanía"]
## Las claves de confederación de la segunda copa continental de clubes.
const SEGUNDAS := ["sud", "uel"]

## El tipo de la competición a partir de su nombre del núcleo (o el visible).
static func tipo_de(nombre: String) -> String:
	var n := nombre.strip_edges()
	if n == "Mundial de Clubes" or n == FICTICIOS["Mundial de Clubes"]:
		return "mundial_clubes"
	if n == "Copa del Mundo" or n == FICTICIOS["Copa del Mundo"]:
		return "mundial_sel"
	if n in SELECCIONES or n in FICTICIOS.values():
		return "selecciones"
	if n.begins_with("Supercopa"):
		return "supercopa"
	var confed: Variant = Datos.tabla("CONFED")
	if confed is Dictionary:
		for k: String in confed:
			var cn := String((confed[k] as Dictionary).get("n", ""))
			if n == cn or n == Nombres.de_tabla(cn) or n == Nombres.limpiar(cn):
				return "continental2" if k in SEGUNDAS else "continental"
	if n.begins_with("Copa") or n.ends_with("Cup") or n == "Copa":
		return "copa"
	return "liga"

## El nombre para enseñar (traducido).
static func nombre_visible(nombre: String) -> String:
	var n := nombre
	if not Datos.base_real:
		n = String(FICTICIOS.get(nombre, nombre))
	return Idiomas.t(n)

## Los dos colores de su identidad: un tono fijo por tipo y una variación por
## nombre, para que dos ligas no salgan iguales.
static func colores(nombre: String) -> Array[Color]:
	var t := tipo_de(nombre)
	var base := {"liga": 0.38, "copa": 0.0, "supercopa": 0.08, "continental": 0.6,
		"continental2": 0.07, "mundial_clubes": 0.12, "mundial_sel": 0.33, "selecciones": 0.55}
	var h := fposmod(float(base.get(t, 0.5)) + float(absi(hash(nombre)) % 100) / 1000.0, 1.0)
	var c1 := Color.from_hsv(h, 0.72, 0.55)
	var c2 := Color(0.93, 0.8, 0.42) if t in ["continental", "mundial_clubes", "mundial_sel", "supercopa"] else Color(0.95, 0.95, 0.97)
	return [c1, c2]

## Las siglas que van dentro del logo (el SVG no dibuja texto).
static func siglas(nombre: String) -> String:
	var s := ""
	for p in nombre_visible(nombre).split(" ", false):
		var ch := p.substr(0, 1)
		if ch == ch.to_upper() and ch != ch.to_lower():
			s += ch
		if s.length() >= 3:
			break
	return s if s != "" else "C"
