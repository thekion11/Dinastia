extends Node
## EL RECORRIDO DE TODAS LAS PANTALLAS (29-9-2026, mapa de metas 15). Tras
## partir `principal.gd` en `ui/pantallas/`, un error de un miembro mal
## reescrito solo saltaría al abrir ESA pantalla o pulsar ESE botón. Esto abre
## cada pestaña y cada sección de cada grupo, la ficha de un jugador propio y
## de uno rival, y en cada pantalla pulsa los botones que no destruyen nada.
##   godot --headless --path . res://pruebas/recorrido_pantallas.tscn
## Imprime "RECORRIDO: n pantallas, m botones" al terminar; los errores salen
## como SCRIPT ERROR en el registro.
const NO_PULSAR := ["Retir", "Vender", "Salir", "Cargar", "Otro mundo", "Guardar", "Despedir", "Dimitir",
	"Borrar", "Rescindir", "Importar", "Exportar", "Nuevo", "Jubil", "Cerrar juego", "Abandonar", "Avanzar",
	"Un día", "Jugar", "Dirigir", "Simular", "Examen", "Penales", "Galería", "Sonido", "Música", "▶"]
var _p: Node
var _n := 0
var _cola: Array = []
var _pantallas := 0
var _botones := 0
## Con RECORRIDO_TEXTOS=<ruta>, además guarda todos los textos que se vieron
## (lo usa la traducción: mapa de metas 17).
var _textos := {}
## M-467 (27-10-2026): con RECORRIDO_IDIOMA=de cambia el idioma al abrir, y con RECORRIDO_LARGOS=<ruta>
## guarda los botones y etiquetas que se salen de la pantalla o salen cortados («pantalla|texto» → motivo).
var _largos := {}
var _donde := ""
var _espera := -1
var _idioma_antes := ""
## M-287 (2-11-2026): lo que tarda en abrirse cada pantalla (pintarla, sin pulsar botones). Con RECORRIDO_MS_MAX=n
## falla si alguna pasa de n ms (la máquina sin GPU pinta más despacio que un PC: el tope es holgado).
var _tiempos := {}

