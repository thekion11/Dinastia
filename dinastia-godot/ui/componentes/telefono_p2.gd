extends "res://ui/componentes/telefono_p1.gd"
## [Capa 2/3 de `telefono.gd`] _tarjeta, _perfil, _publicar, _tribuna, _burbuja_icono, _un_chat … (+4)

func _tarjeta(p: Dictionary) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", Tema.caja(TARJETA, 14, TARJETA))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	var cuenta := String(p["cuenta"])
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 6)
	cab.add_child(_avatar_de(("jugador:" + String(p.get("jugador_id", ""))) if cuenta == "jugador" else cuenta, 26))
	var autor := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, String(p["autor"]) + ("  ✔" if cuenta != "fan" else "") + ("  ⚽ tu plantel" if cuenta == "jugador" else ""))
	autor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	autor.clip_text = true
	cab.add_child(autor)
	cab.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "sem. %d" % int(p["semana"])))
	v.add_child(cab)
	if FOTOS.has(String(p["tipo"])):
		v.add_child(_foto(String(p["tipo"]), 170.0))
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.add_theme_font_size_override("normal_font_size", Tema.TAM_CUERPO)
	var tags := ""
	for h: Variant in p["hashtags"]:
		tags += " [color=#%s]%s[/color]" % [AZUL.to_html(false), String(h)]
	t.text = String(p["texto"]).replace("[", "(").replace("]", ")") + tags
	v.add_child(t)
	if bool(p.get("polemica", false)):
		v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Color("e5534b"), "🔥 Polémica: se está discutiendo mucho"))
	if int(p.get("ingreso", 0)) > 0:
		v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.BIEN, "🛒 Ventas por esta publicación: %s" % Cesiones.dinero(int(p["ingreso"]))))
	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 10)
	v.add_child(acciones)
	var id := int(p["id"])
	var like := Button.new()
	like.flat = true
	like.text = "%s %s" % ["❤️" if bool(p.get("me_gusta_tuyo", false)) else "🤍", cifra(int(p["likes"]))]
	like.pressed.connect(func() -> void:
		m.redes.me_gusta(id)
		var q := m.redes.buscar(id)
		like.text = "%s %s" % ["❤️" if bool(q.get("me_gusta_tuyo", false)) else "🤍", cifra(int(q["likes"]))]
		## El corazón late al tocarlo.
		like.pivot_offset = like.size * 0.5
		var tw := like.create_tween()
		tw.tween_property(like, "scale", Vector2(1.25, 1.25), 0.08)
		tw.tween_property(like, "scale", Vector2.ONE, 0.12))
	acciones.add_child(like)
	var cs: Array = p["comentarios"]
	var mia := cuenta == "dt" or bool(p.get("tuya", false))
	var sin_resp := 0
	for c: Dictionary in cs:
		if String(c.get("respuesta", "")) == "":
			sin_resp += 1
	var ver := Button.new()
	ver.flat = true
	ver.text = "💬 %d" % cs.size() + ((Idiomas.t("  · %d sin responder") % sin_resp) if mia and sin_resp > 0 else "")
	ver.pressed.connect(func() -> void:
		_abiertos[id] = not bool(_abiertos.get(id, false))
		(self as Telefono).abrir_app("tribuna"))
	acciones.add_child(ver)
	acciones.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "⟳ %s" % cifra(int(p["compartidos"]))))
	## A un jugador de tu plantel le puedes comentar (una vez).
	if cuenta == "jugador" and not bool(p.get("comentado", false)):
		var fila := HFlowContainer.new()
		v.add_child(fila)
		for tono: String in Redes.COMENTAR_JUGADOR:
			var d: Array = Redes.COMENTAR_JUGADOR[tono]
			var b := Button.new()
			b.text = "%s %s" % [String(d[0]), String(d[1])]
			b.add_theme_font_size_override("font_size", 11)
			var k := tono
			b.pressed.connect(func() -> void:
				var res := m.redes.comentar_jugador(m, id, k)
				(self as Telefono).abrir_app("tribuna")
				_decir(res))
			fila.add_child(b)
	if bool(_abiertos.get(id, false)):
		for i in cs.size():
			v.add_child(_comentario(p, i, mia))
	return pc

