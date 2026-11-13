extends Node
## LAS PANTALLAS DE GESTIÓN EN EL TELÉFONO (10-11-2026, orden 26: el MÓVIL es un punto débil). Lo mismo que se midió en el HUD del
## partido (`captura_tactil_movil`), ahora en la gestión: un teléfono de 400 ppp (6,5" a 2400×1080, en horizontal, como fija el
## proyecto), con el zoom de interfaz del móvil (`EscalaMovil.ZOOM_MOVIL`) y en ALEMÁN, el idioma de textos más largos. En el menú,
## plantel, táctica, mercado, finanzas, competiciones (pestaña y ficha), selección y ajustes:
##  · letra: cada texto visible mide al menos `MIN_MM_LETRA` mm (alto de la letra, el tamaño de la fuente en pantalla);
##  · toque: cada botón, desplegable, casilla o campo visible y activo mide al menos `MIN_MM_TOQUE` mm de alto y de ancho;
##  · solapes: dos controles que se tocan no se pisan (se tocaría el que no se quería);
##  · textos cortados: lo que recorta su texto (con «…» o sin más) y no cabe ni encogido (`TextoQueCabe`);
##  · nada se sale de la pantalla por los lados.
## Cada pantalla con un club de otro país (orden 34). FOTOS=1 guarda `gm_<pantalla>.jpg` en CAPTURA_DIR.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 2400x1080 res://pruebas/auditoria_gestion_movil.tscn
var DPI := 400.0 if OS.get_environment("DPI") == "" else float(OS.get_environment("DPI"))   ## DPI=267 con 720x1600: el mismo teléfono de 6,5"
const MIN_MM_LETRA := 1.8    ## 11 pt de Apple (≈ 1,8 mm) o 12 sp de Material (≈ 1,9 mm): lo más pequeño que recomiendan para leer
const MIN_MM_TOQUE := 7.0    ## Apple 44 pt ≈ 7 mm; Material 48 dp ≈ 7,6 mm (el mismo `EscalaMovil.MIN_MM_TOQUE`)
const PANTALLAS := ["Inicio", "Mi plantel", "Táctica", "Mercado", "Finanzas", "Clubes", "competición", "Selección", "Ajustes", "Calendario"]
const MIN_ALTO_UTIL := 0.75   ## en los menús, parte del alto de la pantalla que queda para el contenido (con la cabecera grande: ~0,6)
const EJEMPLOS := 4          ## cuántos casos se nombran por comprobación
var _p: Node
var _fallos := 0
var _clubes: Array = []
var _resumen: Array = []
var _alto_util: Array = []
## Las preferencias del jugador tal como estaban: la principal las guarda (con el idioma alemán y el zoom del móvil de esta prueba) y las
## pruebas siguientes arrancaban en alemán (`ate_atajos_menus` buscaba «Táctica» y encontraba «Taktik»). Se devuelven al terminar.
var _prefs_antes: Variant = null

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("sin pantalla no se mide (el tamaño de la ventana es el del teléfono)")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	if FileAccess.file_exists(Principal.PREFS):
		_prefs_antes = FileAccess.get_file_as_bytes(Principal.PREFS)
	PantallaMovil.dpi_forzado = DPI
	EscalaMovil.forzar = true
	if OS.get_environment("CABECERA") == "grande":   ## para las capturas del antes (y comprobar que el interruptor la devuelve)
		PantallaMenu.compacta_pref = false
	Idiomas.idioma = OS.get_environment("IDIOMA") if OS.get_environment("IDIOMA") != "" else "de"
	Idiomas._asegurar(Idiomas.idioma)
	EscalaMovil.poner(get_tree(), EscalaMovil.ZOOM_MOVIL)
	EscalaMovil.vigilar(get_tree())
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 60:
		await get_tree().process_frame
	Idiomas.idioma = OS.get_environment("IDIOMA") if OS.get_environment("IDIOMA") != "" else "de"   ## las preferencias guardadas lo pisan al cargar
	Idiomas._asegurar(Idiomas.idioma)
	_p.call("_refrescar")
	PantallaMenu.compacta_pref = OS.get_environment("CABECERA") != "grande"   ## las preferencias guardadas también lo pisan
	_p.set("_zoom_interfaz", EscalaMovil.ZOOM_MOVIL)
	EscalaMovil.poner(get_tree(), EscalaMovil.ZOOM_MOVIL)
	_elegir_clubes()
	var solo := OS.get_environment("SOLO")
	for i in PANTALLAS.size():
		var nombre: String = PANTALLAS[i]
		if solo != "" and not nombre in solo.split(","):
			continue
		await _con_club(_clubes[i % _clubes.size()])
		await _auditar_pantalla(nombre)
	print("RESUMEN (px/mm %.2f · lienzo %s · idioma %s)" % [PantallaMovil.px_por_mm(self), get_viewport().get_visible_rect().size, Idiomas.idioma])
	for r: String in _resumen:
		print("  " + r)
	if not _alto_util.is_empty():
		print("  alto útil en los menús: %s" % ", ".join(_alto_util.map(func(x: float) -> String: return "%.0f %%" % (x * 100.0))))
	print("===== FIN. %d fallos =====" % _fallos)
	PantallaMovil.dpi_forzado = 0.0
	EscalaMovil.forzar = false
	PantallaMenu.compacta_pref = true
	Idiomas.idioma = "es"
	_devolver_preferencias()
	get_tree().quit(0 if _fallos == 0 else 1)