func _ready() -> void:
	## RECORRIDO_MOVIL=2400x1080 (4-11-2026, caza de fallos del móvil): emula la ventana de un teléfono con el zoom de interfaz del móvil.
	if OS.get_environment("RECORRIDO_MOVIL") != "":
		var wh := OS.get_environment("RECORRIDO_MOVIL").split("x")
		get_window().size = Vector2i(int(wh[0]), int(wh[1]))
		get_window().content_scale_factor = EscalaMovil.ZOOM_MOVIL
		PantallaMovil.dpi_forzado = 400.0
		PantallaMovil.ventana_forzada = Vector2i(int(wh[0]), int(wh[1]))
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	## Después de abrir: la principal carga el idioma de las preferencias guardadas.
	if OS.get_environment("RECORRIDO_IDIOMA") != "":
		_idioma_antes = Idiomas.idioma
		Idiomas.idioma = OS.get_environment("RECORRIDO_IDIOMA")

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		for i in 12:
			_p.call("_avanzar_semana")
		for g: Dictionary in Principal.GRUPOS:
			for ch: Dictionary in g["tabs"]:
				_cola.append(["chip", ch])
		var tabs: TabContainer = _p.get("_pestanas")
		for i in tabs.get_tab_count():
			_cola.append(["tab", tabs.get_tab_title(i)])
		## Los menús a pantalla completa del panel lateral, submenú a submenú.
		for m: Dictionary in MenuLateral.MENUS:
			for k in (m["subs"] as Array).size():
				if not ((m["subs"] as Array)[k] as Dictionary).has("accion") and String((m["subs"] as Array)[k].get("secc", "")) != "kits":
					_cola.append(["menu", String(m["id"]), k])
		_cola.append(["cerrar_menu"])
		_cola.append(["ficha", "propia"])
		_cola.append(["ficha", "rival"])
		## RECORRIDO_SOLO=Ciudad,Editor (15-10-2026): solo los pasos cuyo texto
		## contiene alguna de esas palabras (para aislar un fallo).
		var solo := OS.get_environment("RECORRIDO_SOLO")
		if solo != "":
			var quedan: Array = []
			for paso: Array in _cola:
				for w in solo.split(","):
					if str(paso).contains(w):
						quedan.append(paso)
						break
			_cola = quedan
		## RECORRIDO_TRAMO=i/n (29-9-2026): solo el tramo i de n, para que cada
		## parte quepa en una ejecución corta y en primer plano.
		var tramo := OS.get_environment("RECORRIDO_TRAMO")
		if tramo.contains("/"):
			var i_t := int(tramo.get_slice("/", 0))
			var n_t := maxi(1, int(tramo.get_slice("/", 1)))
			var largo := int(ceil(float(_cola.size()) / float(n_t)))
			_cola = _cola.slice((i_t - 1) * largo, i_t * largo)
		return
	if _n < 10:
		return
	## Se mide dos cuadros después de abrir cada pantalla: lo que se encoge o se coloca tarde ya está en su sitio.
	if _espera > 0:
		_espera -= 1
		return
	if _espera == 0:
		_espera = -1
		_medir()
	## Cierra lo que haya quedado abierto encima (sorteos, pantallas completas).
	for h in _p.get_children():
		if h is Control and (h as Control).mouse_filter == Control.MOUSE_FILTER_STOP and h.get_index() > 3 and h.name != "PanelObjetivos" and h.name != "MenuLateral" and not (h is PantallaMenu):
			h.queue_free()
	if _cola.is_empty():
		print("RECORRIDO: %d pantallas, %d botones" % [_pantallas, _botones])
		_informe_tiempos()
		if _idioma_antes != "":
			_castellano()
		## Ajustes guarda las preferencias al pintarse: sin esto, el idioma de la prueba quedaba como el del juego.
		if _idioma_antes != "":
			Idiomas.idioma = _idioma_antes
			_p.call("_guardar_preferencias")
		var ruta := OS.get_environment("RECORRIDO_TEXTOS")
		if ruta != "":
			var f := FileAccess.open(ruta, FileAccess.WRITE)
			f.store_string(JSON.stringify(_textos))
		if OS.get_environment("RECORRIDO_LARGOS") != "":
			FileAccess.open(OS.get_environment("RECORRIDO_LARGOS"), FileAccess.WRITE).store_string(JSON.stringify(_largos, " "))
			var cortados := _largos.values().filter(func(v: String) -> bool: return v.begins_with("cortado")).size()
			print("LARGOS: %d textos que no caben (%d cortados)" % [_largos.size(), cortados])
			## RECORRIDO_ACCESO_MAX=n: prueba. Falla si hay más de n controles que el teclado no enfoca o que el lector leería en blanco.
			if OS.get_environment("RECORRIDO_ACCESO_MAX") != "":
				var sin := _largos.keys().filter(func(k: String) -> bool: return k.contains("| acceso")).size()
				print("FIN ACCESO. %d fallos" % (1 if sin > int(OS.get_environment("RECORRIDO_ACCESO_MAX")) else 0))
			## RECORRIDO_ANCHO_MAX=n: prueba. Falla si hay más de n paneles deslizables cuyo contenido sea más ancho que ellos (la tabla de Mi plantel, de 10-50 px de más, está aceptada: se desliza).
			if OS.get_environment("RECORRIDO_ANCHO_MAX") != "":
				var anchos := _largos.keys().filter(func(k: String) -> bool: return k.contains("| ancho") and not k.begins_with("tab Mi plantel")).size()
				print("FIN ANCHO. %d fallos" % (1 if anchos > int(OS.get_environment("RECORRIDO_ANCHO_MAX")) else 0))
			## Con RECORRIDO_CORTADOS_MAX=n (especiales.sh todo) es una prueba: falla si hay más de n cortados.
			if OS.get_environment("RECORRIDO_CORTADOS_MAX") != "":
				print("FIN LARGOS. %d fallos" % (1 if cortados > int(OS.get_environment("RECORRIDO_CORTADOS_MAX")) else 0))
		get_tree().quit()
		return
	var paso: Array = _cola.pop_front()
	var t0 := Time.get_ticks_usec()
	match String(paso[0]):
		"chip":
			var ch: Dictionary = paso[1]
			if String(ch.get("secc", "")) == "kits":
				return
			_p.call("_ir_a_chip", ch)
			_p.call("_refrescar")
			_tiempos["chip " + String(ch["tab"]) + "/" + String(ch.get("secc", ""))] = (Time.get_ticks_usec() - t0) / 1000.0
			print("PANTALLA chip %s/%s" % [ch["tab"], ch.get("secc", "")])
		"tab":
			_p.call("_ir_a_pestana", String(paso[1]))
			_p.call("_refrescar")
			_tiempos["tab " + String(paso[1])] = (Time.get_ticks_usec() - t0) / 1000.0
			print("PANTALLA tab %s" % paso[1])
			_pulsar_botones()
		"menu":
			var ml: MenuLateral = _p.get("_menu_lateral")
			if not is_instance_valid(ml.pantalla_abierta) or ml.pantalla_abierta.get_meta("id", "") != paso[1]:
				ml.abrir_menu(String(paso[1]), int(paso[2]))
				ml.pantalla_abierta.set_meta("id", paso[1])
			else:
				ml.pantalla_abierta.elegir(int(paso[2]))
			print("PANTALLA menu %s/%d" % [paso[1], paso[2]])
		"cerrar_menu":
			var ml2: MenuLateral = _p.get("_menu_lateral")
			if is_instance_valid(ml2.pantalla_abierta):
				ml2.pantalla_abierta.cerrar()
			var tabs2: TabContainer = _p.get("_pestanas")
			print("MUDANZA DEVUELTA: %s" % _p.is_ancestor_of(tabs2))
		"ficha":
			var m: Mundo = _p.get("mundo")
			var c: Club = m.mi_club() if paso[1] == "propia" else m.ligas[0].clubes[3]
			_p.call("_ver_ficha", c.plantilla[0])
			print("PANTALLA ficha %s" % paso[1])
			_pulsar_botones()
	_pantallas += 1
	_donde = " ".join(paso.map(func(x: Variant) -> String: return str(x.get("tab", "")) + "/" + str(x.get("secc", "")) if x is Dictionary else str(x)))
	if OS.get_environment("RECORRIDO_TEXTOS") != "":
		_recoger(_p)
	if OS.get_environment("RECORRIDO_LARGOS") != "":
		_espera = 2

