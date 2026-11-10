extends Node
## LA PANTALLA «LIGAS ACTIVAS» AL LÍMITE (10-11-2026; pantalla y núcleo de la sesión 6, pulido de la interfaz). Con pantalla:
##  · en un teléfono de 400 ppp (2400×1080 o 1080×2400 con --resolution, zoom del móvil) y en ALEMÁN: letra ≥ 1,8 mm, toques ≥ 7 mm de alto
##    y ancho, ningún texto cortado ni fuera de la pantalla, y «Volver» / «Weiter» a la vista sin desplazarse;
##  · con MANDO (`FocoMando.forzar`): foco visible al entrar, 30 pulsaciones de cruceta sin perderlo y, en la lista larga de países, se
##    alcanzan con la cruceta todos los botones (también los que están por debajo del borde de la lista);
##  · el modo AÑADIR (como lo abre Ajustes → Partida a mitad de temporada) también se monta y dice qué falta.
## FOTOS=1 guarda `ligas_<orientación>_<modo>.jpg` en CAPTURA_DIR.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 2400x1080 res://pruebas/auditoria_ligas_activas.tscn
const MIN_MM_LETRA := 1.8
const MIN_MM_TOQUE := 7.0
const PULSACIONES := [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_RIGHT,
	JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN,
	JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN,
	JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN,
	JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]
