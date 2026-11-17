class_name PantallaAvanzarBanner
extends RefCounted
## EL BANNER DE LA PANTALLA «AVANZAR» (maqueta, `.banner`): el degradado del color del evento (con luces desenfocadas), el rótulo negro translúcido («13 ABR · EVENTO IMPORTANTE»),
## el titular condensado, la línea descriptiva, una segunda línea en cursiva con la CAUSA o el contexto, y el ARTE del evento a la derecha (copa, pizarra, candado, parte médico…).
## En los partidos, los dos escudos con «VS» y el degradado suave del color del local al del rival (como `b_11.jpg`). Solo se arma con el cursor sobre el día del evento.

const ANCHO := 1128.0
const ALTO := 200.0
const ETIQUETA_DE_CLASE := {EventosDia.PARTIDO: "Partido", EventosDia.PANTALLA: "Decisión importante"}
static var _cursiva: FontVariation

static func fuente_cursiva() -> Font:
	if _cursiva == null:
		_cursiva = FontVariation.new()
		var tema := ThemeDB.get_project_theme()
		_cursiva.base_font = tema.default_font if tema != null and tema.default_font != null else ThemeDB.fallback_font
		_cursiva.variation_transform = Transform2D(Vector2(1, 0), Vector2(-0.2, 1), Vector2.ZERO)
	return _cursiva

## El contexto de un evento (segunda línea): de dónde viene o por qué ocurrió.
static func contexto(ev: Dictionary, m: Mundo) -> String:
	var partes: Array[String] = []
	for c: Array in AvanzarTextos.cifras(ev, m):
		partes.append("%s %s" % [String(c[0]), String(c[1])])
	if not partes.is_empty():
		return " · ".join(partes)
	if String(ev.get("tipo", "")) == "fecha_pais":
		return "%s · %s" % [Idiomas.t("Calendario nacional"), PersonajeDatos.nombre_pais(String(ev.get("pais", "")))]
	if String(ev.get("origen", "")) == EventosDia.ORIGEN_DISPARADOR:
		return Idiomas.t(String(EstiloAvanzar.ficha(ev)[2]))
	return Idiomas.t("Calendario de la temporada")

