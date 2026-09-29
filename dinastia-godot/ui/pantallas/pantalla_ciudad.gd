class_name PantallaCiudad
extends RefCounted
## LA CIUDAD: terrenos, negocios, conciertos, la municipalidad, la sostenibilidad y la seguridad.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _editor_de() -> Editor:
	if p._editor == null or p._editor._mundo() != p.mundo:
		p._editor = Editor.new(p.mundo)
	return p._editor

## EL ALUMBRADO PÚBLICO: de qué color se ve tu ciudad de noche. Es la única
## decisión de la pantalla que no cuesta dinero ni da ingresos, y aun así es de
## las que más cambian cómo se ve el juego -de noche las farolas son lo único
## que dibuja el trazado de la ciudad-. Siete tonos con nombre para el que solo
## quiere algo que quede bien, y un selector libre para el que quiere el suyo.
func _pintar_luces_ciudad(ci: Ciudad) -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "💡 ALUMBRADO PÚBLICO"
	p._lista_ciudad.add_child(t)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 5)
	flow.add_theme_constant_override("v_separation", 5)
	p._lista_ciudad.add_child(flow)
	for par: Array in Ciudad.paletas_luces():
		var hex := String(par[0])
		var b := Button.new()
		b.text = ("● " if ci.luces == hex else "") + String(par[1])
		b.add_theme_font_size_override("font_size", 11)
		b.add_theme_color_override("font_color", Color(hex))
		b.pressed.connect(func() -> void:
			ci.luces = hex
			p._refrescar())
		flow.add_child(b)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_ciudad.add_child(fila)
	var et := p._texto(11, Principal.COL_TEXTO)
	et.text = "O elige el tuyo"
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(et)
	var cp := ColorPickerButton.new()
	cp.color = Color(ci.luces)
	cp.custom_minimum_size = Vector2(84, 24)
	cp.edit_alpha = false
	cp.color_changed.connect(func(nuevo: Color) -> void:
		ci.luces = "#" + nuevo.to_html(false))
	fila.add_child(cp)

func _pintar_terrenos(ci: Ciudad, c: Club) -> void:
	p._lista_ciudad.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_ACENTO)
	t.text = "🗺️ TERRENOS"
	p._lista_ciudad.add_child(t)
	for f: Array in Ciudad.lista_terrenos():
		var clave := String(f[0])
		var mio := ci.tiene_terreno(clave)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_ciudad.add_child(fila)
		var n := p._texto(12, Principal.COL_VERDE if mio else Principal.COL_TEXTO)
		n.text = "%s%s" % ["✔  " if mio else "     ", String(f[1])]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		n.tooltip_text = String(f[3])
		fila.add_child(n)
		var b := Button.new()
		var precio := ci.precio_terreno(clave, c)
		b.text = "Tuyo" if mio else p._dinero(precio)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = mio or c.saldo < precio
		b.custom_minimum_size = Vector2(110, 0)
		b.pressed.connect(func() -> void:
			var p_local := ci.comprar_terreno(clave, p.mundo.mi_club())
			if p_local != "":
				p._escribir("[color=#e05555]No se pudo: %s.[/color]" % p_local)
			p._refrescar())
		fila.add_child(b)
		if not p._modo_experto and not mio:
			var d := p._texto(10, Principal.COL_SUAVE)
			d.text = "     %s" % String(f[3])
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_ciudad.add_child(d)

func _pintar_negocios(ci: Ciudad, c: Club) -> void:
	p._lista_ciudad.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_ACENTO)
	t.text = "🏗️ NEGOCIOS ANEXOS"
	p._lista_ciudad.add_child(t)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Ingresan todas las semanas del año, jueguen o no. Es lo que separa a un club que sobrevive de uno que crece."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ciudad.add_child(ex)
	for f: Array in Ciudad.lista_negocios():
		var clave := String(f[0])
		var hecho := ci.tiene_negocio(clave)
		var terr: Variant = f[3]
		var falta := terr != null and String(terr) != "" and not ci.tiene_terreno(String(terr))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_ciudad.add_child(fila)
		var n := p._texto(12, Principal.COL_VERDE if hecho else (Principal.COL_SUAVE if falta else Principal.COL_TEXTO))
		n.text = "%s%s" % ["✔  " if hecho else "     ", String(f[1])]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		n.tooltip_text = String(f[4])
		fila.add_child(n)
		var r := p._texto(11, Principal.COL_ORO)
		r.text = "+%s/sem" % p._dinero(Eco.escalar(Ciudad.RENTA_NEGOCIO_BASE * float(f[5]), float(c.rep)))
		r.custom_minimum_size = Vector2(96, 0)
		fila.add_child(r)
		var b := Button.new()
		var coste := Eco.escalar(float(f[2]), float(c.rep))
		b.text = "Operando" if hecho else p._dinero(coste)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = hecho or falta or c.saldo < coste
		b.custom_minimum_size = Vector2(110, 0)
		b.pressed.connect(func() -> void:
			var p_local := ci.construir_negocio(clave, p.mundo.mi_club())
			if p_local != "":
				p._escribir("[color=#e05555]No se puede: %s.[/color]" % p_local)
			p._refrescar())
		fila.add_child(b)
		if falta:
			var dt := Ciudad.def_terreno(String(terr))
			var av := p._texto(10, Principal.COL_ORO)
			av.text = "     Requiere antes: %s" % (String(dt[1]) if not dt.is_empty() else String(terr))
			p._lista_ciudad.add_child(av)

