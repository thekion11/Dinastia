extends Node
## PERFILADOR DE GPU/CPU DEL PARTIDO (14-11-2026, optimización de FPS).
##
##   godot --path . --resolution 1280x720 res://pruebas/perfilar_gpu.tscn -- ultra
##   DESACT=msaa,sombra,ssao godot ... -- alto
##
## Mide, con el mismo montaje que `medir_partido.gd`, el tiempo de GPU y de CPU del render
## (`RenderingServer.viewport_get_measured_render_time_*`) y el fotograma entero (reloj real).
## `DESACT` (lista separada por comas) APAGA un efecto SOLO para diagnosticar cuánto cuesta; no es una
## opción del juego: msaa, taa, fxaa, sombra, ssao, ssil, ssr, sdfgi, glow, niebla, volumetrica, ajuste, esc75, esc50.
## Salida: una línea `PERFIL ...` con las medianas.

const CALENTAR := 90
const MUESTRAS := 150

var _vista: VistaEstadio
var _n := 0
var _gpu: Array[float] = []
var _cpu: Array[float] = []
var _frame: Array[float] = []
var _hecho := false
var _t_ant := 0
var _proc: Array[float] = []
var _fis: Array[float] = []

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ALTO)
	var mundo := Mundo.new()
	## PAIS=ESP / CLUB=3: varían el estadio de la captura (regla del dueño: nunca un solo equipo).
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	mundo.generar([pais], 4711)
	var clubes: Array = mundo.ligas[0].clubes
	mundo.mi_club_id = clubes[clampi(OS.get_environment("CLUB").to_int(), 0, clubes.size() - 1)].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]), {})
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0

func _entorno() -> Environment:
	var we: Node = _vista.find_child("WorldEnvironment", true, false)
	if we != null and we is WorldEnvironment:
		return (we as WorldEnvironment).environment
	var w3 := get_viewport().find_world_3d()
	return w3.environment if w3 != null else null

func _aplicar_desact() -> void:
	var lista := OS.get_environment("DESACT").split(",", false)
	var vp := get_viewport()
	var env := _entorno()
	for k in lista:
		match k:
			"msaa": vp.msaa_3d = Viewport.MSAA_DISABLED
			"taa": vp.use_taa = false
			"fxaa": vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			"sombra":
				for l in _vista.find_children("*", "Light3D", true, false):
					(l as Light3D).shadow_enabled = false
			"ssao": if env != null: env.ssao_enabled = false
			"ssil": if env != null: env.ssil_enabled = false
			"ssr": if env != null: env.ssr_enabled = false
			"sdfgi": if env != null: env.sdfgi_enabled = false
			"glow": if env != null: env.glow_enabled = false
			"niebla": if env != null: env.fog_enabled = false
			"volumetrica": if env != null: env.volumetric_fog_enabled = false
			"ajuste": if env != null: env.adjustment_enabled = false
			"fsr77":
				vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
				vp.scaling_3d_scale = 0.77
			"fsr67":
				vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
				vp.scaling_3d_scale = 0.67
			"fsr1_77":
				vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
				vp.scaling_3d_scale = 0.77
			"taaon": vp.use_taa = true
			"msaa2": vp.msaa_3d = Viewport.MSAA_2X
			"esc75": vp.scaling_3d_scale = 0.75
			"esc50": vp.scaling_3d_scale = 0.5

func _contar(n: Node) -> int:
	var c := 1
	for h in n.get_children():
		c += _contar(h)
	return c

## LISTAR=1: imprime los hijos directos de la vista con su número de nodos y si procesan.
## APAGAR=Nombre1,Nombre2: pone process_mode = DISABLED a esos nodos (y sus hijos) SOLO para diagnosticar su coste de CPU.
func _apagar_procesos() -> void:
	if OS.get_environment("LISTAR") != "":
		for h in _vista.get_children():
			print("LISTA %s (%s) nodos=%d proc=%s" % [h.name, h.get_class(), _contar(h), str(h.is_processing())])
		var raiz3d: Node = _vista.get("_raiz3d")
		if raiz3d != null:
			for h in raiz3d.get_children():
				print("LISTA3D %s (%s) nodos=%d proc=%s" % [h.name, h.get_class(), _contar(h), str(h.is_processing())])
	if OS.get_environment("CONTAR") != "":
		## CONTAR=1: nodos de todo el árbol con `_process` o `_physics_process` activo, agrupados por script.
		var por_script := {}
		var pila: Array[Node] = [get_tree().root]
		while not pila.is_empty():
			var n: Node = pila.pop_back()
			pila.append_array(n.get_children())
			if n.is_processing() or n.is_physics_processing():
				var s: Variant = n.get_script()
				var clave: String = (s as Script).resource_path if s != null else "(nativo) " + n.get_class()
				if clave == "":
					clave = "(script sin ruta) %s ej: %s" % [n.get_class(), n.get_path()]
				por_script[clave] = int(por_script.get(clave, 0)) + 1
		var claves := por_script.keys()
		claves.sort_custom(func(a: Variant, b: Variant) -> bool: return por_script[a] > por_script[b])
		for k in claves:
			print("PROC %4d  %s" % [por_script[k], k])
	var por_ruta := OS.get_environment("APAGAR_SCRIPT")   ## APAGAR_SCRIPT=anim_transiciones.gd,...: apaga el `_process` de todos los nodos con ese script (solo diagnóstico)
	if por_ruta != "":
		var apagados := 0
		var pila2: Array[Node] = [get_tree().root]
		while not pila2.is_empty():
			var m: Node = pila2.pop_back()
			pila2.append_array(m.get_children())
			var sc: Variant = m.get_script()
			if sc != null:
				for fin in por_ruta.split(",", false):
					if (sc as Script).resource_path.ends_with(fin) or (fin == "SINRUTA" and (sc as Script).resource_path == ""):
						m.set_process(false)
						m.set_physics_process(false)
						apagados += 1
		print("APAGADOS %d nodos por script" % apagados)
	for nombre in OS.get_environment("APAGAR").split(",", false):
		if nombre == "VISTA":
			_vista.set_process(false)   ## todo el `_process` de VistaEstadio (motor del partido, cine, HUD)
			print("APAGADO VistaEstadio._process")
			continue
		for n in _vista.find_children(nombre, "", true, false):
			n.process_mode = Node.PROCESS_MODE_DISABLED
			print("APAGADO ", n.get_path())

