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

static func mostrar(padre: Control, p: Partido, mi_club: Club, liga_rival: Liga) -> InformeRival:
	var r := InformeRival.new()
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

func _construir() -> void:
	var d := datos(rival, mio, liga)
	var fondo := ColorRect.new()
	fondo.color = COL_FONDO
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 12)
	add_child(raiz)
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 80
	raiz.offset_right = -80
	raiz.offset_top = 36
	raiz.offset_bottom = -30
	var tit := _texto(12, COL_SUAVE)
	tit.text = Idiomas.t("INFORME DEL RIVAL")
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(tit)
	var cab := HBoxContainer.new()
	cab.alignment = BoxContainer.ALIGNMENT_CENTER
	cab.add_theme_constant_override("separation", 14)
	raiz.add_child(cab)
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(rival, 64)
	esc.custom_minimum_size = Vector2(64, 64)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cab.add_child(esc)
	var nom := _texto(34, COL_TEXTO)
	nom.text = rival.nombre
	cab.add_child(nom)
	var sub := _texto(15, COL_ORO)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var partes: Array = []
	if int(d["puesto"]) > 0:
		partes.append(Idiomas.t("%d.º en la liga · %d pts") % [int(d["puesto"]), int(d["pts"])])
	partes.append(Idiomas.t("media del once %d (la tuya %d)") % [roundi(float(d["media_rival"])), roundi(float(d["media_mia"]))])
	sub.text = "  ·  ".join(partes)
	raiz.add_child(sub)
	## La racha en fichas de color.
	if not (d["racha"] as Array).is_empty():
		var fila := HBoxContainer.new()
		fila.alignment = BoxContainer.ALIGNMENT_CENTER
		fila.add_theme_constant_override("separation", 6)
		raiz.add_child(fila)
		var et := _texto(13, COL_SUAVE)
		et.text = Idiomas.t("Últimos partidos:")
		fila.add_child(et)
		for r: String in d["racha"]:
			var ficha := PanelContainer.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = COL_BIEN if r == "V" else (COL_MAL if r == "D" else Color(0.55, 0.55, 0.5))
			sb.set_corner_radius_all(4)
			sb.content_margin_left = 8
			sb.content_margin_right = 8
			ficha.add_theme_stylebox_override("panel", sb)
			var l := _texto(13, Color.WHITE)
			l.text = {"V": "✔", "E": "=", "D": "✖"}[r]
			ficha.add_child(l)
			fila.add_child(ficha)
	var cuerpo := HBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 24)
	raiz.add_child(cuerpo)
	var izq := _columna(cuerpo, Idiomas.t("SU PIZARRA"))
	_linea(izq, texto_pizarra(rival.tactica), COL_TEXTO)
	_linea(izq, "", COL_SUAVE)
	_linea(izq, Idiomas.t("LOS MÁS PELIGROSOS"), COL_SUAVE)
	for j: Jugador in d["mejores"]:
		_linea(izq, "%s  ·  %s  ·  %d" % [j.nombre, j.pos_e, j.ovr], COL_TEXTO)
	var g: Jugador = d["goleador"]
	if g != null:
		_linea(izq, Idiomas.t("⚽ Goleador: %s (%d goles)") % [g.nombre, g.goles], COL_ORO)
	if int(d["bajas"]) > 0:
		_linea(izq, Idiomas.t("🩹 Bajas por lesión: %d") % int(d["bajas"]), COL_MAL)
	var der := _columna(cuerpo, Idiomas.t("CONSEJO DEL CUERPO TÉCNICO"))
	for c: String in d["consejos"]:
		_linea(der, "• " + Idiomas.t(c), COL_TEXTO)
	var hueco := Control.new()
	hueco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(hueco)
	var pie := HBoxContainer.new()
	pie.alignment = BoxContainer.ALIGNMENT_CENTER
	raiz.add_child(pie)
	var b := Button.new()
	b.text = Idiomas.t("Al partido ▶")
	b.custom_minimum_size = Vector2(180, 40)
	b.pressed.connect(func() -> void: cerrado.emit())
	pie.add_child(b)
	b.call_deferred("grab_focus")
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)

func _columna(padre: Control, titulo: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.04)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", sb)
	padre.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	_linea(v, titulo, COL_ORO)
	return v

func _linea(padre: Control, txt: String, col: Color) -> void:
	var l := _texto(15, col)
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
