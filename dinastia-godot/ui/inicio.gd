class_name Inicio
extends Control
## LA PANTALLA DE TÍTULO, portada del "MENÚ DE MODOS" del HTML
## (`renderModoSel()`, v3.0): portada + partida en curso + perfil + la grilla
## de modos jugables, todo en UNA sola pantalla que se desplaza, como en el
## HTML -antes eran dos pantallas separadas (esta y `seleccion_modo.gd`), y
## entre una y otra quedaba un hueco vacío enorme que no existía en el
## original-.
##
## Solo compone lo que ya existe: `Portada.gd` dibuja las nueve carátulas,
## `TarjetaModo.gd` dibuja el degradado de cada tarjeta de modo,
## `Logros.perfil_leer()` ya guardaba el XP del gestor y no lo enseñaba en
## ningún sitio antes de la pantalla de Logros, y `Partida.gd` lleva el
## guardado. Aquí no hay lógica de juego nueva, solo el primer clic.

## La misma paleta que css/estilo.css (`:root`), no una propia de Godot.
const COL_FONDO := Tema.FONDO
const COL_PANEL := Tema.PANEL
const COL_BORDE := Tema.BORDE
const COL_TEXTO := Tema.TEXTO
const COL_SUAVE := Tema.SUAVE
## El verde de siempre. En el club ya elegido el acento es SU color -ver
## principal.gd- pero aquí todavía no hay ningún club escogido.
const COL_ACENTO := Tema.ACENTO
const COL_ORO := Tema.ORO

## Los títulos de cada portada llevan su propio color en el HTML (`.pTretro`,
## `.pTneon`…): un blanco por defecto se perdía sobre el sol naranja del retro
## o el papel claro de prensa. Ausente = el blanco/verde de siempre.
const COLOR_TITULO := {
	"retro": "f7e39a", "prensa": "221e1a", "neon": "fff0fb",
	"trofeo": "f7e39a", "pizarra": "f2f6f2",
}
const COLOR_SUB := {
	"retro": "3a1408", "prensa": "7a2f1f", "neon": "00e5ff",
	"trofeo": "c9a227", "pizarra": "ffe14d",
}
const COLOR_CLAIM := {
	"prensa": "4a4238",
}

## Categorías que hoy no llevan a ninguna carrera jugable -"retos", "tutorial"
## y "proximo" en el HTML, más la tarjeta "Crear tu Club" (`crear:true`)-. Se
## SIGUEN mostrando, como en el HTML: enseñarlas apagadas es honesto, esconderlas
## habría sido fingir que el menú tiene menos modos de los que en verdad tiene.
## "tutorial" dejó la lista el 25-9-2026: lleva a una carrera de entrenador con
## el recorrido guiado encendido (`ui/componentes/tutorial.gd`).
const CATS_SIN_JUGAR := ["proximo"]

const CONFIG_RUTA := "user://ajustes.cfg"

var _banner: Control
var _fondo_banner: TextureRect
var _overlay: TextureRect
var _lbl_sub: Label
var _lbl_titulo: Label
var _lbl_claim: Label
var _fila_picker: HBoxContainer
var _clave := "clasica"

var _campo_nombre: LineEdit
var _fila_dificultad: HBoxContainer
var _dificultad := "normal"
var _fila_base: HBoxContainer
var _lbl_base: Label
var _lbl_estado: Label

var _panel_continuar: VBoxContainer
var _mundo_guardado: Mundo = null

func _ready() -> void:
	_clave = _leer_ajuste()
	_construir()
	_pintar_banner()
	_actualizar_picker()
	_actualizar_continuar()

# --- construcción ------------------------------------------------------------