func _informe_tiempos() -> void:
	var claves := _tiempos.keys()
	claves.sort_custom(func(a, b) -> bool: return float(_tiempos[a]) > float(_tiempos[b]))
	for k in claves.slice(0, 5):
		print("  LENTA %7.1f ms  %s" % [float(_tiempos[k]), k])
	if OS.get_environment("RECORRIDO_MS_MAX") != "":
		var tope := float(OS.get_environment("RECORRIDO_MS_MAX"))
		var malas := claves.filter(func(k) -> bool: return float(_tiempos[k]) > tope)
		print("FIN TIEMPOS. %d fallos (tope %d ms, la peor %.0f ms)" % [malas.size(), int(tope), float(_tiempos[claves[0]]) if not claves.is_empty() else 0.0])

## Lo que no cabe: un control visible que se sale por la derecha de la ventana, o un texto que el control recorta
## (clip o «…») porque es más ancho que el propio control.
func _medir() -> void:
	var ancho := get_viewport().get_visible_rect().size.x
	## Con RECORRIDO_ACCESO (accesibilidad al límite): un control que se pulsa o se escribe, visible, que el teclado/mando no puede enfocar, o que el lector de pantalla leería en blanco.
	if OS.get_environment("RECORRIDO_ACCESO") != "":
		for n2 in _p.find_children("*", "Control", true, false):
			var c2 := n2 as Control
			if not (c2 is Button or c2 is LineEdit or c2 is TextEdit or c2 is Slider) or not c2.is_visible_in_tree() or c2.get_window() != get_tree().root or c2.size.x < 4.0:
				continue
			if c2 is Button and (c2 as Button).disabled:
				continue
			var nom2 := LectorPantalla.texto_de(c2)
			var que := ""
			if c2.focus_mode == Control.FOCUS_NONE and not (c2 is Button and (c2 as Button).toggle_mode and false):
				que = "sin foco (teclado/mando no llega)"
			elif nom2 == "" and not (c2 is Slider or c2 is SpinBox or c2 is TextEdit):
				que = "el lector lo leería en blanco"
			if que != "":
				_largos["%s | acceso %s %s" % [_donde, c2.get_class(), nom2.left(30)]] = que + " @" + str(c2.get_path()).right(60)
	## Con RECORRIDO_ANCHO: un ScrollContainer visible cuyo contenido es más ANCHO que él (un texto sin salto de línea ensancha todo el panel: en alemán o en el lienzo del móvil).
	if OS.get_environment("RECORRIDO_ANCHO") != "":
		for sc2 in _p.find_children("*", "ScrollContainer", true, false):
			var sk2 := sc2 as ScrollContainer
			if sk2.is_visible_in_tree() and sk2.get_child_count() > 0 and sk2.get_window() == get_tree().root:
				var h2 := sk2.get_child(0) as Control
				if h2 != null and h2.get_combined_minimum_size().x > sk2.size.x + 2.0 and sk2.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
					_largos["%s | ancho %s" % [_donde, sk2.name]] = "se sale %d px: el contenido mide %d y cabe %d" % [int(h2.get_combined_minimum_size().x - sk2.size.x), int(h2.get_combined_minimum_size().x), int(sk2.size.x)]
	## Con RECORRIDO_TOQUE: un ScrollContainer visible cuyo contenido no cabe y que no se puede deslizar (el final queda inalcanzable).
	if OS.get_environment("RECORRIDO_TOQUE") != "":
		for sc in _p.find_children("*", "ScrollContainer", true, false):
			var sk := sc as ScrollContainer
			if not sk.is_visible_in_tree() or sk.get_child_count() == 0 or sk.get_window() != get_tree().root:
				continue
			var hijo := sk.get_child(0) as Control
			if hijo != null and hijo.get_combined_minimum_size().y > sk.size.y + 2.0 and sk.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
				_largos["%s | scroll %s" % [_donde, sk.name]] = "no se desliza: contenido %d > %d" % [int(hijo.get_combined_minimum_size().y), int(sk.size.y)]
	for n in _p.find_children("*", "Control", true, false):
		var c := n as Control
		if not (c is Button or c is Label) or not c.is_visible_in_tree() or c.get_window() != get_tree().root:
			continue
		var t: String = c.get("text")
		if t.strip_edges() == "" or c.size.x < 4.0:
			continue
		var motivo := ""
		if c.get_global_rect().end.x > ancho + 2.0 and c.get_global_rect().position.x < ancho:
			motivo = "se sale %d px" % int(c.get_global_rect().end.x - ancho)
		else:
			var corta: bool = c.get("clip_text") or int(c.get("text_overrun_behavior")) != TextServer.OVERRUN_NO_TRIMMING
			var envuelve: bool = int(c.get("autowrap_mode")) != TextServer.AUTOWRAP_OFF
			if corta and not envuelve and not t.contains("\n"):
				var f := c.get_theme_font("font")
				var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, c.get_theme_font_size("font_size")).x
				var hueco := c.size.x - (c.get_theme_stylebox("normal").get_minimum_size().x if c is Button else 0.0)
				if w > hueco + 2.0:
					motivo = "cortado %d/%d px (%s)" % [int(w), int(hueco), c.get_class()]
		## RECORRIDO_TOQUE=<mm> (móvil): un botón más bajo que el toque cómodo (7 mm a ~400 ppp en 2400×1080 con zoom: ~49 px del lienzo).
		if motivo == "" and c is Button and OS.get_environment("RECORRIDO_TOQUE") != "":
			var tope := float(OS.get_environment("RECORRIDO_TOQUE"))
			if c.get_global_rect().size.y * c.get_viewport().get_final_transform().get_scale().y < tope:
				motivo = "toque bajo %.1f px reales" % (c.get_global_rect().size.y * c.get_viewport().get_final_transform().get_scale().y)
		if motivo != "":
			_largos["%s | %s" % [_donde, t.left(80)]] = motivo

