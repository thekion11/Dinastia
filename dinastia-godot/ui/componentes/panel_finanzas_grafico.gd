class_name GraficoFinanzas
extends Control
## LOS DOS GRÁFICOS DE LA PESTAÑA FINANZAS (paquete uifi, 25-10-2026).
##
## · `flujo()`: la caja de hoy y la de cada uno de los próximos 12 meses, en
##   barras, con el eje del cero, las cifras del eje Y y el número de mes. Antes
##   el «FLUJO DE CAJA A 12 MESES» eran dos líneas de texto; un mes en rojo se
##   ve en una barra mucho antes que leyendo «Punto más bajo».
## · `balance()`: lo que tiene el club (caja, plantel, instalaciones) en una
##   barra apilada y, debajo y a la misma escala, lo que debe. Se ve de golpe
##   cuánto del patrimonio es dinero de verdad y cuánto son jugadores.
##
## Solo dibuja lo que le pasan: no calcula nada del club (eso es de
## `PanelFinanzas`, que ya lee la proyección). Pasando el ratón por una barra,
## la ayuda da la cifra exacta.

var _modo := "flujo"
var _valores: Array[int] = []
## [[etiqueta, valor, color], …] del activo, y el pasivo aparte.
var _partes: Array = []
var _pasivo := 0
var _pal: Dictionary = {}
var _letra := 11

static func flujo(saldos: Array[int], paleta: Dictionary) -> GraficoFinanzas:
	var g := GraficoFinanzas.new()
	g._modo = "flujo"
	g._valores = saldos
	g._preparar(paleta)
	g.custom_minimum_size = Vector2(0, round(150.0 * float(paleta.get("escala", 1.0))))
	return g

static func balance(partes: Array, pasivo: int, paleta: Dictionary) -> GraficoFinanzas:
	var g := GraficoFinanzas.new()
	g._modo = "balance"
	g._partes = partes
	g._pasivo = pasivo
	g._preparar(paleta)
	g.custom_minimum_size = Vector2(0, round(78.0 * float(paleta.get("escala", 1.0))))
	return g

func _preparar(paleta: Dictionary) -> void:
	_pal = paleta
	_letra = maxi(9, int(round(10.0 * float(paleta.get("escala", 1.0)))))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	## Sin texto de ayuda, Godot no llama a `_get_tooltip()`.
	tooltip_text = " "
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(queue_redraw)

func _col(clave: String, si_no: Color) -> Color:
	return paleta_color(_pal, clave, si_no)

static func paleta_color(pal: Dictionary, clave: String, si_no: Color) -> Color:
	return pal[clave] if pal.has(clave) else si_no

func _draw() -> void:
	if _modo == "flujo":
		_dibujar_flujo()
	else:
		_dibujar_balance()

# ── FLUJO ───────────────────────────────────────────────────────────────────
## Las cifras del eje: el máximo, el cero y el mínimo (si baja de cero).
func _marcas_y(vmin: int, vmax: int) -> Array[int]:
	var m: Array[int] = [vmax]
	if vmin < 0:
		m.append(0)
	m.append(vmin)
	return m

func _rango() -> Vector2i:
	var vmin := 0
	var vmax := 0
	for v in _valores:
		vmin = mini(vmin, v)
		vmax = maxi(vmax, v)
	if vmax == vmin:
		vmax = vmin + 1
	return Vector2i(vmin, vmax)

func _area_flujo() -> Rect2:
	var f := get_theme_default_font()
	var r := _rango()
	var ancho_eje := 0.0
	for v in _marcas_y(r.x, r.y):
		ancho_eje = maxf(ancho_eje, f.get_string_size(Eco.dinero(v), HORIZONTAL_ALIGNMENT_LEFT, -1, _letra).x)
	var alto_txt := f.get_height(_letra)
	return Rect2(ancho_eje + 8.0, alto_txt * 0.5 + 2.0, maxf(10.0, size.x - ancho_eje - 10.0),
		maxf(10.0, size.y - alto_txt * 2.0 - 6.0))

func _y_de(v: int, a: Rect2, r: Vector2i) -> float:
	return a.position.y + float(r.y - v) / float(r.y - r.x) * a.size.y

func _dibujar_flujo() -> void:
	if _valores.is_empty():
		return
	var f := get_theme_default_font()
	var r := _rango()
	var a := _area_flujo()
	var suave := _col("suave", Color("8ea595"))
	var alto_txt := f.get_height(_letra)
	## Líneas guía y cifras del eje Y (a la derecha de su columna).
	for v in _marcas_y(r.x, r.y):
		var y := _y_de(v, a, r)
		draw_line(Vector2(a.position.x, y), Vector2(a.end.x, y), Color(suave, 0.55 if v == 0 else 0.22), 1.0)
		var txt := Eco.dinero(v)
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, _letra).x
		draw_string(f, Vector2(a.position.x - 6.0 - w, y + alto_txt * 0.32), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, _letra, suave)
	## Las barras: hoy en el color de la casa, los meses en verde o rojo.
	var n := _valores.size()
	var paso := a.size.x / float(n)
	var y0 := _y_de(0, a, r)
	for i in n:
		var v := _valores[i]
		var col := suave if i == 0 else (_col("verde", Color("4caf6d")) if v >= 0 else _col("rojo", Color("e05555")))
		var y := _y_de(v, a, r)
		var x := a.position.x + paso * float(i) + paso * 0.18
		draw_rect(Rect2(x, minf(y, y0), paso * 0.64, maxf(1.5, absf(y0 - y))), Color(col, 0.85))
		var et := Idiomas.t("Hoy") if i == 0 else str(i)
		var we := f.get_string_size(et, HORIZONTAL_ALIGNMENT_LEFT, -1, _letra).x
		draw_string(f, Vector2(a.position.x + paso * (float(i) + 0.5) - we * 0.5, a.end.y + alto_txt + 2.0), et,
			HORIZONTAL_ALIGNMENT_LEFT, -1, _letra, suave)

