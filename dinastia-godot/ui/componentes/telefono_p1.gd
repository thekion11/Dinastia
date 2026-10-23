extends PanelContainer
## [Capa 1/3 de `telefono.gd`] crear, _hora, _decir, _widget_informe, _insignia, _icono_app … (+13)

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

func _hora() -> String:
	return "%02d:%02d" % [18 + (m.semana % 4), (m.semana * 7) % 60]

func _decir(texto: String) -> void:
	_aviso.text = "  " + texto
	_aviso.visible = texto != ""

## El parte del club: tres líneas con cifras alineadas y un filo dorado.
func _widget_informe() -> Control:
	var pc := PanelContainer.new()
	var sb := Tema.caja(Color(0.04, 0.05, 0.07, 0.62), 16, Color(1, 1, 1, 0.1))
	sb.set_border_width_all(0)
	sb.border_width_left = 3
	sb.border_color = Tema.ORO
	sb.set_content_margin_all(10)
	pc.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	pc.add_child(v)
	v.add_child(Tema.etiqueta(Tema.TAM_ROTULO - 2, Tema.ORO, "PARTE DEL CLUB"))
	var c := m.mi_club()
	var prox := m.proximo_partido()
	var rival := "—"
	if prox.size() >= 2 and c != null:
		var otro: Club = prox[1] if prox[0] == c else prox[0]
		rival = ("🏠 " if prox[0] == c else "✈️ ") + otro.nombre
	var puesto := "—"
	for l in m.ligas:
		if c != null and l.clubes.has(c):
			var t: Array = l.tabla()
			for i in t.size():
				if t[i]["club"] == c:
					puesto = "%dº de %d" % [i + 1, t.size()]
			break
	for f: Array in [["Próximo", rival], ["Liga", puesto], ["Caja", Cesiones.dinero(c.saldo) if c != null else "—"]]:
		var fila := HBoxContainer.new()
		var k := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, String(f[0]))
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(k)
		var val := Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, String(f[1]))
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fila.add_child(val)
		v.add_child(fila)
	return pc

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
	b.pressed.connect(func() -> void: (self as Telefono).abrir_app(clave))
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

# --- inicio -----------------------------------------------------------------------

func _inicio() -> void:
	## MEDIO MÓVIL, MEDIO INFORME (13-10-2026): reloj de pantalla de bloqueo,
	## un widget con el parte del club (sobrio, como el informe) y un dock.
	var reloj := Tema.etiqueta(58, Tema.TEXTO, _hora())
	reloj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cuerpo.add_child(reloj)
	var fecha := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "Semana %d · %d" % [m.semana, m.anio])
	fecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cuerpo.add_child(fecha)
	_cuerpo.add_child(_widget_informe())
	var rej := GridContainer.new()
	rej.columns = 4
	rej.add_theme_constant_override("h_separation", 10)
	rej.add_theme_constant_override("v_separation", 14)
	var centro := CenterContainer.new()
	centro.add_child(rej)
	_cuerpo.add_child(centro)
	var dock := HBoxContainer.new()
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_theme_constant_override("separation", 10)
	for a: Array in APPS:
		## Mensajes, Tribuna y Calendario van al dock, como las apps de siempre.
		if String(a[0]) in ["mensajes", "tribuna", "calendario"]:
			dock.add_child(_icono_app(a))
		else:
			rej.add_child(_icono_app(a))
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(0, 150)
	_cuerpo.add_child(hueco)
	var bandeja_dock := PanelContainer.new()
	bandeja_dock.add_theme_stylebox_override("panel", Tema.caja(Color(1, 1, 1, 0.14), 22, Color(1, 1, 1, 0.2)))
	bandeja_dock.add_child(dock)
	_cuerpo.add_child(bandeja_dock)

func _nota(texto: String) -> Label:
	var l := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, texto)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

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

