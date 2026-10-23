extends "res://nucleo/idiomas_p1.gd"
## (Parte 2 de 2 de `idiomas.gd`.)

func _cargar_extra() -> void:
	if not FileAccess.file_exists(EXTRA):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(EXTRA))
	if not (d is Dictionary):
		return
	for k: String in ORDEN:
		_extra[k] = (d as Dictionary).get(k, {})
	## Cada patrón: [regex, plantilla en, pt, fr, it, de, ca, ...] en el orden
	## de `ORDEN`; una plantilla que falte deja la frase en castellano.
	_patrones.clear()
	for fila: Array in (d as Dictionary).get("patrones", []):
		var re := RegEx.new()
		if re.compile(String(fila[0])) == OK:
			var plantillas := {}
			for i in ORDEN.size():
				plantillas[ORDEN[i]] = String(fila[i + 1]) if fila.size() > i + 1 else ""
			_patrones.append([re, plantillas])
	_cargar_narracion()

func _ready() -> void:
	_cargar_extra()
func _ordinales(texto: String) -> String:
	if idioma == "fr":
		if _re_ord_fr == null:
			_re_ord_fr = RegEx.create_from_string("\\b1e\\b")
		return _re_ord_fr.sub(texto, "1er", true)
	if idioma == "ca":
		if _re_ord_ca == null:
			_re_ord_ca = RegEx.create_from_string("\\b(\\d+)(r|n|t|è)\\b")
		var salida := texto
		var hallados := _re_ord_ca.search_all(texto)
		hallados.reverse()
		for m: RegExMatch in hallados:
			var n := int(m.get_string(1))
			var suf := "r" if n == 1 or n == 3 else ("n" if n == 2 else ("t" if n == 4 else "è"))
			salida = salida.substr(0, m.get_start()) + m.get_string(1) + suf + salida.substr(m.get_end())
		return salida
	return texto

## Mayúsculas según el idioma: en turco la «i» con punto da «İ» y la «ı» sin
## punto da «I» (`to_upper()` daba «I» para las dos).
func mayusculas(texto: String) -> String:
	if idioma == "tr":
		texto = texto.replace("i", "İ").replace("ı", "I")
	return texto.to_upper()

func _directa(frase: String) -> String:
	var ex: Dictionary = _extra.get(idioma, {})
	if ex.has(frase) and String(ex[frase]) != "":
		return String(ex[frase])
	var i := ORDEN.find(idioma)
	if i >= 0 and TABLA.has(frase):
		var fila: Array = TABLA[frase]
		if i < fila.size() and String(fila[i]) != "":
			return String(fila[i])
	## TÍTULOS EN MAYÚSCULAS (29-9-2026): muchas cabeceras se pintan con
	## `to_upper()` antes de traducir ("PLANTEL", "PRÓXIMO PARTIDO"). Se busca
	## la forma normal ("Plantel", "Próximo partido") y se devuelve en mayúsculas.
	if frase.length() > 1 and frase == frase.to_upper() and frase != frase.to_lower():
		var baja := frase.to_lower()
		var normal := baja.substr(0, 1).to_upper() + baja.substr(1)
		for cand: String in [normal, baja]:
			if cand == frase:
				continue
			var r := _directa(cand)
			if r != "":
				return mayusculas(r)
	return ""

