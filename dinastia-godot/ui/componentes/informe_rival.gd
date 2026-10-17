class_name InformeRival
extends Control
## EL INFORME DEL RIVAL (17-10-2026): lo que FM y FC enseñan antes de jugar y
## Dinastía no tenía (ver COMPARACION_JUEGOS_2.md). Sale antes del partido en
## vivo: posición y racha del rival, su pizarra, los tres mejores del once
## probable, su goleador, las bajas y un consejo que sale de esos datos.
## Todo se lee del mundo; no inventa nada.

signal cerrado

## Se puede apagar desde Ajustes o desde una prueba.
static var activo := true

const COL_FONDO := Tema.FONDO
const COL_TEXTO := Tema.TEXTO
const COL_SUAVE := Tema.SUAVE
const COL_ORO := Tema.ORO
const COL_BIEN := Tema.BIEN
const COL_MAL := Tema.MAL

var rival: Club
var mio: Club
var liga: Liga
var mundo: Mundo

static func mostrar(padre: Control, p: Partido, mi_club: Club, liga_rival: Liga, mundo_: Mundo = null) -> InformeRival:
	var r := InformeRival.new()
	r.mundo = mundo_
	r.mio = mi_club
	r.rival = p.visita if p.local == mi_club else p.local
	r.liga = liga_rival
	padre.add_child(r)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r._construir()
	return r

## Los datos, separados de la pantalla para poder probarlos sin dibujar.
static func datos(rival_: Club, mio_: Club, liga_: Liga) -> Dictionary:
	var d := {"puesto": 0, "pts": 0, "racha": [], "mejores": [], "goleador": null, "bajas": 0,
		"media_rival": 0.0, "media_mia": 0.0, "consejos": []}
	if liga_ != null:
		var tabla := liga_.tabla()
		for i in tabla.size():
			if (tabla[i]["club"] as Club) == rival_:
				d["puesto"] = i + 1
				d["pts"] = int(tabla[i]["pts"])
		## La racha: los últimos cinco partidos del rival en la liga, del más
		## viejo al más nuevo (V, E, D).
		var racha: Array = []
		for jornada: Array in liga_.historial:
			for r: Dictionary in jornada:
				var es_l: bool = r["local"] == rival_
				if not es_l and r["visita"] != rival_:
					continue
				var a := int(r["gl"] if es_l else r["gv"])
				var b := int(r["gv"] if es_l else r["gl"])
				racha.append("V" if a > b else ("E" if a == b else "D"))
		d["racha"] = racha.slice(maxi(racha.size() - 5, 0))
	var once := rival_.once()
	var orden: Array = once.duplicate()
	orden.sort_custom(func(x: Jugador, y: Jugador) -> bool: return x.ovr > y.ovr)
	d["mejores"] = orden.slice(0, 3)
	var gol: Jugador = null
	for j: Jugador in rival_.plantilla:
		if j.lesion > 0:
			d["bajas"] = int(d["bajas"]) + 1
		elif j.goles > 0 and (gol == null or j.goles > gol.goles):
			gol = j
	d["goleador"] = gol
	d["media_rival"] = _media(once)
	d["media_mia"] = _media(mio_.once()) if mio_ != null else 0.0
	## Los consejos, de la pizarra del rival y de la diferencia de nivel.
	var t := rival_.tactica
	var c: Array = []
	if t != null:
		if t.presion == Tactica.Nivel.ALTO:
			c.append("Presionan arriba: juega rápido o en largo para saltar la presión.")
		if t.linea == Tactica.Nivel.ALTO or t.fuera_de_juego:
			c.append("Defienden adelantados: hay espacio a la espalda de sus centrales.")
		if t.mentalidad == Tactica.Mentalidad.DEFENSIVA or t.linea == Tactica.Nivel.BAJO:
			c.append("Se encierran atrás: abre el campo y busca centros y tiros de fuera.")
		if t.mentalidad == Tactica.Mentalidad.OFENSIVA:
			c.append("Atacan con mucha gente: la contra puede hacerles daño.")
	## Sobre sus jugadores: el mejor y el que más marca, con nombre.
	var top: Array = d["mejores"]
	if not top.is_empty():
		var j0: Jugador = top[0]
		c.append(Idiomas.t("Vigila a %s (%s, %d): es su mejor jugador.") % [j0.nombre, j0.pos_e, j0.ovr])
	if gol != null and (top.is_empty() or gol != top[0]) and gol.goles >= 2:
		c.append(Idiomas.t("%s ya lleva %d goles: no le dejes rematar solo.") % [gol.nombre, gol.goles])
	if int(d["bajas"]) >= 2:
		c.append(Idiomas.t("Tienen %d lesionados: su banco está más corto.") % int(d["bajas"]))
	var racha_: Array = d["racha"]
	if racha_.size() >= 3 and racha_.slice(-3).count("D") >= 2:
		c.append("Llegan con malos resultados: un gol temprano los puede hundir.")
	elif racha_.size() >= 3 and racha_.slice(-3).count("V") == 3:
		c.append("Llegan en racha: cuidado con los primeros minutos.")
	var dif := float(d["media_rival"]) - float(d["media_mia"])
	if dif > 3.0:
		c.append("En el papel son mejores: orden atrás y paciencia.")
	elif dif < -3.0:
		c.append("En el papel sois mejores: toma la iniciativa desde el inicio.")
	if c.is_empty():
		c.append("Partido parejo: los detalles (balón parado, cambios) decidirán.")
	d["consejos"] = c
	return d

