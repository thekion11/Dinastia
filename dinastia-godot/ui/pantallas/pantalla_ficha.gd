class_name PantallaFicha
extends "res://ui/pantallas/pantalla_ficha_p1.gd"
## [Capa 2/2 de `pantalla_ficha.gd`] _club_staff, _pintar_club

## EL PERSONAL CONTRATADO: cuerpo técnico, red de ojeadores, analítica y
## academias. Todo lo que se paga en nómina y no juega.
func _club_staff(c: Club) -> void:
	var t2 := p._texto(11, Principal.COL_SUAVE)
	t2.text = Idiomas.t("CUERPO TÉCNICO  ·  nómina %s/semana") % p._dinero(p.mundo.staff.sueldo_semanal(c.rep))
	p._lista_club.add_child(t2)
	## C9: la jornada legal del personal del país, con su norma.
	var jl := p._texto(11, Principal.COL_SUAVE)
	var fe := Contratos.factor_estructura(c.pais, p.mundo.anio, p.mundo.semana)
	jl.text = Idiomas.t("⚖️ Jornada legal del personal: %s%s") % [Contratos.texto_jornada(c.pais, p.mundo.anio, p.mundo.semana),
		"" if is_equal_approx(fe, 1.0) else Idiomas.t("  (la estructura cuesta un %+d%%)") % int(round((fe - 1.0) * 100.0))]
	jl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_club.add_child(jl)
	## El bono de productividad: una vez por temporada, sube la moral de TODO el
	## plantel, y sube más cuanto mejor vayas. Premiar a la gente yendo primero
	## es una fiesta; hacerlo yendo último se agradece y poco más.
	if p.mundo.staff.escalones_contratados() > 0:
		var fila_bono := HBoxContainer.new()
		fila_bono.add_theme_constant_override("separation", 8)
		p._lista_club.add_child(fila_bono)
		var ya := p.mundo.staff.anio_bono == p.mundo.anio
		var lb := p._texto(12, Principal.COL_SUAVE)
		lb.text = Idiomas.t("Bono de productividad") if not ya else Idiomas.t("Bono de productividad  ·  ya repartido este año")
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_bono.add_child(lb)
		var coste_bono := p.mundo.staff.coste_bono(c.rep)
		var bb := Button.new()
		bb.text = Idiomas.t("Repartir  %s") % p._dinero(coste_bono)
		bb.add_theme_font_size_override("font_size", 11)
		bb.disabled = ya or coste_bono > c.saldo
		bb.pressed.connect(func() -> void: p._ui_club_vida._bono_staff(c))
		fila_bono.add_child(bb)
	for puesto: String in Staff.PUESTOS:
		var datos: Array = Staff.PUESTOS[puesto]
		var n := p.mundo.staff.nivel(puesto)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_club.add_child(fila)
		var nom := p._texto(12, Principal.COL_TEXTO)
		## Las estrellas se leen de un vistazo; "nivel 3 de 5" hay que pararse a
		## leerlo.
		nom.text = "%s  %s" % ["★".repeat(n) + "·".repeat(Staff.NIVEL_MAX - n), datos[0]]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nom)
		if n >= Staff.NIVEL_MAX:
			var tope := p._texto(11, Principal.COL_VERDE); tope.text = Idiomas.t("al máximo")
			fila.add_child(tope)
		else:
			var coste := p.mundo.staff.coste_subir(puesto, c.rep)
			var b := Button.new()
			b.text = Idiomas.t("Contratar  %s") % p._dinero(coste)
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = coste > c.saldo or (p.mundo.roles != null and not p.mundo.roles.puede_contratar_staff())
			b.pressed.connect(func() -> void: _contratar(puesto))
			fila.add_child(b)
		var que := p._texto(11, Principal.COL_SUAVE)
		que.text = "    " + String(datos[1])
		que.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_club.add_child(que)
	_pintar_ojeadores(c)
	_pintar_analitica(c)
	_pintar_academias(c)

func _pintar_club(c: Club) -> void:
	p._limpiar(p._lista_club)
	match p._secc_club:
		"directorio": _club_directorio(c)
		"staff": _club_staff(c)
		"infra": p._club_infra(c)
		"carrera": p._club_carrera(c)
		_: _club_directorio(c)
