class_name AspectoClub
extends RefCounted
## EL ASPECTO DE CADA CLUB REAL (orden 15 del dueño, 27-10-2026): escudo, uniforme y estadio parecidos al club de verdad, sin copiarlo. Los datos
## viven en la fila de `ESTADIO_CLUB` del pack real (privado, con los nombres retocados); esto solo los lee. Campos de la fila que usa:
## Viven en la tabla `ASPECTO_CLUB` (una fila por club, clave = nombre del pack) y, para escudo y camiseta, en la de `ESTADIO_CLUB` de antes; manda la nueva.
##   escudo   [forma, patrón]           (ya existía: ver `Escudo.FORMAS` y `Escudo.PATRONES`)
##   esc      [color1, color2, (color3)] colores del escudo (si no, los del club); el tercero, para los tricolores
##   emblema  figura de `EscudoEmblemas` (canon, ave, corona…)   letras  texto dibujado sobre el escudo (hasta 4)
##   siglas   «CC»                       las letras del escudo (si no, las mayúsculas del nombre)
##   camiseta diseño de `DisenosKit`     (ya existía)
##   kit      {c1, c2, pant, med}        colores de la camiseta, el pantalón y las medias (hex con #); lo que falte sale como siempre
## Quien se haya hecho un uniforme o un escudo propio (`kit_color1`, `esc_color1`, `kit_x`…) manda siempre sobre esto.

static func fila(c: Club) -> Dictionary:
	if c == null:
		return {}
	var r: Dictionary = c.fila_estadio_real().duplicate()
	var t: Variant = Datos.tabla("ASPECTO_CLUB")
	if t is Dictionary:
		var d := t as Dictionary
		var propia: Variant = d.get(c.nombre, d.get(Nombres.limpiar(c.nombre), {}))
		if propia is Dictionary:
			r.merge(propia as Dictionary, true)
	return r

## Color `i` (0 o 1) del escudo del club real; `por_defecto` si la fila no lo trae.
static func esc(c: Club, i: int, por_defecto: String) -> String:
	var r: Variant = fila(c).get("esc", [])
	return String(r[i]) if r is Array and (r as Array).size() > i else por_defecto

static func siglas(c: Club) -> String:
	return String(fila(c).get("siglas", ""))

## Un campo del uniforme real ("c1", "c2", "pant", "med"), o "" si no lo trae.
static func kit(c: Club, campo: String) -> String:
	var k: Variant = fila(c).get("kit", {})
	return String((k as Dictionary).get(campo, "")) if k is Dictionary else ""

## La figura sencilla del escudo (clave de `EscudoEmblemas.FIGURAS`) y las letras que lleva encima («U», «OM», «CABJ»); "" si no tiene.
static func emblema(c: Club) -> String:
	return String(fila(c).get("emblema", ""))

static func letras(c: Club) -> String:
	return String(fila(c).get("letras", ""))