func _perfil(cuenta: String) -> void:
	var r := m.redes
	var cu: Dictionary = r.cuentas[cuenta]
	var pubs := r.de_cuenta(cuenta)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	_cuerpo.add_child(cab)
	cab.add_child(_avatar_de(cuenta, 64))
	var datos := VBoxContainer.new()
	cab.add_child(datos)
	datos.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, String(cu["nombre"]) + "  ✔"))
	datos.add_child(Tema.etiqueta(Tema.TAM_ROTULO, AZUL, String(cu["usuario"])))
	if cuenta == "club" and not r.acceso_club:
		datos.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "🔒 La lleva el community manager"))
	var cifras := HBoxContainer.new()
	cifras.add_theme_constant_override("separation", 18)
	_cuerpo.add_child(cifras)
	for par: Array in [[str(pubs.size()), "publicaciones"], [cifra(int(cu["seguidores"])), "seguidores"],
			[str(140 + int(cu["seguidores"]) % 97) if cuenta == "dt" else "12", "siguiendo"]]:
		var col := VBoxContainer.new()
		col.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, String(par[0])))
		col.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, String(par[1])))
		cifras.add_child(col)
	var rejilla := GridContainer.new()
	rejilla.columns = 3
	rejilla.add_theme_constant_override("h_separation", 3)
	rejilla.add_theme_constant_override("v_separation", 3)
	_cuerpo.add_child(rejilla)
	for p: Dictionary in pubs.slice(0, 9):
		var f := _foto(String(p["tipo"]), 104.0)
		f.custom_minimum_size = Vector2(104, 104)
		rejilla.add_child(f)
	if pubs.is_empty():
		_cuerpo.add_child(_nota("Sin publicaciones todavía."))
	for p: Dictionary in pubs.slice(0, 12):
		_cuerpo.add_child(_tarjeta(p))

func _publicar() -> void:
	var r := m.redes
	var como_club := r.sesion == "club"
	var tipos: Dictionary = Redes.TIPOS_CLUB if como_club else Redes.TIPOS
	if not tipos.has(_tipo_elegido):
		_tipo_elegido = String(tipos.keys()[0])
		_tags_elegidos = []
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, "Nueva publicación" + (" del club" if como_club else "")))
	if not como_club:
		var no := r.puede_publicar(m)
		if no != "":
			_cuerpo.add_child(_nota("⏳ " + no.substr(0, 1).to_upper() + no.substr(1) + "."))
			return
	var rej := GridContainer.new()
	rej.columns = 2
	_cuerpo.add_child(rej)
	for tipo: String in tipos:
		var d: Array = tipos[tipo]
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = tipo == _tipo_elegido
		b.text = "%s %s" % [String(d[0]), String(d[1])]
		b.custom_minimum_size = Vector2(170, 34)
		b.add_theme_font_size_override("font_size", 12)
		var k := tipo
		b.pressed.connect(func() -> void:
			_tipo_elegido = k
			_tags_elegidos = (tipos[k][3] as Array).duplicate()
			(self as Telefono).abrir_app("tribuna"))
		rej.add_child(b)
	if _tags_elegidos.is_empty():
		_tags_elegidos = (tipos[_tipo_elegido][3] as Array).duplicate()
	var d2: Array = tipos[_tipo_elegido]
	_cuerpo.add_child(_foto(_tipo_elegido, 150.0))
	var txt := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, String(d2[2]))
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cuerpo.add_child(txt)
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "HASHTAGS (la tendencia da más alcance)"))
	var tags := HFlowContainer.new()
	_cuerpo.add_child(tags)
	var posibles: Array = (d2[3] as Array).duplicate()
	for extra: String in [Redes.hashtag_club(m.mi_club()), r.tendencia]:
		if not extra in posibles:
			posibles.append(extra)
	for h: String in posibles:
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = h in _tags_elegidos
		b.text = h + (" 📈" if h == r.tendencia else "")
		b.add_theme_font_size_override("font_size", 11)
		var hh := h
		b.toggled.connect(func(si: bool) -> void:
			if si and not hh in _tags_elegidos:
				_tags_elegidos.append(hh)
			elif not si:
				_tags_elegidos.erase(hh))
		tags.add_child(b)
	var efecto := ""
	if como_club:
		efecto = "Efecto: ánimo de la grada %+d" % int(d2[4])
		if int(d2[5]) > 0:
			efecto += " · vende en la tienda"
	else:
		efecto = "Efecto: %s %+d" % [String(Reputacion.FACETAS.get(String(d2[4]), ["?"])[0]).to_lower(), int(d2[5])]
		if int(d2[6]) != 0:
			efecto += ", ánimo de la grada %+d" % int(d2[6])
		if float(d2[8]) > 0.0:
			efecto += " · ⚠️ puede hacerse polémica"
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, efecto))
	var pub := Button.new()
	pub.text = Idiomas.t("Publicar como ") + String(r.cuentas[r.sesion]["usuario"])
	pub.custom_minimum_size = Vector2(0, 40)
	pub.pressed.connect(func() -> void:
		var res := r.publicar(m, _tipo_elegido, _tags_elegidos)
		if res.has("error"):
			_decir(String(res["error"]))
			return
		_tags_elegidos = []
		_sub = "perfil" if not como_club else "club"
		(self as Telefono).abrir_app("tribuna")
		_decir("✔ Publicado: %s me gusta en el primer rato." % cifra(int(res["likes"]))))
	_cuerpo.add_child(pub)

