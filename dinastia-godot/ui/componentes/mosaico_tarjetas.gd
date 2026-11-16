class_name MosaicoTarjetas
extends RefCounted
## LAS TARJETAS CON CONTENIDO PROPIO DEL MOSAICO CENTRAL (16-11, frente 1; el mosaico y sus pestañas en `TableroInicio`).
## «Avanzar en el tiempo», como la pestaña principal de la Liga Master del PES 2020: el PRÓXIMO PARTIDO en grande (los
## dos escudos, competición, día, estadio y tiempo, sobre un césped con el color del local), la TABLA DE POSICIONES
## resumida, el CALENDARIO de lo que viene, la OFICINA DEL DT (objetivo y confianza de la directiva), las NOTICIAS (lo
## último que llegó, con su texto) y la FORMA (los cinco últimos resultados). Y las dos grandes de las otras pestañas:
## Mi plantel y Cuentas del club, con CIFRAS GRANDES por columna (la ficha de atributos del Drive como modelo).

static func avanzar(p: Principal, cuerpo: VBoxContainer, c: Club, liga: Liga, dias: int, acento: Color) -> void:
	var grande := partido(p, c, liga, dias, acento)
	var tabla := _tabla(p, c, liga, acento)
	var prox := _proximos(p, acento)
	var oficina := _oficina(p, c, liga, acento)
	var noticias := _noticias(p, acento)
	noticias.set_meta("ancho", 2.0)
	var forma := _forma(p, c, liga, acento)
	TableroInicio.colocar(cuerpo, grande, [[tabla], [prox]], [oficina, noticias, forma])

## El próximo partido (liga, copa o continental: el primero que venga). Sin partido, contra quién se vuelve.
static func partido(p: Principal, c: Club, liga: Liga, _dias: int, acento: Color) -> Control:
	var m := p.mundo
	var ev: Dictionary = {}
	for e: Dictionary in EventosFecha.proximos(m, p._dia_semana, 8):
		if EventosFecha.es_partido(e) and e.get("rival") is Club:
			ev = e
			break
	if ev.is_empty():
		var tc0 := TableroInicio.tarjeta(Idiomas.t("Próximo partido"), acento, func() -> void: TableroInicio.abrir(p, "Próximo partido"))
		var v0: VBoxContainer = tc0[1]
		v0.add_child(TableroInicio.etiqueta(Idiomas.t("Semana sin partido: entrenamiento doble."), 18, Tema.TEXTO))
		var sig := liga.siguiente_de(c) if liga != null else []
		if sig.size() == 3:
			v0.add_child(TableroInicio.etiqueta(Idiomas.t("Vuelves en la jornada %d") % int(sig[2]), 13, Tema.SUAVE))
		TableroInicio.cerrar(tc0[0])
		return tc0[0]
	var rival: Club = ev["rival"]
	var en_casa := bool(ev.get("local", true))
	var local: Club = c if en_casa else rival
	var visita: Club = rival if en_casa else c
	var fondo := Color(local.color1).darkened(0.74)
	fondo.a = 0.94
	var tc := TableroInicio.tarjeta(Idiomas.t("Próximo partido"), acento, func() -> void: TableroInicio.abrir(p, "Próximo partido"), fondo, "estadio")
	var b: Button = tc[0]
	var cancha := Cancha.new()   ## el césped dibujado detrás (línea de medio campo y círculo central)
	cancha.set_anchors_preset(Control.PRESET_FULL_RECT)
	cancha.color = Color(local.color2 if Color(local.color2).get_luminance() > 0.2 else "#ffffff", 0.07)
	b.add_child(cancha)
	b.move_child(cancha, 0)
	var v: VBoxContainer = tc[1]
	var arriba := HBoxContainer.new()
	v.add_child(arriba)
	var comp := String(ev["texto"]) if String(ev["tipo"]) != "liga" else "%s · %s" % [liga.nombre if liga != null else "", Idiomas.t("Jornada %d") % int(String(ev["etiqueta"]).trim_prefix("J"))]
	var lc := TableroInicio.etiqueta(comp.to_upper(), 13, Tema.oro())
	lc.clip_text = true
	lc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(lc)
	var k := int(ev.get("k", 0))
	var d := k * 7 + int(ev["dia"]) - int(p._dia_semana)
	var cuando := Idiomas.t("Hoy") if d <= 0 else (Idiomas.t("Mañana") if d == 1 else Idiomas.t("en %d días") % d)
	var fecha := "%s %d" % [Idiomas.t(String(Principal.DIAS_LARGOS[int(ev["dia"])])), int(p.fecha_del_dia(int(ev["dia"])).get("day", 1))] if k == 0 \
		else Idiomas.t("Semana %d") % int(ev.get("semana", m.semana + k))
	arriba.add_child(TableroInicio.etiqueta("%s · %s" % [fecha, cuando], 13, Color.WHITE if d <= 1 else Tema.SUAVE.lightened(0.3)))
	var medio := HBoxContainer.new()
	medio.alignment = BoxContainer.ALIGNMENT_CENTER
	medio.add_theme_constant_override("separation", 22)
	medio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(medio)
	for i in 2:
		var club: Club = local if i == 0 else visita
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		medio.add_child(col)
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(club, 72)
		esc.custom_minimum_size = Vector2(72, 72)
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		col.add_child(esc)
		var n := TableroInicio.etiqueta(club.nombre, 17, acento if club == c else Color.WHITE)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.clip_text = true
		col.add_child(n)
		if i == 0:
			var vs := TableroInicio.etiqueta("VS", 26, Color(1, 1, 1, 0.55))
			vs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			medio.add_child(vs)
	var cl := Clima.del_partido(local.pais, m.semana + k, m.anio, local.id + visita.id)
	var estadio := local.estadio_nombre if local.estadio_nombre != "" else Idiomas.t("Estadio de %s") % local.nombre
	var pie := TableroInicio.etiqueta("🏟  %s · %s  ·  %s %s  ·  %s" % [estadio, Idiomas.t("%s butacas") % p._miles(local.estadio_aforo),
		Clima.icono(cl), String(cl["texto"]), Idiomas.t("en casa") if en_casa else Idiomas.t("fuera")], 12, Color(1, 1, 1, 0.75))
	pie.clip_text = true
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pie)
	TableroInicio.cerrar(b)
	return b

