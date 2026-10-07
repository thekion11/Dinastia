class_name Telefono
extends PanelContainer
## TU MÓVIL, COMO UN MÓVIL (28-9-2026). Pantalla de inicio con tu fondo, la
## hora y las apps; la barra de abajo vuelve al inicio desde cualquier app.
##   📣 Tribuna     la red social: tu cuenta y, cuando te la den, la del club
##                  (cerrar sesión y entrar con usuario y clave);
##   💬 Mensajes    chats de la directiva, la familia, el community manager...;
##   📰 Noticias    lo último que pasó;
##   🏦 Banco       la caja del club y tu patrimonio;
##   📅 Calendario  el próximo partido y cómo va la tabla;
##   🖼️ Fotos       las fotos de lo que publicaste;
##   ⚙️ Ajustes     fondo, funda, tamaño de letra y foto de perfil (tu retrato
##                  o una imagen de tu galería).
## La lógica vive en el núcleo (`Redes`, `Movil`); aquí solo se dibuja.

signal estetica_cambiada   ## fondo, funda o foto: la escena 3D recolorea su móvil

const ANCHO := 380.0
const FONDO_APP := Color(0.06, 0.065, 0.08)
const TARJETA := Color(0.1, 0.11, 0.135)
const AZUL := Color(0.35, 0.62, 0.95)
## [clave, nombre, icono, color del icono]
const APPS := [
	["tribuna", "Tribuna", "📣", "3a6df0"], ["mensajes", "Mensajes", "💬", "27ae60"],
	["noticias", "Noticias", "📰", "e67e22"], ["banco", "Banco", "🏦", "16a085"],
	["calendario", "Calendario", "📅", "e74c3c"], ["fotos", "Fotos", "🖼️", "d4a92a"],
	["ajustes", "Ajustes", "⚙️", "6c7a89"],
]
## [emoji, color de arriba, color de abajo] de la "foto" de cada tipo.
const FOTOS := {
	"entreno": ["📸", "3f8f4a", "1d4a26"], "hinchada": ["🙌", "club", "club2"],
	"victoria": ["🥳", "e0b53a", "8a5a12"], "familia": ["👨‍👩‍👧", "e59a6a", "7a3f2a"],
	"cantera": ["🌱", "6fbf5a", "2a5a22"], "indirecta": ["🌶️", "d8452f", "5a1a12"],
	"partido": ["⚽", "club", "club2"], "club": ["🏟️", "club", "club2"],
	"previa": ["📣", "club", "club2"], "camiseta": ["👕", "club", "club2"],
	"socios": ["🎟️", "e0b53a", "club2"], "historia": ["🏆", "e0b53a", "5a3a0a"], "gracias": ["💙", "club", "club2"],
}
const CIRCULO := "shader_type canvas_item;\nvoid fragment(){ vec4 c = texture(TEXTURE, UV); float d = distance(UV, vec2(0.5)); COLOR = vec4(c.rgb, c.a * smoothstep(0.5, 0.47, d)); }"

var m: Mundo
var bandeja: Array = []
var _app := "inicio"
var _sub := "inicio"          ## pestaña dentro de Tribuna
var _marco: StyleBoxFlat
var _papel: TextureRect        ## el fondo de pantalla
var _cuerpo: VBoxContainer
var _scroll: ScrollContainer
var _aviso: Label
var _tipo_elegido := ""
var _tags_elegidos: Array = []
var _abiertos := {}
var _chat := ""
static var _sombra_circulo: Shader

static func crear(mundo: Mundo, noticias: Array = []) -> Telefono:
	var t := Telefono.new()
	t.m = mundo
	t.bandeja = noticias
	t._montar()
	return t

# --- el aparato -----------------------------------------------------------------

