class_name CarreraJugadorUI
extends "res://ui/carrera_jugador_ui_p1.gd"
## [Capa 2/2 de `carrera_jugador_ui.gd`] _centro, _derecha, _pintar_semana, _ready

## EL CENTRO: el partido de la semana y el entrenamiento.
func _centro(j: Jugador, club: Club) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 12)
	## LA SELECCIÓN (MEGAPLAN fase 3): en fecha FIFA, si te convocan.
	if not carrera.convocatoria.is_empty():
		var ps := _panel(Color("ffd24a"))
		v.add_child(ps)
		var sv := VBoxContainer.new()
		sv.add_theme_constant_override("separation", 8)
		ps.add_child(sv)
		sv.add_child(_lbl(13, Color("ffd24a"), "🌎 FECHA FIFA · ¡CONVOCADO!"))
		sv.add_child(_lbl(20, TEXTO, "%s  vs  %s" % [String(carrera.convocatoria["nombre"]), String(carrera.convocatoria["rival"])]))
		sv.add_child(_lbl(13, SUAVE, "Partidos con la selección: %d  ·  goles: %d" % [carrera.caps, carrera.goles_sel]))
		var fs := HBoxContainer.new()
		fs.add_theme_constant_override("separation", 8)
		sv.add_child(fs)
		var bjs := _boton("🎮  JUGAR CON LA SELECCIÓN", Color("ffd24a"), _jugar_seleccion, 50)
		bjs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fs.add_child(bjs)
		var bss := _boton("⏩  Simular", CIAN, _simular_seleccion, 50)
		bss.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fs.add_child(bss)
	var p := _panel(FUCSIA)
	v.add_child(p)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 8)
	p.add_child(pv)
	pv.add_child(_lbl(13, FUCSIA, "PRÓXIMO PARTIDO"))
	if not mundo.temporada_en_curso():
		pv.add_child(_lbl(20, TEXTO, "La temporada terminó."))
		if carrera.toca_retirarse(mundo):
			pv.add_child(_boton("👟  Colgar las botas", LIMA, _pintar_retiro, 50))
		else:
			pv.add_child(_boton("🗓  Empezar la temporada siguiente", LIMA, _nueva_temporada, 50))
	else:
		var par := _partido_de_la_semana(club)
		if par.is_empty():
			pv.add_child(_lbl(20, TEXTO, "Tu club descansa esta jornada."))
		else:
			var rival: Club = par[1] if par[0] == club else par[0]
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 12)
			pv.add_child(fila)
			for cl: Club in [par[0], par[1]]:
				var e := TextureRect.new()
				e.texture = Escudo.textura(cl, 44)
				e.custom_minimum_size = Vector2(44, 44)
				e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				e.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				fila.add_child(e)
				fila.add_child(_lbl(20, TEXTO, Nombres.visible(cl.nombre)))
				if cl == par[0]:
					fila.add_child(_lbl(20, LIMA, "vs"))
			var titular := carrera.es_titular(mundo)
			pv.add_child(_lbl(15, LIMA if titular else SUAVE, ("✅ El DT te pone de titular." if titular else "🪑 Esta semana empiezas en el banco.") + ("  (en casa)" if par[0] == club else "  (de visita, contra %s)" % Nombres.visible(rival.nombre))))
		var botones := HBoxContainer.new()
		botones.add_theme_constant_override("separation", 8)
		pv.add_child(botones)
		if not par.is_empty() and carrera.es_titular(mundo):
			var bj := _boton("🎮  JUGAR EL PARTIDO", LIMA, _jugar_partido, 56)
			bj.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			botones.add_child(bj)
		elif not par.is_empty() and carrera.jugador(mundo) != null and carrera.jugador(mundo).disponible():
			## DESDE EL BANCO (MEGAPLAN fase 3): vas convocado y quizá entras.
			var bb := _boton("🪑  IR AL BANCO (puedes entrar)", LIMA, _ir_al_banco, 56)
			bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			botones.add_child(bb)
		var bs := _boton("⏩  Simular la semana", CIAN, func() -> void: _cerrar_semana({}), 56)
		bs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botones.add_child(bs)
	## El entrenamiento.
	var pe := _panel(CIAN)
	v.add_child(pe)
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 6)
	pe.add_child(ev)
	ev.add_child(_lbl(13, CIAN, "ENTRENAMIENTO DE LA SEMANA"))
	var fila_f := HFlowContainer.new()
	fila_f.add_theme_constant_override("h_separation", 6)
	fila_f.add_theme_constant_override("v_separation", 6)
	ev.add_child(fila_f)
	var grupo := ButtonGroup.new()
	for f: String in CarreraJugador.FOCOS:
		var bf := _boton(String(CarreraJugador.FOCOS[f][0]), CIAN, func() -> void: carrera.foco = f, 36)
		bf.toggle_mode = true
		bf.button_group = grupo
		bf.button_pressed = carrera.foco == f
		fila_f.add_child(bf)
	## La temporada.
	var pt := _panel(Color("ffd24a"))
	v.add_child(pt)
	var tv := VBoxContainer.new()
	pt.add_child(tv)
	tv.add_child(_lbl(13, Color("ffd24a"), "TU TEMPORADA"))
	var s := carrera.stats_temp
	tv.add_child(_lbl(18, TEXTO, "%d partidos (%d de titular)  ·  %d goles  ·  %d asistencias  ·  nota %.2f" % [s["pj"], s["titular"], s["goles"], s["asist"], carrera.nota_media()]))
	for t: Dictionary in carrera.temporadas:
		tv.add_child(_lbl(12, SUAVE, "%d · %s · %d PJ · %d goles · %d asist · nota %.2f" % [int(t["anio"]), String(t["club"]), int(t["pj"]), int(t["goles"]), int(t["asist"]), float(t["nota"])]))
	return v

