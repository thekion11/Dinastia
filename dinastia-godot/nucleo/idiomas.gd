extends "res://nucleo/idiomas_p3.gd"
## [Capa 3/3 de `idiomas.gd`] _cargar_extra, _ready, _ordinales, mayusculas, _directa, _tiene_letras … (+13)

## (3-11-2026, memoria en el móvil) `idiomas_extra.json` con los 9 idiomas ocupaba ~46 MB al arrancar. Ahora solo se guarda la tabla de los idiomas PEDIDOS (`_asegurar`): en castellano
## (que no traduce) no se carga ninguna; al elegir otro, la suya; lo que necesita varias a la vez (buscar el origen de un texto, medir coberturas) llama a `_asegurar_todos`.
func _asegurar(idi: String) -> void:
	if idi == "es" or _cargados.has(idi) or not ORDEN.has(idi):
		return
	_cargar_extra([idi])

func _asegurar_todos() -> void:
	var faltan: Array = []
	for k: String in ORDEN:
		if k != "es" and not _cargados.has(k):
			faltan.append(k)
	if not faltan.is_empty():
		_cargar_extra(faltan)

func _cargar_extra(cuales: Array = []) -> void:
	if not FileAccess.file_exists(EXTRA):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(EXTRA))
	if not (d is Dictionary):
		return
	for k: String in cuales:
		_extra[k] = (d as Dictionary).get(k, {})
		_cargados[k] = true
	_plantillas_de.clear(); _inverso.clear()   ## el origen de un texto puede estar en el idioma recién cargado
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
	_asegurar(idioma)
	TextoQueCabe.vigilar(get_tree())
	LectorPantalla.vigilar(get_tree())   ## M-284: lectura de pantalla, si está encendida
	TecladoPantalla.vigilar(get_tree())   ## M-441: teclado en pantalla con mando en PC/TV
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
## DE DÓNDE VIENE UN TEXTO YA TRADUCIDO (s3, 26-10-2026). Lo que se construye
## una vez con `Idiomas.t` (botones de la cabecera, el panel de objetivos…) queda
## en el idioma de ese momento y no guarda su castellano: al cambiar de idioma en
## Opciones se quedaba en el anterior (arrancar en alemán y pasar a turco dejaba
## «📅 Kalender» o «Mit dem Mentor sprechen»). Devuelve la clave castellana de una
## traducción de cualquier idioma, con su icono delante, o "" si el texto ya es
## una clave castellana o no se conoce.
var _inverso := {}
func origen(texto: String) -> String:
	## Un texto solo puede estar en un idioma que ya se haya cargado (para pintarlo hubo que elegirlo): no hace falta cargar los demás.
	if texto == "" or _directa_es(texto) or _directa_es(IdiomasInverso.normal(texto)):   ## «FORMA» es «Forma» en capitales (el título que pintó `to_upper()`), no la traducción en capitales de otra clave
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
const TOPE_CACHE := 20000   ## frases por idioma en la caché de `t`

func t(frase: String) -> String:
	if idioma == "es" or frase == "":
		return frase
	var cache: Dictionary = _cache.get(idioma, {})
	if cache.has(frase):
		return cache[frase]
	var r := _ordinales(_t(frase, 0))
	if cache.size() >= TOPE_CACHE:
		cache.clear()   ## (A4-INT) las frases con nombres y cifras no se repiten: sin tope la caché crecía toda la partida
	cache[frase] = r
	_cache[idioma] = cache
	## M-463 (28-10-2026): lo que se queda igual se anota, en vez de callar. Muchas son nombres propios o cifras
	## (que no se traducen); el recorrido de pantallas en otro idioma filtra las que parecen castellano.
	if r == frase and sin_traduccion.size() < 4000 and _tiene_letras(frase):
		sin_traduccion[frase] = int(sin_traduccion.get(frase, 0)) + 1
	return r

## Las frases que `t` devolvió sin cambios desde que arrancó el juego (frase → veces). Ver M-463.
var sin_traduccion: Dictionary = {}

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
	_asegurar(cual)
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
	_asegurar(cual)
	var inv := {}
	if cual == "es":
		return inv
	var ex: Dictionary = _extra.get(cual, {})
	for k: String in ex:
		inv[String(ex[k])] = IdiomasInverso.mejor(String(inv.get(String(ex[k]), "")), k, String(ex[k]))
	var i := ORDEN.find(cual)
	if i >= 0:
		for k: String in TABLA:
			var fila: Array = TABLA[k]
			if i < fila.size() and String(fila[i]) != "":
				inv[String(fila[i])] = IdiomasInverso.mejor(String(inv.get(String(fila[i]), "")), k, String(fila[i]))
	return inv

## El castellano de un texto pintado en `antes`, o "" si no se reconoce. Mira
## el texto entero y, si no, sin el icono de delante («📅 Takvim»).
func _a_castellano(txt: String, antes: String, inv: Dictionary) -> String:
	if txt.strip_edges() == "":
		return ""
	if antes == "es" or inv.is_empty():   ## un idioma sin tabla (ja) deja el castellano tal cual: se lee como castellano, no como una traducción
		return txt if _directa(txt) != "" else ""
	if inv.has(txt): return String(inv[txt])
	if IdiomasInverso.en_mayusculas(txt, inv) != "": return IdiomasInverso.en_mayusculas(txt, inv)   ## rótulos pintados con `to_upper()` («FORM»)
	var ini := 0
	while ini < txt.length() and not _es_letra(txt.unicode_at(ini)):
		ini += 1
	if ini > 0 and ini < txt.length() and inv.has(txt.substr(ini)):
		return txt.substr(0, ini) + String(inv[txt.substr(ini)])
	return ""