func _montar() -> void:
	custom_minimum_size = Vector2(ANCHO, 0)
	_marco = Tema.caja(m.movil.color_funda(m.mi_club()), 34, m.movil.color_funda(m.mi_club()).lightened(0.2))
	add_theme_stylebox_override("panel", _marco)
	var borde := MarginContainer.new()
	for k in ["left", "right", "top", "bottom"]:
		borde.add_theme_constant_override("margin_" + k, 10)
	add_child(borde)
	var pantalla := PanelContainer.new()
	var sb := Tema.caja(FONDO_APP, 26, Color(0, 0, 0))
	sb.set_content_margin_all(0)
	pantalla.add_theme_stylebox_override("panel", sb)
	pantalla.clip_contents = true
	borde.add_child(pantalla)
	_papel = TextureRect.new()
	_papel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_papel.stretch_mode = TextureRect.STRETCH_SCALE
	_papel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pantalla.add_child(_papel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	pantalla.add_child(v)
	## Barra de estado.
	var estado := HBoxContainer.new()
	var hora := Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, "   " + _hora())
	hora.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	estado.add_child(hora)
	estado.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, "▂▄▆ 5G  🔋 82%   "))
	v.add_child(estado)
	_aviso = Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, "")
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.visible = false
	v.add_child(_aviso)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_scroll)
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for k in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + k, 8)
	_scroll.add_child(margen)
	_cuerpo = VBoxContainer.new()
	_cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cuerpo.add_theme_constant_override("separation", 8)
	margen.add_child(_cuerpo)
	## La barra de inicio.
	var barra := Button.new()
	barra.flat = true
	barra.text = "━━━━"
	barra.custom_minimum_size = Vector2(0, 30)
	barra.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	barra.pressed.connect(func() -> void: abrir_app("inicio"))
	v.add_child(barra)
	_pintar_papel()
	abrir_app("inicio")

func _hora() -> String:
	return "%02d:%02d" % [18 + (m.semana % 4), (m.semana * 7) % 60]

func _pintar_papel() -> void:
	var d: Array = Movil.FONDOS.get(m.movil.fondo, Movil.FONDOS["noche"])
	var g := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Movil.color(String(d[1]), m.mi_club()))
	gr.set_color(1, Movil.color(String(d[2]), m.mi_club()))
	g.gradient = gr
	g.fill_from = Vector2(0, 0)
	g.fill_to = Vector2(0.3, 1)
	_papel.texture = g
	var col := m.movil.color_funda(m.mi_club())
	_marco.bg_color = col
	_marco.border_color = col.lightened(0.2)

func abrir_app(app: String) -> void:
	_app = app
	_decir("")
	for h in _cuerpo.get_children():
		h.queue_free()
	## En las apps el fondo de pantalla se oscurece, como detrás de una app.
	_papel.modulate = Color(1, 1, 1, 1.0 if app == "inicio" else 0.18)
	match app:
		"inicio": _inicio()
		"tribuna": _tribuna()
		"mensajes": _mensajes()
		"noticias": _noticias()
		"banco": _banco()
		"calendario": _calendario()
		"fotos": _fotos()
		"ajustes": _ajustes()
	_escalar_letra.call_deferred()
	_scroll.scroll_vertical = 0

## El tamaño de letra elegido en Ajustes, aplicado a todo lo que se pintó.
func _escalar_letra() -> void:
	var f := m.movil.factor_letra()
	if is_equal_approx(f, 1.0):
		return
	for n in _cuerpo.find_children("*", "Control", true, false):
		if n is Label or n is Button or n is LineEdit:
			var c := n as Control
			c.add_theme_font_size_override("font_size", int(round(c.get_theme_font_size("font_size") * f)))
		elif n is RichTextLabel:
			var r := n as RichTextLabel
			r.add_theme_font_size_override("normal_font_size", int(round(r.get_theme_font_size("normal_font_size") * f)))

func _decir(texto: String) -> void:
	_aviso.text = "  " + texto
	_aviso.visible = texto != ""

func _nota(texto: String) -> Label:
	var l := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, texto)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _titulo_app(texto: String) -> void:
	var fila := HBoxContainer.new()
	var atras := Button.new()
	atras.flat = true
	atras.text = "‹"
	atras.add_theme_font_size_override("font_size", 22)
	atras.pressed.connect(func() -> void: abrir_app("inicio"))
	fila.add_child(atras)
	fila.add_child(Tema.etiqueta(Tema.TAM_DESTACADO + 2, Tema.TEXTO, texto))
	_cuerpo.add_child(fila)

static func cifra(n: int) -> String:
	if n >= 1000000:
		return "%.1f M" % (float(n) / 1000000.0)
	if n >= 10000:
		return "%d mil" % int(n / 1000)
	if n >= 1000:
		return "%.1f mil" % (float(n) / 1000.0)
	return str(n)

