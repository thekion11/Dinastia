class_name FlechaForma
extends RefCounted
## LA FLECHA DE FORMA (10-11; idea de la «condición» del PES: una flecha de 5 estados junto a cada jugador). Sale de `Jugador.forma` (0-100), que ya
## existía pero no se veía en las listas: ↑ en racha, ↗ bien, → normal, ↘ baja, ↓ muy baja. No se guarda nada (lectura de la ficha).
const FLECHAS := ["↓", "↘", "→", "↗", "↑"]
const UMBRALES := [30, 45, 65, 80]   ## forma mínima para ↘, →, ↗ y ↑

static func nivel(j: Jugador) -> int:
	var n := 0
	for u: int in UMBRALES:
		if j.forma >= u:
			n += 1
	return n

static func color(n: int) -> Color:
	return [Tema.MAL, Color("e08a3c"), Tema.NEUTRO, Tema.BIEN, Tema.ORO][clampi(n, 0, 4)]

## La etiqueta lista para meter en una fila (con su explicación al pasar por encima).
static func etiqueta(j: Jugador, tam := 16) -> Label:
	var n := nivel(j)
	var l := Label.new()
	l.text = FLECHAS[n]
	l.add_theme_font_size_override("font_size", Tema.letra(tam))
	l.add_theme_color_override("font_color", color(n))
	l.custom_minimum_size = Vector2(16, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.tooltip_text = "%s: %d" % [Idiomas.t("Forma"), j.forma]
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	return l
