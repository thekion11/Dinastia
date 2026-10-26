class_name TrazoSuave
extends RefCounted
## LÍNEAS SIN DIENTES DE SIERRA (26-10-2026, fila 15 de la propuesta de la s4).
## `draw_line`/`draw_polyline` de 1-2 px se veían escalonados en los radares,
## la pizarra y el minimapa. Antialiased Line2D (MIT, Calinou,
## `addons/antialiased_line2d/`) dibuja la línea con una textura de borde suave y
## mipmaps hechos a mano, que se ve igual en Forward+ y en Compatibility y no
## depende del MSAA. Como es un NODO (un Line2D), las líneas fijas se crean una
## vez como hijos del control y solo se rehacen cuando cambian sus datos o su
## tamaño; lo que se mueve cada fotograma sigue con `draw_*` y `antialiased`.
##   TrazoSuave.linea(padre, puntos, color, ancho, cerrada)
##   TrazoSuave.limpiar(padre)

const META := "trazo_suave"

## Una línea suave hija de `padre`. `atras` la pone detrás de lo que el padre
## dibuja en su `_draw` (por ejemplo, la malla del radar bajo el relleno).
static func linea(padre: CanvasItem, puntos: PackedVector2Array, color: Color, ancho: float,
		cerrada: bool = false, atras: bool = false) -> Line2D:
	var l := AntialiasedLine2D.new()
	l.set_meta(META, true)
	l.points = AntialiasedLine2D.construct_closed_line(puntos) if cerrada and puntos.size() > 2 else puntos
	l.default_color = color
	l.width = ancho
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.show_behind_parent = atras
	padre.add_child(l)
	return l

## Un círculo (o arco) suave como polilínea.
static func arco(padre: CanvasItem, centro: Vector2, radio: float, color: Color, ancho: float,
		lados: int = 48, atras: bool = false) -> Line2D:
	var pts := PackedVector2Array()
	for i in lados:
		pts.append(centro + Vector2.from_angle(TAU * float(i) / float(lados)) * radio)
	return linea(padre, pts, color, ancho, true, atras)

## Un rectángulo hueco suave.
static func rect(padre: CanvasItem, r: Rect2, color: Color, ancho: float, atras: bool = false) -> Line2D:
	return linea(padre, PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
		Vector2(r.position.x, r.end.y)]), color, ancho, true, atras)

## Quita las líneas suaves que `linea` colgó de `padre` (no toca otros hijos).
static func limpiar(padre: Node) -> void:
	for h in padre.get_children():
		if h.has_meta(META):
			padre.remove_child(h)
			h.queue_free()

## Cuántas líneas suaves cuelgan de `padre` (para las pruebas).
static func cuantas(padre: Node) -> int:
	var n := 0
	for h in padre.get_children():
		if h.has_meta(META):
			n += 1
	return n