func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = COL_FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	## Un margen a los lados sin gastar otro nodo por lado: un solo
	## MarginContainer envolviendo todo el contenido.
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 24)
	margen.add_theme_constant_override("margin_right", 24)
	margen.add_theme_constant_override("margin_top", 20)
	margen.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margen)

	var raiz := VBoxContainer.new()
	raiz.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	raiz.add_theme_constant_override("separation", 14)
	margen.add_child(raiz)

	_construir_banner(raiz)

	_panel_continuar = VBoxContainer.new()
	_panel_continuar.add_theme_constant_override("separation", 8)
	raiz.add_child(_panel_continuar)

	_construir_perfil(raiz)
	_construir_meta(raiz)
	_construir_datos_dt(raiz)

	var titulo := _texto(20, COL_TEXTO)
	titulo.text = "ELIGE TU CAMINO"
	raiz.add_child(titulo)

	var secciones: Variant = Datos.tabla("MODO_SECCIONES")
	var modos: Variant = Datos.tabla("MODOS_JUEGO")
	if secciones is Array and modos is Array:
		for fila: Array in secciones:
			var cat := String(fila[0])
			var stitulo := String(fila[1])
			var sdesc := String(fila[2])
			var de_esta_cat: Array = (modos as Array).filter(func(m: Dictionary) -> bool: return String(m.get("cat", "")) == cat)
			if de_esta_cat.is_empty():
				continue
			if stitulo != "":
				var ct := _texto(13, COL_ORO)
				ct.text = stitulo
				raiz.add_child(ct)
				var cd := _texto(11, COL_SUAVE)
				cd.text = sdesc
				raiz.add_child(cd)
			var grid := GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", 10)
			grid.add_theme_constant_override("v_separation", 10)
			raiz.add_child(grid)
			for m: Dictionary in de_esta_cat:
				grid.add_child(_tarjeta(m))

	_lbl_estado = _texto(12, COL_ORO)
	_lbl_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_estado.visible = false
	raiz.add_child(_lbl_estado)

	_construir_selector_portada(raiz)

	## El fondo animado -"iniciarPhaserMenu()" del HTML-: motas de luz subiendo
	## despacio por toda la pantalla. Va la última, fuera del scroll -como el
	## canvas de Phaser, que flota encima de #main sin desplazarse con la
	## página- y cubriendo el viewport, no el contenido entero.
	var fondo_part := FondoParticulas.new()
	fondo_part.ajustar_area(get_viewport_rect().size)
	add_child(fondo_part)

## La franja panorámica con el fondo de la portada, el degradado que hace
## legible el texto y el título encima. El HTML lo llama `.pHero`: cielo,
## césped o lo que toque, y encima el nombre del juego.
func _construir_banner(raiz: VBoxContainer) -> void:
	_banner = Control.new()
	_banner.custom_minimum_size = Vector2(0, 200)
	_banner.clip_contents = true
	raiz.add_child(_banner)

	_fondo_banner = TextureRect.new()
	_fondo_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo_banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fondo_banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_banner.add_child(_fondo_banner)

	_overlay = TextureRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	_banner.add_child(_overlay)

	var textos := VBoxContainer.new()
	textos.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	textos.offset_left = 22; textos.offset_top = -108
	textos.offset_right = -22; textos.offset_bottom = -16
	textos.add_theme_constant_override("separation", 2)
	_banner.add_child(textos)
	_lbl_sub = _texto(13, COL_ACENTO)
	_lbl_sub.text = "FÚTBOL MANAGER"
	textos.add_child(_lbl_sub)
	_lbl_titulo = _texto(48, COL_TEXTO)
	_lbl_titulo.text = "DINASTÍA"
	textos.add_child(_lbl_titulo)
	_lbl_claim = _texto(13, Color("c3d2c7"))
	_lbl_claim.text = "Forma juveniles, gana la liga, conquista el continente… y algún día verás llegar a la cantera a los hijos de tus leyendas."
	_lbl_claim.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_claim.custom_minimum_size = Vector2(560, 0)
	textos.add_child(_lbl_claim)

