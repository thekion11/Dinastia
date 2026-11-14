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

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ALTO)
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
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
		(_vista.get("_rig") as CameraRig).switch_to(0)
	if _n == CALENTAR - 20:
		_aplicar_desact()
	if _n < CALENTAR:
		return
	var rid := get_viewport().get_viewport_rid()
	_gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
	_cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(rid))
	_frame.append(real_ms)
	if _gpu.size() >= MUESTRAS:
		_hecho = true
		var ruta_cap := OS.get_environment("CAPTURA")   ## CAPTURA=ruta.jpg: guarda el último fotograma para comparar la imagen entre variantes
		if ruta_cap != "":
			get_viewport().get_texture().get_image().save_jpg(ruta_cap, 0.92)
		var f := _mediana(_frame)
		print("PERFIL calidad=%d desact=%s  gpu=%.2f ms  cpu_render=%.2f ms  fotograma=%.2f ms (%.1f FPS)  llamadas=%d  triangulos=%d" % [
			Calidad.elegida, OS.get_environment("DESACT"), _mediana(_gpu), _mediana(_cpu), f, 1000.0 / maxf(f, 0.001),
			int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)),
			int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))])
		get_tree().quit()
