class_name ResumenInicio
extends RefCounted
## LO QUE EL MENÚ CENTRAL DEL PES 2020 TIENE Y EL NUESTRO NO (12-11-2026, referencia del dueño: foto de la Master League en su Drive,
## `PLAN_GENERAL.md` punto 14). Con nuestra estética (verde y dorado de `Tema`) y sin cargar el central (rediseño liviano del 3-11):
##   (la FILA DE ESCUDOS de los próximos partidos ya existe: `FilaProximos`, bajo la tira de días)
##   - una TABLA CORTA (los 5 primeros y, si no está entre ellos, tu club en su puesto), pulsable → Clubes (tablas);
##   - los SOCIOS del club en la misma línea de la tabla.
## Solo usa `Liga` y `Club` (nada de la ciudad ni del estadio: regla de la memoria del menú).

const N_TABLA := 5

## La tabla corta: los primeros `N_TABLA` y tu club si va más abajo, con los socios a la derecha. Null sin liga.
static func tabla_corta(c: Club, liga: Liga, ir: Callable) -> Control:
	var filas := filas_tabla(c, liga, N_TABLA)
	if filas.is_empty():
		return null
	var b := _boton(ir, "Clubes")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cab := HBoxContainer.new()
	cab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := _lbl(Idiomas.t("TABLA"), 11, Tema.SUAVE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(t)
	if c != null and c.socios > 0:
		cab.add_child(_lbl("%s %s" % [_miles(c.socios), Idiomas.t("socios")], 11, Tema.ORO))
	v.add_child(cab)
	for f: Dictionary in filas:
		var mio: bool = f["club"] == c
		var col := Tema.ORO if mio else Tema.TEXTO
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pos := _lbl("%d." % int(f["pos"]), 12, col)
		pos.custom_minimum_size.x = 26
		h.add_child(pos)
		var nom := _lbl((f["club"] as Club).nombre, 12, col)
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nom.clip_text = true
		h.add_child(nom)
		h.add_child(_lbl("%d" % int(f["pj"]), 12, Tema.SUAVE))
		var pts := _lbl("%d" % int(f["pts"]), 12, col)
		pts.custom_minimum_size.x = 28
		pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(pts)
		v.add_child(h)
	b.add_child(v)
	return b

## Filas {club, pos, pj, pts}: las `n` primeras y, si `c` no está entre ellas, la suya al final.
static func filas_tabla(c: Club, liga: Liga, n: int) -> Array:
	var res: Array = []
	if liga == null:
		return res
	var tabla := liga.tabla()
	for i in tabla.size():
		var f: Dictionary = tabla[i]
		if i < n or f["club"] == c:
			res.append({"club": f["club"], "pos": i + 1, "pj": f["pj"], "pts": f["pts"]})
	return res

static func _miles(x: int) -> String:
	var s := str(x)
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

## Un panel pulsable entero (mismo borde que las tarjetas del tablero), que crece con su contenido.
static func _boton(ir: Callable, destino: String) -> PanelContainer:
	var p := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Tema.TARJETA
	e.border_color = Color("26352b")
	e.set_border_width_all(1)
	e.set_corner_radius_all(10)
	e.content_margin_left = 12; e.content_margin_right = 12
	e.content_margin_top = 6; e.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", e)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			ir.call(destino))
	return p

static func _lbl(texto: String, tam: int, col: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
