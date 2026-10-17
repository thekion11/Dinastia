extends Node
## ESTRÉS DE MENÚS (17-10-2026, caza de bugs pedida por el dueño: «seleccionar
## muchas cosas e ir de un menú al otro muchas veces a velocidad sobrehumana»).
## Varias acciones al azar POR FOTOGRAMA: abrir menús laterales y submenús,
## saltar al vecino, cerrar, abrir/plegar el cajón, cambiar de pestaña, abrir
## fichas. Al final cierra todo y compara cuántos nodos quedan (fugas).
##   godot --headless --path . res://pruebas/estres_menus.tscn  (ESTRES_N=fotogramas)
var _p: Node
var _n := 0
var _total := 600
var _nodos0 := 0
var _acciones := 0

func _ready() -> void:
	_total = int(OS.get_environment("ESTRES_N")) if OS.get_environment("ESTRES_N") != "" else 600
	seed(7)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _contar(n: Node) -> int:
	var c := 1
	for h in n.get_children():
		c += _contar(h)
	return c

func _cerrar_todo() -> void:
	var ml: MenuLateral = _p.get("_menu_lateral")
	if is_instance_valid(ml.pantalla_abierta):
		ml.pantalla_abierta.cerrar()
	ml.plegar()
	for h in _p.get_children():
		if h is Control and (h as Control).mouse_filter == Control.MOUSE_FILTER_STOP and h.get_index() > 3 and h.name != "PanelObjetivos" and h.name != "MenuLateral" and not (h is PantallaMenu):
			h.queue_free()

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_p.call("_avanzar_semana")
		return
	if _n == 12:
		_nodos0 = _contar(_p)
		return
	if _n < 12:
		return
	if _n < 12 + _total:
		for _k in randi_range(2, 6):
			_accion()
		return
	if _n == 12 + _total:
		_cerrar_todo()
		return
	if _n == 12 + _total + 6:
		var nodos := _contar(_p)
		print("ESTRÉS: %d acciones; nodos al empezar %d, al terminar %d" % [_acciones, _nodos0, nodos])
		get_tree().quit()

func _accion() -> void:
	_acciones += 1
	var ml: MenuLateral = _p.get("_menu_lateral")
	var m: Mundo = _p.get("mundo")
	match randi() % 9:
		0, 1, 2:
			var menu: Dictionary = MenuLateral.MENUS.pick_random()
			var subs: Array = menu["subs"]
			var k := randi_range(-1, subs.size() - 1)
			if k >= 0 and (subs[k] as Dictionary).has("accion"):
				k = -1
			ml.abrir_menu(String(menu["id"]), k)
		3:
			ml.menu_vecino(1 if randf() < 0.5 else -1)
		4:
			if is_instance_valid(ml.pantalla_abierta):
				ml.pantalla_abierta.cerrar()
		5:
			ml.alternar()
		6:
			var tabs: TabContainer = _p.get("_pestanas")
			if tabs.get_tab_count() > 0:
				_p.call("_ir_a_pestana", tabs.get_tab_title(randi() % tabs.get_tab_count()))
		7:
			var g: Dictionary = Principal.GRUPOS.pick_random()
			var ch: Dictionary = (g["tabs"] as Array).pick_random()
			if String(ch.get("secc", "")) != "kits":
				_p.call("_ir_a_chip", ch)
		8:
			var c: Club = m.mi_club() if randf() < 0.5 else m.ligas[0].clubes[randi() % m.ligas[0].clubes.size()]
			_p.call("_ver_ficha", c.plantilla.pick_random())
