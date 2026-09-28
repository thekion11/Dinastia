class_name Telefono
extends PanelContainer
## EL MÓVIL, INTERACTIVO (28-9-2026). La app de redes TRIBUNA (inventada)
## dentro de un marco de teléfono: la hora y la batería arriba, las pestañas
## abajo como en cualquier app.
##   🏠 Inicio      todo lo que se publica: tu cuenta, la del club, los hinchas;
##   👤 Tu perfil   tu cuenta: seguidores, publicaciones y la rejilla de fotos;
##   🏟️ Club        la cuenta oficial del club;
##   ➕ Publicar    eliges qué subir (foto del entrenamiento, mensaje a la
##                  hinchada...) y sus hashtags, y lo publicas.
## En cada publicación: dar "me gusta", ver los comentarios y, en las tuyas,
## responderlos. Todo pasa por `Redes` (núcleo), que es quien aplica los
## efectos en tu reputación y en la grada.

const ANCHO := 380.0
const FONDO := Color(0.06, 0.065, 0.08)
const TARJETA := Color(0.1, 0.11, 0.135)
const AZUL := Color(0.35, 0.62, 0.95)

## [emoji, color de arriba, color de abajo] de la "foto" de cada tipo.
const FOTOS := {
	"entreno": ["📸", "3f8f4a", "1d4a26"],
	"hinchada": ["🙌", "club", "club2"],
	"victoria": ["🥳", "e0b53a", "8a5a12"],
	"familia": ["👨‍👩‍👧", "e59a6a", "7a3f2a"],
	"cantera": ["🌱", "6fbf5a", "2a5a22"],
	"indirecta": ["🌶️", "d8452f", "5a1a12"],
	"partido": ["⚽", "club", "club2"],
	"club": ["🏟️", "club", "club2"],
}

var m: Mundo
var _pestana := "inicio"
var _cuerpo: VBoxContainer
var _scroll: ScrollContainer
var _aviso: Label
var _tipo_elegido := "entreno"
var _tags_elegidos: Array = []
var _abiertos := {}   ## publicaciones con los comentarios desplegados

static func crear(mundo: Mundo) -> Telefono:
	var t := Telefono.new()
	t.m = mundo
	t._montar()
	return t

func _montar() -> void:
	custom_minimum_size = Vector2(ANCHO, 0)
	add_theme_stylebox_override("panel", Tema.caja(Color(0.02, 0.02, 0.025), 34, Color(0.28, 0.29, 0.32)))
	var marco := MarginContainer.new()
	for k in ["left", "right", "top", "bottom"]:
		marco.add_theme_constant_override("margin_" + k, 10)
	add_child(marco)
	var pantalla := PanelContainer.new()
	pantalla.add_theme_stylebox_override("panel", Tema.caja(FONDO, 26, FONDO))
	marco.add_child(pantalla)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	pantalla.add_child(v)
	## La barra de estado del teléfono.
	var estado := HBoxContainer.new()
	var hora := Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, "  %02d:%02d" % [18 + (m.semana % 4), (m.semana * 7) % 60])
	hora.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	estado.add_child(hora)
	estado.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, "▂▄▆ 5G  🔋 82%  "))
	v.add_child(estado)
	## La cabecera de la app.
	var cab := HBoxContainer.new()
	var logo := Tema.etiqueta(Tema.TAM_DESTACADO + 2, Tema.TEXTO, "  Tribuna")
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(logo)
	cab.add_child(Tema.etiqueta(Tema.TAM_ROTULO, AZUL, "Tendencia: %s  " % m.redes.tendencia))
	v.add_child(cab)
	_aviso = Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, "")
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.visible = false
	v.add_child(_aviso)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_scroll)
	_cuerpo = VBoxContainer.new()
	_cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cuerpo.add_theme_constant_override("separation", 8)
	_scroll.add_child(_cuerpo)
	## Las pestañas de abajo.
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 4)
	v.add_child(nav)
	var pend := m.redes.pendientes()
	for p: Array in [["inicio", "🏠"], ["perfil", "👤" + (" %d" % pend if pend > 0 else "")], ["club", "🏟️"], ["publicar", "➕"]]:
		var b := Button.new()
		b.text = String(p[1])
		b.flat = true
		b.custom_minimum_size = Vector2(80, 40)
		b.add_theme_font_size_override("font_size", 18)
		var clave := String(p[0])
		b.pressed.connect(func() -> void: ir(clave))
		nav.add_child(b)
	ir(_pestana)