func _entrar(usuario: String, clave: String, recordada: bool = false) -> void:
	var r := m.redes
	var u := usuario.strip_edges()
	var error := r.iniciar_sesion(u, clave) if not recordada else r.iniciar_sesion(u, "")
	for h in _cuerpo.get_children():
		h.queue_free()
	if error != "":
		(self as Telefono).abrir_app("tribuna")
		_decir("⚠️ " + error.substr(0, 1).to_upper() + error.substr(1) + ".")
		return
	_cuerpo.add_child(_espera("Iniciando sesión en %s…" % String(r.cuentas[r.sesion]["usuario"])))
	_sub = "inicio"
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		if is_instance_valid(self) and _app == "tribuna":
			(self as Telefono).abrir_app("tribuna")
			_decir("✔ Sesión iniciada: %s" % String(r.cuentas[r.sesion]["usuario"])))

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
	usuario.placeholder_text = Idiomas.t("Usuario (@...)")
	usuario.name = "Usuario"
	_cuerpo.add_child(usuario)
	var clave := LineEdit.new()
	clave.placeholder_text = Idiomas.t("Clave")
	clave.secret = true
	clave.name = "Clave"
	_cuerpo.add_child(clave)
	var entrar := Button.new()
	entrar.text = Idiomas.t("Entrar")
	entrar.custom_minimum_size = Vector2(0, 40)
	entrar.pressed.connect(func() -> void: _entrar(usuario.text, clave.text))
	_cuerpo.add_child(entrar)
	clave.text_submitted.connect(func(_t: String) -> void: _entrar(usuario.text, clave.text))
	_cuerpo.add_child(HSeparator.new())
	_cuerpo.add_child(_nota("Cuentas guardadas en este móvil"))
	## Tu cuenta: un toque (la clave está recordada).
	var yo := Button.new()
	yo.text = Idiomas.t("%s  (tu cuenta)") % String(r.cuentas["dt"]["usuario"])
	yo.pressed.connect(func() -> void:
		_escribir_animado(usuario, String(r.cuentas["dt"]["usuario"]), func() -> void:
			_escribir_animado(clave, "••••••••", func() -> void: _entrar(usuario.text, "", true))))
	_cuerpo.add_child(yo)
	var del_club := Button.new()
	del_club.text = "%s  %s" % [String(r.cuentas["club"]["usuario"]), Idiomas.t("(la clave está en Mensajes)") if r.acceso_club else Idiomas.t("🔒 no es tuya")]
	del_club.disabled = not r.acceso_club
	del_club.pressed.connect(func() -> void:
		_escribir_animado(usuario, String(r.cuentas["club"]["usuario"]), func() -> void: clave.grab_focus()))
	_cuerpo.add_child(del_club)
	if r.acceso_club:
		var usar := Button.new()
		usar.text = Idiomas.t("🔑 Usar la clave guardada")
		usar.pressed.connect(func() -> void: entrar_con_clave_guardada())
		_cuerpo.add_child(usar)
	else:
		_cuerpo.add_child(_nota("La cuenta del club la lleva el community manager. Llevas poco en el club: dale unas semanas."))

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

## CERRAR SESIÓN: un rato con "Cerrando sesión…" y a la pantalla de entrar.
func _cerrar_sesion_animado() -> void:
	for h in _cuerpo.get_children():
		h.queue_free()
	_cuerpo.add_child(_espera("Cerrando sesión de %s…" % String(m.redes.cuentas[m.redes.sesion]["usuario"])))
	m.redes.cerrar_sesion()
	get_tree().create_timer(0.9).timeout.connect(func() -> void:
		if is_instance_valid(self) and _app == "tribuna":
			(self as Telefono).abrir_app("tribuna"))

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

static func cifra(n: int) -> String:
	if n >= 1000000:
		return "%.1f M" % (float(n) / 1000000.0)
	if n >= 10000:
		return "%d mil" % int(n / 1000)
	if n >= 1000:
		return "%.1f mil" % (float(n) / 1000.0)
	return str(n)

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
				(self as Telefono).abrir_app("tribuna")
				_decir(res))
			fila.add_child(b)
	return v