## LOS CONCIERTOS. La decisión más honesta de la pantalla: dinero hoy contra
## rendimiento el domingo.
func _pintar_conciertos(ci: Ciudad, c: Club) -> void:
	p._lista_ciudad.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_ACENTO)
	t.text = "🎤 EVENTOS NO DEPORTIVOS"
	p._lista_ciudad.add_child(t)
	p._dato("Conciertos realizados", str(ci.conciertos), Principal.COL_TEXTO, p._lista_ciudad)
	var bruto := int(round(float(c.estadio_aforo) * Finanzas.ingreso_por_espectador(9.0) * 1.8))
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Un concierto llena la caja de golpe (%s) pero destroza el campo y molesta al barrio. Con el césped por debajo de %d, tus jugadores pierden precisión." % [
			p._dinero(bruto), Ciudad.CESPED_MINIMO_CONCIERTO]
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ciudad.add_child(ex)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_ciudad.add_child(fila)
	var b := Button.new()
	b.text = "🎤 Arrendar para un concierto"
	b.add_theme_font_size_override("font_size", 11)
	b.clip_text = true
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = ci.cesped < Ciudad.CESPED_MINIMO_CONCIERTO
	b.pressed.connect(func() -> void:
		var p_local := ci.arrendar_estadio(p.mundo.mi_club())
		if p_local != "":
			p._escribir("[color=#e05555]No se puede: %s.[/color]" % p_local)
		p._refrescar())
	fila.add_child(b)
	var br := Button.new()
	br.text = "🌱 Resembrar  ·  %s" % p._dinero(ci.coste_resiembra(c))
	br.add_theme_font_size_override("font_size", 11)
	br.clip_text = true
	br.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	br.disabled = ci.cesped >= 100
	br.pressed.connect(func() -> void:
		var p_local := ci.reparar_cesped(p.mundo.mi_club())
		if p_local != "":
			p._escribir("[color=#e05555]No se puede: %s.[/color]" % p_local)
		p._refrescar())
	fila.add_child(br)

func _pintar_municipalidad(ci: Ciudad, c: Club) -> void:
	p._lista_ciudad.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_ACENTO)
	t.text = "🏛️ MUNICIPALIDAD Y VECINOS"
	p._lista_ciudad.add_child(t)
	var lectura := p._texto(11, Principal.COL_SUAVE)
	if ci.vecinos < 35:
		lectura.text = "El barrio está en pie de guerra: cualquier permiso te lo van a tumbar."
	elif ci.vecinos > 70:
		lectura.text = "El barrio te quiere: los permisos salen casi solos."
	else:
		lectura.text = "Relación tibia con el vecindario."
	lectura.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_ciudad.add_child(lectura)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	p._lista_ciudad.add_child(fila)
	for op: Array in [
			["obra", "🏗️ Obra social  ·  %s" % p._dinero(Eco.escalar(Ciudad.COSTE_OBRA_SOCIAL, float(c.rep)))],
			["reunion", "🗣️ Reunión vecinal"],
			["entradas", "🎟️ Entradas para el barrio"]]:
		var que := String(op[0])
		var b := Button.new()
		b.text = String(op[1])
		b.add_theme_font_size_override("font_size", 10)
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			var p_local := ci.gestion_vecinal(que, p.mundo.mi_club())
			if p_local != "":
				p._escribir("[color=#e05555]No se pudo: %s.[/color]" % p_local)
			p._refrescar())
		fila.add_child(b)
	if not p._modo_experto:
		var eg := p._texto(10, Principal.COL_SUAVE)
		eg.text = "Una gestión al mes. La reunión es gratis y puede salir mal: es la única de las tres que se puede volver en contra."
		eg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ciudad.add_child(eg)

	var tp := p._texto(10, Principal.COL_SUAVE)
	tp.text = "Ampliación del estadio"
	p._lista_ciudad.add_child(tp)
	if ci.permiso_ok:
		p._dato("Permiso municipal", "vigente ✔", Principal.COL_VERDE, p._lista_ciudad)
	else:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Para pasar del nivel 5 de tribunas hace falta permiso municipal. Hoy no lo tienes."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ciudad.add_child(ex)
		var b := Button.new()
		b.text = "🏛️ Solicitar permiso  ·  %s" % p._dinero(Eco.escalar(Ciudad.COSTE_PERMISO, float(c.rep)))
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = not ci.permiso.is_empty()
		b.pressed.connect(func() -> void:
			var p_local := ci.pedir_permiso(p.mundo.mi_club())
			if p_local != "":
				p._escribir("[color=#e05555]No se pudo: %s.[/color]" % p_local)
			p._refrescar())
		p._lista_ciudad.add_child(b)
	p._dato("Subvención estimada al cierre", p._dinero(ci.subvencion_anual(c)), Principal.COL_VERDE, p._lista_ciudad)

