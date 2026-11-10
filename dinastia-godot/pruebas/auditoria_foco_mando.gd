extends Node
## AUDITORÍA DE LA NAVEGACIÓN CON MANDO (10-11-2026, orden 26: el FOCO es un punto débil). Abre la pantalla principal con un mando
## simulado (`FocoMando.forzar`) y recorre TODAS las pestañas y los 9 menús laterales. En cada una:
##  · al entrar hay foco, visible, y no en un campo de texto (abriría el teclado en pantalla sin pedirlo);
##  · 30 pulsaciones de cruceta simuladas (abajo, derecha, arriba, izquierda) sin que el foco se pierda ni quede en algo oculto;
##  · cuántos controles enfocables se alcanzan desde el primero siguiendo el grafo de foco (vecinos de las 4 direcciones);
##  · el control enfocado tiene un estilo de foco que se ve (no `StyleBoxEmpty`).
##   godot --headless --path . res://pruebas/auditoria_foco_mando.tscn        (FOTOS=1 con pantalla: capturas en CAPTURA_DIR)
const PULSACIONES := [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN,
	JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_RIGHT,
	JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_UP,
	JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN,
	JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN,
	JOY_BUTTON_DPAD_DOWN]
const ALCANCE_MIN := 0.6   ## parte de los enfocables visibles que se alcanzan desde el primero con la cruceta
var _p: Node
var _fallos := 0
var _resumen: Array = []

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	FocoMando.forzar = true
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 90:
		await get_tree().process_frame
	await _cerrar_eventos()   ## la reunión de inicio de temporada se abre sola y taparía las pestañas
	await _pestanas()
	if OS.get_environment("SOLO_FOTOS") != "1":
		await _menus()
		await _eventos()
		await _teclado()
	print("RESUMEN")
	for r: String in _resumen:
		print("  " + r)
	print("===== FIN. %d fallos =====" % _fallos)
	FocoMando.forzar = false
	get_tree().quit(0 if _fallos == 0 else 1)

## Los eventos que se abren solos (la reunión de inicio de temporada) se CONTESTAN, como haría el jugador: cerrados sin elegir se
## vuelven a ofrecer (para no bloquearlos para siempre) y taparían las pestañas.
func _cerrar_eventos() -> void:
	var habia := false
	for h: Node in _p.get_children():
		if h is EventoDialogo and not h.is_queued_for_deletion():
			(h as EventoDialogo).selector.elegir(0)
			habia = true
		elif h is EventoPantallaCompleta:
			h.queue_free()
	for i in (90 if habia else 3):
		await get_tree().process_frame

func _pulsar(boton: JoyButton) -> void:
	for pulsa in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = boton
		e.pressed = pulsa
		Input.parse_input_event(e)
	await get_tree().process_frame

func _foco() -> Control:
	return get_viewport().gui_get_focus_owner()

func _desc(c: Control) -> String:
	if c == null:
		return "NINGUNO"
	var t: Variant = c.get("text")
	return ("%s «%s»" % [c.get_class(), String(t).left(28).replace("\n", " ")]) if t != null and String(t) != "" else "%s %s" % [c.get_class(), c.name]

## Los enfocables visibles de `raiz`.
func _enfocables(raiz: Node) -> Array:
	var r: Array = []
	for n: Node in raiz.find_children("*", "Control", true, false):
		var c := n as Control
		if c.focus_mode == Control.FOCUS_ALL and c.is_visible_in_tree() and not (c is BaseButton and (c as BaseButton).disabled):
			r.append(c)
	return r

