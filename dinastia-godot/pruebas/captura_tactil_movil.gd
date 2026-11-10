extends Node
## AUDITORÍA DE LOS CONTROLES TÁCTILES DEL PARTIDO EN UN TELÉFONO (10-11-2026, orden 26: partido en MÓVIL). Un teléfono de 400 ppp
## (6,5" a 2400×1080) en horizontal o en vertical (`--resolution`), tres partidos de clubes y países distintos (`PARTIDO=0|1|2`, orden
## 34), y en cada uno: medidas (tamaño de cada botón en mm, separación, área segura, solapes con el marcador y las fichas, cuánto tapan
## del centro), toques simulados (mover, correr, pasar, tirar, cambiar de jugador sin balón, pausa) y fotos con balón, en la banda y
## sin balón. Salida: CAPTURA_DIR/tactil_<orientación>_<partido>_<contexto>.jpg
##   herramientas/captura.sh res://pruebas/captura_tactil_movil.tscn   con   RESOLUCION=2400x1080 (o 1080x2400) PARTIDO=0
var DPI := 400.0 if OS.get_environment("DPI") == "" else float(OS.get_environment("DPI"))   ## DPI=267 con 720x1600: el mismo teléfono de 6,5"
const MIN_MM_GRANDE := 10.0      ## diámetro mínimo de Pase y Tiro (guías: ≥ 9 mm; juegos de fútbol de móvil ≈ 11-13 mm)
const MIN_MM_PEQUENO := 7.0      ## y del resto (Apple 44 pt ≈ 7 mm; Material 48 dp ≈ 7,6 mm)
const SEMILLAS := [20261110, 777, 4242]
const PAISES := ["CHI", "ARG", "ESP"]
var _n := 0
var _ui: CarreraJugadorUI
var _pj: PartidoJugable
var _ct: ControlesTactiles
var _fallos := 0
var _p0 := Vector3.ZERO
var _orient := ""
var _k := 0

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("sin pantalla no se captura nada")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	_k = clampi(int(OS.get_environment("PARTIDO")), 0, 2)
	var v := DisplayServer.window_get_size()
	_orient = "vertical" if v.y > v.x else "horizontal"
	PartidoJugable.con_ceremonia = false
	ControlesTactiles.forzar = true
	PantallaMovil.dpi_forzado = DPI
	EscalaMovil.forzar = true   ## como en el teléfono: el zoom de la interfaz del móvil (en vertical, el del lienzo estrecho)
	EscalaMovil.poner(get_tree(), EscalaMovil.ZOOM_MOVIL)
	AjustesTactil.restaurar()
	## Cada partido, un mundo de otro país (club y país distintos, orden 34): Chile, Argentina y España.
	var m := Mundo.new()
	m.generar([PAISES[_k]], SEMILLAS[_k])
	m.mi_club_id = ""
	m.carrera_jugador = CarreraJugador.crear(m, "Prueba Táctil", "MC", false, SEMILLAS[_k])
	CarreraJugadorUI.mundo = m
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)
	_ui.carrera = m.carrera_jugador

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _a_ventana(pos: Vector2) -> Vector2:
	return pos * (float(DisplayServer.window_get_size().x) / get_viewport().get_visible_rect().size.x)

