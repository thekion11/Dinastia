extends Control
## (Parte 1 de 3 de `inicio.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `inicio.gd`, conserva la clase.)

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

## LA PORTADA QUE CAMBIA SOLA (8-10-2026, pedido: «que el fondo de ahí se vaya
## cambiando cada 30 segundos por sus variantes»). Cada 30 s pasa a la
## siguiente de `Portada.NOMBRES` con un fundido; elegir una a mano la fija
## como punto de partida y reinicia la cuenta. Solo la elegida a mano se
## guarda en ajustes.
const SEG_PORTADA := 30.0
var _fondo_banner2: TextureRect
var _reloj_portada: Timer
var _motas: FondoParticulas
var _bokeh_fondo: FondoParticulas
var _bokeh_banner: FondoParticulas
var _pagina: TextureRect
var _pagina2: TextureRect
var _i_pagina := 0
var _reloj_pagina: Timer

## LA ROTACIÓN ENTERA (8-10, pedido: «había más fondos, faltan para la
## transición»): las 18 portadas Y los 24 fondos de pantalla completa de
## Ajustes (`Fondo.NOMBRES`, con prefijo "fondo:"). Los fondos se dibujaron
## oscuros para ir detrás de la interfaz: en la portada se aclaran un poco.
const PREFIJO_FONDO := "fondo:"

## El color de la luz de cada portada (las partículas se tiñen de él).
const TINTE := {
	"clasica": "9be7b4", "nocturna": "8fb4ff", "retro": "ffcc80", "prensa": "c9a227",
	"neon": "ff6ef7", "tifo": "ff8a65", "trofeo": "ffd54f", "pizarra": "fff59d",
	"minimal": "e0e0e0", "andino": "ffcf8a", "vestuario": "b3e5fc", "cabina": "80deea",
	"ejecutiva": "e6c27a", "tunel": "ffe0b2", "lluvia": "a7c7e7", "datos": "64ffda",
	"graffiti": "ff80ab", "marmol": "f5f5f5",
	"fondo:cesped": "9be7b4", "fondo:nocturna": "8fb4ff", "fondo:retro": "ffcc80", "fondo:prensa": "e6d3a3",
	"fondo:neon": "ff6ef7", "fondo:tifo": "ff8a65", "fondo:trofeo": "ffd54f", "fondo:pizarra": "fff59d",
	"fondo:minimal": "e0e0e0", "fondo:tunel": "ffe0b2", "fondo:lluvia": "a7c7e7", "fondo:amanecer": "ffb385",
	"fondo:autocar": "ffd9a0", "fondo:tiza": "f0f0e8", "fondo:ciudad": "ffd27a", "fondo:montana": "b9e6a0",
	"fondo:playa": "ffe08a", "fondo:nieve": "e3f2ff", "fondo:juntas": "e6c27a", "fondo:mapa": "c8e6a0",
	"fondo:vestuario": "b3e5fc", "fondo:bufandas": "ff8a80", "fondo:diario": "e6d3a3", "fondo:aeropuerto": "9fb8ff",
}

## Mismo truco que `principal.gd`: el ".card" del HTML trae un degradado
## cenital sutil que `StyleBoxFlat` no sabe dar solo, así que se superpone una
## textura de brillo -blanco semitransparente arriba, cero abajo- que ignora
## el ratón.
static var _brillo_panel: Texture2D = null

## La franja de arriba rota por las portadas; los fondos de pantalla
## completa van DETRÁS de toda la página (`_rotar_pagina`): recortados a la
## franja solo se veía un trozo y quedaban lavados.
static func rotacion() -> Array:
	return Portada.NOMBRES.duplicate()

func _textura_de(k: String) -> Texture2D:
	if k.begins_with(PREFIJO_FONDO):
		return Fondo.textura(k.substr(PREFIJO_FONDO.length()))
	return Portada.textura(k, maxi(int(get_viewport_rect().size.x), 1280) * 2)

func _brillo_de(k: String) -> Color:
	return Color(1.45, 1.45, 1.45) if k.begins_with(PREFIJO_FONDO) else Color.WHITE

# --- ajustes: la portada elegida se recuerda entre sesiones ------------------

func _leer_ajuste() -> String:
	var c := ConfigFile.new()
	if c.load(CONFIG_RUTA) != OK:
		return "clasica"
	var k: String = c.get_value("portada", "clave", "clasica")
	return k if rotacion().has(k) else "clasica"