static func _tabla(p: Principal, c: Club, liga: Liga, acento: Color) -> Control:
	var tc := TableroInicio.tarjeta(Idiomas.t("Tabla de posiciones"), acento, func() -> void: TableroInicio.abrir(p, "Ligas y clubes"))
	var v: VBoxContainer = tc[1]
	if liga == null:
		TableroInicio.cerrar(tc[0])
		return tc[0]
	var t: Array = liga.tabla()
	var mio := 0
	for i in t.size():
		if t[i]["club"] == c:
			mio = i
	var filas: Array[int] = []
	for i in t.size():   ## los cinco primeros si vas arriba; si no, los dos primeros y tu zona
		if (i < 5 and mio <= 3) or (mio > 3 and (i < 2 or absi(i - mio) <= 1)):
			filas.append(i)
	var nombre := TableroInicio.etiqueta(liga.nombre, 11, Tema.SUAVE)
	nombre.clip_text = true
	v.add_child(nombre)
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 0)
	v.add_child(g)
	var antes := -1
	for i: int in filas.slice(0, 7):
		if antes >= 0 and i > antes + 1:
			for _k in 4:
				g.add_child(TableroInicio.etiqueta("·" if _k == 2 else "", 10, Tema.SUAVE))
		antes = i
		var club: Club = t[i]["club"]
		var col := acento if club == c else Tema.TEXTO
		g.add_child(TableroInicio.etiqueta("%d" % (i + 1), 13, col))
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(club, 18)
		esc.custom_minimum_size = Vector2(18, 18)
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		g.add_child(esc)
		var n := TableroInicio.etiqueta(club.nombre, 13, col)
		n.clip_text = true
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(n)
		var pts := TableroInicio.etiqueta("%d" % int(t[i]["pts"]), 13, col)
		pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		g.add_child(pts)
	TableroInicio.cerrar(tc[0])
	return tc[0]

