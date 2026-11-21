class_name PanelesVistas3D
extends RefCounted
## LAS PESTAÑAS CON VISTA 3D DEL MENÚ DEL PARTIDO (17-11-2026, Auditoría: Uniforme, Estadio y Cámara «como en el PES»). Presupuesto: cada vista se dibuja
## UNA vez y queda quieta, y nada se monta hasta abrir su pestaña.
##   Uniforme → el futbolista grande de TU club con el uniforme elegido y, al lado, el del rival con el suyo (`RetratoJugador3D`); si los colores
##              chocan, lo avisa y propone el que no choca.
##   Estadio  → la foto del estadio real del partido (`FotosEstadioMenu`: tribunas con los colores del club, la luz de la hora y el clima) con
##              sus datos: nombre, aforo, césped, techo, hora y clima.
##   Cámara   → los mismos botones de siempre (`PanelesMenuPartido.camara`) con la foto de cada distancia en lugar del dibujo.
## Sin pantalla (pruebas) quedan los paneles de siempre, con sus dibujos.

## El dibujo del césped (los patrones de `Club._CESPED` / `CespedTextura`), en palabras.
const CESPED := {"rayas": "A rayas", "rayasH": "A rayas transversales", "damero": "Damero", "damGrande": "Damero grande", "circulos": "En círculos",
	"circular": "En círculos", "diagonal": "En diagonal", "rombos": "En rombos", "liso": "Liso", "espiga": "En espiga", "abanico": "En abanico"}
const UMBRAL_CHOQUE := 0.32   ## distancia de color (RGB, 0-1,7) por debajo de la cual dos camisetas se confunden desde la cámara de la tele
const _RUTA_FOTOS_ESTADIO_MENU := "res://ui/partido_menu/fotos_estadio_menu.gd"
const _RUTA_RETRATO_JUGADOR3D := "res://ui/partido_menu/retrato_jugador3d.gd"

## El perfil del estadio del club local (el diseñado por ti si es el tuyo; si no, el suyo de siempre).
static func perfil(m: MenuPartido) -> Dictionary:
	var pr := m.get_parent()
	var mundo = pr.get("mundo") if pr != null else null
	if mundo != null and mundo.has_method("perfil_estadio_de"):
		return mundo.perfil_estadio_de(m.partido.local)
	return m.partido.local.perfil_estadio()

static func choca(a: Color, b: Color) -> bool:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() < UMBRAL_CHOQUE

## El techo del perfil puede venir como sí/no o como el tipo de techo («parcial», «total»…).
static func _con_techo(t: Variant) -> bool:
	if t is bool:
		return t
	return t is String and String(t) != "" and String(t) != "no" and String(t) != "sin"

static func rival(m: MenuPartido) -> Club:
	return m.partido.visita if m.partido.local == m.mio else m.partido.local

