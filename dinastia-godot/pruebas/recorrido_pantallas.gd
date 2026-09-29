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

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

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
		return
	if _n < 10:
		return
	## Cierra lo que haya quedado abierto encima (sorteos, pantallas completas).
	for h in _p.get_children():
		if h is Control and (h as Control).mouse_filter == Control.MOUSE_FILTER_STOP and h.get_index() > 3 and h.name != "PanelObjetivos" and h.name != "MenuLateral" and not (h is PantallaMenu):
			h.queue_free()
	if _cola.is_empty():
		print("RECORRIDO: %d pantallas, %d botones" % [_pantallas, _botones])
		var ruta := OS.get_environment("RECORRIDO_TEXTOS")
		if ruta != "":
			var f := FileAccess.open(ruta, FileAccess.WRITE)
			f.store_string(JSON.stringify(_textos))
		get_tree().quit()
		return
	var paso: Array = _cola.pop_front()
	match String(paso[0]):
		"chip":
			var ch: Dictionary = paso[1]
			if String(ch.get("secc", "")) == "kits":
				return
			_p.call("_ir_a_chip", ch)
			_p.call("_refrescar")
			print("PANTALLA chip %s/%s" % [ch["tab"], ch.get("secc", "")])
		"tab":
			_p.call("_ir_a_pestana", String(paso[1]))
			_p.call("_refrescar")
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
	if OS.get_environment("RECORRIDO_TEXTOS") != "":
		_recoger(_p)

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
		var t := bt.text
		var ok := t != ""
		for x: String in NO_PULSAR:
			if t.contains(x):
				ok = false
		if ok:
			lista.append(bt)
	for bt: Button in lista.slice(0, 40):
		if is_instance_valid(bt) and bt.is_inside_tree():
			bt.pressed.emit()
			_botones += 1
			if tabs.current_tab != actual:
				tabs.current_tab = actual
