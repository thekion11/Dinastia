extends "res://nucleo/idiomas_p2.gd"
## [Capa intermedia de `idiomas.gd`, entre `idiomas_p2.gd` y `idiomas.gd`] mayusculas, _directa, _patron, _oraciones y `_t` con sus pasos (20-11, orden 63: partido en funciones).
## Va aparte porque `_t` (y sus pasos) llama a `_directa`, `_patron` y `_oraciones`: tienen que estar en una capa por debajo de `idiomas.gd`.

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
	if frase.length() > 1 and frase == frase.to_upper() and frase != frase.to_lower() and not (frase.length() == 3 and Paises.conocido(frase)):   ## un código de país (MAR, DOM) no es un título: «MAR» salía «TUE»
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
	return _por_plantilla(frase, prof)

## (4-11, A4) PLANTILLAS CON %s / %d: una clave con marcadores («Efecto durante %d semanas.») traduce también la frase ya FORMADA («…durante 5 semanas.»).
var _plantillas_de := {}   ## idioma → [[trozo literal más largo, RegEx, traducción], ...]

static func _escapar_re(t: String) -> String:
	var r := t
	for c: String in ["\\", ".", "^", "$", "|", "(", ")", "[", "]", "{", "}", "*", "+", "?"]:
		r = r.replace(c, "\\" + c)
	return r

func _plantillas() -> Array:
	if _plantillas_de.has(idioma):
		return _plantillas_de[idioma]
	var lista: Array = []
	var marca := RegEx.create_from_string("%[sd]")
	var ex: Dictionary = _extra.get(idioma, {})
	for k: String in ex:
		if not (k.contains("%s") or k.contains("%d")):
			continue
		var v := String(ex[k])
		var ms := marca.search_all(k)
		var mv := marca.search_all(v)
		if ms.size() != mv.size():
			continue
		var mismo := true
		for i in ms.size():
			mismo = mismo and ms[i].get_string() == mv[i].get_string()
		if not mismo:
			continue
		var patron := "^"
		var lit := ""
		var pos := 0
		for m: RegExMatch in ms:
			var trozo := k.substr(pos, m.get_start() - pos)
			patron += _escapar_re(trozo) + ("(.+?)" if m.get_string() == "%s" else "(-?\\d+)")
			if trozo.length() > lit.length():
				lit = trozo
			pos = m.get_end()
		var cola := k.substr(pos)
		patron += _escapar_re(cola) + "$"
		lit = cola if cola.length() > lit.length() else lit
		var re := RegEx.create_from_string(patron)
		if re.is_valid() and lit.length() >= 3:
			lista.append([lit, re, v])
	_plantillas_de[idioma] = lista
	return lista

func _por_plantilla(frase: String, prof: int) -> String:
	if frase.length() <= 6 or prof > 2:
		return ""
	for fila: Array in _plantillas():
		if not frase.contains(String(fila[0])):
			continue
		var m: RegExMatch = (fila[1] as RegEx).search(frase)
		if m == null:
			continue
		var salida := String(fila[2])
		var hueco := 0
		var res := ""
		var pos := 0
		for mm: RegExMatch in RegEx.create_from_string("%[sd]").search_all(salida):
			hueco += 1
			var g := m.get_string(hueco)
			if mm.get_string() == "%s" and _tiene_letras(g):
				g = _t(g, prof + 1)
			res += salida.substr(pos, mm.get_start() - pos) + g
			pos = mm.get_end()
		return res + salida.substr(pos)
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

func _t(frase: String, prof: int) -> String:
	var d := _directa(frase)
	if d != "" or prof > 3:
		return d if d != "" else frase
	var v: Variant = _t_icono(frase, prof)
	if v != null:
		return String(v)
	v = _t_cita(frase, prof)
	if v != null:
		return String(v)
	v = _t_oraciones(frase, prof)
	if v != null:
		return String(v)
	v = _t_medio(frase, prof)
	if v != null:
		return String(v)
	v = _t_tramos(frase, prof)
	if v != null:
		return String(v)
	## Por patrones: los grupos con letras también se traducen.
	var pp := _patron(frase, prof)
	return pp if pp != "" else frase

## Icono de delante (emoji, «⚠️ ») aparte antes de partir en oraciones.
func _t_icono(frase: String, prof: int) -> Variant:
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
	return null

## Una cita entera entre comillas: «Hay materia…» es la misma frase que sin ellas.
func _t_cita(frase: String, prof: int) -> Variant:
	## Una cita entera entre comillas (27-10-2026): «Hay materia prima…» es la misma frase que sin ellas.
	if frase.length() > 2 and frase.begins_with("«") and frase.ends_with("»"):
		var dentro := frase.substr(1, frase.length() - 2)
		var td := _t(dentro, prof + 1)
		if td != dentro:
			return "«" + td + "»"
	return null

## Por oraciones: la narración pega varias frases en un mismo texto.
func _t_oraciones(frase: String, prof: int) -> Variant:
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
	return null

## El icono y lo de detrás (emoji, flecha, ▸, :, …) aparte.
func _t_medio(frase: String, prof: int) -> Variant:
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
	return null

## Por tramos separados por «  ·  », «  — », «  | ».
func _t_tramos(frase: String, prof: int) -> Variant:
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
	return null