# ---------------------------------------------------------------- UNIFORME
static func uniforme(m: MenuPartido, v: VBoxContainer) -> void:
	var rv := rival(m)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 30)
	v.add_child(fila)
	## A la izquierda, las tres opciones como botones con sus dos colores.
	var opciones := VBoxContainer.new()
	opciones.add_theme_constant_override("separation", 10)
	opciones.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(opciones)
	var actual := String(OpcionesPartido.leer("uniforme_partido", "titular"))
	var aviso := EstiloAvanzar.etiqueta("", 17, Color("ffd36b"))
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var mio3d: Control = load(_RUTA_RETRATO_JUGADOR3D).crear(m.mio, m.estrella(m.mio), [] if actual == "titular" else PanelesMenuPartido.colores_uniforme(m.mio, actual), 0.3)
	var botones: Dictionary = {}
	for par: Array in PanelesMenuPartido.UNIFORMES:
		var clave := String(par[0])
		var b := _boton_uniforme(m.mio, clave, Idiomas.t(String(par[1])))
		b.button_pressed = clave == actual
		botones[clave] = b
		b.pressed.connect(func() -> void:
			for k: String in botones:
				(botones[k] as Button).set_pressed_no_signal(k == clave)
			OpcionesPartido.guardar("uniforme_partido", clave)
			m.poner_uniforme(clave)
			if mio3d != null:
				mio3d.call("vestir", [] if clave == "titular" else PanelesMenuPartido.colores_uniforme(m.mio, clave))
			_avisar_choque(m, rv, clave, aviso, botones))
		opciones.add_child(b)
	opciones.add_child(aviso)
	PanelesDatos.uniforme(m, opciones)
	## En el centro, tu jugador con el uniforme elegido; a la derecha, el del rival con su titular.
	for lado in 2:
		var club: Club = m.mio if lado == 0 else rv
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		fila.add_child(col)
		var r3d: Control = mio3d if lado == 0 else load(_RUTA_RETRATO_JUGADOR3D).crear(rv, m.estrella(rv), [], -0.3)
		if r3d != null:
			r3d.custom_minimum_size = Vector2(Tema.letra(300), Tema.letra(430))
			col.add_child(r3d)
			r3d.call_deferred("montar")
		var n := EstiloAvanzar.etiqueta(Nombres.visible(club.nombre).to_upper(), 20, Color.WHITE, true)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(n)
	_avisar_choque(m, rv, actual, aviso, botones)

static func _boton_uniforme(c: Club, clave: String, texto: String) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.text = texto
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(Tema.letra(240), Tema.letra(54))
	b.add_theme_font_override("font", EstiloAvanzar.fuente_titulo())
	b.add_theme_font_size_override("font_size", Tema.letra(22))
	var cols := PanelesMenuPartido.colores_uniforme(c, clave)
	b.icon = _muestra(cols[0], cols[1])
	b.add_theme_constant_override("h_separation", 14)
	b.add_theme_stylebox_override("normal", PanelesMenuPartido._estilo(Color(1, 1, 1, 0.06)))
	var sel := PanelesMenuPartido._estilo(Color(PanelesMenuPartido.ROJO, 0.18))
	sel.border_color = PanelesMenuPartido.ROJO
	sel.border_width_left = 5
	for k in ["pressed", "hover_pressed", "hover"]:
		b.add_theme_stylebox_override(k, sel)
	var foco := sel.duplicate() as StyleBoxFlat
	foco.border_color = PreviaMenuPartido.ORO
	foco.set_border_width_all(3)
	b.add_theme_stylebox_override("focus", foco)
	return b

## La muestra de un uniforme: la camiseta partida en sus dos colores.
static func _muestra(c1: Color, c2: Color) -> Texture2D:
	var img := Image.create(36, 36, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(2, 2, 32, 32), Color(1, 1, 1, 0.85))
	img.fill_rect(Rect2i(4, 4, 28, 28), c1)
	img.fill_rect(Rect2i(15, 4, 6, 28), c2)
	return ImageTexture.create_from_image(img)

## Si el uniforme elegido se confunde con el titular del rival, lo dice y propone el primero que no choca.
static func _avisar_choque(m: MenuPartido, rv: Club, clave: String, aviso: Label, _botones: Dictionary) -> void:
	var suyo := PanelesMenuPartido.colores_uniforme(rv, "titular")
	if not choca(PanelesMenuPartido.colores_uniforme(m.mio, clave)[0], suyo[0]):
		aviso.text = Idiomas.t("No se confunde con el rival.")
		aviso.add_theme_color_override("font_color", Color("7fd99a"))
		return
	var propuesta := ""
	for par: Array in PanelesMenuPartido.UNIFORMES:
		if not choca(PanelesMenuPartido.colores_uniforme(m.mio, String(par[0]))[0], suyo[0]):
			propuesta = Idiomas.t(String(par[1]))
			break
	aviso.add_theme_color_override("font_color", Color("ffd36b"))
	aviso.text = Idiomas.t("⚠ Se confunde con el rival: usa «%s».") % propuesta if propuesta != "" else Idiomas.t("⚠ Se confunde con el rival.")