## "TU PERFIL DE GESTOR" -la carrera que sobrevive a esta partida-, portado de
## `perfilTarjetaHTML()`. Reutiliza exactamente lo que ya construyó la pestaña
## de Logros (`Logros.perfil_leer()`/`perfil_nivel()`); aquí solo hacía falta
## enseñarlo también en el menú, que es donde el HTML lo pone.
func _construir_perfil(raiz: VBoxContainer) -> void:
	var perfil := Logros.perfil_leer()
	var nivel := Logros.perfil_nivel(int(perfil["xp"]))
	var caja := _panel()
	raiz.add_child(caja)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14; v.offset_top = 8; v.offset_right = -14; v.offset_bottom = -8
	caja.add_child(v)
	var t := _texto(13, COL_ACENTO)
	t.text = "%s  ·  %d XP" % [String(nivel["nombre"]), int(nivel["xp"])]
	v.add_child(t)
	var barra := ProgressBar.new()
	barra.min_value = 0
	barra.max_value = 100
	barra.value = int(nivel["pct"])
	barra.custom_minimum_size = Vector2(0, 10)
	barra.show_percentage = false
	v.add_child(barra)
	var lema := _texto(11, COL_SUAVE)
	lema.text = String(nivel["lema"])
	v.add_child(lema)

func _construir_datos_dt(raiz: VBoxContainer) -> void:
	var fila_nombre := HBoxContainer.new()
	fila_nombre.add_theme_constant_override("separation", 8)
	raiz.add_child(fila_nombre)
	var ln := _texto(12, COL_SUAVE)
	ln.text = "Tu nombre"
	ln.custom_minimum_size = Vector2(90, 0)
	ln.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila_nombre.add_child(ln)
	_campo_nombre = LineEdit.new()
	_campo_nombre.text = "Míster"
	_campo_nombre.custom_minimum_size = Vector2(240, 32)
	_campo_nombre.placeholder_text = "Nombre del entrenador"
	fila_nombre.add_child(_campo_nombre)

	var fila_dif := HBoxContainer.new()
	fila_dif.add_theme_constant_override("separation", 8)
	raiz.add_child(fila_dif)
	var ld := _texto(12, COL_SUAVE)
	ld.text = "Dificultad"
	ld.custom_minimum_size = Vector2(90, 0)
	ld.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila_dif.add_child(ld)
	_fila_dificultad = HBoxContainer.new()
	_fila_dificultad.add_theme_constant_override("separation", 6)
	fila_dif.add_child(_fila_dificultad)
	var dif: Variant = Datos.tabla("DIF")
	var claves := ["facil", "normal", "leyenda"] if dif is Dictionary else []
	for k: String in claves:
		var d: Dictionary = (dif as Dictionary)[k]
		var b := Button.new()
		b.text = String(d.get("n", k))
		b.toggle_mode = true
		b.button_pressed = (k == _dificultad)
		b.custom_minimum_size = Vector2(90, 28)
		b.pressed.connect(func() -> void: _elegir_dificultad(k))
		_fila_dificultad.add_child(b)
	_construir_selector_base(raiz)

## "BASE DE DATOS": ficticia (la que se publica, por defecto) o el pack real
## si esta instalación lo tiene. Ver `Datos` para el formato y dónde se busca.
## Se aplica AL MOMENTO -`eleccion_club.gd` genera el mundo con lo que haya
## activo- y se recuerda para la próxima vez.
## El álbum, el museo de tus carreras y el mundo heredado (28-9-2026, `Meta`).
func _construir_meta(raiz: VBoxContainer) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	raiz.add_child(fila)
	var d := Meta.leer()
	var b := Button.new()
	b.text = "📒 Álbum y museo  ·  %d cromos, %d títulos" % [(d["cromos"] as Dictionary).size(), (d["museo"] as Array).size()]
	b.pressed.connect(func() -> void: PanelMeta.abrir(self))
	fila.add_child(b)
	if Meta.hay_legado():
		var leg: Dictionary = d["legado"]
		var h := CheckButton.new()
		h.text = "🌍 Heredar el mundo de tu última partida (temporada %d)" % int(leg.get("anio", 0))
		h.button_pressed = Meta.heredar_proximo
		h.toggled.connect(func(si: bool) -> void: Meta.heredar_proximo = si)
		fila.add_child(h)

