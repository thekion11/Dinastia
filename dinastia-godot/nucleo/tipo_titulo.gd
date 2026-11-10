class_name TipoTitulo
extends RefCounted
## CADA TÍTULO, SU FESTEJO (10-11, encargo del dueño). Hasta hoy había una sola vuelta olímpica para todo; ahora el tipo de título decide la
## escena principal y qué festejos extra se ofrecen (`EventoCelebracion` los pinta en 2D; la liga conserva además la vuelta olímpica 3D).
##   liga        → levantar la copa en un ESCENARIO sobre el césped (+ vuelta olímpica 3D, pasillo de campeón del rival)
##   copa        → el PALCO y la entrega de medallas
##   continental → escenario con confeti y FUEGOS artificiales
##   supercopa   → palco (más corto)
##   ascenso / salvacion → festejo SOBRIO (abrazo en el círculo central y la grada)
## Extras comunes a los títulos: foto de plantilla con el trofeo, mantear al DT, champán en el vestuario y desfile en autobús descapotable.

const ESCENA := {"liga": "escenario", "copa": "palco", "continental": "fuegos", "supercopa": "palco", "ascenso": "sobrio", "salvacion": "sobrio", "seleccion": "fuegos"}

## El tipo de un título por su nombre, mirando las competiciones del mundo.
static func de(m: Mundo, nombre: String) -> String:
	if equipo_seleccion(m, nombre) != null:
		return "seleccion"
	var n := nombre.to_lower()
	if n.contains("ascenso"):
		return "ascenso"
	if n.contains("permanencia") or n.contains("salvaci"):
		return "salvacion"
	if n.contains("supercopa") or n.contains("recopa"):
		return "supercopa"
	if m != null:
		for l: Liga in m.ligas:
			if l.nombre == nombre:
				return "liga"
		if m.copa != null and m.copa.nombre == nombre:
			return "copa"
		for k: String in m.continentales:
			if Continental.nombre_conti(k) == nombre:
				return "continental"
	return "copa"

## La selección que acaba de ganar `nombre` (si lo ganó tu selección como seleccionador), o null.
static func equipo_seleccion(m: Mundo, nombre: String) -> Club:
	if m == null or m.selecciones == null or m.selecciones.cargo == null:
		return null
	var u: Dictionary = m.selecciones.cargo.ultimo_titulo
	return u.get("equipo", null) if String(u.get("torneo", "")) == nombre else null

## Los festejos que se ofrecen además de la escena principal, en orden.
static func extras(tipo: String) -> Array[String]:
	match tipo:
		"liga": return ["foto", "manteo", "champan", "desfile", "pasillo"]
		"copa", "continental": return ["foto", "manteo", "champan", "desfile"]
		"supercopa": return ["foto", "champan"]
		"seleccion": return ["foto", "manteo", "champan", "desfile"]
		_: return ["foto", "champan"]   ## ascenso y salvación: sin desfile ni manteo, más sobrio

## Rótulo grande de la escena principal.
static func rotulo(tipo: String) -> String:
	match tipo:
		"liga": return "¡CAMPEONES DE LIGA!"
		"copa": return "¡CAMPEONES DE COPA!"
		"continental": return "¡CAMPEONES DEL CONTINENTE!"
		"supercopa": return "¡SUPERCAMPEONES!"
		"ascenso": return "¡ASCENSO!"
		"salvacion": return "¡SALVADOS!"
		"seleccion": return "¡CAMPEONES CON LA SELECCIÓN!"
	return "¡CAMPEONES!"

## El nombre de cada escena en los botones.
static func nombre_escena(e: String) -> String:
	match e:
		"escenario": return "🏆 Levantar la copa"
		"palco": return "🎖️ Palco y medallas"
		"fuegos": return "🎆 Escenario y fuegos"
		"sobrio": return "🤝 Abrazo en el centro"
		"foto": return "📸 Foto con el trofeo"
		"manteo": return "🙌 Mantear al DT"
		"champan": return "🍾 Champán en el vestuario"
		"desfile": return "🚌 Desfile en autobús"
		"pasillo": return "👏 Pasillo del rival"
	return e

## FIN DE LIGA: ascenso (2.ª división, en zona de subida) o salvación (1.ª, objetivo «evitar el descenso» y fuera de la zona de bajada).
## Devuelve "ascenso", "salvacion" o "". Se mira la tabla ANTES de mover a nadie de división.
static func de_fin_de_liga(m: Mundo) -> String:
	var c := m.mi_club() if m != null else null
	if c == null:
		return ""
	var l := m.liga_de(c)
	if l == null:
		return ""
	var t := l.tabla()
	var puesto := t.size()
	for i in t.size():
		if (t[i] as Dictionary)["club"] == c:
			puesto = i + 1
	if l.division() >= 2 and puesto <= maxi(l.plazas_descenso, 2):
		return "ascenso"
	if l.division() == 1 and m.directiva != null and String(m.directiva.objetivo) == "Evitar el descenso" and puesto <= t.size() - l.plazas_descenso and puesto > 1:
		return "salvacion"
	return ""
