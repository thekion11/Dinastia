class_name PanelVida
extends RefCounted
## LA PANTALLA DE «MI VIDA» (26-9-2026): tu vida de entrenador fuera del club.
## Tres secciones, un chip cada una en el grupo MI VIDA:
##   - "hogar":     casa y transporte, con lo que cuestan por semana;
##   - "familia":   pareja, hijos y mascota, y el asunto de casa pendiente;
##   - "bienestar": estrés, equilibrio vida/trabajo y ocio de la semana.
## Arriba de las tres, siempre, el tablero: patrimonio, estrés y familia.
## La lógica está en `nucleo/vida_dt.gd`; aquí solo se pinta y se llama.

static func pintar(lista: VBoxContainer, p: Control, mundo: Mundo, secc: String) -> void:
	for h in lista.get_children():
		h.queue_free()
	var v := mundo.vida
	var r := mundo.roles
	if v == null or r == null:
		return
	if mundo.mi_club() != null:
		v.crear_perfil(mundo.mi_club().id)
	v.actualizar_escala(r)
	lista.add_child(_tablero(v, r, mundo))
	match secc:
		"hogar":
			_hogar(lista, p, mundo)
		"familia":
			_familia(lista, p, mundo)
		_:
			_bienestar(lista, p, mundo)
	Animar.escalonar(lista)

## -------------------------------------------------------------- TABLERO ---

static func _tarjeta(borde: Color = Tema.BORDE) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := Tema.caja(Tema.TARJETA, Tema.RADIO, borde)
	sb.content_margin_left = Tema.MARGEN
	sb.content_margin_right = Tema.MARGEN
	sb.content_margin_top = Tema.MARGEN - 2
	sb.content_margin_bottom = Tema.MARGEN - 2
	pc.add_theme_stylebox_override("panel", sb)
	return pc

## Una barra de 0 a 100 con su color y su número, que se llena al aparecer.
static func _medidor(titulo: String, valor: int, color: Color, nota: String) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fila := HBoxContainer.new()
	vb.add_child(fila)
	var t := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, titulo.to_upper())
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(t)
	var n := Tema.etiqueta(Tema.TAM_DESTACADO, color, str(valor))
	fila.add_child(n)
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 10)
	barra.max_value = 100
	barra.value = 0
	var fondo := Tema.caja(Color(1, 1, 1, 0.06), 5, Color(0, 0, 0, 0))
	var lleno := Tema.caja(color, 5, Color(0, 0, 0, 0))
	barra.add_theme_stylebox_override("background", fondo)
	barra.add_theme_stylebox_override("fill", lleno)
	vb.add_child(barra)
	if not Animar.reducidas():
		barra.create_tween().tween_property(barra, "value", float(valor), 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		barra.value = valor
	var nt := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, nota)
	vb.add_child(nt)
	return vb

static func _color_estres(e: int) -> Color:
	return Tema.BIEN if e < 40 else (Tema.ORO if e < 70 else Tema.MAL)

static func _tablero(v: VidaDT, r: Roles, mundo: Mundo) -> Control:
	var pc := _tarjeta(Color(Tema.ORO, 0.35))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", Tema.ESPACIO)
	pc.add_child(vb)
	var cab := HBoxContainer.new()
	vb.add_child(cab)
	var tit := Tema.etiqueta(Tema.TAM_TITULO, Tema.ORO, "🏠 MI VIDA")
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(tit)
	var pat := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, "")
	cab.add_child(pat)
	Animar.contar(pat, 0.0, float(r.patrimonio), func(x: float) -> String: return "💰 " + Cesiones.dinero(int(x)))
	var sub := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "Cobras %s a la semana · casa y transporte te cuestan %s" % [
		Cesiones.dinero(r.sueldo_semanal()), Cesiones.dinero(v.coste_semanal())])
	vb.add_child(sub)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 18)
	vb.add_child(fila)
	var nota_e := "Tranquilo" if v.estres < 40 else ("Cargado" if v.estres < 70 else "Al límite: el vestuario lo nota")
	if v.de_baja(mundo.anio, mundo.semana):
		nota_e = "De reposo esta semana por orden médica"
	fila.add_child(_medidor("Estrés", v.estres, _color_estres(v.estres), nota_e))
	fila.add_child(_medidor("Familia", v.familia, Tema.BIEN if v.familia >= 50 else (Tema.ORO if v.familia >= 25 else Tema.MAL),
		"Contentos contigo" if v.familia >= 50 else ("Te echan de menos" if v.familia >= 25 else "Hay tensión en casa")))
	fila.add_child(_medidor("Trabajo", v.balance, Tema.ACENTO, "Preparación de partidos +%.1f%%" % ((v.factor_trabajo(mundo.anio, mundo.semana) - 1.0) * 100.0)))
	return pc

