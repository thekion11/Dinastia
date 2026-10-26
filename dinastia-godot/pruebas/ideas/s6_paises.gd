extends BaseIdea
## SESIÓN 6 (26-10-2026), fila 26 de la propuesta s4 («más países jugables sin
## escribirlos a mano»): MIDE cuántos países conoce el juego y qué les falta para
## ser jugables -liga, nombre del país, nombre traducido a los 8 idiomas, bolsa de
## nombres propia y regiones-. Comprueba que los que ya tienen liga lo tienen todo;
## el resto lo cuenta (es la lista de trabajo de CLDR / GeoNames / faker).

const IDIOMAS := ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]
## Los hispanohablantes sin bolsa propia usan la de fábrica (chilena): cuenta como bolsa.
const HISPANOS := ["CHI", "ARG", "URU", "PAR", "COL", "PER", "ECU", "BOL", "VEN"]

var _extra: Dictionary = {}

## Si la frase está en las 8 tablas de `idiomas_extra.json` (un nombre igual en otro
## idioma, como «Australia», también cuenta: está, aunque se escriba igual).
func _en_los_9(frase: String) -> bool:
	if _extra.is_empty():
		_extra = JSON.parse_string(FileAccess.get_file_as_string("res://datos/idiomas_extra.json"))
	for l in IDIOMAS:
		if not (_extra.get(l, {}) as Dictionary).has(frase):
			return false
	return true

func _probar() -> void:
	_titulo("S6: COBERTURA DE PAÍSES (fila 26)")
	var bandera: Dictionary = Datos.tabla("BANDERA")
	var ligas: Dictionary = Datos.tabla("PAISES_LIGAS")
	var nombres: Dictionary = Datos.tabla("PAIS_SELECCION")
	var pools: Dictionary = Datos.tabla("POOLS_EU")
	var bolsas := {}
	var f := FileAccess.get_file_as_string("res://datos/bolsas_nombres.json")
	var bj: Variant = JSON.parse_string(f)
	if bj is Dictionary:
		bolsas = (bj as Dictionary).get("bolsas", {})
	var cuenta := {"total": bandera.size(), "liga": 0, "nombre": 0, "traducido": 0, "bolsa": 0, "regiones": 0}
	var faltan_liga: Array[String] = []
	var mal_con_liga: Array[String] = []
	for cod: String in bandera:
		var con_liga := ligas.has(cod) or cod == "CHI"
		var con_nombre := nombres.has(cod)
		var traducido := con_nombre and _en_los_9(String(nombres.get(cod, "")))
		var con_bolsa := pools.has(cod) or bolsas.has(cod) or cod in HISPANOS
		var con_region := cod == "ESP"
		cuenta["liga"] += 1 if con_liga else 0
		cuenta["nombre"] += 1 if con_nombre else 0
		cuenta["traducido"] += 1 if traducido else 0
		cuenta["bolsa"] += 1 if con_bolsa else 0
		cuenta["regiones"] += 1 if con_region else 0
		if not con_liga:
			faltan_liga.append(cod)
		elif not (con_nombre and con_bolsa):
			mal_con_liga.append(cod)
	_linea("  Países con bandera: %d · con liga: %d · con nombre: %d · nombre traducido: %d · bolsa de nombres: %d · con regiones: %d" % [
		cuenta["total"], cuenta["liga"], cuenta["nombre"], cuenta["traducido"], cuenta["bolsa"], cuenta["regiones"]])
	_linea("  Sin liga (%d): %s" % [faltan_liga.size(), ", ".join(faltan_liga)])
	_comprobar(cuenta["total"] >= 80, "el juego conoce %d países (por sus banderas)" % cuenta["total"])
	_comprobar(mal_con_liga.is_empty(), "todos los países con liga tienen nombre y bolsa de nombres %s" % str(mal_con_liga))
	_comprobar(cuenta["liga"] == ligas.size() + (0 if ligas.has("CHI") else 1), "jugables hoy: %d de %d (faltan %d)" % [cuenta["liga"], cuenta["total"], faltan_liga.size()])
	## Con datos/paises.json (CLDR): todos los que tienen bandera tienen nombre en los 9 idiomas.
	var sin_nombre: Array[String] = []
	for cod2: String in bandera:
		if not Paises.conocido(cod2) or not _en_los_9(Paises.nombre_es(cod2)):
			sin_nombre.append(cod2)
	_comprobar(sin_nombre.is_empty(), "los %d países con bandera tienen nombre en los 9 idiomas (CLDR) %s" % [bandera.size(), str(sin_nombre)])
	Idiomas.idioma = "de"
	var de := Paises.nombre("CIV") + " / " + PersonajeDatos.nombre_pais("NED") + " / " + PersonajeDatos.nombre_pais("GER")
	Idiomas.idioma = "es"
	_comprobar(de == "Côte d’Ivoire / Niederlande / Deutschland", "en alemán: «%s»" % de)
	_comprobar(Paises.nombre("CIV") == "Costa de Marfil" and Paises.iso("ENG") == "gb-eng", "en castellano «Costa de Marfil», y la bandera de Inglaterra es gb-eng")
