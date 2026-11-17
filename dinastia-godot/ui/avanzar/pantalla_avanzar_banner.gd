class_name PantallaAvanzarBanner
extends RefCounted
## EL BANNER DE LA PANTALLA «AVANZAR» (maqueta, `.banner`): el degradado del color del evento con sus franjas, el rótulo negro translúcido («13 ABR · EVENTO IMPORTANTE»),
## el titular condensado de 38 px, el texto de debajo y el arte del evento a la derecha. En los partidos, los dos escudos con «VS» (como `b_11.jpg`) y el degradado de
## los colores de los dos clubes. Solo se arma cuando el cursor está sobre el día del evento.

const ETIQUETA_DE_CLASE := {EventosDia.PARTIDO: "Partido", EventosDia.PANTALLA: "Decisión importante"}

static func armar(cap: Control, fondo: FondoCine, evs: Array, m: Mundo, fecha: Dictionary) -> void:
	for h in cap.get_children():
		h.free()
	var ev: Dictionary = evs[0]
	var ficha := EstiloAvanzar.ficha(ev)
	var es_partido := String(ev.get("clase", "")) == EventosDia.PARTIDO
	fondo.franjas = true
	var col := EstiloAvanzar.color_de(String(ficha[1]))
	var rival: Variant = ev.get("rival", null)
	if es_partido and rival is Club:
		var local: Club = m.mi_club() if bool(ev.get("local", true)) else rival
		var visita: Club = rival if bool(ev.get("local", true)) else m.mi_club()
		fondo.modo = FondoCine.Modo.EVENTO
		fondo.color = Color("0c1426")
		_degradado(cap, Color(local.color1), Color(visita.color1))
	else:
		fondo.modo = FondoCine.Modo.EVENTO
		fondo.color = col
	fondo.queue_redraw()
	var kicker: String = Idiomas.t(String(ETIQUETA_DE_CLASE.get(String(ev.get("clase", "")), ficha[2]))) if String(ev.get("clase", "")) == EventosDia.PARTIDO else Idiomas.t(String(ficha[2]))
	var rot := "%d %s · %s" % [int(fecha["day"]), Idiomas.t(String(Principal.MESES_LARGOS[int(fecha["month"]) - 1])).left(3).to_upper(), kicker.to_upper()]
	var eti := EstiloAvanzar.etiqueta(rot, 12, EstiloAvanzar.TINTA, false)
	eti.position = Vector2(26, 14)
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
	if es_partido and rival is Club:
		var casa := bool(ev.get("local", true))
		titulo = "%s · %s" % [m.mi_club().nombre if casa else (rival as Club).nombre, (rival as Club).nombre if casa else m.mi_club().nombre]
		sub = "%s · %s" % [String(ev.get("etiqueta", "")), Idiomas.t("en casa" if casa else "de visitante")]
	if evs.size() > 1:
		sub += "  ·  " + Idiomas.t("y %d más") % (evs.size() - 1)
	var t := EstiloAvanzar.etiqueta(titulo, 38, EstiloAvanzar.TINTA, true, true)
	t.position = Vector2(26, 68)
	t.size = Vector2(800, 46)
	t.clip_text = true
	cap.add_child(t)
	var s := EstiloAvanzar.etiqueta(sub, 15, Color(1, 1, 1, 0.88))
	s.position = Vector2(26, 118)
	s.size = Vector2(800, 24)
	s.clip_text = true
	cap.add_child(s)
	if es_partido and rival is Club:
		var f := HBoxContainer.new()
		f.position = Vector2(840, 14)
		f.size = Vector2(260, 128)
		f.alignment = BoxContainer.ALIGNMENT_CENTER
		f.add_theme_constant_override("separation", 14)
		var casa2 := bool(ev.get("local", true))
		for par: Array in [[m.mi_club() if casa2 else rival], ["vs"], [rival if casa2 else m.mi_club()]]:
			if par[0] is Club:
				var tr := TextureRect.new()
				tr.texture = Escudo.textura(par[0] as Club, 110)
				tr.custom_minimum_size = Vector2(96, 110)
				tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				f.add_child(tr)
			else:
				f.add_child(EstiloAvanzar.etiqueta("VS", 22, Color(1, 1, 1, 0.75), true))
		cap.add_child(f)
		return
	var tex := EstiloAvanzar.arte(String(ficha[0]))
	if tex != null:
		var a := TextureRect.new()
		a.texture = tex
		a.position = Vector2(1128 - 8 - 200, 156 - 150)
		a.size = Vector2(200, 150)
		a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cap.add_child(a)

## El degradado suave del local al rival (rojo → azul en `b_11.jpg`) pasando por un tono oscuro, con las franjas inclinadas de la maqueta, sin corte a la mitad.
static func _degradado(cap: Control, a: Color, b: Color) -> void:
	var noche := Color("0c1426")   ## los colores de club muy claros (blanco, amarillo) se oscurecen para que el titular se lea
	a = a.lerp(noche, 0.3 + maxf(0.0, a.get_luminance() - 0.3))
	b = b.lerp(noche, 0.3 + maxf(0.0, b.get_luminance() - 0.3))
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var medio := a.lerp(b, 0.5).lerp(Color("0c1426"), 0.55)
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
		var x := -73.0
		while x < 1160.0:
			f.draw_polygon(PackedVector2Array([Vector2(x + 73, 0), Vector2(x + 103, 0), Vector2(x + 30, 156), Vector2(x, 156)]), PackedColorArray([Color(1, 1, 1, 0.07)]))
			x += 90.0)
	cap.add_child(f)
