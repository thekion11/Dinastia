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
		_cola.append(["ficha", "propia"])
		_cola.append(["ficha", "rival"])
		return
	if _n < 10:
		return
	## Cierra lo que haya quedado abierto encima (sorteos, pantallas completas).
	for h in _p.get_children():
		if h is Control and (h as Control).mouse_filter == Control.MOUSE_FILTER_STOP and h.get_index() > 3 and h.name != "PanelObjetivos":
			h.queue_free()
	if _cola.is_empty():
		print("RECORRIDO: %d pantallas, %d botones" % [_pantallas, _botones])
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
		"ficha":
			var m: Mundo = _p.get("mundo")
			var c: Club = m.mi_club() if paso[1] == "propia" else m.ligas[0].clubes[3]
			_p.call("_ver_ficha", c.plantilla[0])
			print("PANTALLA ficha %s" % paso[1])
			_pulsar_botones()
	_pantallas += 1

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