func _construir_selector_base(raiz: VBoxContainer) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	raiz.add_child(fila)
	var lb := _texto(12, COL_SUAVE)
	lb.text = "Base de datos"
	lb.custom_minimum_size = Vector2(90, 0)
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(lb)
	_fila_base = HBoxContainer.new()
	_fila_base.add_theme_constant_override("separation", 6)
	fila.add_child(_fila_base)
	for real: bool in [false, true]:
		var b := Button.new()
		b.text = "Ficticia" if not real else "Real (pack)"
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(110, 28)
		if real and not Datos.hay_pack_real():
			b.disabled = true
			b.tooltip_text = "No hay ningún pack real instalado. Copia un archivo pack_real.json en:\n%s" \
				% ProjectSettings.globalize_path("user://")
		b.pressed.connect(func() -> void: _elegir_base(real))
		_fila_base.add_child(b)
	_lbl_base = _texto(11, COL_SUAVE)
	_lbl_base.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(_lbl_base)
	_pintar_base()

func _elegir_base(real: bool) -> void:
	Datos.usar_base_real(real)
	Datos.guardar_preferencia_base_real(Datos.base_real)
	_pintar_base()

func _pintar_base() -> void:
	for i in _fila_base.get_child_count():
		(_fila_base.get_child(i) as Button).button_pressed = (i == 1) == Datos.base_real
	if Datos.base_real:
		_lbl_base.text = "Clubes, ligas y jugadores reales de «%s», con sus caras y con los nombres cubiertos (C0lo-C0lo). Solo para uso privado." % Datos.nombre_pack()
	else:
		_lbl_base.text = "384 clubes y 24 ligas inventados, con jugadores generados. Es la base de la versión publicada."

## Una tarjeta del menú de modos -`tarjetaModo()`/`dibujarPortadaModo()` del
## HTML-: la carátula con degradado, el título y el subtítulo. Las que hoy no
## llevan a ninguna carrera jugable se enseñan atenuadas, con la misma
## etiqueta "EN DESARROLLO" que ya usa el HTML para "proximo".
func _tarjeta(m: Dictionary) -> Control:
	var cat := String(m.get("cat", ""))
	var sin_jugar := CATS_SIN_JUGAR.has(cat)

	var caja := PanelContainer.new()
	caja.custom_minimum_size = Vector2(300, 150)
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var e := StyleBoxFlat.new()
	e.bg_color = COL_PANEL
	e.border_color = COL_BORDE
	e.set_border_width_all(1)
	e.set_corner_radius_all(10)
	e.content_margin_left = 0; e.content_margin_right = 0
	e.content_margin_top = 0; e.content_margin_bottom = 0
	caja.add_theme_stylebox_override("panel", e)
	if sin_jugar:
		caja.modulate = Color(1, 1, 1, 0.55)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	caja.add_child(v)

	var cubierta := TextureRect.new()
	cubierta.texture = TarjetaModo.textura(String(m.get("c1", "#161b22")), String(m.get("c2", "#30363d")))
	cubierta.custom_minimum_size = Vector2(0, 84)
	cubierta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cubierta.stretch_mode = TextureRect.STRETCH_SCALE
	v.add_child(cubierta)
	if cat == "proximo":
		var badge := _texto(9, Color("0c1510"))
		badge.text = "  EN DESARROLLO  "
		var fondo_badge := PanelContainer.new()
		var eb := StyleBoxFlat.new()
		eb.bg_color = COL_ORO
		eb.set_corner_radius_all(4)
		fondo_badge.add_theme_stylebox_override("panel", eb)
		fondo_badge.add_child(badge)
		fondo_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		fondo_badge.offset_left = -102; fondo_badge.offset_top = 6
		fondo_badge.offset_right = -8; fondo_badge.offset_bottom = 22
		cubierta.add_child(fondo_badge)

	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", 4)
	var mt := MarginContainer.new()
	mt.add_theme_constant_override("margin_left", 12); mt.add_theme_constant_override("margin_right", 12)
	mt.add_theme_constant_override("margin_top", 8); mt.add_theme_constant_override("margin_bottom", 10)
	mt.add_child(textos)
	v.add_child(mt)
	var tt := _texto(14, COL_TEXTO)
	tt.text = String(m.get("titulo", ""))
	textos.add_child(tt)
	var ts := _texto(11, COL_SUAVE)
	ts.text = String(m.get("sub", ""))
	ts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(ts)

	## Todo el panel es el botón: un botón transparente encima ocupa el rect
	## entero, que es más agradable de pulsar que un botón chico dentro.
	var b := Button.new()
	b.flat = true
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void: _al_pulsar_modo(m))
	caja.add_child(b)
	return caja