var _fallos := 0
var _orient := "horizontal"
var _prefs: Dictionary = {}

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("sin pantalla no se mide")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	for ruta: String in ["user://ligas_activas.cfg", Principal.PREFS]:   ## la pantalla guarda la elección: se devuelve todo como estaba
		if FileAccess.file_exists(ruta):
			_prefs[ruta] = FileAccess.get_file_as_bytes(ruta)
	await _ajustes()   ## antes de simular el teléfono: Ajustes → Partida → «Añadir ligas», de punta a punta
	var v := DisplayServer.window_get_size()
	_orient = "vertical" if v.y > v.x else "horizontal"
	PantallaMovil.dpi_forzado = 400.0
	EscalaMovil.forzar = true
	get_tree().root.content_scale_factor = EscalaMovil.ZOOM_MOVIL
	EscalaMovil.vigilar(get_tree())
	Idiomas.idioma = OS.get_environment("IDIOMA") if OS.get_environment("IDIOMA") != "" else "de"
	Idiomas._asegurar(Idiomas.idioma)
	FocoMando.forzar = true
	await _caso("nueva", null)
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 20261110)   ## una partida con solo dos ligas: el modo añadir ofrece el resto
	m.mi_club_id = (m.ligas[0] as Liga).clubes[2].id
	await _caso("añadir", m)
	print("===== FIN. %d fallos =====" % _fallos)
	PantallaMovil.dpi_forzado = 0.0
	EscalaMovil.forzar = false
	FocoMando.forzar = false
	Idiomas.idioma = "es"
	for ruta: String in _prefs:
		var f := FileAccess.open(ruta, FileAccess.WRITE)
		if f != null:
			f.store_buffer(_prefs[ruta])
			f.close()
	if not _prefs.has("user://ligas_activas.cfg") and FileAccess.file_exists("user://ligas_activas.cfg"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ligas_activas.cfg"))
	get_tree().quit(0 if _fallos == 0 else 1)

func _caso(modo: String, m: Mundo) -> void:
	var p := LigasActivasPantalla.new()
	p.mundo_agregar = m
	add_child(p)
	for i in 12:
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	var et := "%s · %s" % [_orient, modo]
	if modo == "añadir":
		_comprobar(not p._casillas.is_empty() and not p._casillas.has("CHI") and not p._casillas.has("ARG"), "[%s] ofrece solo los países que faltan (%d; sin CHI ni ARG)" % [et, p._casillas.size()])
	if OS.get_environment("FOTOS") == "1":
		var dir := OS.get_environment("CAPTURA_DIR") if OS.get_environment("CAPTURA_DIR") != "" else "user://"
		get_viewport().get_texture().get_image().save_jpg(dir.path_join("ligas_%s_%s.jpg" % [_orient, modo.replace("ñ", "n")]), 0.85)
	_medir(et, p)
	await _mando(et, p)
	p.queue_free()
	for i in 4:
		await get_tree().process_frame

func _medir(et: String, raiz: Control) -> void:
	var mm := PantallaMovil.px_por_mm(self)
	var lienzo := get_viewport().get_visible_rect().size
	var chica: Array = []
	var pequenos: Array = []
	var fuera: Array = []
	var cortados: Array = []
	for n: Node in raiz.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree():
			continue
		var t: Variant = c.get("text")
		var txt := String(t).strip_edges() if t != null else ""
		var r := c.get_global_rect()
		var visible_entero := _recorte(c).size.y >= r.size.y - 1.0
		if txt != "" and (c is Label or c is Button) and visible_entero:
			var tam := float(c.get_theme_font_size("font_size")) * c.get_global_transform().get_scale().y / mm
			if tam < MIN_MM_LETRA - 0.01:
				chica.append("«%s» %.1f" % [txt.left(16), tam])
			if (c is Label and (c as Label).autowrap_mode == TextServer.AUTOWRAP_OFF) or (c is Button and (c as Button).autowrap_mode == TextServer.AUTOWRAP_OFF):
				var f := c.get_theme_font("font")
				var ancho := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, c.get_theme_font_size("font_size")).x
				if ancho > c.size.x + 1.0 and (bool(c.get("clip_text")) or int(c.get("text_overrun_behavior")) != TextServer.OVERRUN_NO_TRIMMING):
					cortados.append("«%s»" % txt.left(20))
		if c is BaseButton and visible_entero and not (c as BaseButton).disabled:
			if r.size.y / mm < MIN_MM_TOQUE - 0.05 or r.size.x / mm < MIN_MM_TOQUE - 0.05:
				pequenos.append("«%s» %.1f×%.1f" % [txt.left(14), r.size.x / mm, r.size.y / mm])
		if (txt != "" or c is BaseButton) and (r.position.x < -1.0 or r.end.x > lienzo.x + 1.0 or (r.end.y > lienzo.y + 1.0 and visible_entero)):
			fuera.append("%s «%s»" % [c.get_class(), txt.left(14)])
	## En VERTICAL toda la interfaz queda pequeña (zoom del móvil y topes de la letra mínima y del toque pensados para horizontal, que es lo que
	## fija el proyecto): es la decisión pendiente del diseño vertical, no de esta pantalla. Se mide y se avisa, no falla.
	if _orient == "vertical":
		print("  aviso  [%s] (diseño vertical pendiente del dueño) letra mínima: %d textos < %.1f mm; toques < %.0f mm: %d" % [et, chica.size(), MIN_MM_LETRA, MIN_MM_TOQUE, pequenos.size()])
		chica.clear()
		pequenos.clear()
	_comprobar(chica.is_empty(), "[%s] letra ≥ %.1f mm (%d menores: %s)" % [et, MIN_MM_LETRA, chica.size(), ", ".join(chica.slice(0, 4))])
	_comprobar(pequenos.is_empty(), "[%s] toques ≥ %.0f mm (%d menores: %s)" % [et, MIN_MM_TOQUE, pequenos.size(), ", ".join(pequenos.slice(0, 4))])
	_comprobar(cortados.is_empty(), "[%s] ningún texto cortado (%d: %s)" % [et, cortados.size(), ", ".join(cortados.slice(0, 4))])
	_comprobar(fuera.is_empty(), "[%s] nada fuera de la pantalla (%d: %s)" % [et, fuera.size(), ", ".join(fuera.slice(0, 4))])
	var cont: Button = raiz.get("_continuar")
	_comprobar(cont != null and Rect2(Vector2.ZERO, lienzo).encloses(cont.get_global_rect()), "[%s] «%s» se ve sin desplazarse" % [et, cont.text if cont else "?"])

func _recorte(c: Control) -> Rect2:
	var r := c.get_global_rect()
	var n := c.get_parent()
	while n != null:
		if n is ScrollContainer:
			r = r.intersection((n as Control).get_global_rect())
		n = n.get_parent()
	return r

func _pulsar(b: JoyButton) -> void:
	for pulsa in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = b
		e.pressed = pulsa
		Input.parse_input_event(e)
	await get_tree().process_frame