func _recoger(n: Node) -> void:
	var ts: Array = []
	if n is Label:
		ts.append((n as Label).text)
	elif n is OptionButton:
		for i in (n as OptionButton).item_count:
			ts.append((n as OptionButton).get_item_text(i))
	elif n is Button:
		ts.append((n as Button).text)
	if n is Control and (n as Control).tooltip_text != "":
		ts.append((n as Control).tooltip_text)
	for t: String in ts:
		t = t.strip_edges()
		if t != "":
			_textos[t] = int(_textos.get(t, 0)) + 1
	for h in n.get_children():
		_recoger(h)

func _pulsar_botones() -> void:
	var tabs: TabContainer = _p.get("_pestanas")
	var actual := tabs.current_tab
	var lista: Array = []
	for b in _p.find_children("*", "Button", true, false):
		var bt := b as Button
		if not bt.is_visible_in_tree() or bt.disabled:
			continue
		## Nada dentro de ventanas emergentes (29-9-2026): en «Elegir club»
		## pulsaba los 32 clubes seguidos EN UN SOLO CUADRO -32 cambios de mando
		## y reconstrucciones- y el cuadro no terminaba nunca. Un jugador no
		## puede hacer eso: la ventana se cierra al elegir.
		if bt.get_window() != get_tree().root:
			continue
		var t := bt.text
		var ok := t != ""
		for x: String in NO_PULSAR:
			if t.contains(x):
				ok = false
		if ok:
			lista.append(bt)
	for bt: Button in lista.slice(0, 40):
		if is_instance_valid(bt) and bt.is_inside_tree():
			if OS.get_environment("RECORRIDO_VERBOSO") != "":
				print("  BOTON «%s» t=%d" % [bt.text, Time.get_ticks_msec()])
			bt.pressed.emit()
			_botones += 1
			if tabs.current_tab != actual:
				tabs.current_tab = actual

