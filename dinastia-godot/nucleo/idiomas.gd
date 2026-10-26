extends "res://nucleo/idiomas_p1.gd"
## [Capa 2/2 de `idiomas.gd`] _cargar_extra, _ready, _ordinales, mayusculas, _directa, _tiene_letras … (+7)

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
	## El icono de delante («🙏 », «⚠️ ») aparte ANTES de partir en oraciones
	## (petición 2 de la sesión 2): con varias oraciones, la primera se traducía
	## sola y el resto quedaba en castellano aunque la frase entera sin el icono
	## fuera una clave. El móvil lo esquivaba con su propio `_t_icono`.
	## Solo símbolos (emoji, flechas: desde U+2000) y espacios: «, ¿ o ( son parte de la frase.
	var ini0 := 0
	while ini0 < frase.length() and (frase.unicode_at(ini0) >= 0x2000 or frase.unicode_at(ini0) == 32):
		ini0 += 1
	if ini0 > 0 and ini0 < frase.length():
		var resto := frase.substr(ini0)
		var dr := _directa(resto)
		if dr == "" and prof < 2:
			dr = _patron(resto, prof)
		if dr != "":
			return frase.substr(0, ini0) + dr
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

## DE DÓNDE VIENE UN TEXTO YA TRADUCIDO (s3, 26-10-2026). Lo que se construye
## una vez con `Idiomas.t` (botones de la cabecera, el panel de objetivos…) queda
## en el idioma de ese momento y no guarda su castellano: al cambiar de idioma en
## Opciones se quedaba en el anterior (arrancar en alemán y pasar a turco dejaba
## «📅 Kalender» o «Mit dem Mentor sprechen»). Devuelve la clave castellana de una
## traducción de cualquier idioma, con su icono delante, o "" si el texto ya es
## una clave castellana o no se conoce.
var _inverso := {}
func origen(texto: String) -> String:
	if texto == "" or _directa_es(texto):
		return ""
	if _inverso.is_empty():
		for k: String in TABLA:
			for v: Variant in TABLA[k]:
				if String(v) != "" and not _inverso.has(String(v)):
					_inverso[String(v)] = k
		for idi: String in ORDEN:
			var ex: Dictionary = _extra.get(idi, {})
			for k2: String in ex:
				var v2 := String(ex[k2])
				if v2 != "" and not _inverso.has(v2):
					_inverso[v2] = k2
	if _inverso.has(texto):
		return String(_inverso[texto])
	## Con el icono de delante aparte («📅 Kalender» → «📅 Calendario»).
	var i := 0
	while i < texto.length() and (texto.unicode_at(i) >= 0x2000 or texto.unicode_at(i) == 32):
		i += 1
	if i > 0 and i < texto.length() and _inverso.has(texto.substr(i)):
		return texto.substr(0, i) + String(_inverso[texto.substr(i)])
	return ""

## ¿Es ya una clave castellana conocida?
func _directa_es(texto: String) -> bool:
	if TABLA.has(texto):
		return true
	for idi: String in ORDEN:
		if (_extra.get(idi, {}) as Dictionary).has(texto):
			return true
	return false

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

## CAMBIO DE IDIOMA EN PARTIDA (26-10-2026, auditoría de textos). Muchos rótulos
## se escriben UNA vez al construir la pantalla (`Idiomas.t` al crearlos): al
## cambiar de idioma en Ajustes, `_refrescar()` repintaba lo dinámico, pero la
## barra de arriba («Calendario», «Un día», el buscador, el mentor...) seguía en
## el idioma anterior hasta reiniciar. Esto recorre el árbol, devuelve cada
## texto a su castellano con el diccionario inverso de `antes` y lo traduce al
## idioma nuevo. Lo que no reconoce (nombres, cifras) lo deja como está.
func retraducir_arbol(n: Node, antes: String) -> void:
	if antes == idioma:
		return
	var inv := _inverso_de(antes)
	_retraducir(n, antes, inv)

func _retraducir(n: Node, antes: String, inv: Dictionary) -> void:
	if (n is Button or n is Label) and not n.has_meta("_i18n_src"):
		var txt := String(n.get("text"))
		var es := _a_castellano(txt, antes, inv)
		if es != "":
			n.set("text", t(es))
	elif n is LineEdit:
		var le := n as LineEdit
		var es2 := _a_castellano(le.placeholder_text, antes, inv)
		if es2 != "":
			le.placeholder_text = t(es2)
	if n is Control and (n as Control).tooltip_text != "":
		var es3 := _a_castellano((n as Control).tooltip_text, antes, inv)
		if es3 != "":
			(n as Control).tooltip_text = t(es3)
	for h in n.get_children():
		_retraducir(h, antes, inv)

## Diccionario traducción -> castellano de un idioma (de las dos tablas).
func _inverso_de(cual: String) -> Dictionary:
	var inv := {}
	if cual == "es":
		return inv
	var ex: Dictionary = _extra.get(cual, {})
	for k: String in ex:
		inv[String(ex[k])] = k
	var i := ORDEN.find(cual)
	if i >= 0:
		for k: String in TABLA:
			var fila: Array = TABLA[k]
			if i < fila.size() and String(fila[i]) != "":
				inv[String(fila[i])] = k
	return inv

## El castellano de un texto pintado en `antes`, o "" si no se reconoce. Mira
## el texto entero y, si no, sin el icono de delante («📅 Takvim»).
func _a_castellano(txt: String, antes: String, inv: Dictionary) -> String:
	if txt.strip_edges() == "":
		return ""
	if antes == "es":
		return txt if _directa(txt) != "" else ""
	if inv.has(txt):
		return String(inv[txt])
	var ini := 0
	while ini < txt.length() and not _es_letra(txt.unicode_at(ini)):
		ini += 1
	if ini > 0 and ini < txt.length() and inv.has(txt.substr(ini)):
		return txt.substr(0, ini) + String(inv[txt.substr(ini)])
	return ""