# --- tribuna ------------------------------------------------------------------------

func _tribuna() -> void:
	var r := m.redes
	if r.sesion == "":
		_login()
		return
	## Cabecera: la cuenta con la sesión abierta y cambiar de cuenta.
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	var atras := Button.new()
	atras.flat = true
	atras.text = "‹"
	atras.add_theme_font_size_override("font_size", 22)
	atras.pressed.connect(func() -> void: (self as Telefono).abrir_app("inicio"))
	cab.add_child(atras)
	cab.add_child(_avatar_de(r.sesion, 30))
	var quien := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, String(r.cuentas[r.sesion]["usuario"]))
	quien.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quien.clip_text = true
	cab.add_child(quien)
	var cambiar := Button.new()
	cambiar.text = Idiomas.t("⇄ Cuenta")
	cambiar.add_theme_font_size_override("font_size", 11)
	cambiar.pressed.connect(_cerrar_sesion_animado)
	cab.add_child(cambiar)
	_cuerpo.add_child(cab)
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO, AZUL, "  Tendencia: %s" % r.tendencia))
	## Pestañas de la red.
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	for t: Array in [["inicio", "🏠"], ["perfil", "👤"], ["club", "🏟️"], ["publicar", "➕"]]:
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = _sub == String(t[0])
		b.text = String(t[1])
		b.custom_minimum_size = Vector2(70, 32)
		var k := String(t[0])
		b.pressed.connect(func() -> void:
			_sub = k
			(self as Telefono).abrir_app("tribuna"))
		tabs.add_child(b)
	_cuerpo.add_child(tabs)
	match _sub:
		"inicio":
			for p: Dictionary in r.publicaciones.slice(0, 25):
				_cuerpo.add_child(_tarjeta(p))
			if r.publicaciones.is_empty():
				_cuerpo.add_child(_nota("Todavía no hay nada. Publica algo desde ➕."))
		"perfil": _perfil(r.sesion)
		"club": _perfil("club")
		"publicar": _publicar()

## Un círculo de color con el emoji del contacto (su «foto»).
func _burbuja_icono(icono: String, lado: float) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(lado, lado)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := Tema.caja(Color(0.2, 0.24, 0.3), int(lado / 2.0), Color(0.2, 0.24, 0.3))
	sb.set_content_margin_all(0)
	p.add_theme_stylebox_override("panel", sb)
	var l := Tema.etiqueta(int(lado * 0.5), Tema.TEXTO, icono)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

func _un_chat() -> void:
	## Cabecera del chat: atrás, foto, nombre y «en línea».
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var atras := Button.new()
	atras.flat = true
	atras.text = "‹"
	atras.add_theme_font_size_override("font_size", 22)
	atras.pressed.connect(func() -> void:
		_chat = ""
		(self as Telefono).abrir_app("mensajes"))
	fila.add_child(atras)
	var icono := "💬"
	for ch: Dictionary in m.movil.chats():
		if String(ch["de"]) == _chat:
			icono = String(ch["icono"])
	fila.add_child(_burbuja_icono(icono, 34))
	var cab := VBoxContainer.new()
	cab.add_theme_constant_override("separation", 0)
	cab.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, _chat))
	cab.add_child(Tema.etiqueta(Tema.TAM_ROTULO - 2, Color("25d366"), "en línea"))
	fila.add_child(cab)
	_cuerpo.add_child(fila)
	var lista: Array = []
	for msj: Dictionary in m.movil.mensajes:
		if String(msj["de"]) == _chat:
			lista.push_front(msj)
			msj["leido"] = true
	var semana_previa := -1
	for msj: Dictionary in lista:
		## Separador de fecha cuando cambia la semana, centrado.
		if int(msj["semana"]) != semana_previa:
			semana_previa = int(msj["semana"])
			var fecha := Tema.etiqueta(Tema.TAM_ROTULO - 2, Tema.SUAVE, "Semana %d · %d" % [int(msj["semana"]), int(msj["anio"])])
			fecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_cuerpo.add_child(fecha)
		var envoltura := HBoxContainer.new()
		var burbuja := PanelContainer.new()
		var sb := Tema.caja(Color(0.15, 0.2, 0.24), 14, Color(0.15, 0.2, 0.24))
		sb.corner_radius_top_left = 3
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 6
		sb.content_margin_bottom = 4
		burbuja.add_theme_stylebox_override("panel", sb)
		burbuja.custom_minimum_size = Vector2(0, 0)
		burbuja.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		burbuja.add_child(v)
		var l := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, String(msj["texto"]))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(minf(260.0, 9.0 * String(msj["texto"]).length()), 0)
		v.add_child(l)
		var hora := Tema.etiqueta(Tema.TAM_ROTULO - 3, Tema.SUAVE, _hora())
		hora.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.add_child(hora)
		envoltura.add_child(burbuja)
		_cuerpo.add_child(envoltura)