## M-458 / M-463 (28-10-2026): las frases que `Idiomas.t` dejó igual y que PARECEN castellano (dos o más palabras
## típicas), en otro idioma. Con RECORRIDO_FALTAN=<ruta> las guarda; con RECORRIDO_CASTELLANO_MAX=n es una prueba.
const PALABRAS_ES := ["que", "se", "tu", "tus", "con", "para", "por", "del", "las", "los", "una", "está", "hay", "más",
	"pero", "muy", "sin", "años", "semanas", "jugadores", "partido", "partidos", "equipo", "tienes", "puedes", "cuando"]

## Palabras de la lista que SON también del idioma de destino (en portugués «que», «se», «para», «por» y «tu» son suyas; «del», «una» y «tu» son catalanas): se quitan
## de la cuenta en ese idioma, o una frase ya traducida (que vuelve a pasar por `Idiomas.t` y queda igual) parecería castellano (4-11-2026).
const COMPARTIDAS := {"pt": ["que", "se", "para", "por", "tu", "tus", "semanas"], "ca": ["que", "se", "tu", "del", "una"], "it": ["se", "tu", "con", "una", "del"],
	"fr": ["que", "se", "tu"], "pl": ["tu", "tus"]}

func _castellano() -> void:
	var palabras: Array = PALABRAS_ES.filter(func(w: String) -> bool: return not (COMPARTIDAS.get(Idiomas.idioma, []) as Array).has(w))
	var re := RegEx.create_from_string("(?i)(?<![\\p{L}])(" + "|".join(palabras) + ")(?![\\p{L}])")
	## Las siglas de posición (POR, DEF, MED, DEL) se quedan en castellano en todos los idiomas (orden 15) y «POR»/«DEL»
	## parecían «por»/«del»: se quitan antes de contar, igual que el formato del editor («Club;Nombre;POS;Edad…»).
	var siglas := RegEx.create_from_string("\\b(POR|DEF|MED|DEL|DFC|LAT|BAN|POS)\\b|Club;Nombre;[^ ]*")
	var malas: Array = []
	for f: String in Idiomas.sin_traduccion:
		if re.search_all(siglas.sub(f, "", true)).size() >= 2:
			malas.append(f)
	malas.sort()
	print("CASTELLANO: %d frases sin traducir que parecen castellano" % malas.size())
	if OS.get_environment("RECORRIDO_FALTAN") != "":
		FileAccess.open(OS.get_environment("RECORRIDO_FALTAN"), FileAccess.WRITE).store_string("\n".join(malas))
	if OS.get_environment("RECORRIDO_CASTELLANO_MAX") != "":
		print("FIN CASTELLANO. %d fallos" % (1 if malas.size() > int(OS.get_environment("RECORRIDO_CASTELLANO_MAX")) else 0))

