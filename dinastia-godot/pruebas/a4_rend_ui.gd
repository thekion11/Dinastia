extends Node
## A4 rendimiento de la INTERFAZ (4-11-2026): qué hay vivo detrás del menú y de las pantallas de gestión en calidad MÍNIMA (la del móvil).
##   CALIDAD=minimo xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/a4_rend_ui.tscn
## Cuenta nodos, los que procesan cada fotograma (y de ellos los OCULTOS), los SubViewport que se repintan siempre y las llamadas de dibujo.
var _p: Node
var _n := 0
var _paso := 0
var _menus: Array = []
var _final := 0

func _ready() -> void:
	Calidad.elegida = Calidad.MINIMO if OS.get_environment("CALIDAD") != "medio" else Calidad.MEDIO
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	if OS.get_environment("REPETIR") != "":
		for r in 8:
			_menus.append(["plantel", 0])
		return
	for mn: Dictionary in MenusLaterales.MENUS:
		var subs: Array = mn["subs"]
		for i in subs.size():
			if not (subs[i] as Dictionary).has("accion") and String((subs[i] as Dictionary).get("secc", "")) != "kits":
				_menus.append([String(mn["id"]), i])

func _medir(que: String) -> void:
	var total := 0; var procesan := 0; var ocultos := 0; var fisica := 0
	var por_clase := {}; var por_oculto := {}
	var svp: Array[String] = []
	var pila: Array = [_p]
	while not pila.is_empty():
		var x: Node = pila.pop_back()
		total += 1
		if x.is_processing():
			procesan += 1
			var scr: Script = x.get_script()
			var nom := String(scr.resource_path).get_file() if scr != null else x.get_class()
			por_clase[nom] = int(por_clase.get(nom, 0)) + 1
			if x is CanvasItem and not (x as CanvasItem).is_visible_in_tree():
				ocultos += 1
				por_oculto[nom] = int(por_oculto.get(nom, 0)) + 1
		if x.is_physics_processing():
			fisica += 1
		if x is SubViewport and (x as SubViewport).render_target_update_mode == SubViewport.UPDATE_ALWAYS:
			svp.append(String(x.get_path()).right(60))
		for h in x.get_children():
			pila.append(h)
	var top := por_clase.keys()
	top.sort_custom(func(a: String, b: String) -> bool: return por_clase[a] > por_clase[b])
	var topo := por_oculto.keys()
	topo.sort_custom(func(a: String, b: String) -> bool: return por_oculto[a] > por_oculto[b])
	print("MED %s | nodos %d | procesan %d (ocultos %d) | física %d | draw %d | prim %d | mem %d MB | SubViewport siempre: %s" % [que, total, procesan, ocultos, fisica,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		int(OS.get_static_memory_usage() / 1048576), str(svp)])
	print("   procesan: ", top.slice(0, 6).map(func(k: String) -> String: return "%s×%d" % [k, por_clase[k]]))
	print("   ocultos : ", topo.slice(0, 6).map(func(k: String) -> String: return "%s×%d" % [k, por_oculto[k]]))

func _process(_d: float) -> void:
	_n += 1
	Engine.max_fps = 0
	if _n == 30:
		_medir("menú inicial")
	if _n > 30 and (_n - 30) % 12 == 0 and _paso < _menus.size():
		var mm: Array = _menus[_paso]
		if is_instance_valid(_p._menu_lateral.pantalla_abierta):
			(_p._menu_lateral.pantalla_abierta as PantallaMenu).cerrar()
		_p._menu_lateral.abrir_menu(mm[0], mm[1])
		_paso += 1
	if _paso > 0 and (_n - 30) % 12 == 8 and _paso <= _menus.size() and (_paso % 6 == 1 or _paso == _menus.size() or OS.get_environment("REPETIR") != ""):
		_medir("pantalla %s/%d" % [_menus[_paso - 1][0], _menus[_paso - 1][1]])
	if _paso >= _menus.size() and _final == 0 and (_n - 30) % 12 == 10:
		if is_instance_valid(_p._menu_lateral.pantalla_abierta):
			(_p._menu_lateral.pantalla_abierta as PantallaMenu).cerrar()
		_final = 1
	if _final > 0:
		_final += 1
		if _final == 40:
			_medir("TRAS CERRAR TODO")
			get_tree().quit()
