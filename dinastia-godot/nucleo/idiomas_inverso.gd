class_name IdiomasInverso
extends RefCounted
## DESEMPATE DEL DICCIONARIO INVERSO (18-11-2026). Al cambiar de idioma con una pantalla abierta, `Idiomas._inverso_de` pasa del texto traducido al castellano. Dos
## claves distintas pueden tener la MISMA traducción («Forma» y «Racha» son ambas «Form» en inglés): ganaba la última y el rótulo cambiaba de significado.
## Ahora gana la clave más parecida a la traducción (más letras iguales al principio): «Form» → «Forma». En un empate, la última, como siempre.

static func mejor(actual: String, nueva: String, traduccion: String) -> String:
	if actual == "":
		return nueva
	return nueva if _prefijo(nueva, traduccion) >= _prefijo(actual, traduccion) else actual

static func _prefijo(a: String, b: String) -> int:
	var nat := Nativo.de("nuc_prefijo_comun")
	if nat != null:
		return nat.nuc_prefijo_comun(a, b)
	return _prefijo_gd(a, b)

## Gemela GDScript de `nuc_prefijo_comun` (extensión C++, orden 63): respaldo sin binario y comparación en `pruebas/probar_nativo_puras.gd`.
static func _prefijo_gd(a: String, b: String) -> int:
	var x := a.to_lower()
	var y := b.to_lower()
	var n := 0
	while n < x.length() and n < y.length() and x.unicode_at(n) == y.unicode_at(n):
		n += 1
	return n

## Un texto en MAYÚSCULAS («FORM») que `Idiomas` produjo con la regla de títulos: se busca como «Form» o «form» y la clave sale en mayúsculas («FORMA»),
## para que al repintar pase otra vez por esa regla. "" si no es mayúsculas o no se reconoce.
static func en_mayusculas(txt: String, inv: Dictionary) -> String:
	if txt.length() < 2 or txt != txt.to_upper() or txt == txt.to_lower():
		return ""
	var baja := txt.to_lower()
	for cand: String in [baja.substr(0, 1).to_upper() + baja.substr(1), baja]:
		if inv.has(cand):
			return String(inv[cand]).to_upper()
	return ""

## La forma normal de un texto en MAYÚSCULAS («FORMA» → «Forma»); si no es todo mayúsculas, el mismo texto.
static func normal(texto: String) -> String:
	if texto.length() < 2 or texto != texto.to_upper() or texto == texto.to_lower():
		return texto
	var baja := texto.to_lower()
	return baja.substr(0, 1).to_upper() + baja.substr(1)