## Una foto redonda (perfil).
func _avatar(tex: Texture2D, lado: float, respaldo: String) -> Control:
	if tex == null:
		return Tema.etiqueta(int(lado * 0.8), Tema.TEXTO, respaldo)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(lado, lado)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if _sombra_circulo == null:
		_sombra_circulo = Shader.new()
		_sombra_circulo.code = CIRCULO
	var sm := ShaderMaterial.new()
	sm.shader = _sombra_circulo
	tr.material = sm
	return tr

func _avatar_de(cuenta: String, lado: float) -> Control:
	if cuenta == "dt":
		return _avatar(m.movil.textura_perfil(m), lado, "🧑‍💼")
	if cuenta == "club" and m.mi_club() != null:
		return _avatar(Escudo.textura(m.mi_club(), int(lado * 2)), lado, "🏟️")
	if cuenta.begins_with("jugador:"):
		var j := m.jugador_por_id(cuenta.trim_prefix("jugador:"))
		var c := m.mi_club()
		if j != null:
			return _avatar(Cara.textura(j, c.color1 if c != null else "#2b6b45", c.color2 if c != null else "#ffffff", int(lado * 2)), lado, "⚽")
	return Tema.etiqueta(int(lado * 0.7), Tema.TEXTO, "🙂")

# --- inicio -----------------------------------------------------------------------

func _inicio() -> void:
	_cuerpo.add_child(Control.new())
	var reloj := Tema.etiqueta(64, Tema.TEXTO, _hora())
	reloj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cuerpo.add_child(reloj)
	var fecha := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "Semana %d · %d" % [m.semana, m.anio])
	fecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cuerpo.add_child(fecha)
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(0, 30)
	_cuerpo.add_child(hueco)
	var rej := GridContainer.new()
	rej.columns = 4
	rej.add_theme_constant_override("h_separation", 10)
	rej.add_theme_constant_override("v_separation", 14)
	var centro := CenterContainer.new()
	centro.add_child(rej)
	_cuerpo.add_child(centro)
	for a: Array in APPS:
		rej.add_child(_icono_app(a))

func _insignia(app: String) -> int:
	match app:
		"tribuna": return m.redes.pendientes()
		"mensajes": return m.movil.sin_leer()
	return 0

func _icono_app(a: Array) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	var b := Button.new()
	b.custom_minimum_size = Vector2(62, 62)
	b.text = String(a[2])
	b.add_theme_font_size_override("font_size", 28)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(String(a[3]))
	sb.set_corner_radius_all(16)
	b.add_theme_stylebox_override("normal", sb)
	var sb2 := sb.duplicate() as StyleBoxFlat
	sb2.bg_color = sb.bg_color.lightened(0.15)
	b.add_theme_stylebox_override("hover", sb2)
	b.add_theme_stylebox_override("pressed", sb2)
	var clave := String(a[0])
	b.pressed.connect(func() -> void: abrir_app(clave))
	col.add_child(b)
	var n := _insignia(clave)
	if n > 0:
		var ins := Tema.etiqueta(Tema.TAM_ROTULO, Color.WHITE, " %d " % n)
		var sbi := StyleBoxFlat.new()
		sbi.bg_color = Color("e5534b")
		sbi.set_corner_radius_all(9)
		ins.add_theme_stylebox_override("normal", sbi)
		ins.position = Vector2(46, -4)
		b.add_child(ins)
	var nom := Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, String(a[1]))
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(nom)
	return col

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
	atras.pressed.connect(func() -> void: abrir_app("inicio"))
	cab.add_child(atras)
	cab.add_child(_avatar_de(r.sesion, 30))
	var quien := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, String(r.cuentas[r.sesion]["usuario"]))
	quien.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quien.clip_text = true
	cab.add_child(quien)
	var cambiar := Button.new()
	cambiar.text = "⇄ Cuenta"
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
			abrir_app("tribuna"))
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

## CERRAR SESIÓN: un rato con "Cerrando sesión…" y a la pantalla de entrar.
func _cerrar_sesion_animado() -> void:
	for h in _cuerpo.get_children():
		h.queue_free()
	_cuerpo.add_child(_espera("Cerrando sesión de %s…" % String(m.redes.cuentas[m.redes.sesion]["usuario"])))
	m.redes.cerrar_sesion()
	get_tree().create_timer(0.9).timeout.connect(func() -> void:
		if is_instance_valid(self) and _app == "tribuna":
			abrir_app("tribuna"))