func ir(pestana: String) -> void:
	_pestana = pestana
	for h in _cuerpo.get_children():
		h.queue_free()
	match pestana:
		"inicio":
			for p: Dictionary in m.redes.publicaciones.slice(0, 25):
				_cuerpo.add_child(_tarjeta(p))
			if m.redes.publicaciones.is_empty():
				_cuerpo.add_child(_nota("Todavía no hay nada. Publica algo desde ➕."))
		"perfil":
			_perfil("dt")
		"club":
			_perfil("club")
		"publicar":
			_publicar()
	_scroll.scroll_vertical = 0

func _decir(texto: String) -> void:
	_aviso.text = "  " + texto
	_aviso.visible = texto != ""

func _nota(texto: String) -> Label:
	var l := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, texto)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func cifra(n: int) -> String:
	if n >= 1000000:
		return "%.1f M" % (float(n) / 1000000.0)
	if n >= 10000:
		return "%d mil" % int(n / 1000)
	if n >= 1000:
		return "%.1f mil" % (float(n) / 1000.0)
	return str(n)

# --- perfil ---------------------------------------------------------------------

func _perfil(cuenta: String) -> void:
	var cu: Dictionary = m.redes.cuentas[cuenta]
	var pubs := m.redes.de_cuenta(cuenta)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	_cuerpo.add_child(cab)
	var avatar := Tema.etiqueta(40, Tema.TEXTO, "🧑‍💼" if cuenta == "dt" else "🏟️")
	cab.add_child(avatar)
	var datos := VBoxContainer.new()
	cab.add_child(datos)
	datos.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, String(cu["nombre"]) + "  ✔"))
	datos.add_child(Tema.etiqueta(Tema.TAM_ROTULO, AZUL, String(cu["usuario"])))
	var cifras := HBoxContainer.new()
	cifras.add_theme_constant_override("separation", 18)
	_cuerpo.add_child(cifras)
	for par: Array in [[str(pubs.size()), "publicaciones"], [cifra(int(cu["seguidores"])), "seguidores"],
			[str(140 + int(cu["seguidores"]) % 97) if cuenta == "dt" else "12", "siguiendo"]]:
		var col := VBoxContainer.new()
		col.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, String(par[0])))
		col.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, String(par[1])))
		cifras.add_child(col)
	## La rejilla de fotos, como en cualquier perfil.
	var rejilla := GridContainer.new()
	rejilla.columns = 3
	rejilla.add_theme_constant_override("h_separation", 3)
	rejilla.add_theme_constant_override("v_separation", 3)
	_cuerpo.add_child(rejilla)
	for p: Dictionary in pubs.slice(0, 9):
		var f := _foto(String(p["tipo"]), 104.0, false)
		f.custom_minimum_size = Vector2(104, 104)
		rejilla.add_child(f)
	if pubs.is_empty():
		_cuerpo.add_child(_nota("Sin publicaciones todavía." if cuenta == "dt" else "El club aún no publicó nada."))
	for p: Dictionary in pubs.slice(0, 12):
		_cuerpo.add_child(_tarjeta(p))

# --- una publicación ----------------------------------------------------------------

func _color_de(clave: String) -> Color:
	var c := m.mi_club()
	if clave == "club":
		return Color(c.color1) if c != null else Color("1f5fa8")
	if clave == "club2":
		return Color(c.color2).darkened(0.3) if c != null else Color("0e2f5a")
	return Color(clave)