## LA DERECHA: los eventos con sus decisiones y las ofertas.
func _derecha(_j: Jugador) -> Control:
	var p := _panel(FUCSIA)
	p.custom_minimum_size = Vector2(400, 0)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	sc.add_child(v)
	v.add_child(_lbl(13, FUCSIA, "LO QUE TE PASA  (%d)" % carrera.eventos.size()))
	if carrera.eventos.is_empty():
		v.add_child(_lbl(14, SUAVE, "Nada pendiente. Entrena y juega."))
	for i in carrera.eventos.size():
		var e: Dictionary = carrera.eventos[i]
		var caja := _panel(LIMA)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		caja.add_child(cv)
		cv.add_child(_lbl(17, LIMA, String(e["titulo"])))
		cv.add_child(_lbl(13, TEXTO, String(e["texto"])))
		var ops: Array = e["opciones"]
		for k in ops.size():
			var idx := i
			var op := k
			cv.add_child(_boton(String(ops[k]["texto"]), CIAN, func() -> void:
				_msg = "Decidiste: " + carrera.resolver(mundo, idx, op)
				_pintar_semana(), 38))
		v.add_child(caja)
	if not carrera.ofertas.is_empty():
		v.add_child(_lbl(13, Color("ffd24a"), "OFERTAS"))
		for i in carrera.ofertas.size():
			var o: Dictionary = carrera.ofertas[i]
			var cl: Club = mundo.clubes.get(String(o["club_id"]))
			if cl == null:
				continue
			var k := i
			v.add_child(_boton("✈  %s te quiere · %s/sem · %d sem para decidir" % [Nombres.visible(cl.nombre), Eco.dinero(int(o["sueldo"])), int(o["semanas"])], Color("ffd24a"), func() -> void:
				if carrera.aceptar_oferta(mundo, k):
					_msg = "¡Fichaste por %s!" % carrera.club(mundo).nombre
				_pintar_semana(), 44))
	if not carrera.historial.is_empty():
		v.add_child(_lbl(13, SUAVE, "TUS DECISIONES"))
		for h: Dictionary in carrera.historial.slice(maxi(0, carrera.historial.size() - 6)):
			v.add_child(_lbl(12, SUAVE, "%d/%d · %s → %s" % [int(h["anio"]), int(h["semana"]), String(h["titulo"]), String(h["eleccion"])]))
	return p

# ---------------------------------------------------------------- la semana

func _pintar_semana() -> void:
	_limpiar()
	var m := mundo
	var c := carrera
	var j := c.jugador(m)
	var club := c.club(m)
	if j == null or club == null:
		_pintar_crear()
		return
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 22; raiz.offset_right = -22; raiz.offset_top = 16; raiz.offset_bottom = -16
	raiz.add_theme_constant_override("separation", 12)
	_cuerpo.add_child(raiz)
	## Cabecera.
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 14)
	raiz.add_child(cab)
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(club, 52)
	esc.custom_minimum_size = Vector2(52, 52)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cab.add_child(esc)
	var tit := VBoxContainer.new()
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(tit)
	tit.add_child(_lbl(30, LIMA, j.nombre.to_upper()))
	tit.add_child(_lbl(14, SUAVE, "%s  ·  %s  ·  %d años  ·  temporada %d, semana %d" % [Nombres.visible(club.nombre), j.pos_e, j.edad, m.anio, m.semana]))
	cab.add_child(_boton("💾 Guardar", CIAN, _guardar, 40))
	cab.add_child(_boton("🏠 Menú", SUAVE, _salir, 40))
	if _msg != "":
		var aviso := _lbl(15, FUCSIA, _msg)
		raiz.add_child(aviso)
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 14)
	raiz.add_child(cols)
	cols.add_child(_carta(j))
	## Con la convocatoria la columna crece: se desplaza en vez de cortarse.
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cols.add_child(sc)
	var centro := _centro(j, club)
	centro.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sc.add_child(centro)
	cols.add_child(_derecha(j))
	Idiomas.traducir_arbol(_cuerpo)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://ui/fondo_menu.gdshader")
	mat.set_shader_parameter("estilo", 3)
	mat.set_shader_parameter("c1", Color("050608"))
	mat.set_shader_parameter("c2", Color("0e1218"))
	mat.set_shader_parameter("c3", LIMA)
	mat.set_shader_parameter("aspecto", Vector2(1.78, 1.0))
	if Calidad.motor_ligero:
		fondo.color = Color("0e1218")
	else:
		fondo.material = mat
	add_child(fondo)
	_cuerpo = Control.new()
	_cuerpo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_cuerpo)
	if mundo != null and mundo.carrera_jugador != null:
		carrera = mundo.carrera_jugador
		_pintar_semana()
	else:
		_pintar_crear()