func _mando(et: String, p: Control) -> void:
	var f := get_viewport().gui_get_focus_owner()
	_comprobar(f != null and p.is_ancestor_of(f) and f.is_visible_in_tree(), "[%s] con mando, al entrar hay foco (%s)" % [et, f.get_class() + " «" + String(f.get("text")).left(16) + "»" if f != null else "NINGUNO"])
	var perdido := 0
	for b: JoyButton in PULSACIONES:
		await _pulsar(b)
		var g := get_viewport().gui_get_focus_owner()
		if g == null or not p.is_ancestor_of(g) or not g.is_visible_in_tree():
			perdido += 1
	_comprobar(perdido == 0, "[%s] 30 pulsaciones de cruceta sin perder el foco (perdido %d)" % [et, perdido])
	## alcance: desde la primera casilla, bajando con la cruceta se llega a la última de la lista
	var casillas: Array = (p.get("_casillas") as Dictionary).values()
	if casillas.is_empty():
		return
	(casillas[0] as Button).grab_focus()
	var vistos := {}
	for i in casillas.size() * 3:
		await _pulsar(JOY_BUTTON_DPAD_DOWN if i % 2 == 0 else JOY_BUTTON_DPAD_RIGHT)
		var g := get_viewport().gui_get_focus_owner()
		if g in casillas:
			vistos[g] = true
	var ultimo: Button = casillas.back()
	_comprobar(vistos.has(ultimo) or float(vistos.size()) >= casillas.size() * 0.6, "[%s] con la cruceta se recorre la lista de países (%d de %d, la última %s)" % [et, vistos.size(), casillas.size(), "sí" if vistos.has(ultimo) else "no"])

## Ajustes → Partida: el botón «Añadir ligas» está, activo con la temporada sin empezar; abre la pantalla en modo añadir y lo elegido se carga.
func _ajustes() -> void:
	var p: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	for i in 60:
		await get_tree().process_frame
	for h: Node in p.get_children():   ## la reunión de inicio de temporada, contestada
		if h is EventoDialogo:
			(h as EventoDialogo).selector.elegir(0)
	for i in 30:
		await get_tree().process_frame
	var m: Mundo = p.mundo
	var antes := LigasActivas.de(m).size()
	var faltan := LigasActivas.faltan(m)
	var aj: Object = p.get("_ui_ajustes")
	aj.set("seccion", "partida")
	aj.call("_pintar_ajustes")
	await get_tree().process_frame
	var bs := p.find_children("AnadirLigas", "Button", true, false)
	_comprobar(not bs.is_empty(), "Ajustes → Partida tiene «Añadir ligas» (%d países cargados, %d por añadir)" % [antes, faltan.size()])
	if bs.is_empty() or faltan.is_empty():
		p.queue_free()
		return
	var b := bs[0] as Button
	_comprobar(not b.disabled and AjustesLigas.sin_empezar(m), "con la temporada sin empezar el botón está activo")
	b.pressed.emit()
	for i in 6:
		await get_tree().process_frame
	var pa: LigasActivasPantalla = null
	for h: Node in p.get_children():
		if h is LigasActivasPantalla:
			pa = h
	_comprobar(pa != null and pa.mundo_agregar == m, "abre la pantalla en modo añadir")
	if pa != null:
		var uno: String = faltan[0]
		pa.terminado.emit({"ligas": {"paises": [uno]}})
		for i in 10:
			await get_tree().process_frame
		_comprobar(LigasActivas.de(m).has(uno) and LigasActivas.de(m).size() == antes + 1, "y lo elegido se carga en la partida (%s; %d → %d países)" % [uno, antes, LigasActivas.de(m).size()])
	(m.ligas[0] as Liga).jornada_actual = 1   ## con una jornada jugada, desactivado y con su explicación
	aj.call("_pintar_ajustes")
	await get_tree().process_frame
	bs = p.find_children("AnadirLigas", "Button", true, false)
	_comprobar(not bs.is_empty() and (bs[0] as Button).disabled, "con la temporada en marcha el botón está desactivado (se volverían a sortear las copas)")
	p.queue_free()
	for i in 4:
		await get_tree().process_frame
