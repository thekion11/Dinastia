class_name CeremoniaDespedida
extends EventoPantallaCompleta
## LA CEREMONIA DEL HOMENAJE, A PANTALLA COMPLETA (regla del dueño, 9-11): sale tras el partido de despedida (nunca antes ni por un menú). Una tarjeta grande por
## HOMENAJEADO de tu club (retrato, nombre, edad y nota, y su CAMISETA RETIRADA con el número) y, si no hay, las tres mayores Leyendas de la noche.
## Se cierra con «Continuar» (emite `terminado`). Retratos del juego (`Principal._retrato`, caras ficticias).

## `homenajeados`: [{jugador, dorsal}] de tu club; `leyendas`: el club de las Leyendas (para completar con sus mejores).
static func mostrar(pr: Principal, homenajeados: Array, leyendas: Club) -> CeremoniaDespedida:
	var c := CeremoniaDespedida.new()
	c._montar_base(pr)
	c._rellenar(pr, homenajeados, leyendas)
	return c

func _rellenar(pr: Principal, homenajeados: Array, leyendas: Club) -> void:
	## (12-11) Teléfono de pie: a 500 px, con el campo 3D a ese ancho y las tarjetas en rejilla de 2 (a 1000 px se salía todo por la derecha).
	var de_pie := EscalaMovil.es_vertical()
	_centro.custom_minimum_size = Vector2(ancho_base(1000.0), 0)
	_centro.add_child(etiqueta(Idiomas.t("PARTIDO DE DESPEDIDA"), 15, Tema.SUAVE))
	_centro.add_child(etiqueta("🎖️ " + Idiomas.t("Homenaje"), 28 if de_pie else 40, Tema.ORO, true, false))
	var filas: Array = []
	for h: Dictionary in homenajeados:
		filas.append({"j": h["jugador"], "dorsal": int(h["dorsal"]), "propio": true})
	if filas.is_empty():
		var top: Array = leyendas.plantilla.duplicate()
		top.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
		for j: Jugador in top.slice(0, 3):
			filas.append({"j": j, "dorsal": 0, "propio": false})
	## (10-11) EL HOMENAJE EN 3D EN EL CAMPO: los homenajeados con su camiseta retirada, bajo los focos (`HomenajeCampo3D`; sin pantalla no se monta).
	var mio := pr.mundo.mi_club() if pr.mundo != null else null
	if homenajeados.is_empty():
		mio = leyendas   ## sin homenajeados de tu club, las Leyendas con sus colores
	var campo: Control = load("res://visor/homenaje_campo3d.gd").montar(filas, Color(mio.color1) if mio else Tema.ACENTO, Color(mio.color2) if mio else Color.WHITE)
	if campo != null:
		campo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if de_pie:
			campo.custom_minimum_size = Vector2(ANCHO_DE_PIE - 8.0, 300)
		_centro.add_child(campo)
	var tarjetas: Container
	if de_pie:
		tarjetas = GridContainer.new()
		(tarjetas as GridContainer).columns = 2
		tarjetas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tarjetas.add_theme_constant_override("h_separation", 12)
		tarjetas.add_theme_constant_override("v_separation", 12)
	else:
		tarjetas = HBoxContainer.new()
		(tarjetas as HBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
		tarjetas.add_theme_constant_override("separation", 28)
	_centro.add_child(tarjetas)
	for f: Dictionary in filas.slice(0, 4):
		tarjetas.add_child(_tarjeta(pr, f))
	var seguir := boton(Idiomas.t("Continuar"), true)
	seguir.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	seguir.custom_minimum_size = Vector2(320, 58)
	seguir.pressed.connect(func() -> void: terminado.emit())
	_centro.add_child(seguir)

func _tarjeta(pr: Principal, f: Dictionary) -> Control:
	var j: Jugador = f["j"]
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.32)
	sb.border_color = Color(Tema.ORO, 0.7)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(10)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 14
	pc.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.custom_minimum_size = Vector2(200 if EscalaMovil.es_vertical() else 220, 0)
	pc.add_child(col)
	var r := pr._retrato(j, 84)
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.custom_minimum_size = Vector2(84, 84)
	r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(r)
	col.add_child(etiqueta(j.nombre, 17 if EscalaMovil.es_vertical() else 22, Tema.ORO))
	col.add_child(etiqueta("%d %s · %s %d · %s" % [j.edad, Idiomas.t("años"), Idiomas.t("Nota"), j.ovr, Idiomas.t(String(j.pos_e))], 14, Tema.SUAVE))
	if bool(f["propio"]) and int(f["dorsal"]) > 1:
		col.add_child(etiqueta("👕 #%d" % int(f["dorsal"]), 34, Tema.TEXTO))
		col.add_child(etiqueta(Idiomas.t("Camiseta retirada"), 14, Tema.ORO))
	return pc
