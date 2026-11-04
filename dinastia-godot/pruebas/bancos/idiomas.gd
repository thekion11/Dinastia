extends BaseIdea
## BANCO «idiomas» · PRUEBAS PROPIAS (fase 2, 4-11-2026): los 9 idiomas en detalle. Parte A (en proceso, segundos): la tabla `idiomas_extra.json` de cada
## idioma contra la de los demás (mismas claves, nada vacío, mismos marcadores %s/%d, mismas etiquetas BBCode, mismos saltos de línea, sin caracteres
## rotos, glifo en las fuentes propias para cada letra), los patrones con números (regex válida, `$n` existentes, plantilla en los 8 idiomas) y el
## comportamiento de `Idiomas.t` (ida y vuelta, mayúsculas turcas, ordinales franceses y catalanes). Parte B (`IDIOMAS_PANTALLAS=1` o sin `IDIOMAS_RAPIDO`,
## minutos): el recorrido de TODAS las pantallas en cada idioma, sin castellano suelto y con pocos textos cortados.
const LANGS := ["en", "pt", "fr", "it", "de", "ca", "pl", "tr"]
const MARCADOR := "%[-+0#]*\\d*(?:\\.\\d+)?[sdfxXc%]"
const ETIQUETA := "\\[/?[a-z_]+(?:=[^\\]]*)?\\]"
## Frases que el recorrido da por castellano sin traducir (el detector ya descuenta las palabras compartidas con pt/ca/it/fr, `COMPARTIDAS` en recorrido_pantallas.gd). Medido el 4-11-2026: 0-1 por idioma;
## el tope 3 deja margen a las frases que salen según el azar de la partida (eventos, noticias).
const TOPE_CASTELLANO := {"en": 3, "de": 3, "tr": 3, "pt": 3, "ca": 3, "fr": 3, "it": 3, "pl": 3}
var _d: Dictionary = {}
var _re_marca: RegEx
var _re_tag: RegEx

func _marcas(s: String) -> Array:
	var r: Array = []
	for m: RegExMatch in _re_marca.search_all(s):
		r.append(m.get_string())
	r.sort()
	return r

func _tags(s: String) -> Array:
	var r: Array = []
	for m: RegExMatch in _re_tag.search_all(s):
		var t := m.get_string()
		r.append(t.get_slice("=", 0).trim_suffix("]") + "]")
	return r

func _probar() -> void:
	_titulo("BANCO IDIOMAS · los 9 idiomas, tabla por tabla")
	_respaldar_user()
	_re_marca = RegEx.create_from_string(MARCADOR)
	_re_tag = RegEx.create_from_string(ETIQUETA)
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(Idiomas.EXTRA))
	_comprobar(d is Dictionary, "idiomas_extra.json se lee")
	if not (d is Dictionary):
		return
	_d = d
	_comprobar(Idiomas.ORDEN.size() == 8 and Array(Idiomas.ORDEN) == Array(LANGS), "ORDEN lista los 8 idiomas traducidos (+ el castellano, que es la clave) (%s)" % str(Idiomas.ORDEN))
	for l: String in LANGS:
		_comprobar(_d.has(l) and (_d[l] as Dictionary).size() > 1000, "%s: la tabla existe y es grande (%d textos)" % [l, (_d.get(l, {}) as Dictionary).size()])
	_estructura()
	_marcadores_y_etiquetas()
	_caracteres_y_glifos()
	_fuga_de_castellano()
	_patrones()
	_comportamiento()
	if OS.get_environment("IDIOMAS_RAPIDO") == "":
		await _pantallas()
	_restaurar_user()

## Mismas claves en los 8 idiomas, nada vacío.
func _estructura() -> void:
	var union := {}
	for l: String in LANGS:
		for k: String in _d[l]:
			union[k] = true
	Idiomas._asegurar_todos()
	for l: String in LANGS:
		var faltan := 0
		var vacias := 0
		var ejemplo := ""
		Idiomas.idioma = l
		## Una clave que la tabla del idioma no trae puede venir de las otras fuentes (TABLA, narración): solo falta si `t` la deja en castellano.
		for k: String in union:
			if not (_d[l] as Dictionary).has(k) and Idiomas.t(k) == k:
				faltan += 1
				ejemplo = k
		for k: String in _d[l]:
			if String(_d[l][k]).strip_edges() == "":
				vacias += 1
		## pt, ca e it comparten muchas palabras con el castellano («Mundo», «Exportar», «Música»): ahí caben más cognados.
		var tope := 80 if l in ["pt", "ca", "it"] else 8
		_comprobar(faltan <= tope, "%s: resuelve las %d claves de la unión (sin traducir %d, tope %d) %s" % [l, union.size(), faltan, tope, ejemplo.left(60)])
		_comprobar(vacias == 0, "%s: ningún texto vacío (%d)" % [l, vacias])
	Idiomas.idioma = "es"

