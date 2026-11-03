extends Node
## Lo que dibuja la PANTALLA CENTRAL (3-11, el dueño midió 28 FPS en el menú con la GPU al 100 %): llamadas, objetos
## y 3D vivo detrás de la interfaz. Con gráfica (xvfb + opengl3), no --headless:
##   xvfb-run -a godot --rendering-driver opengl3 --path . res://pruebas/zz_medir_menu_gpu.tscn
var _p: Node
var _n := 0
var _dibujados := 0
var _t0 := 0

func _ready() -> void:
	Calidad.elegida = Calidad.MINIMO if OS.get_environment("MEDIO") == "" else Calidad.MEDIO
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 5:
		var m := Mundo.new()
		m.generar(["CHI", "ARG"], 4711)
		m.tomar_el_mando(m.ligas[0].clubes[0].id)
		_p.set("mundo", m)
		_p.call("_refrescar")
	if _n == 90:
		var vp := get_viewport()
		print("MENU llamadas %d  objetos %d  primitivas %d" % [
			vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
			vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME),
			vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)])
		print("MENU total (2D+3D): llamadas %d  primitivas %d  memoria de vídeo %d MB" % [
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576])
		for n in get_tree().root.find_children("*", "VisualInstance3D", true, false):
			print("MENU 3D vivo: ", n.get_path(), " ", n.get_class())
		var n3d := 0
		var vis3d := 0
		for n in get_tree().root.find_children("*", "VisualInstance3D", true, false):
			n3d += 1
			if (n as VisualInstance3D).is_visible_in_tree():
				vis3d += 1
		var subs := get_tree().root.find_children("*", "SubViewport", true, false)
		var vivos := []
		for s: Node in subs:
			if (s as SubViewport).render_target_update_mode == SubViewport.UPDATE_ALWAYS:
				vivos.append(str(s.get_path()))
		var animados := 0
		var canvas := 0
		for c in get_tree().root.find_children("*", "CanvasItem", true, false):
			if (c as CanvasItem).is_visible_in_tree():
				canvas += 1
				var mat := (c as CanvasItem).material
				if mat is ShaderMaterial and (mat as ShaderMaterial).shader != null and "TIME" in (mat as ShaderMaterial).shader.code:
					animados += 1
		print("MENU 3D: %d nodos, %d visibles · SubViewports %d (siempre activos: %s) · CanvasItems visibles %d · con shader animado %d · procesando %d" % [
			n3d, vis3d, subs.size(), str(vivos), canvas, animados, get_tree().root.find_children("*", "", true, false).filter(func(x: Node) -> bool: return x.is_processing()).size()])
		var quien := []
		for x in get_tree().root.find_children("*", "", true, false):
			if x.is_processing():
				quien.append(str(x.get_path()).get_file() + ":" + x.get_class())
		print("MENU procesan: ", quien)
		_dibujados = 0
		RenderingServer.frame_post_draw.connect(func() -> void: _dibujados += 1)
		_t0 = Time.get_ticks_msec()
	if _n > 90 and _t0 > 0 and Time.get_ticks_msec() - _t0 > 3000:
		print("MENU en 3 s (bajo consumo=%s): %d fotogramas dibujados" % [str(OS.low_processor_usage_mode), _dibujados])
		get_tree().quit()