## Los que se alcanzan con la cruceta desde `ini`, dentro de `raiz`: búsqueda por vecinos de las 4 direcciones, pero dando el foco
## a cada control antes de buscar los suyos (y esperando un fotograma), para que la zona de desplazamiento se mueva como en el juego
## (`follow_focus`) y aparezca lo que estaba fuera de la pantalla.
func _alcanzables(ini: Control, raiz: Node) -> int:
	if ini == null:
		return 0
	var vistos := {ini: true}
	var cola: Array = [ini]
	while not cola.is_empty() and vistos.size() < 400:
		var c: Control = cola.pop_front()
		if not is_instance_valid(c) or not c.is_visible_in_tree():
			continue
		c.grab_focus()
		await get_tree().process_frame
		for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			var v := c.find_valid_focus_neighbor(lado)
			## arriba/abajo dentro de una zona de desplazamiento: la misma regla que `GuardianFoco._input` (lo recortado por el borde)
			var sc := GuardianFoco._zona(c)
			if (lado == SIDE_TOP or lado == SIDE_BOTTOM) and sc != null and (v == null or not sc.is_ancestor_of(v)):
				var sig := GuardianFoco.siguiente_en(sc, c, 1 if lado == SIDE_BOTTOM else -1)
				if sig != null:
					v = sig
			if v != null and not vistos.has(v) and raiz.is_ancestor_of(v):
				vistos[v] = true
				cola.append(v)
	return vistos.size()

## `modal`: la capa está encima de todo (un menú): que el foco salga de ella también es perderlo.
func _auditar(nombre: String, raiz: Control, modal := false) -> void:
	for i in 10:
		await get_tree().process_frame
	## y algo de RELOJ: sin pantalla 10 fotogramas duran mucho menos que una vuelta del guardián (`GuardianFoco.CADA`)
	await get_tree().create_timer(GuardianFoco.CADA * 1.5).timeout
	var f := _foco()
	var total := _enfocables(raiz)
	var dentro := f != null and f.is_visible_in_tree()
	_comprobar(dentro, "[%s] al entrar hay foco visible (%s; %d enfocables)" % [nombre, _desc(f), total.size()])
	if f != null:
		_comprobar(not (f is LineEdit or f is TextEdit), "[%s] el foco no empieza en un campo de texto (abriría el teclado)" % nombre)
		var st := f.get_theme_stylebox("focus")
		## un `Control` a secas no dibuja el estilo de foco del tema: tiene que dibujar el suyo (y decirlo con la meta «foco_visible»)
		var se_ve := f.has_meta("foco_visible") if f.get_class() == "Control" else (st != null and not (st is StyleBoxEmpty))
		_comprobar(se_ve, "[%s] el foco se ve (estilo «focus» de %s)" % [nombre, f.get_class()])
	var perdido := 0
	var visitados := {}
	for b: JoyButton in PULSACIONES:
		await _pulsar(b)
		var g := _foco()
		if g == null or not g.is_visible_in_tree() or (modal and not raiz.is_ancestor_of(g)):
			perdido += 1
		else:
			visitados[g] = true
	_comprobar(perdido == 0, "[%s] 30 pulsaciones de cruceta sin perder el foco (perdido %d veces, %d controles visitados)" % [nombre, perdido, visitados.size()])
	var alc: int = (await _alcanzables(FocoMando.primero(raiz), raiz)) if not total.is_empty() else 0
	var parte := float(alc) / maxf(1.0, float(total.size()))
	_resumen.append("%-14s enfocables %3d, alcanzables desde el primero %3d (%.0f %%), visitados %d, foco al entrar: %s" % [nombre, total.size(), alc, parte * 100.0, visitados.size(), _desc(f)])
	if total.size() >= 3:
		_comprobar(parte >= ALCANCE_MIN, "[%s] con la cruceta se llega a la mayoría (%d de %d)" % [nombre, alc, total.size()])
	if OS.get_environment("FOTOS") == "1" and nombre in ["Mi plantel", "Ajustes", "Clubes"]:
		var dir := OS.get_environment("CAPTURA_DIR") if OS.get_environment("CAPTURA_DIR") != "" else "user://"
		get_viewport().get_texture().get_image().save_jpg(dir.path_join("foco_%s.jpg" % nombre.replace(" ", "_")), 0.88)