## ---------------------------------------------------------------- HOGAR ---

static func _opciones(lista: VBoxContainer, p: Control, titulo: String, tabla: Dictionary, orden: Array,
		actual: String, alcance: String, al_elegir: Callable) -> void:
	lista.add_child(Tema.rotulo(titulo))
	## Flujo y no rejilla fija: con las columnas laterales abiertas el panel
	## central es angosto, y cinco tarjetas de 150 lo ensanchaban y empujaban
	## la ficha del jugador fuera de la pantalla (recorrido D4).
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", Tema.ESPACIO)
	grid.add_theme_constant_override("v_separation", Tema.ESPACIO)
	lista.add_child(grid)
	var v: VidaDT = p.get("mundo").vida
	for k: String in orden:
		var d: Array = tabla[k]
		var es := k == actual
		var pc := _tarjeta(Color(Tema.ORO, 0.8) if es else Tema.BORDE)
		pc.custom_minimum_size = Vector2(128, 140)
		grid.add_child(pc)
		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		pc.add_child(vb)
		var ic := Tema.etiqueta(40, Tema.TEXTO, String(d[3]))
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(ic)
		var nom := Tema.etiqueta(Tema.TAM_CUERPO, Tema.ORO if es else Tema.TEXTO, String(d[0]))
		nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(nom)
		var coste := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "%s/sem\ndescanso %d" % [Cesiones.dinero(v.precio(int(d[1]))), int(d[2])])
		coste.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(coste)
		if es:
			var ya := Tema.etiqueta(Tema.TAM_ROTULO, Tema.BIEN, "✔ " + alcance)
			ya.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vb.add_child(ya)
		else:
			var b := Button.new()
			b.text = "Elegir"
			b.add_theme_font_size_override("font_size", 12)
			var clave := k
			b.pressed.connect(func() -> void: al_elegir.call(clave))
			vb.add_child(b)

static func _hogar(lista: VBoxContainer, p: Control, mundo: Mundo) -> void:
	var v := mundo.vida
	## Tu casa en 3D, con tu DT en la terraza mirando las redes (28-9-2026).
	var ver := Button.new()
	ver.text = "🏡 Ver tu casa"
	ver.custom_minimum_size = Vector2(0, 34)
	ver.pressed.connect(func() -> void: CasaEscena3D.abrir(p, mundo, p.get("_bandeja")))
	lista.add_child(ver)
	var movil := Button.new()
	var pend := mundo.redes.pendientes() if mundo.redes != null else 0
	movil.text = "📱 Abrir el móvil (Tribuna)" + ("  · %d comentarios sin responder" % pend if pend > 0 else "")
	movil.custom_minimum_size = Vector2(0, 34)
	movil.pressed.connect(func() -> void: Telefono.abrir(p, mundo))
	lista.add_child(movil)
	_opciones(lista, p, "🏠 DÓNDE VIVES (la mudanza cuesta cuatro semanas de la casa nueva)", VidaDT.VIVIENDAS,
		VidaDT.ORDEN_VIVIENDA, v.vivienda, "vives aquí", func(k: String) -> void:
			_resultado(p, mundo.vida.cambiar_vivienda(k, mundo.roles), "Mudanza hecha."))
	_opciones(lista, p, "🚗 CÓMO TE MUEVES (el pie son seis semanas de cuota)", VidaDT.TRANSPORTES,
		VidaDT.ORDEN_TRANSPORTE, v.transporte, "lo usas", func(k: String) -> void:
			_resultado(p, mundo.vida.cambiar_transporte(k, mundo.roles), "Listo."))

## Muestra el error o el éxito y repinta.
static func _resultado(p: Control, problema: String, ok: String) -> void:
	if problema != "":
		Aviso.mostrar(p, "alerta", "⚠️", "No se pudo", problema)
	else:
		Aviso.mostrar(p, "vida", "✔", ok, "")
	p.call("_refrescar")

## -------------------------------------------------------------- FAMILIA ---

static func _persona(icono: String, nombre: String, detalle: String) -> PanelContainer:
	var pc := _tarjeta()
	pc.custom_minimum_size = Vector2(170, 0)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	pc.add_child(hb)
	hb.add_child(Tema.etiqueta(34, Tema.TEXTO, icono))
	var vb := VBoxContainer.new()
	hb.add_child(vb)
	vb.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, nombre))
	vb.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, detalle))
	return pc