static func _tiene_letras(s: String) -> bool:
	for i in s.length():
		var c := s.unicode_at(i)
		if (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or (c >= 192 and c <= 687):
			return true
	return false

func _patron(frase: String, prof: int) -> String:
	for par: Array in _patrones:
		var m: RegExMatch = (par[0] as RegEx).search(frase)
		if m == null or m.get_start() != 0 or m.get_end() != frase.length():
			continue
		var plantilla := String((par[1] as Dictionary).get(idioma, ""))
		if plantilla == "":
			continue
		for g in range(m.get_group_count(), 0, -1):
			var v := m.get_string(g)
			if _tiene_letras(v):
				v = _t(v, prof + 1)
			plantilla = plantilla.replace("$%d" % g, v)
		return plantilla
	return ""

## Parte un texto en oraciones, conservando los espacios de entre medio.
func _oraciones(texto: String) -> Array:
	var partes: Array = []
	var ini := 0
	var i := 0
	while i < texto.length():
		var c := texto[i]
		if (c == "." or c == "!" or c == "?" or c == "»") and i + 1 < texto.length() and texto[i + 1] == " ":
			partes.append(texto.substr(ini, i + 1 - ini))
			ini = i + 1
		i += 1
	partes.append(texto.substr(ini))
	return partes

static func _es_letra(c: int) -> bool:
	return (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or (c >= 192 and c <= 687) or (c >= 48 and c <= 57) or c == 191 or c == 161

func _t(frase: String, prof: int) -> String:
	var d := _directa(frase)
	if d != "" or prof > 3:
		return d if d != "" else frase
	## Por oraciones: la narración a veces pega varias frases en un mismo
	## texto («Pregunta. Tardaste en contestar: en la sala se notó.»).
	if prof < 2 and frase.length() > 30 and (frase.contains(". ") or frase.contains("! ") or frase.contains("? ")):
		## Si el texto entero encaja en un patrón, gana el patrón.
		var entero := _patron(frase, prof)
		if entero != "":
			return entero
		var partes := _oraciones(frase)
		if partes.size() > 1:
			var cambio := false
			for k in partes.size():
				var o: String = partes[k]
				var limpia := o.strip_edges()
				if limpia == "":
					continue
				var to := _t(limpia, prof + 1)
				if to != limpia:
					partes[k] = o.replace(limpia, to)
					cambio = true
			if cambio:
				return "".join(partes)
	## El icono de delante (emoji, flecha) y lo de detrás (▸, :, …) aparte.
	var ini := 0
	while ini < frase.length() and not _es_letra(frase.unicode_at(ini)):
		ini += 1
	var fin := frase.length()
	while fin > ini and not _es_letra(frase.unicode_at(fin - 1)) and frase.unicode_at(fin - 1) != 41:
		fin -= 1
	if ini > 0 or fin < frase.length():
		var medio := frase.substr(ini, fin - ini)
		if medio != "" and medio != frase:
			var tm := _t(medio, prof + 1)
			if tm != medio:
				return frase.substr(0, ini) + tm + frase.substr(fin)
	## Por tramos.
	for sep: String in ["  ·  ", " · ", " — ", " | "]:
		if frase.contains(sep):
			var partes := frase.split(sep)
			var cambio := false
			for k in partes.size():
				var tp := _t(partes[k], prof + 1)
				if tp != partes[k]:
					cambio = true
				partes[k] = tp
			if cambio:
				return sep.join(partes)
	## Por patrones: los grupos con letras también se traducen.
	var pp := _patron(frase, prof)
	return pp if pp != "" else frase

## Traduce una frase suelta. Si no está en la tabla, devuelve la castellana: una
## interfaz medio traducida se lee; una llena de claves crudas, no.
## En orden: la frase entera; sin el icono o la flecha de los extremos; por
## tramos separados con « · »; y por patrones con números ("Jornada 3 de 30").
func t(frase: String) -> String:
	if idioma == "es" or frase == "":
		return frase
	var cache: Dictionary = _cache.get(idioma, {})
	if cache.has(frase):
		return cache[frase]
	var r := _ordinales(_t(frase, 0))
	cache[frase] = r
	_cache[idioma] = cache
	return r

## Traduce un árbol de interfaz entero (etiquetas, botones y ayudas). Para las
## pantallas que no cuelgan de la principal -la Carrera de Jugador, el
## partido jugable-. Guarda el castellano original en el propio nodo para poder
## volver a él o repintar en otro idioma.
func traducir_arbol(n: Node) -> void:
	if idioma == "es":
		return
	if n is Button:
		var b := n as Button
		if not b.has_meta("_i18n_src"):
			b.set_meta("_i18n_src", b.text)
		b.text = t(String(b.get_meta("_i18n_src")))
	elif n is Label:
		var l := n as Label
		if not l.has_meta("_i18n_src") or String(l.get_meta("_i18n_out", "")) != l.text:
			l.set_meta("_i18n_src", l.text)
		l.text = t(String(l.get_meta("_i18n_src")))
		l.set_meta("_i18n_out", l.text)
	if n is Control and (n as Control).tooltip_text != "":
		(n as Control).tooltip_text = t((n as Control).tooltip_text)
	for h in n.get_children():
		traducir_arbol(h)

## Cuántas frases hay traducidas a cada idioma. Lo usa la propia pantalla de
## ajustes para decir la verdad sobre la cobertura en vez de prometer un juego
## entero traducido.
func cobertura(cual: String) -> int:
	var i := ORDEN.find(cual)
	if i < 0:
		return TABLA.size()
	var n := 0
	var ex: Dictionary = _extra.get(cual, {})
	for k: String in ex:
		if not TABLA.has(k):
			n += 1
	for k: String in TABLA:
		var fila: Array = TABLA[k]
		if (i < fila.size() and String(fila[i]) != "") or String(ex.get(k, "")) != "":
			n += 1
	return n