func _espera(texto: String) -> Control:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.custom_minimum_size = Vector2(0, 360)
	var giro := Tema.etiqueta(40, AZUL, "◌")
	giro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(giro)
	var tw := giro.create_tween().set_loops()
	tw.tween_property(giro, "modulate:a", 0.3, 0.3)
	tw.tween_property(giro, "modulate:a", 1.0, 0.3)
	v.add_child(_nota(texto))
	return v

## ENTRAR: usuario y clave. Tu cuenta personal recuerda la clave; la del club
## pide la que te llegó por Mensajes (o "Usar la clave guardada", que la
## escribe letra a letra).
func _login() -> void:
	var r := m.redes
	var logo := Tema.etiqueta(34, Tema.TEXTO, "Tribuna")
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cuerpo.add_child(logo)
	_cuerpo.add_child(_nota("Inicia sesión"))
	var usuario := LineEdit.new()
	usuario.placeholder_text = "Usuario (@...)"
	usuario.name = "Usuario"
	_cuerpo.add_child(usuario)
	var clave := LineEdit.new()
	clave.placeholder_text = "Clave"
	clave.secret = true
	clave.name = "Clave"
	_cuerpo.add_child(clave)
	var entrar := Button.new()
	entrar.text = "Entrar"
	entrar.custom_minimum_size = Vector2(0, 40)
	entrar.pressed.connect(func() -> void: _entrar(usuario.text, clave.text))
	_cuerpo.add_child(entrar)
	clave.text_submitted.connect(func(_t: String) -> void: _entrar(usuario.text, clave.text))
	_cuerpo.add_child(HSeparator.new())
	_cuerpo.add_child(_nota("Cuentas guardadas en este móvil"))
	## Tu cuenta: un toque (la clave está recordada).
	var yo := Button.new()
	yo.text = "%s  (tu cuenta)" % String(r.cuentas["dt"]["usuario"])
	yo.pressed.connect(func() -> void:
		_escribir_animado(usuario, String(r.cuentas["dt"]["usuario"]), func() -> void:
			_escribir_animado(clave, "••••••••", func() -> void: _entrar(usuario.text, "", true))))
	_cuerpo.add_child(yo)
	var del_club := Button.new()
	del_club.text = "%s  %s" % [String(r.cuentas["club"]["usuario"]), "(la clave está en Mensajes)" if r.acceso_club else "🔒 no es tuya"]
	del_club.disabled = not r.acceso_club
	del_club.pressed.connect(func() -> void:
		_escribir_animado(usuario, String(r.cuentas["club"]["usuario"]), func() -> void: clave.grab_focus()))
	_cuerpo.add_child(del_club)
	if r.acceso_club:
		var usar := Button.new()
		usar.text = "🔑 Usar la clave guardada"
		usar.pressed.connect(func() -> void: entrar_con_clave_guardada())
		_cuerpo.add_child(usar)
	else:
		_cuerpo.add_child(_nota("La cuenta del club la lleva el community manager. Llevas poco en el club: dale unas semanas."))

## Escribe usuario y clave del club letra a letra y entra (lo usa también la
## captura de prueba).
func entrar_con_clave_guardada() -> void:
	var r := m.redes
	var usuario := _cuerpo.find_child("Usuario", true, false) as LineEdit
	var clave := _cuerpo.find_child("Clave", true, false) as LineEdit
	if usuario == null or clave == null:
		return
	_escribir_animado(usuario, String(r.cuentas["club"]["usuario"]), func() -> void:
		_escribir_animado(clave, r.clave_club, func() -> void: _entrar(usuario.text, clave.text)))

## Escribe `texto` en el campo letra a letra y después llama a `luego`.
func _escribir_animado(campo: LineEdit, texto: String, luego: Callable) -> void:
	campo.text = ""
	var tw := create_tween()
	for i in texto.length():
		var parcial := texto.substr(0, i + 1)
		tw.tween_callback(func() -> void:
			if is_instance_valid(campo):
				campo.text = parcial).set_delay(0.045)
	tw.tween_callback(luego).set_delay(0.2)