func _foto(tipo: String, alto: float, con_emoji_grande: bool = true) -> Control:
	var d: Array = FOTOS.get(tipo, ["💬", "3a3f4a", "1a1d24"])
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(0, alto)
	caja.clip_contents = true
	var tr := TextureRect.new()
	var g := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, _color_de(String(d[1])))
	gr.set_color(1, _color_de(String(d[2])))
	g.gradient = gr
	g.fill_from = Vector2(0, 0)
	g.fill_to = Vector2(0.4, 1)
	tr.texture = g
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(tr)
	var e := Tema.etiqueta(int(alto * (0.42 if con_emoji_grande else 0.45)), Tema.TEXTO, String(d[0]))
	e.set_anchors_preset(Control.PRESET_FULL_RECT)
	e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caja.add_child(e)
	return caja

func _tarjeta(p: Dictionary) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", Tema.caja(TARJETA, 14, TARJETA))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	var cuenta := String(p["cuenta"])
	var cab := HBoxContainer.new()
	cab.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, "🧑‍💼" if cuenta == "dt" else ("🏟️" if cuenta == "club" else "🙂")))
	var autor := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, String(p["autor"]) + ("  ✔" if cuenta != "fan" else ""))
	autor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(autor)
	cab.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "sem. %d" % int(p["semana"])))
	v.add_child(cab)
	if FOTOS.has(String(p["tipo"])):
		v.add_child(_foto(String(p["tipo"]), 170.0))
	## El texto con los hashtags en azul.
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
	## Me gusta, comentarios y compartidos.
	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 10)
	v.add_child(acciones)
	var id := int(p["id"])
	var like := Button.new()
	like.flat = true
	like.text = "%s %s" % ["❤️" if bool(p.get("me_gusta_tuyo", false)) else "🤍", cifra(int(p["likes"]))]
	like.pressed.connect(func() -> void:
		m.redes.me_gusta(id)
		like.text = "%s %s" % ["❤️" if bool(m.redes.buscar(id).get("me_gusta_tuyo", false)) else "🤍", cifra(int(m.redes.buscar(id)["likes"]))])
	acciones.add_child(like)
	var cs: Array = p["comentarios"]
	var sin_resp := 0
	for c: Dictionary in cs:
		if String(c.get("respuesta", "")) == "":
			sin_resp += 1
	var ver := Button.new()
	ver.flat = true
	ver.text = "💬 %d" % cs.size() + (("  · %d sin responder" % sin_resp) if cuenta == "dt" and sin_resp > 0 else "")
	ver.pressed.connect(func() -> void:
		_abiertos[id] = not bool(_abiertos.get(id, false))
		ir(_pestana))
	acciones.add_child(ver)
	acciones.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "⟳ %s" % cifra(int(p["compartidos"]))))
	if bool(_abiertos.get(id, false)):
		for i in cs.size():
			v.add_child(_comentario(p, i))
	return pc

func _comentario(p: Dictionary, i: int) -> Control:
	var c: Dictionary = p["comentarios"][i]
	var v := VBoxContainer.new()
	var col := Tema.BIEN if String(c["tono"]) == "bien" else (Color("e5534b") if String(c["tono"]) == "mal" else Tema.SUAVE)
	var l := Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, "%s  %s" % [String(c["autor"]), String(c["texto"])])
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", col.lerp(Tema.TEXTO, 0.5))
	v.add_child(l)
	var resp := String(c.get("respuesta", ""))
	if resp != "":
		var r := Tema.etiqueta(Tema.TAM_ROTULO, AZUL, "   ↳ %s  %s  (♥ %d)" % [String(m.redes.cuentas["dt"]["usuario"]), resp, int(c.get("respuesta_likes", 0))])
		r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(r)
	elif String(p["cuenta"]) == "dt":
		## Responder: cuatro tonos.
		var fila := HFlowContainer.new()
		v.add_child(fila)
		var id := int(p["id"])
		for tono: String in Redes.RESPUESTAS:
			var d: Array = Redes.RESPUESTAS[tono]
			var b := Button.new()
			b.text = "%s %s" % [String(d[0]), String(d[1])]
			b.add_theme_font_size_override("font_size", 11)
			var k := tono
			b.pressed.connect(func() -> void:
				_decir(m.redes.responder(m, id, i, k))
				ir(_pestana))
			fila.add_child(b)
	return v

# --- publicar -------------------------------------------------------------------------

