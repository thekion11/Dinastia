extends BaseIdea
## s3 (26-10-2026): AUDITORÍA DE LA INTERFAZ DE LA PRINCIPAL (orden del dueño: textos cortados, foco con
## mando, en 1280×720 y 1920×1080, en español, alemán y turco). Recorre TODAS las pestañas de los
## bloques y de los hubs y mira lo que de verdad se ve:
##  · cortado: una etiqueta o un botón que recorta su texto (clip u «…») y no le cabe;
##  · sin foco: un botón visible al que no se llega con el mando (`FOCUS_NONE`).
## Lo visual fino (solapes, contraste) se mira en capturas aparte (`pruebas/captura_s3_interfaz.tscn`).
## AUDITORIA=detalle imprime cada caso. Falla si una pasada (idioma × resolución) tiene más
## cortes que `TOPE_CORTADOS`. Medido el 26-10 tras arreglar: 7/7/3 (es/de/tr) a 1280×720 y
## 23/21/17 a 1920×1080 (antes: 69/16/12 y 139/84/28); y 0 botones sin foco (antes 18).
var IDIOMAS: Array = OS.get_environment("AUDITORIA_IDIOMAS").split(",") if OS.get_environment("AUDITORIA_IDIOMAS") != "" else ["es", "de", "tr"]
var RESOLUCIONES: Array = [Vector2i(1280, 720)] if OS.get_environment("AUDITORIA_RES") == "1280" else [Vector2i(1280, 720), Vector2i(1920, 1080)]
const TOPE_CORTADOS := 30
const TOPE_SIN_FOCO := 0
var _p: Principal

func _ready() -> void:
	await get_tree().process_frame
	_titulo("S3: AUDITORÍA DE LA INTERFAZ (textos cortados y foco con mando)")
	var m := Mundo.new()
	m.generar([], 20261026)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	Principal.mundo_pregenerado = m
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 4:
		await get_tree().process_frame
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	## Pintar Ajustes guarda las preferencias: se restaura el idioma de la máquina al final.
	var idioma_antes := Idiomas.idioma
	var peor := 0
	var sin_foco := 0
	for res: Vector2i in RESOLUCIONES:
		get_tree().root.size = res
		for l: String in IDIOMAS:
			Idiomas.idioma = l
			var r := await _recorrer()
			peor = maxi(peor, int(r[0]))
			sin_foco += int(r[1])
			_linea("  %s %dx%d: %d textos cortados, %d botones sin foco de mando (en %d pestañas)" % [l, res.x, res.y, r[0], r[1], r[2]])
			var top: Dictionary = r[3]
			var claves := top.keys()
			claves.sort_custom(func(a, b): return int(top[a]) > int(top[b]))
			for i in mini(200 if OS.get_environment("AUDITORIA") == "detalle" else 4, claves.size()):
				_linea("      %3d× %s" % [int(top[claves[i]]), claves[i]])
	Idiomas.idioma = idioma_antes
	_p._guardar_preferencias()
	_comprobar(peor <= TOPE_CORTADOS, "ninguna pasada pasa de %d textos cortados (la peor: %d)" % [TOPE_CORTADOS, peor])
	_comprobar(sin_foco <= TOPE_SIN_FOCO, "todos los botones visibles se alcanzan con el mando (%d sin foco)" % sin_foco)
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _pestanas() -> Array:
	var out: Array = []
	for g: Dictionary in Principal.GRUPOS:
		for ch: Dictionary in g["tabs"]:
			if String(ch.get("secc", "")) != "kits":
				out.append(ch)
	for h: String in Principal.HUBS:
		for t: String in Principal.HUBS[h]["tabs"]:
			out.append({"tab": t, "label": t})
	return out

func _recorrer() -> Array:
	var cortados := 0
	var sin_foco := 0
	var vistas := 0
	var donde := {}
	for ch: Dictionary in _pestanas():
		_p._ir_a_chip(ch)
		_p._refrescar()
		for i in 6:
			await get_tree().process_frame
		vistas += 1
		for n in _p.find_children("*", "Control", true, false):
			var c := n as Control
			if not c.is_visible_in_tree() or c.size.x < 2.0:
				continue
			if not c.get_global_rect().intersects(Rect2(Vector2.ZERO, Vector2(get_tree().root.size))):
				continue
			var txt := ""
			var corta := false
			if c is Label:
				var lb := c as Label
				if lb.autowrap_mode == TextServer.AUTOWRAP_OFF and (lb.clip_text or lb.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING):
					txt = lb.text
					corta = _ancho(lb, txt) > lb.size.x + 2.0
			elif c is Button:
				var b := c as Button
				if b.focus_mode == Control.FOCUS_NONE and not b.disabled and b.mouse_filter != Control.MOUSE_FILTER_IGNORE:
					sin_foco += 1
					var k0 := "sin foco: %s · «%s»" % [_ruta(b), b.text.left(24)]
					donde[k0] = int(donde.get(k0, 0)) + 1
				if b.clip_text or b.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
					txt = b.text
					var sb := b.get_theme_stylebox("normal")
					var margen := (sb.content_margin_left + sb.content_margin_right) if sb != null else 8.0
					var icono := (b.icon.get_width() + 4.0) if b.icon != null and not b.expand_icon else 0.0
					corta = _ancho(b, txt) + maxf(margen, 0.0) + icono > b.size.x + 2.0
			if corta and txt.strip_edges() != "":
				cortados += 1
				var k := "cortado: «%s» (%s)" % [txt.left(30), String(ch["label"])]
				donde[k] = int(donde.get(k, 0)) + 1
	return [cortados, sin_foco, vistas, donde]

func _ancho(c: Control, txt: String) -> float:
	var f := c.get_theme_font("font")
	var t := c.get_theme_font_size("font_size")
	var w := 0.0
	for linea in txt.split("\n"):
		w = maxf(w, f.get_string_size(linea, HORIZONTAL_ALIGNMENT_LEFT, -1, t).x)
	return w

## Quién lo pinta: la clase del script del primer antepasado con script.
func _ruta(n: Node) -> String:
	var a := n
	while a != null and a.get_script() == null:
		a = a.get_parent()
	return (a.get_script() as Script).resource_path.get_file() if a != null else "?"
