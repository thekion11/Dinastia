class_name EventoDespedida
extends EventoPantallaCompleta
## EL AVISO DEL PARTIDO DE DESPEDIDA, A PANTALLA COMPLETA (regla del dueño, 9-11): aparece SOLO al llegar el fin de la temporada (lo dispara `AvanceSemana`
## cuando la liga termina). Tu club frente a las Leyendas, sus tres mayores figuras y tres opciones: Jugarlo, Simularlo o Ahora no. Emite `elegido(op)`.
static func mostrar(pr: Principal, leyendas: Club) -> EventoDespedida:
	var e := EventoDespedida.new()
	e._montar_base(pr)
	e._rellenar(pr, leyendas)
	return e

func _rellenar(pr: Principal, leyendas: Club) -> void:
	_centro.add_child(etiqueta("%s · %d" % [Idiomas.t("FIN DE TEMPORADA"), pr.mundo.anio], 15, Tema.SUAVE))
	_centro.add_child(etiqueta("🎖️ " + Idiomas.t("Partido de despedida"), 46, Tema.ORO, true, false))
	_centro.add_child(etiqueta("%s %d %s" % [Idiomas.t("Tu equipo se enfrenta a las Leyendas: los"), leyendas.plantilla.size(),
		Idiomas.t("mejores jugadores que se retiran esta temporada. Es un partido de gala: no cuenta para la liga y no deja lesiones.")], 17, Tema.TEXTO))
	## (9-11, orden del dueño) Solo el ESCUDO de las Leyendas (5 diseños que rotan por temporada) y, a su lado, el ONCE TITULAR de los retirados con su busto 3D.
	var cuerpo := HBoxContainer.new()
	cuerpo.alignment = BoxContainer.ALIGNMENT_CENTER
	cuerpo.add_theme_constant_override("separation", 48)
	_centro.add_child(cuerpo)
	cuerpo.add_child(_escudo(leyendas, 170))
	cuerpo.add_child(_cancha(pr, leyendas))
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 14)
	_centro.add_child(botones)
	for par: Array in [["jugar", "▶ " + Idiomas.t("Jugarlo"), true], ["simular", "⏭ " + Idiomas.t("Simularlo"), false], ["no", Idiomas.t("Ahora no"), false]]:
		var b := boton(String(par[1]), bool(par[2]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var op := String(par[0])
		b.pressed.connect(func() -> void: elegido.emit(op))
		botones.add_child(b)

## El escudo de las Leyendas de la temporada y su nombre.
func _escudo(c: Club, alto: int) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var tr := TextureRect.new()
	tr.texture = Escudo.textura(c, alto)
	tr.custom_minimum_size = Vector2(alto, alto)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(tr)
	var nom := etiqueta(c.nombre, 22, Tema.ORO)
	nom.custom_minimum_size = Vector2(240, 0)
	col.add_child(nom)
	return col

## El once titular de las Leyendas sobre una cancha: delanteros arriba, portero abajo; cada uno con su busto 3D (el mismo modelo que juega), nombre y nota.
func _cancha(pr: Principal, c: Club) -> Control:
	var panel := PanelContainer.new()
	var est := Tema.caja(Color("173a26"), Tema.RADIO_GRANDE, Color(1, 1, 1, 0.25))
	est.set_content_margin_all(10)
	est.shadow_color = Color(0, 0, 0, 0.5)
	est.shadow_size = 12
	panel.add_theme_stylebox_override("panel", est)
	var filas := VBoxContainer.new()
	filas.add_theme_constant_override("separation", 4)
	panel.add_child(filas)
	var once := c.once()
	for grupo: String in ["DEL", "MED", "DEF", "POR"]:
		var fila := HBoxContainer.new()
		fila.alignment = BoxContainer.ALIGNMENT_CENTER
		fila.add_theme_constant_override("separation", 22)
		for j: Jugador in once:
			if j.pos == grupo:
				fila.add_child(_figura(pr, j))
		if fila.get_child_count() > 0:
			filas.add_child(fila)
	return panel

func _figura(pr: Principal, j: Jugador) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	var r := pr._retrato(j, 54)
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(r)
	var nj := etiqueta(j.nombre, 11, Tema.TEXTO, true, false)
	nj.custom_minimum_size = Vector2(112, 0)
	nj.clip_text = true
	col.add_child(nj)
	col.add_child(etiqueta("%s · %d" % [j.pos_e, j.ovr], 11, Tema.ORO))
	return col