func _pestanas() -> void:
	var pest: TabContainer = _p.get("_pestanas")
	for i in pest.get_tab_count():
		var t := pest.get_tab_title(i)
		await _cerrar_eventos()
		if OS.get_environment("SOLO_FOTOS") == "1" and not (t in ["Mi plantel", "Ajustes", "Clubes"]):
			continue
		_p.call("_ir_a_pestana", t)
		await _auditar(t, pest.get_tab_control(i))

func _menus() -> void:
	var ml: MenuLateral = _p.get("_menu_lateral")
	for id: String in ["historia", "gente", "carrera", "operaciones", "vida", "editar", "ajustes", "ciudad", "estadio"]:
		ml.abrir_menu(id, -1)
		for i in 6:
			await get_tree().process_frame
		var pm: Control = ml.pantalla_abierta if is_instance_valid(ml.pantalla_abierta) else null
		if pm == null:
			_comprobar(false, "[menú %s] se abre" % id)
			continue
		await _auditar("menú " + id, pm, true)
		for h in get_tree().root.find_children("*", "PantallaMenu", true, false):
			(h as Node).queue_free()
		await get_tree().process_frame

## Los eventos a pantalla completa: la reunión con la directiva (`EventoDialogo`) y la rueda de prensa, como capas encima.
func _eventos() -> void:
	var ev: Dictionary = EventosClub._directiva(_p.mundo)
	if not ev.is_empty():
		var esc := EventoDialogo.mostrar(_p, ev)
		await _auditar("evento directiva", esc._raiz, true)
		esc.queue_free()
		await get_tree().process_frame
	_p.mundo.prensa.abrir_rueda(true, false)
	_p._abrir_rueda_pantalla_completa(_p.mundo.prensa.entrevista)
	for i in 30:
		await get_tree().process_frame
	var r: Variant = _p.get("_rueda_pop")
	if r is Control and is_instance_valid(r):
		await _auditar("rueda de prensa", r as Control, true)
		(r as Control).queue_free()
	else:
		_comprobar(false, "[rueda de prensa] se abre a pantalla completa")
	await get_tree().process_frame

## La orden 33 (el teclado en pantalla con mando): Cuadrado borra, Triángulo espacio, L2 mayúsculas, R2 confirma.
func _teclado() -> void:
	var campo := LineEdit.new()
	campo.text = "Dinastía"
	add_child(campo)
	var enviado := [""]
	campo.text_submitted.connect(func(t: String) -> void: enviado[0] = t)
	var t := TecladoPantalla.abrir(campo)
	for i in 4:
		await get_tree().process_frame
	await _pulsar(JOY_BUTTON_X)
	_comprobar(campo.text == "Dinastí", "teclado: Cuadrado borra («%s»)" % campo.text)
	await _pulsar(JOY_BUTTON_Y)
	_comprobar(campo.text == "Dinastí ", "teclado: Triángulo pone un espacio («%s»)" % campo.text)
	var q: Button = null
	for b: Node in t.find_children("*", "Button", true, false):
		if String((b as Button).text).to_lower() == "q":
			q = b
	var antes := q.text if q != null else ""
	for v: float in [1.0, 0.0]:
		var e := InputEventJoypadMotion.new()
		e.axis = JOY_AXIS_TRIGGER_LEFT
		e.axis_value = v
		Input.parse_input_event(e)
		await get_tree().process_frame
	_comprobar(q != null and q.text != antes, "teclado: L2 cambia mayúsculas/minúsculas (la tecla pasa de «%s» a «%s»)" % [antes, q.text if q != null else "?"])
	for v: float in [1.0, 0.0]:
		var e := InputEventJoypadMotion.new()
		e.axis = JOY_AXIS_TRIGGER_RIGHT
		e.axis_value = v
		Input.parse_input_event(e)
		await get_tree().process_frame
	await get_tree().process_frame
	_comprobar(enviado[0] == "Dinastí " and not is_instance_valid(t) or (is_instance_valid(t) and t.is_queued_for_deletion()), "teclado: R2 confirma (envía «%s» y cierra)" % enviado[0])
	campo.queue_free()