func _publicar() -> void:
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, "Nueva publicación"))
	var no := m.redes.puede_publicar(m)
	if no != "":
		_cuerpo.add_child(_nota("⏳ " + no.substr(0, 1).to_upper() + no.substr(1) + "."))
		return
	var rej := GridContainer.new()
	rej.columns = 2
	_cuerpo.add_child(rej)
	for tipo: String in Redes.TIPOS:
		var d: Array = Redes.TIPOS[tipo]
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = tipo == _tipo_elegido
		b.text = "%s %s" % [String(d[0]), String(d[1])]
		b.custom_minimum_size = Vector2(170, 34)
		b.add_theme_font_size_override("font_size", 12)
		var k := tipo
		b.pressed.connect(func() -> void:
			_tipo_elegido = k
			_tags_elegidos = (Redes.TIPOS[k][3] as Array).duplicate()
			ir("publicar"))
		rej.add_child(b)
	if _tags_elegidos.is_empty():
		_tags_elegidos = (Redes.TIPOS[_tipo_elegido][3] as Array).duplicate()
	var d2: Array = Redes.TIPOS[_tipo_elegido]
	## La vista previa: la foto y el texto.
	_cuerpo.add_child(_foto(_tipo_elegido, 150.0))
	var txt := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, String(d2[2]))
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cuerpo.add_child(txt)
	## Los hashtags: los sugeridos, el del club y el que es tendencia.
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "HASHTAGS (la tendencia da más alcance)"))
	var tags := HFlowContainer.new()
	_cuerpo.add_child(tags)
	var posibles: Array = (d2[3] as Array).duplicate()
	for extra: String in [Redes.hashtag_club(m.mi_club()), m.redes.tendencia]:
		if not extra in posibles:
			posibles.append(extra)
	for h: String in posibles:
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = h in _tags_elegidos
		b.text = h + (" 📈" if h == m.redes.tendencia else "")
		b.add_theme_font_size_override("font_size", 11)
		var hh := h
		b.toggled.connect(func(si: bool) -> void:
			if si and not hh in _tags_elegidos:
				_tags_elegidos.append(hh)
			elif not si:
				_tags_elegidos.erase(hh))
		tags.add_child(b)
	var efecto := "Efecto: %s %+d" % [String(Reputacion.FACETAS.get(String(d2[4]), ["?"])[0]).to_lower(), int(d2[5])]
	if int(d2[6]) != 0:
		efecto += ", ánimo de la grada %+d" % int(d2[6])
	if float(d2[8]) > 0.0:
		efecto += " · ⚠️ puede hacerse polémica"
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, efecto))
	var pub := Button.new()
	pub.text = "Publicar"
	pub.custom_minimum_size = Vector2(0, 40)
	pub.pressed.connect(func() -> void:
		var r := m.redes.publicar(m, _tipo_elegido, _tags_elegidos)
		if r.has("error"):
			_decir(String(r["error"]))
			return
		_decir("✔ Publicado: %s me gusta en el primer rato." % cifra(int(r["likes"])))
		_tags_elegidos = []
		ir("perfil"))
	_cuerpo.add_child(pub)

## Abre el móvil a pantalla completa (desde MI VIDA o el despacho).
static func abrir(p: Control, mundo: Mundo) -> Control:
	var pop := Control.new()
	pop.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.mouse_filter = Control.MOUSE_FILTER_STOP
	p.add_child(pop)
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.75)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.add_child(centro)
	var tel := Telefono.crear(mundo)
	## A la altura de la pantalla VISIBLE (la interfaz va escalada: 780 px
	## "de diseño" se salían por abajo y tapaban las pestañas).
	var alto := p.get_viewport_rect().size.y
	tel.custom_minimum_size = Vector2(ANCHO, clampf(alto - 40.0, 420.0, 780.0))
	centro.add_child(tel)
	var cerrar := Button.new()
	cerrar.text = "✕ Guardar el móvil"
	cerrar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	cerrar.offset_left = -200
	cerrar.offset_right = -30
	cerrar.offset_top = 24
	cerrar.offset_bottom = 60
	cerrar.pressed.connect(func() -> void:
		pop.queue_free()
		if p.has_method("_refrescar"):
			p.call("_refrescar"))
	pop.add_child(cerrar)
	return pop