# ---------------------------------------------------------------- ESTADIO
static func estadio(m: MenuPartido, v: VBoxContainer) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 34)
	v.add_child(fila)
	var izq := VBoxContainer.new()
	izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	izq.add_theme_constant_override("separation", 10)
	fila.add_child(izq)
	var local := m.partido.local
	var pf := perfil(m)
	izq.add_child(EstiloAvanzar.etiqueta(Nombres.visible(local.estadio_nombre) if local.estadio_nombre != "" else Idiomas.t("Estadio de %s") % local.nombre, 34, Color.WHITE, true))
	var datos := GridContainer.new()
	datos.columns = 2
	datos.add_theme_constant_override("h_separation", 22)
	datos.add_theme_constant_override("v_separation", 8)
	izq.add_child(datos)
	var clima := "%s %s" % [Clima.icono(m.clima), String(m.clima.get("texto", ""))] if not m.clima.is_empty() else Idiomas.t("Sin datos")
	for par: Array in [["Aforo", Idiomas.t("%d espectadores") % int(pf.get("aforo", local.estadio_aforo))],
			["Césped", Idiomas.t(String(CESPED.get(String(pf.get("cesped", "rayas")), "A rayas")))], ["Techo", Idiomas.t("Sí") if _con_techo(pf.get("techo", false)) else Idiomas.t("No")],
			["Hora", PreviaMenuPartido.hora(m.partido, m.clima)], ["Clima del partido", clima]]:
		datos.add_child(EstiloAvanzar.etiqueta(Idiomas.t(String(par[0])).to_upper(), 15, PreviaMenuPartido.SUAVE))
		datos.add_child(EstiloAvanzar.etiqueta(String(par[1]), 22, Color.WHITE, true))
	PanelesDatos.estadio(m, izq, pf)
	PanelesMenuPartido.nota(izq, "El clima lo pone la ciudad y la época del año; el estadio es el del equipo local.")
	var foto := MiniaturaMenu.new()
	foto.tipo = MiniaturaMenu.Tipo.ESTADIO
	foto.custom_minimum_size = Vector2(Tema.letra(640), Tema.letra(360))
	fila.add_child(foto)
	_pedir_fotos(m, func(f: Dictionary) -> void:
		if is_instance_valid(foto):
			foto.foto = f.get("estadio"))

# ---------------------------------------------------------------- CÁMARA
static func camara(m: MenuPartido, v: VBoxContainer) -> void:
	var antes := v.get_child_count()   ## los hijos del panel anterior aún no se han borrado: solo cuentan los nuevos
	PanelesMenuPartido.camara(m, v)
	var nuevos: Array = []
	for k in range(antes, v.get_child_count()):
		nuevos.append_array(v.get_child(k).find_children("*", "MiniaturaMenu", true, false))
	var minis: Dictionary = {}
	var i := 0
	for n in nuevos:
		if i >= PanelesMenuPartido.CAMARAS.size():
			break
		minis[String(PanelesMenuPartido.CAMARAS[i][0])] = n
		(n as Control).custom_minimum_size.y = Tema.letra(160)
		i += 1
	PanelesDatos.camara(v)
	_pedir_fotos(m, func(f: Dictionary) -> void:
		for k: String in minis:
			if is_instance_valid(minis[k]):
				(minis[k] as MiniaturaMenu).foto = f.get(k))

static func _pedir_fotos(m: MenuPartido, al_terminar: Callable) -> void:
	load(_RUTA_FOTOS_ESTADIO_MENU).pedir(m, m.partido.local, perfil(m), load(_RUTA_FOTOS_ESTADIO_MENU).luz_de(m.clima), al_terminar, m.estrella(m.partido.local))