func _titulo_app(texto: String) -> void:
	var fila := HBoxContainer.new()
	var atras := Button.new()
	atras.flat = true
	atras.text = "‹"
	atras.add_theme_font_size_override("font_size", 22)
	atras.pressed.connect(func() -> void: (self as Telefono).abrir_app("inicio"))
	fila.add_child(atras)
	fila.add_child(Tema.etiqueta(Tema.TAM_DESTACADO + 2, Tema.TEXTO, texto))
	_cuerpo.add_child(fila)

# --- mensajes, noticias, banco, calendario, fotos --------------------------------------

func _mensajes() -> void:
	if _chat != "":
		_un_chat()
		return
	## COMO UNA APP DE MENSAJERÍA (13-10-2026): fila con foto redonda, nombre,
	## último mensaje en gris y el contador verde de no leídos.
	_titulo_app("Mensajes")
	var chats := m.movil.chats()
	if chats.is_empty():
		_cuerpo.add_child(_nota("No tienes mensajes."))
	for ch: Dictionary in chats:
		var b := Button.new()
		b.flat = true
		b.custom_minimum_size = Vector2(0, 60)
		var fila := HBoxContainer.new()
		fila.set_anchors_preset(Control.PRESET_FULL_RECT)
		fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_theme_constant_override("separation", 10)
		b.add_child(fila)
		fila.add_child(_burbuja_icono(String(ch["icono"]), 42))
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(col)
		var nom := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, String(ch["de"]))
		col.add_child(nom)
		var ult := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, String(ch["ultimo"]))
		ult.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		ult.custom_minimum_size = Vector2(10, 0)
		col.add_child(ult)
		var n := int(ch["sin_leer"])
		if n > 0:
			var badge := PanelContainer.new()
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var sb := Tema.caja(Color("25d366"), 10, Color("25d366"))
			sb.content_margin_left = 7
			sb.content_margin_right = 7
			badge.add_theme_stylebox_override("panel", sb)
			badge.add_child(Tema.etiqueta(Tema.TAM_ROTULO - 2, Color(0.05, 0.1, 0.06), str(n)))
			fila.add_child(badge)
		var de := String(ch["de"])
		b.pressed.connect(func() -> void:
			_chat = de
			(self as Telefono).abrir_app("mensajes"))
		_cuerpo.add_child(b)
		var linea := ColorRect.new()
		linea.color = Color(1, 1, 1, 0.06)
		linea.custom_minimum_size = Vector2(0, 1)
		_cuerpo.add_child(linea)

## Tarjeta del estilo informe: fondo de app y filo dorado a la izquierda.
func _caja_informe(destacada := false) -> StyleBoxFlat:
	var sb := Tema.caja(TARJETA.lightened(0.04) if destacada else TARJETA, 12, TARJETA)
	sb.set_border_width_all(0)
	sb.border_width_left = 3
	sb.border_color = Tema.ORO if destacada else Color(1, 1, 1, 0.18)
	sb.set_content_margin_all(10)
	return sb

func _noticias() -> void:
	_titulo_app("Noticias")
	if bandeja.is_empty():
		_cuerpo.add_child(_nota("Sin noticias por ahora."))
	## Medio informe (13-10-2026): titular en negrita con filo dorado a la
	## izquierda, la primera noticia destacada como portada.
	var primera := true
	for n: Dictionary in bandeja.slice(0, 20):
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", _caja_informe(primera))
		var v := VBoxContainer.new()
		pc.add_child(v)
		if primera:
			v.add_child(Tema.etiqueta(Tema.TAM_ROTULO - 2, Tema.ORO, "PORTADA"))
		var t := Tema.etiqueta(Tema.TAM_DESTACADO if primera else Tema.TAM_CUERPO, Tema.TEXTO, String(n.get("titulo", "")))
		primera = false
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(t)
		var c := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, String(n.get("cuerpo", "")))
		c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(c)
		_cuerpo.add_child(pc)