static func _media(js: Array) -> float:
	if js.is_empty():
		return 0.0
	var s := 0.0
	for j: Jugador in js:
		s += j.ovr
	return s / js.size()

static func texto_pizarra(t: Tactica) -> String:
	if t == null:
		return ""
	var ment: String = ["Defensiva", "Equilibrada", "Ofensiva"][clampi(t.mentalidad, 0, 2)]
	var pre: String = ["presión baja", "presión media", "presión alta"][clampi(t.presion, 0, 2)]
	var lin: String = ["línea baja", "línea media", "línea alta"][clampi(t.linea, 0, 2)]
	return "%s · %s · %s · %s" % [t.formacion, Idiomas.t(ment), Idiomas.t(pre), Idiomas.t(lin)]

## La pantalla (2.ª versión, 17-10-2026, tras el veredicto «no respeta la
## estética»): fondo vivo de los menús, los dos escudos, la FORMACIÓN dibujada
## en un campo, el ONCE PROBABLE con media, nota media por partido y goles, y el
## consejo dicho por el MENTOR con su cara (el mismo de `MentorVoz`).
func _construir() -> void:
	var d := datos(rival, mio, liga)
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = PanelControles.SHADER_FONDO
	sm.shader = sh
	fondo.material = sm
	add_child(fondo)
	for tipo: String in ["bokeh", "motas"]:
		var fp := FondoParticulas.new(tipo)
		fp.color = Tema.ORO.lerp(Color.WHITE, 0.4) if tipo == "motas" else Tema.ACENTO.lerp(Color.WHITE, 0.2)
		add_child(fp)
		fp.ajustar_area(get_viewport_rect().size)
	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 14)
	add_child(raiz)
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 48
	raiz.offset_right = -48
	raiz.offset_top = 26
	raiz.offset_bottom = -22
	var tit := _texto(14, Tema.ORO)
	tit.text = Idiomas.t("INFORME DEL RIVAL")
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(tit)
	## Cabecera: tu escudo VS el suyo.
	var cab := HBoxContainer.new()
	cab.alignment = BoxContainer.ALIGNMENT_CENTER
	cab.add_theme_constant_override("separation", 18)
	raiz.add_child(cab)
	if mio != null:
		cab.add_child(_escudo(mio, 52))
		var n1 := _texto(24, COL_SUAVE)
		n1.text = mio.nombre
		cab.add_child(n1)
	var vs := _texto(18, Tema.ORO)
	vs.text = "VS"
	cab.add_child(vs)
	var n2 := _texto(34, COL_TEXTO)
	n2.text = rival.nombre
	cab.add_child(n2)
	cab.add_child(_escudo(rival, 72))
	## Datos rápidos en fichas.
	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 10)
	raiz.add_child(chips)
	if int(d["puesto"]) > 0:
		_chip(chips, Idiomas.t("%d.º en la liga · %d pts") % [int(d["puesto"]), int(d["pts"])], Tema.ORO)
	_chip(chips, Idiomas.t("media del once %d (la tuya %d)") % [roundi(float(d["media_rival"])), roundi(float(d["media_mia"]))], Tema.ACENTO)
	if int(d["bajas"]) > 0:
		_chip(chips, Idiomas.t("🩹 Bajas por lesión: %d") % int(d["bajas"]), COL_MAL)
	if not (d["racha"] as Array).is_empty():
		var et := _texto(14, COL_SUAVE)
		et.text = "   " + Idiomas.t("Últimos partidos:")
		chips.add_child(et)
		for r: String in d["racha"]:
			_chip(chips, {"V": "✔", "E": "=", "D": "✖"}[r], COL_BIEN if r == "V" else (COL_MAL if r == "D" else Color(0.55, 0.55, 0.5)), true)
	## Cuerpo en tres columnas.
	var cuerpo := HBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 18)
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(cuerpo)
	var once := rival.once()
	## 1) La formación.
	var c1 := _columna(cuerpo, Idiomas.t("SU PIZARRA"), 0.9)
	var campo := Campo.new()
	campo.once = once
	campo.formacion = rival.tactica.formacion if rival.tactica != null else "4-3-3"
	campo.color = Color(rival.color1)
	campo.color2 = Color(rival.color2)
	campo.custom_minimum_size = Vector2(0, 330)
	campo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c1.add_child(campo)
	_linea(c1, texto_pizarra(rival.tactica), COL_TEXTO, 14)
	## 2) El once probable con su rendimiento.
	var c2 := _columna(cuerpo, Idiomas.t("ONCE PROBABLE"), 1.25)
	var tabla := GridContainer.new()
	tabla.columns = 5
	tabla.add_theme_constant_override("h_separation", 14)
	tabla.add_theme_constant_override("v_separation", 5)
	c2.add_child(tabla)
	for h: String in ["Pos.", "Jugador", "Media", "Nota", "Goles"]:
		var lh := _texto(12, COL_SUAVE)
		lh.text = Idiomas.t(h)
		tabla.add_child(lh)
	var mejor: Jugador = (d["mejores"] as Array)[0] if not (d["mejores"] as Array).is_empty() else null
	var gol: Jugador = d["goleador"]
	var forms: Dictionary = Datos.tabla("FORMS")
	var ranuras: Array = (forms.get(campo.formacion, forms.get("4-3-3", {})) as Dictionary).get("s", [])
	for k in once.size():
		var j: Jugador = once[k]
		var destaca := j == mejor or j == gol
		var col := Tema.ORO if destaca else COL_TEXTO
		## El puesto en que juega hoy y, si no es el suyo, el natural.
		var puesto := String((ranuras[k] as Array)[0]) if k < ranuras.size() else j.pos_e
		_celda(tabla, puesto if puesto == j.pos_e else "%s (%s)" % [puesto, j.pos_e], COL_SUAVE if puesto == j.pos_e else COL_MAL.lerp(Color.WHITE, 0.3))
		_celda(tabla, j.nombre + (" ★" if j == mejor else "") + (" ⚽" if j == gol else ""), col)
		_celda(tabla, str(j.ovr), col)
		var nm := j.media_notas()
		_celda(tabla, "%.1f" % nm if nm > 0.0 else "–", _color_nota(nm))
		_celda(tabla, str(j.goles), col)
	var nota_eq := 0.0
	var n_eq := 0
	for j: Jugador in once:
		if j.media_notas() > 0.0:
			nota_eq += j.media_notas()
			n_eq += 1
	if n_eq > 0:
		_linea(c2, Idiomas.t("Nota media del once por partido: %.1f") % (nota_eq / n_eq), _color_nota(nota_eq / n_eq), 14)
	## 3) El consejo, dicho por el mentor con su cara.
	var c3 := _columna(cuerpo, Idiomas.t("CONSEJO DEL CUERPO TÉCNICO"), 1.0)
	var quien := HBoxContainer.new()
	quien.add_theme_constant_override("separation", 12)
	c3.add_child(quien)
	var modo: String = mundo.roles.modo_actual() if mundo != null and mundo.roles != null else "dt"
	var ctx := Tutorial.contexto(mundo)
	var m := Tutorial.mentor_de(modo, ctx)
	var cara := TextureRect.new()
	cara.texture = Tutorial._cara_mentor(m, ctx)
	cara.custom_minimum_size = Vector2(96, 96)
	cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	quien.add_child(cara)
	var qv := VBoxContainer.new()
	qv.alignment = BoxContainer.ALIGNMENT_CENTER
	quien.add_child(qv)
	var qn := _texto(17, COL_TEXTO)
	qn.text = String(m.get("nombre", ""))
	qv.add_child(qn)
	var qc := _texto(12, COL_SUAVE)
	qc.text = Idiomas.t(String(m.get("cargo", "")))
	qc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qc.custom_minimum_size = Vector2(200, 0)
	qv.add_child(qc)
	var globo := PanelContainer.new()
	globo.add_theme_stylebox_override("panel", Tema.caja(Color(0.07, 0.10, 0.08, 0.92), Tema.RADIO, Tema.ACENTO))
	c3.add_child(globo)
	var gv := VBoxContainer.new()
	gv.add_theme_constant_override("separation", 8)
	globo.add_child(gv)
	for c: String in d["consejos"]:
		_linea(gv, "• " + Idiomas.t(c), COL_TEXTO, 15)
	var pie := HBoxContainer.new()
	pie.alignment = BoxContainer.ALIGNMENT_CENTER
	raiz.add_child(pie)
	var b := Button.new()
	b.text = Idiomas.t("Al partido ▶")
	b.custom_minimum_size = Vector2(200, 44)
	b.pressed.connect(func() -> void: cerrado.emit())
	pie.add_child(b)
	b.call_deferred("grab_focus")
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)

