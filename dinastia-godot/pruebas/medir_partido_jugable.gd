extends Node
## RENDIMIENTO DEL PARTIDO 3D JUGABLE EN MÍNIMA (4-11-2026, orden 22: 5 FPS en el móvil del dueño). Abre el partido de la carrera (el de «jugar partido») con la
## cámara real, los controles táctiles puestos y la calidad indicada, y mide:
##   - lo que NO depende de la máquina: llamadas de dibujo, triángulos, objetos, nodos, memoria de vídeo (con pantalla: xvfb + opengl3);
##   - CPU del proceso por fotograma y cuánto baja al apagar cada clase de script (`CPU=1`, funciona sin pantalla; el tiempo de pared headless NO sirve).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/medir_partido_jugable.tscn            (conteos)
##   CPU=1 godot --headless --path . res://pruebas/medir_partido_jugable.tscn                                                        (CPU por clase)
## Variables: CALIDAD=minimo|medio|alto (por omisión minimo), OCULTAR=Nodo1,Nodo2 (oculta nodos por nombre y mide qué baja), REPETIR=n.
var _ui: CarreraJugadorUI
var _pj: PartidoJugable
var _n := 0
var _hecho := false

func _ready() -> void:
	var c := OS.get_environment("CALIDAD")
	Calidad.elegida = Calidad.ALTO if c == "alto" else (Calidad.MEDIO if c == "medio" else Calidad.MINIMO)
	PartidoJugable.con_ceremonia = false
	ControlesTactiles.forzar = true
	PantallaMovil.dpi_forzado = 400.0
	PantallaMovil.ventana_forzada = Vector2i(2400, 1080)
	PantallaMovil.lienzo_forzado = Vector2(1600, 720)
	AjustesTactil.restaurar()
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)

func _process(_d: float) -> void:
	if _hecho:
		return
	_n += 1
	Engine.max_fps = 0
	if _n == 10:
		_ui._crear()
	if _n == 20:
		var club := _ui.carrera.club(CarreraJugadorUI.mundo)
		var par := _ui._partido_de_la_semana(club)
		_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 120.0)
		_pj.motor.autopiloto = true
	if _n == 500:
		_hecho = true
		_medir()

func _cpu_ms() -> float:
	var f := FileAccess.open("/proc/self/stat", FileAccess.READ)
	if f == null:
		return 0.0
	var t := f.get_line()
	var campos := t.substr(t.rfind(")") + 2).split(" ")
	return (float(campos[11]) + float(campos[12])) * 10.0

func _cuadros(c: int) -> float:
	for i in 5:
		await get_tree().process_frame
	var t0 := _cpu_ms()
	for i in c:
		await get_tree().process_frame
	return (_cpu_ms() - t0) / float(c)

## Cuánto baja el fotograma al apagar `ns`: se mide con ellos apagados y ENTRE dos medidas con ellos encendidos (el partido se vuelve más barato solo al
## calentarse; comparar con una base medida al principio daba -8 ms para todo).
func _sin(ns: Array, rep: int) -> float:
	var antes := 0.0
	for i in rep:
		antes += await _cuadros(150)
	for n in ns:
		(n as Node).process_mode = Node.PROCESS_MODE_DISABLED
	var apagado := 0.0
	for i in rep:
		apagado += await _cuadros(150)
	for n in ns:
		(n as Node).process_mode = Node.PROCESS_MODE_INHERIT
	var despues := 0.0
	for i in rep:
		despues += await _cuadros(150)
	return ((antes + despues) / 2.0 - apagado) / float(rep)