# ── BALANCE ─────────────────────────────────────────────────────────────────
func _total_activo() -> int:
	var t := 0
	for p: Array in _partes:
		t += maxi(0, int(p[1]))
	return t

func _area_balance() -> Dictionary:
	var f := get_theme_default_font()
	var izq := 0.0
	for et: String in [Idiomas.t("Activo"), Idiomas.t("Pasivo")]:
		izq = maxf(izq, f.get_string_size(et, HORIZONTAL_ALIGNMENT_LEFT, -1, _letra).x)
	izq += 8.0
	var alto := f.get_height(_letra) + 6.0
	return {"x": izq, "ancho": maxf(10.0, size.x - izq), "alto": alto}

func _dibujar_balance() -> void:
	var f := get_theme_default_font()
	var suave := _col("suave", Color("8ea595"))
	var ar := _area_balance()
	var x0: float = ar["x"]
	var ancho: float = ar["ancho"]
	var alto: float = ar["alto"]
	var escala := float(maxi(1, maxi(_total_activo(), _pasivo)))
	var base := alto * 0.72
	draw_string(f, Vector2(0, base), Idiomas.t("Activo"), HORIZONTAL_ALIGNMENT_LEFT, -1, _letra, suave)
	var x := x0
	for p: Array in _partes:
		var w := ancho * float(maxi(0, int(p[1]))) / escala
		if w <= 0.0:
			continue
		draw_rect(Rect2(x, 2.0, w, alto - 4.0), Color(p[2] as Color, 0.85))
		var pct := "%d%%" % int(round(float(p[1]) * 100.0 / float(maxi(1, _total_activo()))))
		var wp := f.get_string_size(pct, HORIZONTAL_ALIGNMENT_LEFT, -1, _letra).x
		if wp + 6.0 < w:
			draw_string(f, Vector2(x + (w - wp) * 0.5, base), pct, HORIZONTAL_ALIGNMENT_LEFT, -1, _letra, Color("0c130e"))
		x += w
	var y2 := alto + 4.0
	draw_string(f, Vector2(0, y2 + base), Idiomas.t("Pasivo"), HORIZONTAL_ALIGNMENT_LEFT, -1, _letra, suave)
	if _pasivo > 0:
		draw_rect(Rect2(x0, y2 + 2.0, maxf(2.0, ancho * float(_pasivo) / escala), alto - 4.0), Color(_col("rojo", Color("e05555")), 0.85))
	else:
		draw_string(f, Vector2(x0, y2 + base), Idiomas.t("sin deuda"), HORIZONTAL_ALIGNMENT_LEFT, -1, _letra, suave)
	## La leyenda, con el color de cada tramo.
	var ly := y2 + alto + 4.0
	var lx := x0
	var leyenda: Array = _partes.duplicate()
	leyenda.append([Idiomas.t("Pasivo"), _pasivo, _col("rojo", Color("e05555"))])
	for p: Array in leyenda:
		var et := String(p[0])
		var we := f.get_string_size(et, HORIZONTAL_ALIGNMENT_LEFT, -1, _letra).x
		if lx + 14.0 + we > size.x and lx > x0:
			break
		draw_rect(Rect2(lx, ly + 3.0, 9.0, 9.0), p[2] as Color)
		draw_string(f, Vector2(lx + 13.0, ly + base - 2.0), et, HORIZONTAL_ALIGNMENT_LEFT, -1, _letra, suave)
		lx += 13.0 + we + 14.0

# ── AYUDA AL PASAR EL RATÓN ─────────────────────────────────────────────────
func _get_tooltip(pos: Vector2) -> String:
	if _modo == "flujo":
		if _valores.is_empty():
			return ""
		var a := _area_flujo()
		var i := clampi(int((pos.x - a.position.x) / (a.size.x / float(_valores.size()))), 0, _valores.size() - 1)
		return (Idiomas.t("Caja hoy: %s") % Eco.dinero(_valores[i])) if i == 0 \
			else (Idiomas.t("Caja en el mes %d: %s") % [i, Eco.dinero(_valores[i])])
	var partes: PackedStringArray = []
	for p: Array in _partes:
		partes.append("%s: %s" % [String(p[0]), Eco.dinero(int(p[1]))])
	partes.append("%s: %s" % [Idiomas.t("Pasivo"), Eco.dinero(_pasivo)])
	return "\n".join(partes)