func _escudo(c: Club, px: int) -> TextureRect:
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(c, px)
	esc.custom_minimum_size = Vector2(px, px)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return esc

func _chip(padre: Control, txt: String, col: Color, lleno := false) -> void:
	var ficha := PanelContainer.new()
	var sb := Tema.caja(col if lleno else Color(col, 0.14), Tema.RADIO_CHICO, col)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	ficha.add_theme_stylebox_override("panel", sb)
	var l := _texto(14, Color.WHITE if lleno else col.lerp(Color.WHITE, 0.35))
	l.text = txt
	ficha.add_child(l)
	padre.add_child(ficha)

func _celda(padre: Control, txt: String, col: Color) -> void:
	var l := _texto(14, col)
	l.text = txt
	padre.add_child(l)

## Nota por partido: verde si rinde, ámbar normal, rojo si no.
static func _color_nota(n: float) -> Color:
	if n <= 0.0:
		return Tema.SUAVE
	return Tema.BIEN if n >= 7.0 else (Tema.ORO if n >= 6.0 else Tema.MAL)

## El campo con la formación: puntos del color del club donde va cada uno (las
## ranuras de `FORMS`), con apellido y media.
class Campo extends Control:
	var once: Array = []
	var formacion := "4-3-3"
	var color := Color.RED
	var color2 := Color.WHITE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		## Proporción de campo (68 × 105), centrado.
		var alto := r.size.y
		var ancho := minf(r.size.x, alto * 0.68)
		var o := Vector2((r.size.x - ancho) * 0.5, 0)
		var cr := Rect2(o, Vector2(ancho, alto))
		draw_rect(cr, Color("1f6b3a"))
		for k in 8:
			if k % 2 == 0:
				draw_rect(Rect2(o + Vector2(0, alto * k / 8.0), Vector2(ancho, alto / 8.0)), Color("23753f"))
		var lc := Color(1, 1, 1, 0.55)
		draw_rect(cr, lc, false, 2.0)
		draw_line(o + Vector2(0, alto * 0.5), o + Vector2(ancho, alto * 0.5), lc, 2.0)
		draw_arc(o + Vector2(ancho * 0.5, alto * 0.5), ancho * 0.13, 0, TAU, 40, lc, 2.0)
		for arriba in [true, false]:
			var y0 := 0.0 if arriba else alto * (1.0 - 0.16)
			draw_rect(Rect2(o + Vector2(ancho * 0.2, y0), Vector2(ancho * 0.6, alto * 0.16)), lc, false, 2.0)
		var forms: Dictionary = Datos.tabla("FORMS")
		var ranuras: Array = (forms.get(formacion, forms.get("4-3-3", {})) as Dictionary).get("s", [])
		var fuente := get_theme_default_font()
		for i in mini(ranuras.size(), once.size()):
			var rn: Array = ranuras[i]
			## Atacan hacia arriba: el portero abajo.
			var p := o + Vector2(float(rn[1]) / 100.0 * ancho, float(rn[2]) / 100.0 * alto)
			var j: Jugador = once[i]
			draw_circle(p + Vector2(1.5, 2), 11.0, Color(0, 0, 0, 0.35))
			draw_circle(p, 11.0, color)
			draw_arc(p, 11.0, 0, TAU, 24, color2, 2.0)
			var med := str(j.ovr)
			var tw := fuente.get_string_size(med, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			draw_string(fuente, p + Vector2(-tw * 0.5, 4), med, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color2)
			var ap := j.nombre.get_slice(" ", j.nombre.get_slice_count(" ") - 1)
			var aw := fuente.get_string_size(ap, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(fuente, p + Vector2(-aw * 0.5 + 1, 27), ap, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 0, 0, 0.6))
			draw_string(fuente, p + Vector2(-aw * 0.5, 26), ap, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
func _columna(padre: Control, titulo: String, peso := 1.0) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = peso
	var sb := Tema.caja(Color(0.06, 0.09, 0.07, 0.88), Tema.RADIO_GRANDE, Color(Tema.ACENTO, 0.6))
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", sb)
	padre.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	_linea(v, titulo, Tema.ORO, 15)
	return v

func _linea(padre: Control, txt: String, col: Color, tam := 15) -> void:
	var l := _texto(tam, col)
	l.text = txt
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	padre.add_child(l)

func _texto(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrado.emit()