func _devolver_preferencias() -> void:
	if _prefs_antes is PackedByteArray:
		var f := FileAccess.open(Principal.PREFS, FileAccess.WRITE)
		if f != null:
			f.store_buffer(_prefs_antes)
			f.close()
	elif FileAccess.file_exists(Principal.PREFS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Principal.PREFS))

## Tres clubes de tres países distintos (el del jugador y dos más).
func _elegir_clubes() -> void:
	var m: Mundo = _p.mundo
	_clubes = [m.mi_club()]
	var paises := {(m.mi_club() as Club).pais: true}
	for l: Liga in m.ligas:
		if _clubes.size() >= 3:
			break
		if l.clubes.is_empty() or paises.has((l.clubes[0] as Club).pais):
			continue
		var c: Club = l.clubes[(_clubes.size() * 4 + 2) % l.clubes.size()]
		paises[c.pais] = true
		_clubes.append(c)

func _con_club(c: Club) -> void:
	var m: Mundo = _p.mundo
	if m.mi_club() != c:
		m.tomar_el_mando(c.id)
		m.prensa.eventos_vistos.append("directiva:%d" % m.anio)
		_p.call("_refrescar")
	for i in 20:
		await get_tree().process_frame
	await _cerrar_capas()

func _cerrar_capas() -> void:
	for h: Node in _p.get_children():
		if h is PantallaMenu and not (h as PantallaMenu).cerrando():
			(h as PantallaMenu).cerrar()   ## devuelve el contenido de la pestaña a su sitio (si se libera sin más, se pierde)
		elif h is EventoPantallaCompleta or h is Competicion or h.name == "CapaTutorial":
			h.queue_free()
	for i in 20:
		await get_tree().process_frame