func _conteos(etiqueta: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	print("MEDIDA %s: llamadas=%d triangulos=%d objetos=%d nodos=%d video=%.0fMB" % [etiqueta,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])

## Milisegundos de PARED por fotograma (mediana de 40): con pantalla (xvfb + llvmpipe) la gráfica es por software y limitada por relleno de píxeles, así que sirve para
## comparar qué efecto o pasada cuesta más (no para certificar FPS de un teléfono).
func _ms_pared() -> float:
	for i in 6:
		await get_tree().process_frame
	var v: Array = []
	for i in 40:
		var t0 := Time.get_ticks_usec()
		await get_tree().process_frame
		v.append(float(Time.get_ticks_usec() - t0) / 1000.0)
	v.sort()
	return v[v.size() / 2]

func _quitar(que: String) -> void:
	var envs := _pj.find_children("*", "WorldEnvironment", true, false)
	match que:
		"ajuste": for e in envs: (e as WorldEnvironment).environment.adjustment_enabled = false
		"tonos": for e in envs: (e as WorldEnvironment).environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		"niebla": for e in envs: (e as WorldEnvironment).environment.fog_enabled = false
		"cielo": for e in envs:
			(e as WorldEnvironment).environment.background_mode = Environment.BG_COLOR
			(e as WorldEnvironment).environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		"msaa": _pj._vp.msaa_3d = Viewport.MSAA_DISABLED
		"hud": for h in _pj.get_children():
			if h is Control and not (h is SubViewportContainer): (h as Control).visible = false
		"controles": (_pj.get_node("ControlesTactiles") as Control).visible = false
		"omni": for l in _pj.find_children("*", "OmniLight3D", true, false): (l as Light3D).visible = false
		"luz": for l in _pj.find_children("*", "DirectionalLight3D", true, false): (l as Light3D).visible = false
		"jugadores": for n in _pj.motor.jugadores: ((n as Dictionary)["node"] as Node3D).visible = false
		"mundo3d": _pj._vp.render_target_update_mode = SubViewport.UPDATE_DISABLED

func _llamadas() -> int:
	for i in 3:
		await get_tree().process_frame
	return int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))