func _construir_selector_portada(raiz: VBoxContainer) -> void:
	raiz.add_child(HSeparator.new())
	var panel_picker := _panel()
	raiz.add_child(panel_picker)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14; v.offset_top = 10; v.offset_right = -14; v.offset_bottom = -10
	v.add_theme_constant_override("separation", 8)
	panel_picker.add_child(v)
	var t := _texto(11, COL_SUAVE)
	t.text = "PORTADA DEL JUEGO"
	v.add_child(t)
	_fila_picker = HBoxContainer.new()
	_fila_picker.add_theme_constant_override("separation", 6)
	var scroll_picker := ScrollContainer.new()
	scroll_picker.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_picker.add_child(_fila_picker)
	v.add_child(scroll_picker)
	for k: String in Portada.NOMBRES:
		var b := Button.new()
		b.text = String(Portada.TITULOS[k])
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, 32)
		b.pressed.connect(func() -> void: _elegir(k))
		_fila_picker.add_child(b)

func _texto(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l

## Mismo truco que `principal.gd`: el ".card" del HTML trae un degradado
## cenital sutil que `StyleBoxFlat` no sabe dar solo, así que se superpone una
## textura de brillo -blanco semitransparente arriba, cero abajo- que ignora
## el ratón.
static var _brillo_panel: Texture2D = null
static func _textura_brillo_panel() -> Texture2D:
	if _brillo_panel != null:
		return _brillo_panel
	## OJO: `Gradient.set_color(i, ...)` indexa por PUNTO, no por offset -y
	## `add_point()` desplaza los índices de los puntos que venían después-,
	## así que fijar los tres colores de un tirón evita que el punto final se
	## quede en su blanco opaco de fábrica.
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, 0.10), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_LINEAR
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	t.width = 4
	t.height = 128
	_brillo_panel = t
	return t

func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = COL_PANEL
	e.border_color = COL_BORDE
	e.set_border_width_all(1)
	e.set_corner_radius_all(8)
	p.add_theme_stylebox_override("panel", e)
	var brillo := TextureRect.new()
	brillo.texture = _textura_brillo_panel()
	brillo.set_anchors_preset(Control.PRESET_FULL_RECT)
	brillo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	## SIN esto, TextureRect pide como mínimo el tamaño NATIVO de la textura
	## (128px de alto) y estira el panel entero para dárselo -el brillo
	## crecía la tarjeta en vez de solo pintarla-.
	brillo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brillo.stretch_mode = TextureRect.STRETCH_SCALE
	p.add_child(brillo)
	return p

# --- la portada ---------------------------------------------------------------

func _pintar_banner() -> void:
	## Se pide el doble de la resolución real y se deja que STRETCH_KEEP_ASPECT_
	## COVERED la encoja: es la misma regla que ya deja escrita Portada.gd para
	## la tabla y el plantel, y aquí el lienzo ocupa toda la pantalla.
	var ancho := maxi(int(get_viewport_rect().size.x), 1280) * 2
	_fondo_banner.texture = Portada.textura(_clave, ancho)
	_overlay.texture = _degradado(_clave)
	_lbl_titulo.add_theme_color_override("font_color", Color(String(COLOR_TITULO.get(_clave, "eef3ee"))))
	_lbl_sub.add_theme_color_override("font_color", Color(String(COLOR_SUB.get(_clave, "3fa06a"))))
	_lbl_claim.add_theme_color_override("font_color", Color(String(COLOR_CLAIM.get(_clave, "c3d2c7"))))