func _entrar(usuario: String, clave: String, recordada: bool = false) -> void:
	var r := m.redes
	var u := usuario.strip_edges()
	var error := r.iniciar_sesion(u, clave) if not recordada else r.iniciar_sesion(u, "")
	for h in _cuerpo.get_children():
		h.queue_free()
	if error != "":
		abrir_app("tribuna")
		_decir("⚠️ " + error.substr(0, 1).to_upper() + error.substr(1) + ".")
		return
	_cuerpo.add_child(_espera("Iniciando sesión en %s…" % String(r.cuentas[r.sesion]["usuario"])))
	_sub = "inicio"
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		if is_instance_valid(self) and _app == "tribuna":
			abrir_app("tribuna")
			_decir("✔ Sesión iniciada: %s" % String(r.cuentas[r.sesion]["usuario"])))

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

func _foto(tipo: String, alto: float) -> Control:
	var d: Array = FOTOS.get(tipo, ["💬", "3a3f4a", "1a1d24"])
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(0, alto)
	caja.clip_contents = true
	var tr := TextureRect.new()
	var g := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Movil.color(String(d[1]), m.mi_club()))
	gr.set_color(1, Movil.color(String(d[2]), m.mi_club()))
	g.gradient = gr
	g.fill_from = Vector2(0, 0)
	g.fill_to = Vector2(0.4, 1)
	tr.texture = g
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(tr)
	var e := Tema.etiqueta(int(alto * 0.42), Tema.TEXTO, String(d[0]))
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
	ver.text = "💬 %d" % cs.size() + (("  · %d sin responder" % sin_resp) if mia and sin_resp > 0 else "")
	ver.pressed.connect(func() -> void:
		_abiertos[id] = not bool(_abiertos.get(id, false))
		abrir_app("tribuna"))
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
				abrir_app("tribuna")
				_decir(res))
			fila.add_child(b)
	if bool(_abiertos.get(id, false)):
		for i in cs.size():
			v.add_child(_comentario(p, i, mia))
	return pc

func _comentario(p: Dictionary, i: int, mia: bool) -> Control:
	var c: Dictionary = p["comentarios"][i]
	var v := VBoxContainer.new()
	var col := Tema.BIEN if String(c["tono"]) == "bien" else (Color("e5534b") if String(c["tono"]) == "mal" else Tema.SUAVE)
	var l := Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, "%s  %s" % [String(c["autor"]), String(c["texto"])])
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", col.lerp(Tema.TEXTO, 0.5))
	v.add_child(l)
	var resp := String(c.get("respuesta", ""))
	if resp != "":
		var quien := String(m.redes.cuentas["club" if String(p["cuenta"]) == "club" else "dt"]["usuario"])
		var r := Tema.etiqueta(Tema.TAM_ROTULO, AZUL, "   ↳ %s  %s  (♥ %d)" % [quien, resp, int(c.get("respuesta_likes", 0))])
		r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(r)
	elif mia:
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
				var res := m.redes.responder(m, id, i, k)
				abrir_app("tribuna")
				_decir(res))
			fila.add_child(b)
	return v

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
			abrir_app("tribuna"))
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
	pub.text = "Publicar como " + String(r.cuentas[r.sesion]["usuario"])
	pub.custom_minimum_size = Vector2(0, 40)
	pub.pressed.connect(func() -> void:
		var res := r.publicar(m, _tipo_elegido, _tags_elegidos)
		if res.has("error"):
			_decir(String(res["error"]))
			return
		_tags_elegidos = []
		_sub = "perfil" if not como_club else "club"
		abrir_app("tribuna")
		_decir("✔ Publicado: %s me gusta en el primer rato." % cifra(int(res["likes"]))))
	_cuerpo.add_child(pub)

# --- mensajes, noticias, banco, calendario, fotos --------------------------------------

func _mensajes() -> void:
	if _chat != "":
		_un_chat()
		return
	_titulo_app("Mensajes")
	var chats := m.movil.chats()
	if chats.is_empty():
		_cuerpo.add_child(_nota("No tienes mensajes."))
	for ch: Dictionary in chats:
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 56)
		var ult := String(ch["ultimo"])
		b.text = "%s  %s%s\n      %s" % [String(ch["icono"]), String(ch["de"]),
			("  (%d)" % int(ch["sin_leer"])) if int(ch["sin_leer"]) > 0 else "",
			ult.substr(0, 34) + ("…" if ult.length() > 34 else "")]
		b.add_theme_font_size_override("font_size", 12)
		var de := String(ch["de"])
		b.pressed.connect(func() -> void:
			_chat = de
			abrir_app("mensajes"))
		_cuerpo.add_child(b)

