class_name CebraRejilla
extends RefCounted
## FILAS ALTERNAS («cebra») EN LAS TABLAS DE DATOS (3-11-2026, evaluación de la interfaz: «tablas densas sin guías»): las filas impares de un
## `GridContainer` se pintan con una franja tenue DETRÁS de las celdas, de lado a lado. Una sola función para todas las rejillas de datos
## (`CebraRejilla.poner(g)`): se dibuja en el `draw` de la propia rejilla (que va antes que sus hijos) y no toca ni una celda.
## El tono es un gris medio con poca opacidad: sube ~4 % la luminosidad de un fondo oscuro y baja ~2 % la de uno claro.
const TONO := Color(0.62, 0.62, 0.62, 0.075)
const LINEA := Color(0.62, 0.62, 0.62, 0.10)   ## la guía de 1 px bajo cada fila (también sin zebra, p. ej. en filas sueltas)

static func poner(g: GridContainer) -> GridContainer:
	if g.has_meta("cebra"):
		return g
	g.set_meta("cebra", true)
	g.draw.connect(func() -> void: _pintar(g))
	g.sort_children.connect(g.queue_redraw)
	return g

static func _pintar(g: GridContainer) -> void:
	var cols := maxi(g.columns, 1)
	var n := g.get_child_count()
	var sep := float(g.get_theme_constant("v_separation"))
	var fila := 0
	var i := 0
	while i < n:
		var y0 := INF
		var y1 := -INF
		for k in range(i, mini(i + cols, n)):
			var c := g.get_child(k) as Control
			if c == null or not c.visible:
				continue
			y0 = minf(y0, c.position.y)
			y1 = maxf(y1, c.position.y + c.size.y)
		if y0 < INF:
			var r := Rect2(0.0, y0 - sep * 0.5, g.size.x, y1 - y0 + sep)
			if fila % 2 == 1:
				g.draw_rect(r, TONO)
			g.draw_line(Vector2(0.0, r.end.y - 0.5), Vector2(g.size.x, r.end.y - 0.5), LINEA, 1.0)
		fila += 1
		i += cols