static func _proximos(p: Principal, acento: Color) -> Control:
	var tc := TableroInicio.tarjeta(Idiomas.t("Calendario"), acento, func() -> void: CalendarioSemanas.mostrar(p, p.mundo, p._dia_semana), Color(0, 0, 0, 0), "tunel")
	var v: VBoxContainer = tc[1]
	var lista := EventosFecha.proximos(p.mundo, p._dia_semana, 5)
	if lista.is_empty():
		v.add_child(TableroInicio.etiqueta(Idiomas.t("Temporada terminada"), 13, Tema.SUAVE))
	for e: Dictionary in lista:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		v.add_child(h)
		if e.get("rival") is Club:
			var esc := TextureRect.new()
			esc.texture = Escudo.textura(e["rival"], 20)
			esc.custom_minimum_size = Vector2(20, 20)
			esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			h.add_child(esc)
		else:
			var ic := TableroInicio.etiqueta(String(e["icono"]), 13, Tema.TEXTO)
			ic.custom_minimum_size.x = 20
			h.add_child(ic)
		var et := TableroInicio.etiqueta(String(e["etiqueta"]).to_upper() if e["tipo"] != "liga" else String(e["etiqueta"]), 11, Tema.oro() if e["tipo"] != "liga" else Tema.SUAVE)
		et.custom_minimum_size.x = 30
		h.add_child(et)
		var tx := TableroInicio.etiqueta(String(e["texto"]), 13, Tema.TEXTO)
		tx.clip_text = true
		tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(tx)
	TableroInicio.cerrar(tc[0])
	return tc[0]

static func _oficina(p: Principal, c: Club, liga: Liga, acento: Color) -> Control:
	var tc := TableroInicio.tarjeta(Idiomas.t("Oficina del DT"), acento, func() -> void: TableroInicio.abrir(p, "Mi carrera"), Color(0, 0, 0, 0), "oficina")
	var v: VBoxContainer = tc[1]
	var dir := p.mundo.directiva
	if dir != null and String(dir.objetivo) != "":
		var o := TableroInicio.etiqueta(Idiomas.t(String(dir.objetivo)), 13, Tema.TEXTO)
		o.clip_text = true
		v.add_child(o)
	var barras := HBoxContainer.new()
	barras.add_theme_constant_override("separation", 12)
	v.add_child(barras)
	barras.add_child(_barra(Idiomas.t("Confianza"), c.confianza, acento))
	var puesto := 0
	if liga != null and liga.jornada_actual > 0:
		var t: Array = liga.tabla()
		for i in t.size():
			if t[i]["club"] == c:
				puesto = i + 1
	if dir != null and dir.meta_puesto > 0:
		var pr := ObjetivoDirectiva.progreso(puesto, int(dir.meta_puesto), liga.clubes.size() if liga != null else 0)
		barras.add_child(_barra(Idiomas.t("Objetivo"), pr, Tema.BIEN if pr >= 100 else (Tema.oro() if pr >= 50 else Tema.MAL)))
	TableroInicio.cerrar(tc[0])
	return tc[0]

static func _barra(rotulo: String, valor: int, col: Color) -> Control:
	var h := VBoxContainer.new()   ## rótulo y cifra arriba, la barra debajo (dos caben lado a lado)
	h.add_theme_constant_override("separation", 2)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var arriba := HBoxContainer.new()
	h.add_child(arriba)
	var r := TableroInicio.etiqueta(rotulo, 11, Tema.SUAVE)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(r)
	arriba.add_child(TableroInicio.etiqueta("%d" % valor, 13, Tema.TEXTO))
	var b := ProgressBar.new()
	b.show_percentage = false
	b.value = clampi(valor, 0, 100)
	b.custom_minimum_size = Vector2(60, 8)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(1, 1, 1, 0.1)
	fondo.set_corner_radius_all(4)
	var lleno := StyleBoxFlat.new()
	lleno.bg_color = col
	lleno.set_corner_radius_all(4)
	b.add_theme_stylebox_override("background", fondo)
	b.add_theme_stylebox_override("fill", lleno)
	h.add_child(b)
	return h