static func _familia(lista: VBoxContainer, p: Control, mundo: Mundo) -> void:
	var v := mundo.vida
	## El asunto de casa pendiente, arriba y destacado.
	if not v.pendiente.is_empty():
		var pc := _tarjeta(Color(Tema.ORO, 0.9))
		lista.add_child(pc)
		var vb := VBoxContainer.new()
		pc.add_child(vb)
		vb.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, "PASA EN CASA"))
		var t := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, String(v.pendiente["texto"]))
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(t)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", Tema.ESPACIO)
		vb.add_child(hb)
		for op: String in ["a", "b"]:
			var b := Button.new()
			b.text = String(v.pendiente[op])
			var o := op
			b.pressed.connect(func() -> void:
				var res := mundo.vida.resolver(o, mundo.roles, mundo.mi_club(), mundo.prensa, mundo.anio, mundo.semana)
				Aviso.mostrar(p, "vida", "🏠", "Mi vida", res)
				p.call("_refrescar"))
			hb.add_child(b)
		Animar.pulso(pc, 1.03)
	lista.add_child(Tema.rotulo("👨‍👩‍👧 TU FAMILIA"))
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", Tema.ESPACIO)
	fila.add_theme_constant_override("v_separation", Tema.ESPACIO)
	lista.add_child(fila)
	var perfil := v.perfil
	if String(perfil.get("pareja", "")) != "":
		fila.add_child(_persona("💑", String(perfil["pareja"]), "Tu pareja"))
	for hj: Dictionary in perfil.get("hijos", []):
		fila.add_child(_persona("🧒" if int(hj["edad"]) < 13 else "🧑", String(hj["nombre"]), "%d años" % int(hj["edad"])))
	if String(perfil.get("mascota", "")) != "":
		fila.add_child(_persona("🐕", String(perfil["mascota"]), "La mascota de la casa"))
	if fila.get_child_count() == 0:
		fila.add_child(_persona("🧍", "Solo tú", "Vives solo, con el fútbol"))
	## Lo que ha pasado.
	lista.add_child(Tema.rotulo("📔 LO QUE HA PASADO"))
	if v.historial.is_empty():
		lista.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "Todavía nada que contar."))
	for h: Dictionary in v.historial.slice(0, 10):
		var l := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "• " + String(h["texto"]))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lista.add_child(l)

## ------------------------------------------------------------ BIENESTAR ---

static func _bienestar(lista: VBoxContainer, p: Control, mundo: Mundo) -> void:
	var v := mundo.vida
	lista.add_child(Tema.rotulo("⚖️ EQUILIBRIO VIDA / TRABAJO"))
	var pc := _tarjeta()
	lista.add_child(pc)
	var vb := VBoxContainer.new()
	pc.add_child(vb)
	var hb := HBoxContainer.new()
	vb.add_child(hb)
	hb.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "👨‍👩‍👧 Familia"))
	var sl := HSlider.new()
	sl.min_value = 0
	sl.max_value = 100
	sl.step = 5
	sl.value = v.balance
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(260, 24)
	hb.add_child(sl)
	hb.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "Trabajo 💼"))
	var expl := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "")
	expl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(expl)
	var explicar := func(x: float) -> void:
		expl.text = "Trabajo al %d%%: preparación +%.1f%%, estrés %s por semana, familia %s." % [int(x),
			float(clampi(int(x) - 50, 0, 50)) * 0.06,
			("%+d" % int((x - 50.0) / 8.0)) if absf(x - 50.0) >= 8.0 else "±0",
			("%+d" % -int((x - 55.0) / 6.0)) if absf(x - 55.0) >= 6.0 else "±0"]
	explicar.call(sl.value)
	sl.value_changed.connect(func(x: float) -> void:
		mundo.vida.balance = int(x)
		explicar.call(x))
	## El ocio de la semana.
	var ya := v.ocio_semana == VidaDT._abs(mundo.anio, mundo.semana)
	lista.add_child(Tema.rotulo("🎾 UN RESPIRO ESTA SEMANA" + ("  ·  ya te lo diste" if ya else "")))
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", Tema.ESPACIO)
	grid.add_theme_constant_override("v_separation", Tema.ESPACIO)
	lista.add_child(grid)
	for k: String in VidaDT.OCIO:
		var o: Array = VidaDT.OCIO[k]
		var b := Button.new()
		b.text = "%s  %s\n%s · estrés %d%s" % [String(o[4]), String(o[0]), Cesiones.dinero(v.precio(int(o[1]))) if int(o[1]) > 0 else "gratis",
			int(o[2]), (" · familia +%d" % int(o[3])) if int(o[3]) > 0 else ""]
		b.custom_minimum_size = Vector2(168, 52)
		b.disabled = ya
		b.add_theme_font_size_override("font_size", 12)
		var clave := k
		b.pressed.connect(func() -> void:
			_resultado(p, mundo.vida.hacer_ocio(clave, mundo.roles, mundo.anio, mundo.semana), String(VidaDT.OCIO[clave][0])))
		grid.add_child(b)
	var nota := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE,
		"Con el estrés alto tres semanas seguidas, el médico te manda a reposo una semana. Con el estrés bajo, el vestuario trabaja más a gusto.")
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista.add_child(nota)