func _toque(dedo: int, pos: Vector2, pulsa: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = dedo
	e.position = _a_ventana(pos)
	e.pressed = pulsa
	Input.parse_input_event(e)

func _arrastre(dedo: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = dedo
	e.position = _a_ventana(pos)
	Input.parse_input_event(e)

func _foto(contexto: String) -> void:
	var dir := OS.get_environment("CAPTURA_DIR") if OS.get_environment("CAPTURA_DIR") != "" else "user://"
	get_viewport().get_texture().get_image().save_jpg(dir.path_join("tactil_%s_%d_%s.jpg" % [_orient, _k, contexto]), 0.88)

## Las medidas de los botones visibles en este contexto.
func _auditar(contexto: String) -> void:
	var mm := PantallaMovil.px_por_mm(self)
	var lienzo := get_viewport().get_visible_rect().size
	var vis: Array = []
	for b: String in ControlesTactiles.BOTONES:
		if _ct.visible_ahora(b):
			vis.append(b)
	var texto := PackedStringArray()
	for b: String in vis:
		var d := _ct.radio_de(b) * 2.0 / mm
		texto.append("%s %.1f mm" % [b, d])
		var minimo := MIN_MM_GRANDE if b in ["A", "B"] else MIN_MM_PEQUENO
		_comprobar(d >= minimo, "[%s] %s mide %.1f mm (mínimo %.0f)" % [contexto, b, d, minimo])
		var c := _ct.centro_de(b)
		var r := _ct.radio_de(b)
		_comprobar(c.x - r >= 0.0 and c.x + r <= lienzo.x and c.y - r >= 0.0 and c.y + r <= lienzo.y, "[%s] %s entra entero en la pantalla" % [contexto, b])
	print("  [%s] tamaños: %s (%.2f px/mm, lienzo %dx%d)" % [contexto, ", ".join(texto), mm, lienzo.x, lienzo.y])
	## Separación entre botones (≥ 2 mm de borde a borde: un pulgar no pulsa dos).
	for i in vis.size():
		for j in range(i + 1, vis.size()):
			var a: String = vis[i]
			var b: String = vis[j]
			var hueco := (_ct.centro_de(a).distance_to(_ct.centro_de(b)) - _ct.radio_de(a) - _ct.radio_de(b)) / mm
			_comprobar(hueco >= 2.0, "[%s] %s y %s separados %.1f mm (mínimo 2)" % [contexto, a, b, hueco])
	## Solapes con el HUD (marcador, estadísticas, ficha del jugador, estrategias): ningún botón encima de un texto.
	for nodo: Node in _pj.find_children("*", "Control", true, false):
		var c := nodo as Control
		if c == null or c == _ct or not c.is_visible_in_tree() or c.size.x < 20.0 or c.get_parent() is ControlesTactiles or c.get_viewport() != get_viewport():
			continue
		if not (c is Label or c is PanelContainer or c is Button):
			continue
		if c.modulate.a < 0.05 or c.self_modulate.a < 0.05:
			continue   ## desvanecido (el aviso de «Saque de puerta» se queda puesto con alfa 0)
		var rect := _rect_visible(c)
		if rect.size.x >= lienzo.x * 0.9 and rect.size.y >= lienzo.y * 0.9:
			continue   ## capas a pantalla completa
		for b: String in vis:
			var cc := _ct.centro_de(b)
			var cerca := Vector2(clampf(cc.x, rect.position.x, rect.end.x), clampf(cc.y, rect.position.y, rect.end.y))
			if cerca.distance_to(cc) < _ct.radio_de(b) - 2.0:
				_comprobar(false, "[%s] %s tapa «%s» (%s)" % [contexto, b, (c as Label).text.left(24) if c is Label else c.name, c.get_class()])
	## Lo que tapan del centro de la pantalla (donde está el juego): el tercio central del ancho, por debajo del marcador. En VERTICAL
	## el cuarto de abajo es la franja de los pulgares (con 1.280 de ancho el arco entra por fuerza en el tercio central): se mide por encima.
	var tapado := 0
	var total := 0
	var fondo := lienzo.y * (0.75 if lienzo.y > lienzo.x else 1.0)
	for x in range(int(lienzo.x / 3.0), int(lienzo.x * 2.0 / 3.0), 8):
		for y in range(int(lienzo.y * 0.15), int(fondo), 8):
			total += 1
			for b: String in vis:
				if Vector2(x, y).distance_to(_ct.centro_de(b)) < _ct.radio_de(b):
					tapado += 1
					break
	var pct := 100.0 * float(tapado) / maxf(1.0, float(total))
	print("  [%s] botones sobre el tercio central: %.1f %%" % [contexto, pct])
	_comprobar(pct <= 3.0, "[%s] los botones casi no tapan el centro del juego (%.1f %%, máximo 3)" % [contexto, pct])

## El rectángulo que de verdad se ve: en una etiqueta, el de su texto (no el de su caja, que puede ser mucho más ancha).
func _rect_visible(c: Control) -> Rect2:
	var r := c.get_global_rect()
	if not (c is Label):
		return r
	var l := c as Label
	var f := l.get_theme_font("font")
	var tam := l.get_theme_font_size("font_size")
	var ancho := 0.0
	for linea in l.text.split("\n"):
		ancho = maxf(ancho, f.get_string_size(linea, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x)
	ancho *= c.get_global_transform().get_scale().x
	match l.horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			return Rect2(r.position.x + (r.size.x - ancho) * 0.5, r.position.y, ancho, r.size.y)
		HORIZONTAL_ALIGNMENT_RIGHT:
			return Rect2(r.end.x - ancho, r.position.y, ancho, r.size.y)
	return Rect2(r.position, Vector2(minf(ancho, r.size.x), r.size.y))

## (10-11) EL HUD del partido con el mismo método: letra en mm, solapes entre paneles, cuánto tapan del centro, ancho de la ficha.
func _auditar_hud(contexto: String) -> void:
	var mm := PantallaMovil.px_por_mm(self)
	var lienzo := get_viewport().get_visible_rect().size
	var paneles: Array = []
	for nodo: Node in _pj.find_children("*", "Control", true, false):
		var c := nodo as Control
		if c == null or c == _ct or not c.is_visible_in_tree() or c.modulate.a < 0.05 or c.get_parent() is ControlesTactiles:
			continue
		if c.get_viewport() != get_viewport():
			continue   ## lo que se dibuja en otra ventana (el videomarcador del estadio, en 3D)
		var r := _rect_visible(c)
		if r.size.x >= lienzo.x * 0.9 and r.size.y >= lienzo.y * 0.9:
			continue
		if c is Label and (c as Label).text.strip_edges() != "":
			var alto := float((c as Label).get_theme_font_size("font_size")) * c.get_global_transform().get_scale().y / mm
			_comprobar(alto >= HudTactil.MIN_MM, "[%s] la letra de «%s» mide %.1f mm (mínimo %.1f)" % [contexto, (c as Label).text.left(20).replace("\n", " "), alto, HudTactil.MIN_MM])
		if (c is PanelContainer or c is ProgressBar or (c is Label and (c as Label).text.strip_edges() != "")) and c.get_parent() == _pj:
			paneles.append([c, r])   ## (las etiquetas sueltas del HUD también: el aviso grande)
	for i in paneles.size():
		for j in range(i + 1, paneles.size()):
			var a: Rect2 = paneles[i][1]
			var b: Rect2 = paneles[j][1]
			_comprobar(not a.grow(-2.0).intersects(b.grow(-2.0)), "[%s] el HUD no se pisa: %s y %s" % [contexto, (paneles[i][0] as Control).name, (paneles[j][0] as Control).name])
	var tapado := 0
	var total := 0
	for x in range(int(lienzo.x / 3.0), int(lienzo.x * 2.0 / 3.0), 8):
		for y in range(int(lienzo.y * 0.15), int(lienzo.y * (0.75 if lienzo.y > lienzo.x else 1.0)), 8):
			total += 1
			for pr: Array in paneles:
				if pr[0] == _pj._banner:
					continue   ## el aviso grande («Saque de banda», «¡GOL!») va en el centro a propósito y dura ~2 s
				if (pr[1] as Rect2).has_point(Vector2(x, y)):
					tapado += 1
					break
	var pct := 100.0 * float(tapado) / maxf(1.0, float(total))
	print("  [%s] HUD sobre el tercio central: %.1f %%" % [contexto, pct])
	_comprobar(pct <= 4.0, "[%s] el HUD casi no tapa el centro del juego (%.1f %%, máximo 4)" % [contexto, pct])
	var ficha: Control = _pj._hud_abajo[0] if not _pj._hud_abajo.is_empty() else null
	if ficha != null:
		var fr := ficha.get_global_rect()
		print("  [%s] ficha del jugador: %.0f %% del ancho, %.1f × %.1f mm" % [contexto, 100.0 * fr.size.x / lienzo.x, fr.size.x / mm, fr.size.y / mm])
		## (en vertical el nombre, con letra legible, ya mide ~30 mm de un teléfono de ~68 mm de ancho: hasta el 45 %)
		_comprobar(fr.size.x / lienzo.x <= (0.50 if lienzo.y > lienzo.x else 0.30), "[%s] la ficha del jugador no ocupa de más (%.0f %% del ancho)" % [contexto, 100.0 * fr.size.x / lienzo.x])

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		var club := _ui.carrera.club(CarreraJugadorUI.mundo)
		var par := _ui._partido_de_la_semana(club)
		print("PARTIDO %d (%s): %s (%s) - %s (%s)" % [_k, _orient, (par[0] as Club).nombre, (par[0] as Club).pais, (par[1] as Club).nombre, (par[1] as Club).pais])
		_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 120.0)
		_ct = _pj.get_node_or_null("ControlesTactiles") as ControlesTactiles
		_comprobar(_ct != null, "el partido monta los controles táctiles")
	if _ct == null:
		return
	## Las tres situaciones de botones, con sus medidas y su foto.
	var pasos := {70: "con", 80: "banda", 90: "sin"}
	if _n in [70, 80, 90]:
		ControlesTactiles.contexto_forzado = String(pasos[_n])
	if _n == 90:   ## el aviso grande y la barra de potencia, a la vista para medirlos
		_pj._mostrar_banner("Saque de banda")
		_pj._barra.visible = true
	if _n in [74, 84, 94]:
		_auditar(String(pasos[_n - 4]))
		_auditar_hud(String(pasos[_n - 4]))
		_foto(String(pasos[_n - 4]))
	if _n == 100:
		ControlesTactiles.contexto_forzado = ""
		_pj._barra.visible = false
		_p0 = _pj.motor.pos(_pj.motor.usuario)
		var c0 := _ct.centro_reposo()
		_toque(0, c0, true)
		_arrastre(0, c0 + Vector2(_ct.radio_stick() * 0.8, 0))
		_toque(1, _ct.centro_de("Sprint"), true)
	if _n == 102:
		_comprobar(Mando.movimiento().length() > 0.5, "el stick responde al fotograma siguiente (%.2f)" % Mando.movimiento().length())
	if _n == 160:
		var p1: Vector3 = _pj.motor.pos(_pj.motor.usuario)
		_comprobar(Input.is_action_pressed("jugar_sprint"), "el dedo del sprint corre")
		_comprobar(Vector2(p1.x - _p0.x, p1.z - _p0.z).length() > 1.0, "el jugador se ha movido con el dedo (%.1f m)" % Vector2(p1.x - _p0.x, p1.z - _p0.z).length())
		_foto("mueve")
		_toque(2, _ct.centro_de("A"), true)
		_toque(3, _ct.centro_de("B"), true)
	if _n == 162:
		_comprobar(Input.is_action_pressed("jugar_pase") and Input.is_action_pressed("jugar_tiro"), "Pase y Tiro pulsados con otros dedos a la vez")
		_toque(3, _ct.centro_de("B"), false)
		_toque(2, _ct.centro_de("A"), false)
		_toque(1, _ct.centro_de("Sprint"), false)
		_toque(0, _ct.centro_reposo(), false)
	if _n == 166:
		_comprobar(Mando.movimiento() == Vector2.ZERO and not Input.is_action_pressed("jugar_sprint") and not Input.is_action_pressed("jugar_pase"), "al levantar los dedos todo se suelta")
		## Sin balón: el botón Cambiar existe y manda su acción.
		ControlesTactiles.contexto_forzado = "sin"
	if _n == 168:
		_toque(4, _ct.centro_de("Cambiar"), true)
	if _n == 170:
		_comprobar(Input.is_action_pressed("jugar_cambiar"), "sin balón, Cambiar pide el cambio de jugador")
		_toque(4, _ct.centro_de("Cambiar"), false)
		ControlesTactiles.contexto_forzado = ""
	if _n == 172:
		_toque(5, _ct.centro_de("Pausa"), true)
	if _n == 174:
		_toque(5, _ct.centro_de("Pausa"), false)
	if _n == 200:
		_comprobar(_pj.get("_pausa") != null, "el botón II abre la pausa (táctica y cambios)")
		_foto("pausa")
		print("===== FIN. %d fallos =====" % _fallos)
		ControlesTactiles.forzar = false
		PantallaMovil.dpi_forzado = 0.0
		ControlesTactiles.contexto_forzado = ""
		AjustesTactil.restaurar()
		get_tree().quit(0 if _fallos == 0 else 1)
