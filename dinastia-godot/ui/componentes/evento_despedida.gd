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
	var mio := pr.mundo.mi_club()
	_centro.add_child(etiqueta("%s · %d" % [Idiomas.t("FIN DE TEMPORADA"), pr.mundo.anio], 15, Tema.SUAVE))
	_centro.add_child(etiqueta("🎖️ " + Idiomas.t("Partido de despedida"), 46, Tema.ORO, true, false))
	_centro.add_child(etiqueta("%s %d %s" % [Idiomas.t("Tu equipo se enfrenta a las Leyendas: los"), leyendas.plantilla.size(),
		Idiomas.t("mejores jugadores que se retiran esta temporada. Es un partido de gala: no cuenta para la liga y no deja lesiones.")], 17, Tema.TEXTO))
	var cruce := HBoxContainer.new()
	cruce.alignment = BoxContainer.ALIGNMENT_CENTER
	cruce.add_theme_constant_override("separation", 44)
	_centro.add_child(cruce)
	cruce.add_child(_equipo(mio, 118))
	cruce.add_child(etiqueta("VS", 38, Tema.ORO, true, false))
	cruce.add_child(_equipo(leyendas, 118))
	var top: Array = leyendas.plantilla.duplicate()
	top.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	var figuras := HBoxContainer.new()
	figuras.alignment = BoxContainer.ALIGNMENT_CENTER
	figuras.add_theme_constant_override("separation", 26)
	_centro.add_child(figuras)
	for j: Jugador in top.slice(0, 3):
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		var r := pr._retrato(j, 84)
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(r)
		var nj := etiqueta(j.nombre, 14, Tema.ORO)
		nj.custom_minimum_size = Vector2(160, 0)
		col.add_child(nj)
		col.add_child(etiqueta("%s %d · %s" % [Idiomas.t("Nota"), j.ovr, j.pos_e], 12, Tema.SUAVE))
		figuras.add_child(col)
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 14)
	_centro.add_child(botones)
	for par: Array in [["jugar", "▶ " + Idiomas.t("Jugarlo"), true], ["simular", "⏭ " + Idiomas.t("Simularlo"), false], ["no", Idiomas.t("Ahora no"), false]]:
		var b := boton(String(par[1]), bool(par[2]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var op := String(par[0])
		b.pressed.connect(func() -> void: elegido.emit(op))
		botones.add_child(b)

## El escudo (o la insignia dorada de las Leyendas) y el nombre del equipo.
func _equipo(c: Club, alto: int) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var tr := TextureRect.new()
	tr.texture = Escudo.textura(c, alto)
	tr.custom_minimum_size = Vector2(alto, alto)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(tr)
	var nom := etiqueta(c.nombre, 20, Tema.TEXTO)
	nom.custom_minimum_size = Vector2(260, 0)
	col.add_child(nom)
	return col
