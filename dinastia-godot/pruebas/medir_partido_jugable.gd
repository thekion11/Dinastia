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
		"luz": for l in _pj.find_children("*", "DirectionalLight3D", true, false): (l as Light3D).visible = false
		"jugadores": for n in _pj.motor.jugadores: ((n as Dictionary)["node"] as Node3D).visible = false
		"mundo3d": _pj._vp.render_target_update_mode = SubViewport.UPDATE_DISABLED

func _medir() -> void:
	await _conteos("base")
	if OS.get_environment("QUITAR") != "":
		var base_ms := await _ms_pared()
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
