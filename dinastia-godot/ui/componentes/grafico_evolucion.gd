class_name GraficoEvolucion
extends Control
## LA EVOLUCIÓN DE UN JUGADOR EN LA FICHA (2-11-2026, M-295): una línea con su media por temporada (eje de la
## izquierda, en verde) y otra con su valor de mercado (a su propia escala, en dorado, solo de temporadas que lo
## guardaron). Pasando el ratón, la ayuda da las cifras de la temporada más cercana. Solo dibuja `historial`.

var _hist: Array = []
var _pal: Dictionary = {}
var _letra := 10

static func de(historial: Array, paleta: Dictionary) -> GraficoEvolucion:
	var g := GraficoEvolucion.new()
	g._hist = historial.duplicate()
	g._pal = paleta
	g._letra = maxi(8, int(round(10.0 * float(paleta.get("escala", 1.0)))))
	g.custom_minimum_size = Vector2(0, round(90.0 * float(paleta.get("escala", 1.0))))
	g.mouse_filter = Control.MOUSE_FILTER_PASS
	return g

func _area() -> Rect2:
	return Rect2(Vector2(26, 6), size - Vector2(34, 22))

func _x(i: int) -> float:
	var a := _area()
	return a.position.x + a.size.x * (float(i) / float(maxi(1, _hist.size() - 1)))

func _draw() -> void:
	if _hist.size() < 2:
		return
	var a := _area()
	var f := get_theme_default_font()
	var suave: Color = _pal.get("suave", Color(0.6, 0.6, 0.6))
	var verde: Color = _pal.get("verde", Color(0.3, 0.8, 0.4))
	var oro := Color(0.95, 0.75, 0.25)
	var ovrs: Array[float] = []
	var vals: Array[float] = []
	for h: Dictionary in _hist:
		ovrs.append(float(h.get("ovr", 0)))
		vals.append(float(h.get("val", -1)))
	var lo := floorf((ovrs.min() - 2.0) / 5.0) * 5.0
	var hi := ceilf((ovrs.max() + 2.0) / 5.0) * 5.0
	draw_line(a.position + Vector2(0, a.size.y), a.end, Color(suave, 0.4), 1.0)
	draw_string(f, Vector2(0, a.position.y + _letra), str(int(hi)), HORIZONTAL_ALIGNMENT_LEFT, -1, _letra, suave)
	draw_string(f, Vector2(0, a.end.y), str(int(lo)), HORIZONTAL_ALIGNMENT_LEFT, -1, _letra, suave)
	## El valor, a su escala (si hay al menos dos temporadas con él).
	var con_val: Array[int] = []
	for i in vals.size():
		if vals[i] >= 0.0:
			con_val.append(i)
	if con_val.size() >= 2:
		var vmax := 1.0
		for i in con_val:
			vmax = maxf(vmax, vals[i])
		for k in range(1, con_val.size()):
			var i0 := con_val[k - 1]
			var i1 := con_val[k]
			draw_line(Vector2(_x(i0), a.end.y - a.size.y * vals[i0] / vmax), Vector2(_x(i1), a.end.y - a.size.y * vals[i1] / vmax), Color(oro, 0.85), 1.5, true)
	## La media, encima.
	for i in range(1, ovrs.size()):
		draw_line(Vector2(_x(i - 1), a.end.y - a.size.y * (ovrs[i - 1] - lo) / (hi - lo)),
			Vector2(_x(i), a.end.y - a.size.y * (ovrs[i] - lo) / (hi - lo)), verde, 2.0, true)
	for i in ovrs.size():
		draw_circle(Vector2(_x(i), a.end.y - a.size.y * (ovrs[i] - lo) / (hi - lo)), 2.5, verde)
	## Años en el eje: primero y último.
	draw_string(f, Vector2(_x(0) - 10, size.y - 2), str(_hist[0].get("anio", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, _letra, suave)
	draw_string(f, Vector2(_x(_hist.size() - 1) - 24, size.y - 2), str(_hist[-1].get("anio", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, _letra, suave)
	draw_string(f, Vector2(a.position.x + 4, a.position.y + _letra), Idiomas.t("— media"), HORIZONTAL_ALIGNMENT_LEFT, -1, _letra, verde)
	if con_val.size() >= 2:
		draw_string(f, Vector2(a.position.x + 64, a.position.y + _letra), Idiomas.t("— valor"), HORIZONTAL_ALIGNMENT_LEFT, -1, _letra, oro)

func _get_tooltip(pos: Vector2) -> String:
	if _hist.is_empty():
		return ""
	var mejor := 0
	for i in _hist.size():
		if absf(_x(i) - pos.x) < absf(_x(mejor) - pos.x):
			mejor = i
	var h: Dictionary = _hist[mejor]
	var t := Idiomas.t("%s · media %d") % [str(h.get("anio", "")), int(h.get("ovr", 0))]
	if int(h.get("val", -1)) >= 0:
		t += Idiomas.t(" · valor %s") % Eco.dinero(int(h["val"]))
	return t