## %s/%d/%.1f iguales y las mismas etiquetas BBCode y saltos de línea que el original.
func _marcadores_y_etiquetas() -> void:
	for l: String in LANGS:
		var m1: Array[String] = []
		var m2: Array[String] = []
		var m3: Array[String] = []
		for k: String in _d[l]:
			var v := String(_d[l][k])
			if _marcas(k) != _marcas(v):
				m1.append(k.left(50))
			if _tags(k) != _tags(v):
				m2.append(k.left(50))
			if k.count("\n") != v.count("\n"):
				m3.append(k.left(50))
		_comprobar(m1.is_empty(), "%s: mismos marcadores %%s/%%d que el original (%d distintos) %s" % [l, m1.size(), str(m1.slice(0, 3))])
		_comprobar(m2.is_empty(), "%s: mismas etiquetas [b]… que el original (%d distintas) %s" % [l, m2.size(), str(m2.slice(0, 3))])
		_comprobar(m3.size() <= 3, "%s: mismos saltos de línea (%d distintos) %s" % [l, m3.size(), str(m3.slice(0, 3))])

## Sin cuadros ni control; cada carácter tiene glifo en la cadena de fuentes propias.
func _caracteres_y_glifos() -> void:
	var cadena: Array[Font] = Fuentes.repuesto()
	var base := Fuentes.propia("Inter")
	if base != null:
		cadena.push_front(base)
	for l: String in LANGS:
		var usados := {}
		var rotos := 0
		for k: String in _d[l]:
			var v := String(_d[l][k])
			for i in v.length():
				var c := v.unicode_at(i)
				usados[c] = true
				if c == 0xFFFD or (c < 32 and c != 10 and c != 9) or c == 0x7F:
					rotos += 1
		var sin: Array[String] = []
		for cp: int in usados:
			if cp < 32:
				continue
			var hay := false
			for f: Font in cadena:
				if f.has_char(cp):
					hay = true
					break
			if not hay:
				sin.append("%s U+%04X" % [String.chr(cp), cp])
		_comprobar(rotos == 0, "%s: sin caracteres rotos ni de control (%d)" % [l, rotos])
		_comprobar(sin.is_empty(), "%s: %d caracteres distintos, todos con glifo %s" % [l, usados.size(), str(sin.slice(0, 12))])

## Marcas inequívocas del castellano en un idioma que no lo usa («¿», «¡», «ñ», «ción»): se toleran los nombres propios.
func _fuga_de_castellano() -> void:
	var re := RegEx.create_from_string("[¿¡]|ñ|ción\\b|ciones\\b|\\b(los|las|para)\\s")
	for l: String in ["en", "de", "fr", "it", "pl", "tr"]:
		var sospechosos: Array[String] = []
		for k: String in _d[l]:
			var v := String(_d[l][k])
			if re.search(v) != null and re.search(k) != null and (v == k or v.similarity(k) > 0.8):
				sospechosos.append(v.left(50))
		_comprobar(sospechosos.size() <= 25, "%s: pocos textos que siguen en castellano (%d, tope 25) %s" % [l, sospechosos.size(), str(sospechosos.slice(0, 3))])
	for l: String in LANGS:
		var iguales := 0
		var largos := 0
		for k: String in _d[l]:
			if k.length() > 12 and k.contains(" "):
				largos += 1
				if String(_d[l][k]) == k:
					iguales += 1
		_comprobar(largos == 0 or float(iguales) / float(largos) < 0.12, "%s: menos del 12 %% de las frases largas quedan igual que el castellano (%d de %d)" % [l, iguales, largos])

## Patrones con números: la regex compila, las plantillas usan solo $n que existen, y están en los 8 idiomas.
func _patrones() -> void:
	var pats: Array = _d.get("patrones", [])
	_comprobar(pats.size() > 100, "hay patrones con números (%d)" % pats.size())
	var re_ref := RegEx.create_from_string("\\$(\\d)")
	var mal_regex := 0
	var mal_cols := 0
	var mal_ref: Array[String] = []
	var vacios := 0
	for f: Array in pats:
		if f.size() != 9:
			mal_cols += 1
			continue
		var re := RegEx.new()
		if re.compile(String(f[0])) != OK:
			mal_regex += 1
			continue
		var n := re.get_group_count()
		for i in range(1, 9):
			var plantilla := String(f[i])
			if plantilla.strip_edges() == "":
				vacios += 1
			for m: RegExMatch in re_ref.search_all(plantilla):
				if int(m.get_string(1)) > n:
					mal_ref.append("%s → $%s" % [String(f[0]).left(40), m.get_string(1)])
	_comprobar(mal_cols == 0, "cada patrón trae regex + 8 plantillas (%d mal)" % mal_cols)
	_comprobar(mal_regex == 0, "todas las regex compilan (%d no)" % mal_regex)
	_comprobar(mal_ref.is_empty(), "ninguna plantilla usa un $n que la regex no captura %s" % str(mal_ref.slice(0, 3)))
	_comprobar(vacios == 0, "ninguna plantilla vacía (%d)" % vacios)