func _pintar_sostenibilidad(ci: Ciudad, c: Club) -> void:
	p._lista_ciudad.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_ACENTO)
	t.text = "🌿 SOSTENIBILIDAD"
	p._lista_ciudad.add_child(t)
	p._dato("Cubierta solar", "%s%s" % ["●".repeat(ci.paneles), "○".repeat(Ciudad.PANELES_MAX - ci.paneles)],
		Principal.COL_VERDE if ci.paneles > 0 else Principal.COL_SUAVE, p._lista_ciudad)
	if ci.paneles > 0:
		p._dato("Ahorro energético", "%s/semana" % p._dinero(ci.ahorro_energetico(c)), Principal.COL_VERDE, p._lista_ciudad)
	p._dato("Certificación ecológica", "certificado ✔" if ci.certificado else "sin certificar",
		Principal.COL_VERDE if ci.certificado else Principal.COL_SUAVE, p._lista_ciudad)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p._lista_ciudad.add_child(fila)
	var bp := Button.new()
	bp.text = "☀️ Paneles solares" if ci.paneles >= Ciudad.PANELES_MAX else \
		"☀️ Paneles  ·  %s" % p._dinero(Eco.escalar(Ciudad.COSTE_PANELES, float(c.rep)) * (ci.paneles + 1))
	bp.add_theme_font_size_override("font_size", 11)
	bp.clip_text = true
	bp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bp.disabled = ci.paneles >= Ciudad.PANELES_MAX
	bp.pressed.connect(func() -> void:
		var p_local := ci.instalar_paneles(p.mundo.mi_club())
		if p_local != "":
			p._escribir("[color=#e05555]No se puede: %s.[/color]" % p_local)
		p._refrescar())
	fila.add_child(bp)
	var bc := Button.new()
	bc.text = "🌿 Certificar  ·  %s" % p._dinero(Eco.escalar(Ciudad.COSTE_CERTIFICACION, float(c.rep)))
	bc.add_theme_font_size_override("font_size", 11)
	bc.clip_text = true
	bc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bc.disabled = ci.certificado or ci.paneles < 2
	bc.pressed.connect(func() -> void:
		var p_local := ci.certificar(p.mundo.mi_club())
		if p_local != "":
			p._escribir("[color=#e05555]No se puede: %s.[/color]" % p_local)
		p._refrescar())
	fila.add_child(bc)

func _pintar_seguridad(ci: Ciudad, c: Club) -> void:
	p._lista_ciudad.add_child(HSeparator.new())
	var t := p._texto(11, p.COL_ACENTO)
	t.text = "🛡️ SEGURIDAD DEL ESTADIO"
	p._lista_ciudad.add_child(t)
	for op: Array in [["privada", "Seguridad privada", ci.seg_privada],
			["camaras", "Cámaras y protocolo", ci.seg_camaras]]:
		var que := String(op[0])
		var niv: int = op[2]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_ciudad.add_child(fila)
		var n := p._texto(12, Principal.COL_TEXTO)
		n.text = "%s  %s%s" % [String(op[1]), "●".repeat(niv), "○".repeat(Ciudad.SEGURIDAD_MAX - niv)]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		fila.add_child(n)
		var b := Button.new()
		var coste := Eco.escalar(200000.0 if que == "privada" else 260000.0, float(c.rep)) * (niv + 1)
		b.text = "MÁX" if niv >= Ciudad.SEGURIDAD_MAX else p._dinero(coste)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = niv >= Ciudad.SEGURIDAD_MAX or c.saldo < coste
		b.custom_minimum_size = Vector2(110, 0)
		b.pressed.connect(func() -> void:
			var p_local := ci.mejorar_seguridad(que, p.mundo.mi_club())
			if p_local != "":
				p._escribir("[color=#e05555]No se puede: %s.[/color]" % p_local)
			p._refrescar())
		fila.add_child(b)
	var riesgo := ci.riesgo_incidente(
		p.mundo.prensa.animo if p.mundo.prensa else 60,
		p.mundo.prensa.funa if p.mundo.prensa else 0)
	p._dato("Riesgo de incidente por partido en casa", "%d%%" % int(round(riesgo * 100.0)),
		Principal.COL_ROJO if riesgo > 0.08 else Principal.COL_SUAVE, p._lista_ciudad)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "Un incidente grave cuesta puertas cerradas o aforo reducido, y eso es taquilla que no vuelve. Sube con el mal ambiente y la funa."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_ciudad.add_child(ex)