func _texto(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l

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
	## La siguiente portada entra encima, fundiéndose.
	_fondo_banner2 = TextureRect.new()
	_fondo_banner2.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo_banner2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fondo_banner2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fondo_banner2.modulate.a = 0.0
	_banner.add_child(_fondo_banner2)
	## Luces desenfocadas flotando sobre la foto, bajo el texto.
	_bokeh_banner = FondoParticulas.new("bokeh")
	_bokeh_banner.amount = 9
	_banner.add_child(_bokeh_banner)

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
	_lbl_sub.text = Idiomas.t("FÚTBOL MANAGER")
	textos.add_child(_lbl_sub)
	_lbl_titulo = _texto(48, COL_TEXTO)
	_lbl_titulo.text = Idiomas.t("DINASTÍA")
	textos.add_child(_lbl_titulo)
	_lbl_claim = _texto(13, Color("c3d2c7"))
	_lbl_claim.text = Idiomas.t("Forma juveniles, gana la liga, conquista el continente… y algún día verás llegar a la cantera a los hijos de tus leyendas.")
	_lbl_claim.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_claim.custom_minimum_size = Vector2(560, 0)
	textos.add_child(_lbl_claim)
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
	b.text = Idiomas.t("📒 Álbum y museo  ·  %d cromos, %d títulos") % [(d["cromos"] as Dictionary).size(), (d["museo"] as Array).size()]
	b.pressed.connect(func() -> void: PanelMeta.abrir(self))
	fila.add_child(b)
	if Meta.hay_legado():
		var leg: Dictionary = d["legado"]
		var h := CheckButton.new()
		h.text = Idiomas.t("🌍 Heredar el mundo de tu última partida (temporada %d)") % int(leg.get("anio", 0))
		h.button_pressed = Meta.heredar_proximo
		h.toggled.connect(func(si: bool) -> void: Meta.heredar_proximo = si)
		fila.add_child(h)

func _elegir_dificultad(k: String) -> void:
	_dificultad = k
	for b: Button in _fila_dificultad.get_children():
		b.button_pressed = (b.text == String((Datos.tabla("DIF") as Dictionary).get(k, {}).get("n", "")))

func _pintar_base() -> void:
	for i in _fila_base.get_child_count():
		(_fila_base.get_child(i) as Button).button_pressed = (i == 1) == Datos.base_real
	if Datos.base_real:
		_lbl_base.text = Idiomas.t("Clubes, ligas y jugadores reales de «%s», con sus caras y con los nombres cubiertos (C0lo-C0lo). Solo para uso privado.") % Datos.nombre_pack()
	else:
		_lbl_base.text = Idiomas.t("384 clubes y 24 ligas inventados, con jugadores generados. Es la base de la versión publicada.")

func _elegir_base(real: bool) -> void:
	Datos.usar_base_real(real)
	Datos.guardar_preferencia_base_real(Datos.base_real)
	_pintar_base()

func _construir_selector_base(raiz: VBoxContainer) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	raiz.add_child(fila)
	var lb := _texto(12, COL_SUAVE)
	lb.text = Idiomas.t("Base de datos")
	lb.custom_minimum_size = Vector2(90, 0)
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(lb)
	_fila_base = HBoxContainer.new()
	_fila_base.add_theme_constant_override("separation", 6)
	fila.add_child(_fila_base)
	for real: bool in [false, true]:
		var b := Button.new()
		b.text = Idiomas.t("Ficticia") if not real else Idiomas.t("Real (pack)")
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(110, 28)
		if real and not Datos.hay_pack_real():
			b.disabled = true
			b.tooltip_text = Idiomas.t("No hay ningún pack real instalado. Copia un archivo pack_real.json en:\n%s") \
				% ProjectSettings.globalize_path("user://")
		b.pressed.connect(func() -> void: _elegir_base(real))
		_fila_base.add_child(b)
	_lbl_base = _texto(11, COL_SUAVE)
	_lbl_base.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(_lbl_base)
	_pintar_base()

func _construir_datos_dt(raiz: VBoxContainer) -> void:
	var fila_nombre := HBoxContainer.new()
	fila_nombre.add_theme_constant_override("separation", 8)
	raiz.add_child(fila_nombre)
	var ln := _texto(12, COL_SUAVE)
	ln.text = Idiomas.t("Tu nombre")
	ln.custom_minimum_size = Vector2(90, 0)
	ln.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila_nombre.add_child(ln)
	_campo_nombre = LineEdit.new()
	_campo_nombre.text = Idiomas.t("Míster")
	_campo_nombre.custom_minimum_size = Vector2(240, 32)
	_campo_nombre.placeholder_text = Idiomas.t("Nombre del entrenador")
	fila_nombre.add_child(_campo_nombre)

	var fila_dif := HBoxContainer.new()
	fila_dif.add_theme_constant_override("separation", 8)
	raiz.add_child(fila_dif)
	var ld := _texto(12, COL_SUAVE)
	ld.text = Idiomas.t("Dificultad")
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
		b.text = Idiomas.t("%s  %s\n%s\nMeta: %s") % [String(r[1]), String(r[2]), String(r[3]), String(r[4])]
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
	cerrar.text = Idiomas.t("Volver")
	cerrar.pressed.connect(capa.queue_free)
	v.add_child(cerrar)

func _avisar(texto: String) -> void:
	_lbl_estado.text = texto
	_lbl_estado.visible = true