func _medir() -> void:
	if OS.get_environment("CPU") == "":
		## Escena CONGELADA (cámara, jugadores y balón quietos): los conteos entre dos ocultaciones se comparan sin deriva (en marcha, las llamadas bailan entre 400 y 700 según el momento).
		_pj.set_process(false)
		_pj.motor.set_process(false)
		_pj.motor.set_physics_process(false)
		for h in _pj.get_children():
			h.set_process(false)
	await _conteos("base")
	if OS.get_environment("LUCES") != "":
		var por := {}
		for l in _pj.find_children("*", "Light3D", true, false):
			var k := "%s sombra=%s visible=%s rango=%s" % [(l as Node).get_class(), str((l as Light3D).shadow_enabled), str((l as Light3D).is_visible_in_tree()), str(snappedf(float((l as Light3D).get("omni_range") if (l as Node).get_class() == "OmniLight3D" else ((l as Light3D).get("spot_range") if (l as Node).get_class() == "SpotLight3D" else 0.0)), 1))]
			por[k] = int(por.get(k, 0)) + 1
		for k in por:
			print("LUZ x%-4d %s" % [por[k], k])
		for l in _pj.find_children("*", "OmniLight3D", true, false):
			var o := l as OmniLight3D
			var c := _pj._cam
			var dist := c.global_position.distance_to(o.global_position)
			print("OMNI pos=%s energia=%.1f rango=%.0f dist_camara=%.0f en_frustum=%s padre=%s" % [str(o.global_position.snapped(Vector3.ONE)), o.light_energy, o.omni_range, dist, str(_esfera_en_frustum(c, o.global_position, o.omni_range)), String(o.get_parent().name)])
		var vp: SubViewport = _pj._vp
		print("VIEWPORT msaa_3d=%d scaling_mode=%d scale=%.2f taa=%s fxaa=%d debanding=%s hdr2d=%s" % [vp.msaa_3d, vp.scaling_3d_mode, vp.scaling_3d_scale, str(vp.use_taa), vp.screen_space_aa, str(vp.use_debanding), str(vp.use_hdr_2d)])
		get_tree().quit()
		return
	if OS.get_environment("CENSO") != "":
		_censo()
		get_tree().quit()
		return
	if OS.get_environment("LISTAR") != "":
		## LISTAR=Clase: cuántos nodos de esa clase hay y bajo qué padre (nombre) cuelgan.
		var por_padre := {}
		for n in _pj.find_children("*", OS.get_environment("LISTAR"), true, false):
			var k := String(n.get_parent().name) + " > " + String((n as Node).name).rstrip("0123456789@")
			por_padre[k] = int(por_padre.get(k, 0)) + 1
		var claves := por_padre.keys()
		claves.sort_custom(func(a, b) -> bool: return por_padre[a] > por_padre[b])
		for k in claves.slice(0, 25):
			print("LISTA %4d  %s" % [por_padre[k], k])
		get_tree().quit()
		return
	if OS.get_environment("POR_HUD") != "":
		## POR_HUD=1 (12-11): cuántas llamadas pesa cada pieza 2D del partido (hijos Control de PartidoJugable y de los controles táctiles).
		var base_h: int = await _llamadas()
		print("HUD base %d llamadas" % base_h)
		var piezas: Array = []
		for h in _pj.get_children():
			if h is Control and not (h is SubViewportContainer) and (h as Control).visible:
				piezas.append(h)
		var ct := _pj.get_node_or_null("ControlesTactiles")
		if ct != null:
			for h in ct.get_children():
				if h is CanvasItem and (h as CanvasItem).visible:
					piezas.append(h)
		for h: CanvasItem in piezas:
			h.visible = false
			var ll: int = await _llamadas()
			h.visible = true
			var texto := ""
			for l in h.find_children("*", "Label", true, false):
				texto += (l as Label).text.substr(0, 18) + "|"
			print("HUD -%3d  %s (%s) %s" % [base_h - ll, h.name, h.get_class(), texto])
		get_tree().quit()
		return
	if OS.get_environment("POR_HIJO") != "":
		## POR_HIJO=1 (12-11): cuántas llamadas pesa cada hijo de la escena 3D (se oculta uno, se cuenta y se vuelve a mostrar).
		var base_ll: int = await _llamadas()
		var filas: Array = []
		for h in _pj._raiz.get_children():
			if not (h is Node3D) or not (h as Node3D).visible:
				continue
			(h as Node3D).visible = false
			var ll: int = await _llamadas()
			(h as Node3D).visible = true
			filas.append([base_ll - ll, "%s (%s, %d hijos)" % [h.name, h.get_class(), h.get_child_count()]])
		filas.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
		for f: Array in filas.slice(0, 25):
			print("HIJO -%4d  %s" % [f[0], f[1]])
		get_tree().quit()
		return
	if OS.get_environment("CONTEO") != "":
		## CONTEO=controles,hud: tras ocultar cada cosa, vuelve a contar (acumulado). Lo que baja son llamadas de DIBUJO 2D (el HUD del partido y los botones).
		for q in OS.get_environment("CONTEO").split(","):
			_quitar(q)
			await _conteos("sin " + q)
		get_tree().quit()
		return
	if OS.get_environment("QUITAR") != "":
		var base_ms := await _ms_pared()
		var base2 := await _ms_pared()
		print("PARED repetida (ruido): %.1f ms" % base2)
		print("PARED base %.1f ms (viewport 3D %s, MSAA %d, escala %.2f)" % [base_ms, str(_pj._vp.size), _pj._vp.msaa_3d, _pj._vp.scaling_3d_scale])
		for q in OS.get_environment("QUITAR").split(","):
			_quitar(q)
			var ms := await _ms_pared()
			print("PARED sin %-10s %.1f ms  (-%.1f)" % [q, ms, base_ms - ms])
		get_tree().quit()
		return
	var ocultar := OS.get_environment("OCULTAR")
	if ocultar != "":
		for nombre in ocultar.split(","):
			for nd in _pj.find_children(nombre, "Node3D", true, false):
				(nd as Node3D).visible = false
		await _conteos("sin " + ocultar)
	if OS.get_environment("CPU") == "":
		get_tree().quit()
		return
	var por_clase := {}
	for n in _pj.find_children("*", "Node", true, false):
		if n.get_script() != null and (n.is_processing() or n.is_physics_processing()):
			var k := String(n.get_script().resource_path.get_file())
			if not por_clase.has(k):
				por_clase[k] = []
			por_clase[k].append(n)
	var rep := maxi(1, int(OS.get_environment("REPETIR")) if OS.get_environment("REPETIR") != "" else 1)
	var base := 0.0
	for i in rep:
		base += await _cuadros(150)
	base /= rep
	print("CPUP base %.2f ms  (%d clases con proceso, %d nodos)" % [base, por_clase.size(), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	var filas: Array = []
	for k: String in por_clase:
		var d := await _sin(por_clase[k], rep)
		filas.append([d, "CPUP sin %-34s x%-4d -%.2f ms" % [k, por_clase[k].size(), d]])
	for clase in ["AnimationPlayer", "AnimationTree", "Skeleton3D", "Label3D", "GPUParticles3D", "CPUParticles3D"]:
		var ns := _pj.find_children("*", clase, true, false)
		var d2 := await _sin(ns, rep)
		filas.append([d2, "CPUP sin %-34s x%-4d -%.2f ms" % [clase, ns.size(), d2]])
	filas.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for f: Array in filas:
		print(f[1])
	print("===== FIN. 0 fallos =====")
	get_tree().quit()

## CENSO de lo que de verdad se dibuja: cada GeometryInstance3D visible cuyo AABB cruza la pirámide de la cámara real, agrupado por «padre > nombre» con sus llamadas
## (superficies; las multimallas cuentan una por superficie) y triángulos. Es una estimación (no ve la oclusión ni el LOD), pero ordena dónde está el gasto.
func _censo() -> void:
	var cam: Camera3D = _pj._cam
	var planos := cam.get_frustum()
	var grupos := {}
	var total_ll := 0
	var total_tr := 0
	for n in _pj._raiz.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var caja := g.global_transform * g.get_aabb()
		var dentro := true
		for pl: Plane in planos:
			var peor := Vector3(caja.position.x + (caja.size.x if pl.normal.x < 0.0 else 0.0), caja.position.y + (caja.size.y if pl.normal.y < 0.0 else 0.0), caja.position.z + (caja.size.z if pl.normal.z < 0.0 else 0.0))
			if pl.distance_to(peor) > 0.0:
				dentro = false
				break
		if not dentro:
			continue
		var ll := 0
		var tr := 0
		if g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			var m := (g as MeshInstance3D).mesh
			ll = m.get_surface_count()
			for i in m.get_surface_count():
				var arr := m.surface_get_arrays(i)
				tr += (arr[Mesh.ARRAY_INDEX].size() if arr[Mesh.ARRAY_INDEX] != null else (arr[Mesh.ARRAY_VERTEX].size())) / 3
		elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null and (g as MultiMeshInstance3D).multimesh.mesh != null:
			var mm := (g as MultiMeshInstance3D).multimesh
			ll = mm.mesh.get_surface_count()
			for i in mm.mesh.get_surface_count():
				var arr2 := mm.mesh.surface_get_arrays(i)
				tr += (arr2[Mesh.ARRAY_INDEX].size() if arr2[Mesh.ARRAY_INDEX] != null else arr2[Mesh.ARRAY_VERTEX].size()) / 3 * mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
		elif g is Label3D:
			ll = 1
			tr = 2
		var k := String(n.get_parent().name).rstrip("0123456789@") + " > " + n.get_class() + ":" + String(n.name).rstrip("0123456789@")
		var e: Array = grupos.get(k, [0, 0, 0])
		e[0] += 1
		e[1] += ll
		e[2] += tr
		grupos[k] = e
		total_ll += ll
		total_tr += tr
	var claves := grupos.keys()
	claves.sort_custom(func(a, b) -> bool: return grupos[a][1] > grupos[b][1])
	print("CENSO total estimado: %d llamadas, %d triángulos" % [total_ll, total_tr])
	for k in claves.slice(0, 30):
		print("CENSO x%-4d llamadas %-4d tris %-8d  %s" % [grupos[k][0], grupos[k][1], grupos[k][2], k])

func _esfera_en_frustum(cam: Camera3D, centro: Vector3, radio: float) -> bool:
	for pl: Plane in cam.get_frustum():
		if pl.distance_to(centro) > radio:
			return false
	return true
