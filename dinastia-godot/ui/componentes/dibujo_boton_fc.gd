class_name DibujoBotonFC
extends RefCounted
## EL DIBUJO DE LOS BOTONES DEL MANDO TÁCTIL (11-11-2026): fondo oscuro translúcido, ARO de color, texto en MAYÚSCULAS y TRIANGULITOS del color del botón en el aro,
## que indican hacia dónde se puede deslizar. Aparte de `ControlesTactiles` (norma de 450 líneas). Sin estado: todo llega por argumentos.

## `lienzo`: el control donde se dibuja; `c`, `r`: centro y radio; `col`: color del aro; `lineas`: etiqueta ya traducida (con «\n»); `opac`: opacidad de Ajustes;
## `activo`: dedo encima; `apagado`: botón sin acción; `s`: escala; `triangulos`: direcciones con gesto (`MandoFC.DIRS`); `alfa_texto`: 1 salvo en el cambio de posesión.
## `fase` (12-11, móvil): -1 = todo; 0 = fondo, 1 = aro, 2 = triangulitos, 3 = contorno del texto, 4 = texto. Quien dibuja varios botones
## hace cada fase de todos antes de la siguiente. Y las formas son RECTÁNGULOS de una textura-atlas (`atlas()`): en Compatibility cada
## círculo, arco o polígono era su propia llamada de dibujo (31 del mando entero); los rectángulos de una misma textura van en un lote.
static func boton(lienzo: CanvasItem, c: Vector2, r: float, col: Color, lineas: PackedStringArray, opac: float, activo: bool, apagado: bool, s: float, triangulos: Array, alfa_texto := 1.0, fondo := 0.42, fac_texto := 0.30, fase := -1) -> void:
	var op_b := opac * (0.45 if apagado else 1.0)
	if fase < 0 or fase == 0:
		disco(lienzo, c, r, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.62 * op_b) if activo else Color(0.04, 0.05, 0.08, fondo * op_b))
	if fase < 0 or fase == 1:
		aro(lienzo, c, r, 4.0 * s, Color(col.r, col.g, col.b, (0.95 if activo else 0.75) * op_b))
	if fase < 0 or fase == 2:
		for d: Variant in triangulos:
			var v: Vector2 = MandoFC.VEC[String(d)]
			var punta := c + v * (r + 15.0 * s)
			var base := c + v * (r + 4.0 * s)
			var caja := Rect2(punta, Vector2.ZERO).expand(base + Vector2(-v.y, v.x) * 7.0 * s).expand(base - Vector2(-v.y, v.x) * 7.0 * s)
			lienzo.draw_texture_rect_region(atlas(), caja, REGION_TRI[String(d)], Color(col.r, col.g, col.b, 0.9 * op_b))
	if fase >= 0 and fase < 3:
		return
	var fuente := ThemeDB.fallback_font
	var tam := int(roundf(clampf(r * fac_texto, 11.0, 40.0 if fac_texto > 0.4 else 24.0)))
	for k in lineas.size():
		var y := c.y + float(tam) * 0.35 + (float(k) - float(lineas.size() - 1) * 0.5) * float(tam) * 1.15
		var tk := tam if k == 0 else int(tam * 0.85)
		var txt := lineas[k].to_upper()
		if fase != 4:
			lienzo.draw_string_outline(fuente, Vector2(c.x - r, y), txt, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, tk, 5, Color(0, 0, 0, 0.8 * op_b * alfa_texto))
		if fase != 3:
			lienzo.draw_string(fuente, Vector2(c.x - r, y), txt, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, tk, Color(1, 1, 1, (1.0 if k == 0 else 0.85) * op_b * alfa_texto))

## ── El atlas de formas (generado una vez en código: sin archivos) ──
const T := 256
const REGION_DISCO := Rect2(0, 0, T, T)
const REGION_ARO := Rect2(T, 0, T, T)
## Triangulitos de 64×64 bajo el disco y el aro, con la punta hacia su dirección.
const REGION_TRI := {"arriba": Rect2(0, T, 64, 64), "abajo": Rect2(64, T, 64, 64), "izquierda": Rect2(128, T, 64, 64), "derecha": Rect2(192, T, 64, 64)}
## Grosor del aro del atlas respecto a su radio exterior (el de los botones: 4 px a escala 1 sobre radios de ~60-90 px).
const ARO_GROSOR := 0.06
static var _atlas: ImageTexture

static func atlas() -> ImageTexture:
	if _atlas != null:
		return _atlas
	var img := Image.create(T * 2, T + 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var rad := T * 0.5 - 2.0
	for y in T:
		for x in T:
			var d := Vector2(x + 0.5 - T * 0.5, y + 0.5 - T * 0.5).length()
			img.set_pixel(x, y, Color(1, 1, 1, clampf(rad - d + 0.5, 0.0, 1.0)))
			var dentro := rad * (1.0 - ARO_GROSOR)
			img.set_pixel(T + x, y, Color(1, 1, 1, clampf(minf(rad - d, d - dentro) + 0.5, 0.0, 1.0)))
	for k in 4:
		var dir := String(MandoFC.DIRS[k])
		var o: Rect2 = REGION_TRI[dir]
		var v: Vector2 = MandoFC.VEC[dir]
		var tri := PackedVector2Array([Vector2(32, 32) + v * 30.0, Vector2(32, 32) - v * 30.0 + Vector2(-v.y, v.x) * 30.0, Vector2(32, 32) - v * 30.0 - Vector2(-v.y, v.x) * 30.0])
		for y in 64:
			for x in 64:
				if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), tri):
					img.set_pixel(int(o.position.x) + x, int(o.position.y) + y, Color(1, 1, 1, 1))
	_atlas = ImageTexture.create_from_image(img)
	return _atlas

## Un círculo lleno de radio `r` (un rectángulo del atlas).
static func disco(lienzo: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	lienzo.draw_texture_rect_region(atlas(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), REGION_DISCO, col)

## Un aro de radio `r` y grosor ~`ancho` (centrado en `r`, como `draw_arc`).
static func aro(lienzo: CanvasItem, c: Vector2, r: float, ancho: float, col: Color) -> void:
	var exterior := r + ancho * 0.5
	lienzo.draw_texture_rect_region(atlas(), Rect2(c - Vector2(exterior, exterior), Vector2(exterior, exterior) * 2.0), REGION_ARO, col)