func _auditar_pantalla(nombre: String) -> void:
	if nombre == "competición":
		_p.call("_abrir_competicion")
	elif nombre != "Inicio":
		_p.call("_ir_a_pestana", nombre)
	if nombre == "Ajustes":   ## la categoría «Pantalla»: la del interruptor de la cabecera
		## (13-11) Se PULSA la pestaña, como el jugador (antes se ponía `seccion` a mano y la cabecera se quedaba en «Sonido»).
		var pulsada := false
		for b: Node in _p.find_children("*", "Button", true, false):
			if b is Button and (b as Button).is_visible_in_tree() and (b as Button).text.begins_with("🖥"):
				(b as Button).pressed.emit()
				pulsada = true
				break
		if not pulsada:
			var aj: Object = _p.get("_ui_ajustes")
			aj.set("seccion", "pantalla")
			aj.call("_pintar_ajustes")
	for i in 30:
		await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	for t: Node in _p.find_children("CapaTutorial", "", false, false):
		t.queue_free()   ## la tarjeta del tutorial no es de la pantalla (y se pliega sola)
	await get_tree().process_frame
	var capa: Control = GuardianFoco.capa_arriba(_p)
	var raiz: Control = capa if capa != null else _p
	var club: Club = (_p.mundo as Mundo).mi_club()
	var etiqueta := "%s · %s (%s)" % [nombre, club.nombre, club.pais]
	if OS.get_environment("FOTOS") == "1":
		var dir := OS.get_environment("CAPTURA_DIR") if OS.get_environment("CAPTURA_DIR") != "" else "user://"
		get_viewport().get_texture().get_image().save_jpg(dir.path_join("gm_%s.jpg" % nombre.replace(" ", "_").replace("í", "i").replace("ó", "o")), 0.85)
	_medir(etiqueta, raiz)
	if raiz is PantallaMenu:
		var cuerpo: Control = raiz.get("_cuerpo")
		var parte := cuerpo.size.y / get_viewport().get_visible_rect().size.y
		_alto_util.append(parte)
		_comprobar(parte >= MIN_ALTO_UTIL, "[%s] alto útil para el contenido: %.0f %% de la pantalla (mínimo %.0f %%, cabecera compacta %s)" % [etiqueta, parte * 100.0, MIN_ALTO_UTIL * 100.0, "SÍ" if PantallaMenu.compacta() else "NO"])
	if nombre == "Ajustes":
		_comprobar(not raiz.find_children("CabeceraCompacta", "Button", true, false).is_empty(), "[%s] está el interruptor «Cabecera compacta en el móvil»" % etiqueta)
	await _cerrar_capas()

## Lo visible de `raiz` que de verdad se ve en pantalla: dentro del lienzo y no recortado del todo por una zona de desplazamiento.
func _visibles(raiz: Control) -> Array:
	var lienzo := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	var r: Array = []
	for n: Node in raiz.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree() or c.modulate.a < 0.05 or c.get_viewport() != get_viewport():
			continue
		var rc := _recorte(c)
		if rc.size.x < 2.0 or rc.size.y < 2.0 or not lienzo.intersects(rc):
			continue
		r.append(c)
	return r

## El rectángulo del control que queda a la vista dentro de las zonas de desplazamiento que lo contienen.
func _recorte(c: Control) -> Rect2:
	var r := c.get_global_rect()
	var n := c.get_parent()
	while n != null and n != _p:
		if n is ScrollContainer or (n is Control and (n as Control).clip_contents):
			r = r.intersection((n as Control).get_global_rect())
		n = n.get_parent()
	return r

func _texto(c: Control) -> String:
	var t: Variant = c.get("text")
	return String(t).strip_edges() if t != null else ""

func _escala(c: Control) -> float:
	return c.get_global_transform().get_scale().y

