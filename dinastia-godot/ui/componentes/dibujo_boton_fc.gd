class_name DibujoBotonFC
extends RefCounted
## EL DIBUJO DE LOS BOTONES DEL MANDO TÁCTIL (11-11-2026): fondo oscuro translúcido, ARO de color, texto en MAYÚSCULAS y TRIANGULITOS del color del botón en el aro,
## que indican hacia dónde se puede deslizar. Aparte de `ControlesTactiles` (norma de 450 líneas). Sin estado: todo llega por argumentos.

## `lienzo`: el control donde se dibuja; `c`, `r`: centro y radio; `col`: color del aro; `lineas`: etiqueta ya traducida (con «\n»); `opac`: opacidad de Ajustes;
## `activo`: dedo encima; `apagado`: botón sin acción; `s`: escala; `triangulos`: direcciones con gesto (`MandoFC.DIRS`); `alfa_texto`: 1 salvo en el cambio de posesión.
static func boton(lienzo: CanvasItem, c: Vector2, r: float, col: Color, lineas: PackedStringArray, opac: float, activo: bool, apagado: bool, s: float, triangulos: Array, alfa_texto := 1.0, fondo := 0.42, fac_texto := 0.30) -> void:
	var op_b := opac * (0.45 if apagado else 1.0)
	lienzo.draw_circle(c, r, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.62 * op_b) if activo else Color(0.04, 0.05, 0.08, fondo * op_b))
	lienzo.draw_arc(c, r, 0.0, TAU, 40, Color(col.r, col.g, col.b, (0.95 if activo else 0.75) * op_b), 4.0 * s)
	for d: Variant in triangulos:
		var v: Vector2 = MandoFC.VEC[String(d)]
		var perp := Vector2(-v.y, v.x)
		var base := c + v * (r + 4.0 * s)
		lienzo.draw_colored_polygon(PackedVector2Array([c + v * (r + 15.0 * s), base + perp * 7.0 * s, base - perp * 7.0 * s]), Color(col.r, col.g, col.b, 0.9 * op_b))
	var fuente := ThemeDB.fallback_font
	var tam := int(roundf(clampf(r * fac_texto, 11.0, 40.0 if fac_texto > 0.4 else 24.0)))
	for k in lineas.size():
		var y := c.y + float(tam) * 0.35 + (float(k) - float(lineas.size() - 1) * 0.5) * float(tam) * 1.15
		var tk := tam if k == 0 else int(tam * 0.85)
		var txt := lineas[k].to_upper()
		lienzo.draw_string_outline(fuente, Vector2(c.x - r, y), txt, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, tk, 5, Color(0, 0, 0, 0.8 * op_b * alfa_texto))
		lienzo.draw_string(fuente, Vector2(c.x - r, y), txt, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, tk, Color(1, 1, 1, (1.0 if k == 0 else 0.85) * op_b * alfa_texto))