static func armar(cap: Control, fondo: FondoCine, evs: Array, m: Mundo, fecha: Dictionary) -> void:
	for h in cap.get_children():
		h.free()
	var ev: Dictionary = evs[0]
	var ficha := EstiloAvanzar.ficha(ev)
	var es_partido := String(ev.get("clase", "")) == EventosDia.PARTIDO
	var rival: Variant = ev.get("rival", null)
	var con_escudos := es_partido and rival is Club
	fondo.franjas = true
	fondo.bokeh = not con_escudos and not Animar.reducidas()
	fondo.set_process(fondo.bokeh)
	if con_escudos:
		var casa := bool(ev.get("local", true))
		var local: Club = m.mi_club() if casa else rival
		var visita: Club = rival if casa else m.mi_club()
		fondo.modo = FondoCine.Modo.EVENTO
		fondo.color = Color("0c1426")
		_degradado(cap, Color(local.color1), Color(visita.color1))
	else:
		fondo.modo = FondoCine.Modo.EVENTO
		fondo.color = EstiloAvanzar.color_de(String(ficha[1]))
	fondo.queue_redraw()
	var kicker := Idiomas.t(String(ETIQUETA_DE_CLASE.get(String(ev.get("clase", "")), ficha[2]))) if es_partido else Idiomas.t(String(ficha[2]))
	var rot := "%d %s · %s" % [int(fecha["day"]), Idiomas.t(String(Principal.MESES_LARGOS[int(fecha["month"]) - 1])).left(3).to_upper(), kicker.to_upper()]
	var eti := EstiloAvanzar.etiqueta(rot, 12, EstiloAvanzar.TINTA, false)
	eti.position = Vector2(26, 16)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.38)
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	eti.add_theme_stylebox_override("normal", sb)
	cap.add_child(eti)
	var titulo := AvanzarTextos.titulo(ev)
	var sub := AvanzarTextos.texto(ev)
	var ctx := contexto(ev, m)
	if con_escudos:
		var casa2 := bool(ev.get("local", true))
		titulo = "%s · %s" % [m.mi_club().nombre if casa2 else (rival as Club).nombre, (rival as Club).nombre if casa2 else m.mi_club().nombre]
		sub = "%s · %s" % [String(ev.get("etiqueta", "")), Idiomas.t("en casa" if casa2 else "de visitante")]
		var sede: Club = m.mi_club() if casa2 else rival
		ctx = sede.estadio_nombre if sede.estadio_nombre != "" else Idiomas.t("Calendario de la temporada")
	if evs.size() > 1:
		ctx += "  ·  " + Idiomas.t("y %d más") % (evs.size() - 1)
	var ancho_txt := 760.0
	var t := EstiloAvanzar.etiqueta(titulo, 46, EstiloAvanzar.TINTA, true, true)
	t.position = Vector2(26, 78)
	t.size = Vector2(ancho_txt, 56)
	t.clip_text = true
	cap.add_child(t)
	var s := EstiloAvanzar.etiqueta(sub, 16, Color(1, 1, 1, 0.92))
	s.position = Vector2(26, 138)
	s.size = Vector2(ancho_txt, 24)
	s.clip_text = true
	cap.add_child(s)
	var c := EstiloAvanzar.etiqueta(ctx, 14, Color(1, 1, 1, 0.68))
	c.add_theme_font_override("font", fuente_cursiva())
	c.position = Vector2(26, 166)
	c.size = Vector2(ancho_txt, 22)
	c.clip_text = true
	cap.add_child(c)
	if con_escudos:
		var f := HBoxContainer.new()
		f.position = Vector2(ANCHO - 330, 24)
		f.size = Vector2(300, ALTO - 48)
		f.alignment = BoxContainer.ALIGNMENT_CENTER
		f.add_theme_constant_override("separation", 16)
		var casa3 := bool(ev.get("local", true))
		for par: Array in [[m.mi_club() if casa3 else rival], ["vs"], [rival if casa3 else m.mi_club()]]:
			if par[0] is Club:
				var tr := TextureRect.new()
				tr.texture = Escudo.textura(par[0] as Club, 128)
				tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tr.custom_minimum_size = Vector2(112, 128)
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				f.add_child(tr)
			else:
				f.add_child(EstiloAvanzar.etiqueta("VS", 24, Color(1, 1, 1, 0.75), true))
		cap.add_child(f)
		return
	var tex := EstiloAvanzar.arte(String(ficha[0]))
	if tex != null:
		var a := TextureRect.new()
		a.texture = tex
		a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		a.size = Vector2(ALTO * 1.34, ALTO)
		a.position = Vector2(ANCHO - 14.0 - a.size.x, 0)
		a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cap.add_child(a)

## El degradado suave del local al rival pasando por un tono oscuro, con las franjas inclinadas de la maqueta, sin corte a la mitad.
static func _degradado(cap: Control, a: Color, b: Color) -> void:
	var noche := Color("0c1426")   ## los colores de club muy claros (blanco, amarillo) se oscurecen para que el titular se lea
	a = a.lerp(noche, 0.3 + maxf(0.0, a.get_luminance() - 0.3))
	b = b.lerp(noche, 0.3 + maxf(0.0, b.get_luminance() - 0.3))
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var medio := a.lerp(b, 0.5).lerp(noche, 0.55)
	g.colors = PackedColorArray([Color(a, 0.95), Color(medio, 0.95), Color(b, 0.95)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0.4)
	gt.fill_to = Vector2(1, 0.6)
	var r := TextureRect.new()
	r.texture = gt
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	cap.add_child(r)
	var f := Control.new()
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	f.draw.connect(func() -> void:
		var x := -93.0
		while x < 1160.0:
			f.draw_polygon(PackedVector2Array([Vector2(x + 93, 0), Vector2(x + 123, 0), Vector2(x + 30, ALTO), Vector2(x, ALTO)]), PackedColorArray([Color(1, 1, 1, 0.07)]))
			x += 90.0)
	cap.add_child(f)
