extends BaseIdea
## TEXTOS EN LOS 9 IDIOMAS SIN MARCAS SUELTAS (6-11, pista B punto 12). Recorre `datos/idiomas_extra.json` y exige, para cada traducción exacta de los 8 idiomas:
## los mismos marcadores de formato (%s, %d, %f…) y en el mismo número que la frase en castellano, las mismas etiquetas BBCode, los mismos saltos de línea,
## sin espacios sobrantes que la original no tenga y sin restos de plantillas ({0}, <x>, ???, TODO). Un marcador de menos rompe el `%` en pantalla;
## uno de más lo muestra tal cual al jugador.
const IDIOMAS := ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]

func _probar() -> void:
	_titulo("IDIOMAS · marcadores, etiquetas y saltos coherentes en las 8 traducciones")
	var f := FileAccess.open("res://datos/idiomas_extra.json", FileAccess.READ)
	_comprobar(f != null, "existe datos/idiomas_extra.json")
	if f == null:
		return
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	var re_spec := RegEx.create_from_string("%[-+0-9.]*[sdfxX%]")
	var re_tag := RegEx.create_from_string("\\[/?[a-z_]+(?:=[^\\]]*)?\\]")
	var re_resto := RegEx.create_from_string("\\{\\d*\\}|<[a-z]+>|\\?\\?\\?|TODO|XXX")
	var total := 0
	for l: String in IDIOMAS:
		var tabla: Dictionary = d[l]
		var malos: Array[String] = []
		for k: String in tabla:
			var v := String(tabla[k])
			total += 1
			var motivo := ""
			if _lista(re_spec, k) != _lista(re_spec, v):
				motivo = "marcadores"
			elif _lista(re_tag, k, true) != _lista(re_tag, v, true):
				motivo = "etiquetas"
			elif k.count("\n") != v.count("\n"):
				motivo = "saltos"
			elif v != v.strip_edges() and k == k.strip_edges():
				motivo = "espacios"
			elif re_resto.search(v) != null and re_resto.search(k) == null:
				motivo = "resto de plantilla"
			if motivo != "":
				malos.append("%s [%s]" % [k.left(40), motivo])
		_comprobar(malos.is_empty(), "%s: %d traducciones coherentes %s" % [l, tabla.size(), str(malos.slice(0, 4)) if not malos.is_empty() else ""])
	_comprobar(total > 20000, "se revisan %d traducciones exactas" % total)

## Los coincidentes de `re` ordenados (con `solo_nombre`, sin el «=valor» de las etiquetas).
func _lista(re: RegEx, texto: String, solo_nombre := false) -> String:
	var r: Array[String] = []
	for m in re.search_all(texto):
		var s := m.get_string()
		if solo_nombre and s.contains("="):
			s = s.get_slice("=", 0) + "]"
		r.append(s)
	r.sort()
	return ",".join(r)