## `Idiomas.t` de verdad: ida y vuelta con claves reales, patrones, mayúsculas turcas y ordinales.
func _comportamiento() -> void:
	var antes := Idiomas.idioma
	Idiomas._asegurar_todos()
	for l: String in LANGS:
		Idiomas.idioma = l
		var malas := 0
		var n := 0
		var claves: Array = (_d[l] as Dictionary).keys()
		var paso := maxi(claves.size() / 300, 1)
		for i in range(0, claves.size(), paso):
			n += 1
			if Idiomas.t(String(claves[i])) != String(_d[l][claves[i]]) and not String(claves[i]).contains("%"):
				malas += 1
		_comprobar(malas <= n / 50, "%s: Idiomas.t devuelve la traducción de %d claves muestreadas (%d distintas)" % [l, n, malas])
		_comprobar(Idiomas.t("texto que no existe en ninguna tabla 12345") == "texto que no existe en ninguna tabla 12345", "%s: lo que no se conoce se deja tal cual" % l)
	Idiomas.idioma = "tr"
	_comprobar(Idiomas.mayusculas("izmir") == "İZMİR" and Idiomas.mayusculas("ılık") == "ILIK", "tr: mayúsculas turcas (i→İ, ı→I)")
	Idiomas.idioma = "en"
	_comprobar(Idiomas.mayusculas("istanbul") == "ISTANBUL", "en: mayúsculas normales")
	Idiomas.idioma = "ca"
	_comprobar(Idiomas._ordinales("el 1r, 2r, 3r, 4r i 5r") == "el 1r, 2n, 3r, 4t i 5è", "ca: ordinales (1r 2n 3r 4t 5è)")
	Idiomas.idioma = "fr"
	_comprobar(Idiomas._ordinales("le 1e et 2e") == "le 1er et 2e", "fr: 1e → 1er")
	Idiomas.idioma = "es"
	_comprobar(Idiomas.t("Plantel") == "Plantel", "es: el castellano no se toca")
	Idiomas.idioma = antes

## Parte B: el recorrido de todas las pantallas en cada idioma (proceso aparte por idioma).
func _pantallas() -> void:
	var exe := OS.get_executable_path()
	var raiz := ProjectSettings.globalize_path("res://")
	for l: String in LANGS:
		var salida: Array = []
		var t0 := Time.get_ticks_msec()
		var largos := OS.get_user_data_dir() + "/largos_%s.json" % l
		OS.set_environment("RECORRIDO_IDIOMA", l)
		OS.set_environment("RECORRIDO_CASTELLANO_MAX", str(int(TOPE_CASTELLANO[l])))
		OS.set_environment("RECORRIDO_LARGOS", largos)
		OS.set_environment("RECORRIDO_CORTADOS_MAX", "6")
		OS.execute(exe, ["--headless", "--path", raiz, "res://pruebas/recorrido_pantallas.tscn"], salida, true)
		var out := "\n".join(PackedStringArray(salida))
		var cast := out.find("FIN CASTELLANO. 0 fallos") >= 0
		var cort := out.find("FIN LARGOS. 0 fallos") >= 0
		var m := RegEx.create_from_string("CASTELLANO: (\\d+) frases").search(out)
		var n_largos := RegEx.create_from_string("LARGOS: (\\d+) textos que no caben \\((\\d+) cortados\\)").search(out)
		_comprobar(cast, "%s: el recorrido de pantallas deja pocas frases en castellano (%s, tope %d)" % [l, m.get_string(1) if m != null else "?", TOPE_CASTELLANO[l]])
		_comprobar(cort, "%s: como mucho 6 textos cortados (%s) · %d s" % [l, (n_largos.get_string(2) + " de " + n_largos.get_string(1)) if n_largos != null else "?", (Time.get_ticks_msec() - t0) / 1000])
	for v: String in ["RECORRIDO_IDIOMA", "RECORRIDO_CASTELLANO_MAX", "RECORRIDO_LARGOS", "RECORRIDO_CORTADOS_MAX"]:
		OS.unset_environment(v)