func _medir(etiqueta: String, raiz: Control) -> void:
	var mm := PantallaMovil.px_por_mm(self)
	var lienzo := get_viewport().get_visible_rect().size
	var vis := _visibles(raiz)
	var chica: Array = []
	var menor := INF
	var pequenos: Array = []
	var cortados: Array = []
	var fuera: Array = []
	var toques: Array = []
	for c: Control in vis:
		var txt := _texto(c)
		if txt != "" and (c is Label or c is Button or c is LineEdit or c is RichTextLabel):
			var tam := float(c.get_theme_font_size("normal_font_size" if c is RichTextLabel else "font_size")) * _escala(c) / mm
			menor = minf(menor, tam)
			if tam < MIN_MM_LETRA - 0.01:
				chica.append("«%s» %.1f" % [txt.left(18).replace("\n", " "), tam])
			if _cortado(c):
				cortados.append("«%s»" % txt.left(24).replace("\n", " "))
		var rc := c.get_global_rect()
		if (rc.position.x < -1.0 or rc.end.x > lienzo.x + 1.0) and (txt != "" or c is BaseButton) and _recorte(c).size.x >= rc.size.x - 1.0:
			fuera.append("%s «%s»" % [c.get_class(), txt.left(16)])
		if _tocable(c):
			toques.append(c)
			var r := _recorte(c)
			if r.size.y >= rc.size.y - 1.0 and r.size.x >= rc.size.x - 1.0:   ## solo los que se ven enteros (no a medias en el borde de una lista)
				var alto := rc.size.y * _escala(c) / _escala(c) / mm
				var ancho := rc.size.x / mm
				if alto < MIN_MM_TOQUE - 0.05 or ancho < MIN_MM_TOQUE - 0.05:
					pequenos.append("%s «%s» %.1f×%.1f" % [c.get_class(), (txt if txt != "" else String(c.name)).left(14).replace("\n", " "), ancho, alto])
	var solapes: Array = []
	for i in toques.size():
		var a: Control = toques[i]
		var ra := _recorte(a).grow(-1.5)
		for j in range(i + 1, toques.size()):
			var b: Control = toques[j]
			if a.is_ancestor_of(b) or b.is_ancestor_of(a):
				continue
			if ra.intersects(_recorte(b).grow(-1.5)):
				solapes.append("«%s» y «%s»" % [_texto(a).left(12) if _texto(a) != "" else String(a.name), _texto(b).left(12) if _texto(b) != "" else String(b.name)])
	_comprobar(chica.is_empty(), "[%s] la letra mide ≥ %.1f mm (%d menores: %s)" % [etiqueta, MIN_MM_LETRA, chica.size(), ", ".join(chica.slice(0, EJEMPLOS))])
	_comprobar(pequenos.is_empty(), "[%s] lo que se toca mide ≥ %.0f mm (%d de %d menores: %s)" % [etiqueta, MIN_MM_TOQUE, pequenos.size(), toques.size(), ", ".join(pequenos.slice(0, EJEMPLOS))])
	_comprobar(solapes.is_empty(), "[%s] lo que se toca no se pisa (%d: %s)" % [etiqueta, solapes.size(), ", ".join(solapes.slice(0, EJEMPLOS))])
	_comprobar(cortados.is_empty(), "[%s] ningún texto cortado (%d: %s)" % [etiqueta, cortados.size(), ", ".join(cortados.slice(0, EJEMPLOS))])
	_comprobar(fuera.is_empty(), "[%s] nada se sale por los lados (%d: %s)" % [etiqueta, fuera.size(), ", ".join(fuera.slice(0, EJEMPLOS))])
	_resumen.append("%-44s letra mínima %.1f mm · %d toques (%d pequeños) · %d solapes · %d cortados · %d fuera" % [etiqueta, menor if menor < INF else 0.0, toques.size(), pequenos.size(), solapes.size(), cortados.size(), fuera.size()])

func _tocable(c: Control) -> bool:
	if c is BaseButton:
		return not (c as BaseButton).disabled and c.mouse_filter != Control.MOUSE_FILTER_IGNORE
	return (c is LineEdit or c is SpinBox or c is HSlider or c is VSlider) and c.mouse_filter != Control.MOUSE_FILTER_IGNORE

## Recorta su texto («…» o corte) y el texto no cabe en una línea.
func _cortado(c: Control) -> bool:
	if not (c is Label or c is Button):
		return false
	var t := _texto(c)
	if t.ends_with("…") or t.ends_with("..."):   ## recortado a mano por el código (no es «Suchen…» de un campo vacío)
		return not (t.length() <= 12 and t.count(" ") == 0)
	if int(c.get("autowrap_mode")) != TextServer.AUTOWRAP_OFF:
		if c is Label and (c as Label).max_lines_visible > 0:
			return (c as Label).get_line_count() > (c as Label).max_lines_visible
		return false
	var recorta := bool(c.get("clip_text")) or int(c.get("text_overrun_behavior")) != TextServer.OVERRUN_NO_TRIMMING
	if not recorta:
		return false
	var f := c.get_theme_font("font")
	var tam := c.get_theme_font_size("font_size")
	var ancho := 0.0
	for linea in _texto(c).split("\n"):
		ancho = maxf(ancho, f.get_string_size(linea, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x)
	var hueco := c.size.x
	if c is Button:
		var b := c as Button
		var sb := b.get_theme_stylebox("normal")
		hueco -= (sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT)) if sb != null else 0.0
		if b.icon != null:
			hueco -= b.icon.get_width() + b.get_theme_constant("h_separation")
	return ancho > hueco + 1.0