func _un_chat() -> void:
	var fila := HBoxContainer.new()
	var atras := Button.new()
	atras.flat = true
	atras.text = "‹"
	atras.add_theme_font_size_override("font_size", 22)
	atras.pressed.connect(func() -> void:
		_chat = ""
		abrir_app("mensajes"))
	fila.add_child(atras)
	fila.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, _chat))
	_cuerpo.add_child(fila)
	var lista: Array = []
	for msj: Dictionary in m.movil.mensajes:
		if String(msj["de"]) == _chat:
			lista.push_front(msj)
			msj["leido"] = true
	for msj: Dictionary in lista:
		var burbuja := PanelContainer.new()
		burbuja.add_theme_stylebox_override("panel", Tema.caja(Color(0.16, 0.18, 0.22), 14, Color(0.16, 0.18, 0.22)))
		var l := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, String(msj["texto"]))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		burbuja.add_child(l)
		_cuerpo.add_child(burbuja)
		_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "  semana %d · %d" % [int(msj["semana"]), int(msj["anio"])]))

func _noticias() -> void:
	_titulo_app("Noticias")
	if bandeja.is_empty():
		_cuerpo.add_child(_nota("Sin noticias por ahora."))
	for n: Dictionary in bandeja.slice(0, 20):
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", Tema.caja(TARJETA, 12, TARJETA))
		var v := VBoxContainer.new()
		pc.add_child(v)
		var t := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, String(n.get("titulo", "")))
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(t)
		var c := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, String(n.get("cuerpo", "")))
		c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(c)
		_cuerpo.add_child(pc)

func _banco() -> void:
	_titulo_app("Banco")
	var c := m.mi_club()
	var filas := []
	if c != null:
		filas.append(["🏟️ Caja del club", Cesiones.dinero(c.saldo), Tema.BIEN if c.saldo >= 0 else Color("e5534b")])
	if m.roles != null:
		filas.append(["👤 Tu patrimonio", Cesiones.dinero(m.roles.patrimonio), Tema.TEXTO])
	if m.fondo != null:
		filas.append(["💼 Tu fondo de inversión", Cesiones.dinero(m.fondo.valor_total(m)), Tema.ORO])
	for f: Array in filas:
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", Tema.caja(TARJETA, 12, TARJETA))
		var v := VBoxContainer.new()
		pc.add_child(v)
		v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, String(f[0])))
		v.add_child(Tema.etiqueta(Tema.TAM_DESTACADO + 4, f[2], String(f[1])))
		_cuerpo.add_child(pc)

func _calendario() -> void:
	_titulo_app("Calendario")
	var c := m.mi_club()
	var prox := m.proximo_partido()
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(TARJETA, 12, TARJETA))
	var v := VBoxContainer.new()
	caja.add_child(v)
	v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "PRÓXIMO PARTIDO"))
	if prox.size() >= 2:
		v.add_child(Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, "%s  vs  %s" % [(prox[0] as Club).nombre, (prox[1] as Club).nombre]))
		v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "🏠 En casa" if prox[0] == c else "✈️ De visita"))
	else:
		v.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "Semana sin partido de liga."))
	_cuerpo.add_child(caja)
	## La tabla, cerca de tu puesto.
	for l in m.ligas:
		if not l.clubes.has(c):
			continue
		var t: Array = l.tabla()
		var yo := 0
		for i in t.size():
			if t[i]["club"] == c:
				yo = i
		_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "  TU LIGA"))
		for i in range(maxi(0, yo - 2), mini(t.size(), yo + 3)):
			var fila: Dictionary = t[i]
			var cl: Club = fila["club"]
			_cuerpo.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.ORO if cl == c else Tema.TEXTO, "%2d. %s  ·  %d pts" % [i + 1, cl.nombre, int(fila.get("pts", 0))]))
		break