func _mediana(a: Array[float]) -> float:
	if a.is_empty():
		return 0.0
	var b := a.duplicate()
	b.sort()
	return b[b.size() / 2]

func _process(_d: float) -> void:
	if _hecho:
		return
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
		return
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
		return
	_n += 1
	var ahora := Time.get_ticks_usec()
	var real_ms := (ahora - _t_ant) / 1000.0
	_t_ant = ahora
	if _n == 12 and OS.get_environment("CONGELAR") != "":
		Engine.time_scale = 0.0   ## CONGELAR=1: la escena se detiene en el mismo punto en todas las variantes, para comparar capturas
	if _n == 5:
		(_vista.get("_rig") as CameraRig).switch_to(OS.get_environment("CAM").to_int())   ## CAM=n: otra cámara del rig para la captura (0 = Transmisión)
	if _n == CALENTAR - 20:
		_aplicar_desact()
		_apagar_procesos()
	if _n < CALENTAR:
		return
	var rid := get_viewport().get_viewport_rid()
	_gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
	_cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(rid))
	_frame.append(real_ms)
	_proc.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	_fis.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	if _gpu.size() >= MUESTRAS:
		_hecho = true
		var ruta_cap := OS.get_environment("CAPTURA")   ## CAPTURA=ruta.jpg: guarda el último fotograma para comparar la imagen entre variantes
		if ruta_cap != "":
			get_viewport().get_texture().get_image().save_jpg(ruta_cap, 0.92)
		var f := _mediana(_frame)
		print("PERFIL calidad=%d desact=%s  gpu=%.2f ms  cpu_render=%.2f ms  scripts=%.2f ms  fisica=%.2f ms  fotograma=%.2f ms (%.1f FPS)  llamadas=%d  triangulos=%d" % [
			Calidad.elegida, OS.get_environment("DESACT"), _mediana(_gpu), _mediana(_cpu), _mediana(_proc), _mediana(_fis), f, 1000.0 / maxf(f, 0.001),
			int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)),
			int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))])
		if OS.get_environment("PIEZAS") != "":
			_medir_piezas()
		get_tree().quit()

## PIEZAS=1: cronometra, llamándolas 200 veces, las piezas del `_process` de VistaEstadio (µs por llamada).
func _medir_piezas() -> void:
	var motor: Object = _vista.get("_motor")
	var stats: Object = _vista.get("_stats")
	Engine.time_scale = 0.0
	var piezas: Array = [
		["motor.paso(1/60)", func() -> void: motor.call("paso", 1.0 / 60.0)],
		["_pistas_camara", func() -> void: _vista.call("_pistas_camara")],
		["_rotulo_automatico", func() -> void: _vista.call("_rotulo_automatico")],
		["_actualizar_tacticas", func() -> void: _vista.call("_actualizar_tacticas")],
		["_refrescar_marcador", func() -> void: _vista.call("_refrescar_marcador")],
		["_mover_cursor", func() -> void: _vista.call("_mover_cursor")],
		["_hud_juego", func() -> void: _vista.call("_hud_juego")],
		["_cine_paso", func() -> void: _vista.call("_cine_paso", 0.016)],
		["_escalar_rotulos", func() -> void: _vista.call("_escalar_rotulos")],
		["_despejar_rotulos", func() -> void: _vista.call("_despejar_rotulos", 0.016)],
		["_hud_realizacion", func() -> void: _vista.call("_hud_realizacion", 0.016)],
		["ocultar_techo_ante", func() -> void: StadiumBuilder.ocultar_techo_ante(get_viewport().get_camera_3d())],
	]
	if stats != null:
		piezas.append(["stats.muestrear", func() -> void: stats.call("muestrear", motor, 1.0 / 60.0)])
	for p in piezas:
		var f: Callable = p[1]
		var t0 := Time.get_ticks_usec()
		for i in 200:
			f.call()
		print("PIEZA %-24s %8.1f us" % [p[0], (Time.get_ticks_usec() - t0) / 200.0])