## El degradado que hace legible el texto encima de la foto. La prensa tiene
## fondo claro -papel-, así que su degradado es claro y no negro: uno negro
## sobre un fondo de periódico se habría comido las letras oscuras igual.
func _degradado(k: String) -> GradientTexture2D:
	var g := Gradient.new()
	if k == "prensa":
		g.set_color(0, Color(0.937, 0.906, 0.847, 0.93))
		g.add_point(0.55, Color(0.937, 0.906, 0.847, 0.72))
		g.set_color(1, Color(0.937, 0.906, 0.847, 0.0))
	else:
		g.set_color(0, Color(0, 0, 0, 0.68))
		g.add_point(0.46, Color(0, 0, 0, 0.4))
		g.set_color(1, Color(0, 0, 0, 0.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_LINEAR
	t.fill_from = Vector2(0, 1)
	t.fill_to = Vector2(0, 0)
	t.width = 4
	t.height = 200
	return t

func _elegir(k: String) -> void:
	_clave = k
	_guardar_ajuste(k)
	_pintar_banner()
	_actualizar_picker()

func _actualizar_picker() -> void:
	for i in Portada.NOMBRES.size():
		var b: Button = _fila_picker.get_child(i)
		b.button_pressed = (Portada.NOMBRES[i] == _clave)

# --- ajustes: la portada elegida se recuerda entre sesiones ------------------

func _leer_ajuste() -> String:
	var c := ConfigFile.new()
	if c.load(CONFIG_RUTA) != OK:
		return "clasica"
	var k: String = c.get_value("portada", "clave", "clasica")
	return k if Portada.NOMBRES.has(k) else "clasica"

func _guardar_ajuste(k: String) -> void:
	var c := ConfigFile.new()
	c.load(CONFIG_RUTA)
	c.set_value("portada", "clave", k)
	c.save(CONFIG_RUTA)

func _elegir_dificultad(k: String) -> void:
	_dificultad = k
	for b: Button in _fila_dificultad.get_children():
		b.button_pressed = (b.text == String((Datos.tabla("DIF") as Dictionary).get(k, {}).get("n", "")))

# --- partida en curso ---------------------------------------------------------

## "PARTIDA EN CURSO" -`panelEstadoPartida()` del HTML-: escudo, club, la
## jornada en la que vas y un resumen corto, con Continuar/Borrar. Se carga la
## partida UNA vez -barata, ~50 ms medidos en el banco de pruebas- y se
## conserva para no leer el fichero dos veces si el jugador pulsa Continuar.
func _actualizar_continuar() -> void:
	for h in _panel_continuar.get_children():
		_panel_continuar.remove_child(h)
		h.free()
	if not _hay_partida():
		return
	_mundo_guardado = Partida.cargar("partida")
	if _mundo_guardado == null:
		return
	var c := _mundo_guardado.mi_club()
	if c == null:
		return
	var caja := _panel()
	_panel_continuar.add_child(caja)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.set_anchors_preset(Control.PRESET_FULL_RECT)
	fila.offset_left = 14; fila.offset_top = 10; fila.offset_right = -14; fila.offset_bottom = -10
	caja.add_child(fila)

	var escudo := TextureRect.new()
	escudo.texture = Escudo.textura(c, 40)
	escudo.custom_minimum_size = Vector2(40, 44)
	## Sin esto el escudo sale a su tamaño real de rasterizado -4x, para que
	## las curvas no salgan dentadas al escalar- en vez de los 40 px pedidos.
	escudo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	escudo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fila.add_child(escudo)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	fila.add_child(v)
	var et := _texto(9, COL_ACENTO)
	et.text = "PARTIDA EN CURSO"
	v.add_child(et)
	var nom := _texto(15, COL_TEXTO)
	nom.text = c.nombre
	v.add_child(nom)
	var l := _mundo_guardado.liga_de(c)
	var puesto := 0
	var pts := 0
	if l != null:
		var tabla := l.tabla()
		for i in tabla.size():
			if tabla[i]["club"] == c:
				puesto = i + 1
				pts = int(tabla[i]["pts"])
				break
	var resumen := _texto(11, COL_SUAVE)
	var trofeos := _mundo_guardado.directiva.trofeos.size() if _mundo_guardado.directiva != null else 0
	resumen.text = "Año %d · %dº con %d pts · Caja %s · %d título(s)" % [
		_mundo_guardado.anio, puesto, pts, _dinero(c.saldo), trofeos]
	resumen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(resumen)

	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 8)
	fila.add_child(botones)
	var bc := Button.new()
	bc.text = "▶ Continuar"
	bc.custom_minimum_size = Vector2(110, 32)
	bc.pressed.connect(_continuar)
	botones.add_child(bc)
	var bx := Button.new()
	bx.text = "✕"
	bx.custom_minimum_size = Vector2(32, 32)
	bx.pressed.connect(_borrar_partida)
	botones.add_child(bx)

func _dinero(n: int) -> String:
	return Eco.dinero(n)

func _borrar_partida() -> void:
	Partida.borrar("partida")
	_mundo_guardado = null
	_actualizar_continuar()

# --- arrancar partida ---------------------------------------------------------

func _hay_partida() -> bool:
	return not Partida.listar().is_empty()

func _continuar() -> void:
	var m := _mundo_guardado if _mundo_guardado != null else Partida.cargar("partida")
	if m == null:
		return
	Principal.mundo_a_cargar = m
	get_tree().change_scene_to_file("res://escenas/principal.tscn")

## Una tarjeta de modo, pulsada. Las jugables siguen exactamente el camino de
## siempre -nombre, dificultad, elegir club-; las que todavía no lo son
## enseñan por qué, en vez de fingir que llevan a algún sitio -"proximo" con
## el mismo texto que el `toast()` del HTML, las demás con su propio motivo-.
func _al_pulsar_modo(m: Dictionary) -> void:
	var cat := String(m.get("cat", ""))
	var titulo := String(m.get("titulo", ""))
	if bool(m.get("crear", false)):
		## CREAR TU CLUB (26-9-2026): la elección de club ya sabía fundar;
		## ahora la tarjeta lleva ahí con el panel de fundar destacado.
		Principal.fundar_pedido = true
		m = {"id": "dt"}
	match cat:
		"retos":
			## LOS RETOS (26-9-2026): se elige uno de los cinco y el club lo
			## pone el propio reto.
			_elegir_reto()
			return
		"tutorial":
			## Una carrera de entrenador de verdad, con el recorrido encendido:
			## se aprende jugando la propia partida, no una de mentira que
			## luego hay que tirar. Se elige el club como siempre.
			Principal.tutorial_pedido = true
			m = {"id": "dt"}
		"proximo":
			_avisar("🚧 %s todavía no se puede jugar. Está en la lista para cuando esté listo." % titulo)
			return
	var nombre := _campo_nombre.text.strip_edges()
	Principal.modo_elegido = String(m.get("id", "dt"))
	Principal.dt_nombre_elegido = nombre if nombre != "" else "Míster"
	Principal.dificultad_elegida = _dificultad
	get_tree().change_scene_to_file("res://escenas/eleccion_club.tscn")

func _avisar(texto: String) -> void:
	_lbl_estado.text = texto
	_lbl_estado.visible = true


## El selector de retos: los cinco, con su planteamiento y su meta.
func _elegir_reto() -> void:
	var capa := ColorRect.new()
	capa.color = Color(0, 0, 0, 0.6)
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(capa)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(centro)
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Tema.ORO))
	caja.custom_minimum_size = Vector2(640, 0)
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	caja.add_child(v)
	v.add_child(Tema.etiqueta(Tema.TAM_TITULO, Tema.ORO, "🎯 RETOS"))
	var nota := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, "Una temporada con una meta. Si la cumples, va a tu vitrina; después la carrera sigue.")
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nota)
	for r: Array in Retos.LISTA:
		var b := Button.new()
		b.text = "%s  %s\n%s\nMeta: %s" % [String(r[1]), String(r[2]), String(r[3]), String(r[4])]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 76)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var id := String(r[0])
		b.pressed.connect(func() -> void:
			var nombre := _campo_nombre.text.strip_edges()
			Principal.reto_pedido = id
			Principal.modo_elegido = "dt"
			Principal.dt_nombre_elegido = nombre if nombre != "" else "Míster"
			Principal.dificultad_elegida = _dificultad
			get_tree().change_scene_to_file("res://escenas/eleccion_club.tscn"))
		v.add_child(b)
	var cerrar := Button.new()
	cerrar.text = "Volver"
	cerrar.pressed.connect(capa.queue_free)
	v.add_child(cerrar)