## Lo último que llegó a la bandeja (titular y texto, como la noticia con cita del PES). Solo noticias de verdad: los avisos
## técnicos del registro (p. ej. «la última vez el juego anotó N errores») no se pintan aquí (siguen en «Lo que va pasando»).
static func _noticias(p: Principal, acento: Color) -> Control:
	var tc := TableroInicio.tarjeta(Idiomas.t("Noticias"), acento, func() -> void: TableroInicio.abrir(p, "Correo"))
	var v: VBoxContainer = tc[1]
	var bandeja: Array = p.get("_bandeja") if p.get("_bandeja") != null else []
	if bandeja.is_empty():
		v.add_child(TableroInicio.etiqueta(Idiomas.t("Sin noticias por ahora"), 15, Tema.TEXTO))
		v.add_child(TableroInicio.etiqueta(Idiomas.t("Lo que pase en el club y en la liga llegará aquí."), 12, Tema.SUAVE))
		return _fin_noticias(tc[0], bandeja, acento)
	var n: Dictionary = bandeja[0]
	var t := TableroInicio.etiqueta(String(n.get("titulo", "")), 16, Color.WHITE)
	t.clip_text = true
	v.add_child(t)
	var cu := TableroInicio.etiqueta("«%s»" % String(n.get("cuerpo", "")).strip_edges(), 13, Color(1, 1, 1, 0.72))
	cu.clip_text = true
	v.add_child(cu)
	return _fin_noticias(tc[0], bandeja, acento)

static func _fin_noticias(b: Control, bandeja: Array, acento: Color) -> Control:
	var sin_leer := 0
	for x: Dictionary in bandeja:
		if not bool(x.get("leida", false)):
			sin_leer += 1
	if sin_leer > 0:
		var chip := TableroInicio.etiqueta(Idiomas.t("%d sin leer") % sin_leer, 12, acento)
		chip.anchor_left = 1.0; chip.anchor_right = 1.0
		chip.offset_left = -110; chip.offset_right = -14; chip.offset_top = 8; chip.offset_bottom = 26
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		b.add_child(chip)
	TableroInicio.cerrar(b)
	return b

static func _forma(p: Principal, c: Club, liga: Liga, acento: Color) -> Control:
	var tc := TableroInicio.tarjeta(Idiomas.t("Forma"), acento, func() -> void: TableroInicio.abrir(p, "Récords"))
	var v: VBoxContainer = tc[1]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	v.add_child(h)
	var ultimo := ""
	var res: Array[String] = []
	if liga != null:
		for i in range(liga.historial.size() - 1, -1, -1):
			if res.size() >= 5:
				break
			for r: Dictionary in liga.historial[i]:
				if r["local"] != c and r["visita"] != c:
					continue
				var mios := int(r["gl"]) if r["local"] == c else int(r["gv"])
				var suyos := int(r["gv"]) if r["local"] == c else int(r["gl"])
				res.append("G" if mios > suyos else ("P" if mios < suyos else "E"))
				if ultimo == "":
					ultimo = "J%d  %s %d-%d %s" % [i + 1, (r["local"] as Club).nombre, int(r["gl"]), int(r["gv"]), (r["visita"] as Club).nombre]
	res.reverse()
	if res.is_empty():
		v.add_child(TableroInicio.etiqueta(Idiomas.t("Aún sin partidos jugados."), 13, Tema.SUAVE))
	for r: String in res:
		var pc := PanelContainer.new()
		var e := StyleBoxFlat.new()
		e.bg_color = Tema.bien() if r == "G" else (Tema.mal() if r == "P" else Color("6b7a70"))
		e.set_corner_radius_all(4)
		e.content_margin_left = 7; e.content_margin_right = 7
		pc.add_theme_stylebox_override("panel", e)
		pc.add_child(TableroInicio.etiqueta(r, 14, Color.WHITE))
		h.add_child(pc)
	if ultimo != "":
		var u := TableroInicio.etiqueta(ultimo, 12, Tema.SUAVE)
		u.clip_text = true
		v.add_child(u)
	TableroInicio.cerrar(tc[0])
	return tc[0]