func _fotos() -> void:
	_titulo_app("Fotos")
	var rej := GridContainer.new()
	rej.columns = 3
	rej.add_theme_constant_override("h_separation", 3)
	rej.add_theme_constant_override("v_separation", 3)
	_cuerpo.add_child(rej)
	rej.add_child(_avatar(m.movil.textura_perfil(m), 104, "🧑‍💼"))
	var n := 1
	for p: Dictionary in m.redes.publicaciones:
		if (String(p["cuenta"]) == "dt" or bool(p.get("tuya", false))) and FOTOS.has(String(p["tipo"])):
			var f := _foto(String(p["tipo"]), 104.0)
			f.custom_minimum_size = Vector2(104, 104)
			rej.add_child(f)
			n += 1
	## Las del modo foto (fase 5): ciudad, estadio y casa.
	for ruta: String in ModoFoto.fotos():
		var img := Image.load_from_file(ProjectSettings.globalize_path(ruta))
		if img == null or img.is_empty():
			continue
		var tr := TextureRect.new()
		tr.texture = ImageTexture.create_from_image(img)
		tr.custom_minimum_size = Vector2(104, 104)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		rej.add_child(tr)
		n += 1
	_cuerpo.add_child(_nota("%d foto%s" % [n, "" if n == 1 else "s"]))

# --- ajustes ----------------------------------------------------------------------------

func _ajustes() -> void:
	_titulo_app("Ajustes")
	var mv := m.movil
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "FONDO DE PANTALLA"))
	var fondos := HFlowContainer.new()
	_cuerpo.add_child(fondos)
	for k: String in Movil.FONDOS:
		var d: Array = Movil.FONDOS[k]
		var kk := k
		fondos.add_child(_muestra(Movil.color(String(d[1]), m.mi_club()), String(d[0]), mv.fondo == k, func() -> void:
			mv.fondo = kk
			_pintar_papel()
			estetica_cambiada.emit()
			abrir_app("ajustes")))
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "FUNDA"))
	var fundas := HFlowContainer.new()
	_cuerpo.add_child(fundas)
	for f: Array in Movil.FUNDAS:
		var clave := String(f[1])
		fundas.add_child(_muestra(Movil.color(clave, m.mi_club()), String(f[0]), mv.funda == clave, func() -> void:
			mv.funda = clave
			_pintar_papel()
			estetica_cambiada.emit()
			abrir_app("ajustes")))
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "TAMAÑO DE LETRA"))
	var letras := HBoxContainer.new()
	_cuerpo.add_child(letras)
	for i in Movil.LETRAS.size():
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = mv.letra == i
		b.text = String(Movil.LETRAS[i][0])
		var k2 := i
		b.pressed.connect(func() -> void:
			mv.letra = k2
			abrir_app("ajustes"))
		letras.add_child(b)
	_cuerpo.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "FOTO DE PERFIL"))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	_cuerpo.add_child(fila)
	fila.add_child(_avatar(mv.textura_perfil(m), 72, "🧑‍💼"))
	var botones := VBoxContainer.new()
	fila.add_child(botones)
	var retrato := Button.new()
	retrato.text = "🧑 Usar mi personaje"
	retrato.pressed.connect(func() -> void:
		mv.foto_perfil = "retrato"
		estetica_cambiada.emit()
		abrir_app("ajustes"))
	botones.add_child(retrato)
	var galeria := Button.new()
	galeria.text = "🖼️ Elegir de mi galería"
	galeria.pressed.connect(_elegir_de_galeria)
	botones.add_child(galeria)

func _muestra(col: Color, nombre: String, elegido: bool, al_tocar: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(40, 40)
	b.tooltip_text = nombre
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(20)
	sb.set_border_width_all(3 if elegido else 1)
	sb.border_color = Tema.ORO if elegido else Color(1, 1, 1, 0.3)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.pressed.connect(al_tocar)
	return b

## LA GALERÍA: el selector de archivos del sistema (el nativo en móvil y en
## escritorio). La imagen se recorta al cuadrado y se guarda como tu foto.
func _elegir_de_galeria() -> void:
	var fd := FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.use_native_dialog = true
	fd.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Imágenes"])
	fd.title = "Elige tu foto de perfil"
	get_tree().root.add_child(fd)
	fd.file_selected.connect(func(ruta: String) -> void:
		var error := m.movil.usar_foto_de_galeria(ruta)
		fd.queue_free()
		if is_instance_valid(self):
			abrir_app("ajustes")
			_decir("✔ Foto de perfil actualizada." if error == "" else "⚠️ " + error)
			estetica_cambiada.emit())
	fd.canceled.connect(fd.queue_free)
	fd.popup_centered_ratio(0.7)

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
	var noticias: Array = p.get("_bandeja") if p.get("_bandeja") != null else []
	var tel := Telefono.crear(mundo, noticias)
	## A la altura de la pantalla VISIBLE (la interfaz va escalada: 780 px
	## "de diseño" se salían por abajo y tapaban la barra de inicio).
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