## Mi plantel (grande de «Dirección del equipo»): cifras grandes por columna y la estrella.
static func plantel(p: Principal, c: Club, acento: Color) -> Control:
	var tc := TableroInicio.tarjeta(Idiomas.t("Mi plantel"), acento, func() -> void: TableroInicio.abrir(p, "Mi plantel"), Color(0, 0, 0, 0), "vestuario")
	var v: VBoxContainer = tc[1]
	var lesionados := 0
	var moral := 0
	var mejor: Jugador = null
	for j: Jugador in c.plantilla:
		if j.lesion > 0:
			lesionados += 1
		moral += j.moral
		if mejor == null or j.ovr > mejor.ovr:
			mejor = j
	moral = moral / maxi(c.plantilla.size(), 1)
	v.add_child(_cifras([[Idiomas.t("Media"), "%d" % roundi(c.media()), acento], [Idiomas.t("Jugadores"), "%d" % c.plantilla.size(), Tema.TEXTO],
		[Idiomas.t("Lesionados"), "%d" % lesionados, Tema.mal() if lesionados > 0 else Tema.TEXTO], [Idiomas.t("Moral"), "%d" % moral, Tema.bien() if moral >= 60 else Tema.oro()]]))
	if mejor != null:
		v.add_child(TableroInicio.etiqueta("★ %s · %s %d · %s" % [mejor.nombre, mejor.pos, mejor.ovr, c.tactica.formacion], 14, Tema.oro()))
	TableroInicio.cerrar(tc[0])
	return tc[0]

## Cuentas del club (grande de «Información del club»): la caja en grande y sus cifras.
static func cuentas(p: Principal, c: Club, acento: Color) -> Control:
	var tc := TableroInicio.tarjeta(Idiomas.t("Cuentas del club"), acento, func() -> void: TableroInicio.abrir(p, "Cuentas del club"), Color(0, 0, 0, 0), "despacho")
	var v: VBoxContainer = tc[1]
	v.add_child(TableroInicio.etiqueta(Idiomas.t("Caja").to_upper(), 12, Tema.SUAVE))
	v.add_child(TableroInicio.etiqueta(p._dinero(c.saldo), 40, Tema.bien() if c.saldo >= 0 else Tema.mal()))
	v.add_child(_cifras([[Idiomas.t("Sueldos/sem"), p._dinero(c.masa_salarial()), Tema.TEXTO], [Idiomas.t("Socios"), p._miles(c.socios), acento],
		[Idiomas.t("Butacas"), p._miles(c.estadio_aforo), Tema.TEXTO]]))
	TableroInicio.cerrar(tc[0])
	return tc[0]

## Una banda de cifras: [rótulo, cifra, color] por columna, la cifra grande arriba y el rótulo debajo.
static func _cifras(datos: Array) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for d: Array in datos:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", -4)
		h.add_child(col)
		var n := TableroInicio.etiqueta(String(d[1]), 21 if DisenoVertical.activo() else 30, d[2])
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.clip_text = true
		col.add_child(n)
		var r := TableroInicio.etiqueta(String(d[0]).to_upper(), 11, Tema.SUAVE)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.clip_text = true
		col.add_child(r)
	return h

## El césped de la tarjeta del partido: línea de medio campo y círculo central, tenues.
class Cancha extends Control:
	var color := Color(1, 1, 1, 0.07)
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var cx := size.x * 0.5
		draw_line(Vector2(cx, 0), Vector2(cx, size.y), color, 2.0)
		draw_arc(Vector2(cx, size.y * 0.5), size.y * 0.3, 0.0, TAU, 48, color, 2.0)
		for i in 6:   ## franjas del césped
			if i % 2 == 0:
				draw_rect(Rect2(size.x * i / 6.0, 0, size.x / 6.0, size.y), Color(1, 1, 1, 0.025))
