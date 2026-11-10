extends Node
## Lo que dibuja la PANTALLA CENTRAL (3-11, el dueño midió 28 FPS en el menú con la GPU al 100 %): llamadas, objetos
## y 3D vivo detrás de la interfaz. Con gráfica (xvfb + opengl3), no --headless:
##   xvfb-run -a godot --rendering-driver opengl3 --path . res://pruebas/zz_medir_menu_gpu.tscn
var _p: Node
var _n := 0
var _dibujados := 0
var _t0 := 0

## PANTALLA (3-11, orden del líder): qué pantalla se deja quieta y se mide. Vacío = la central; `lateral:<id>` = un menú del panel lateral (plantel, dinero, competiciones,
## historia, gente, carrera, operaciones, vida, editar, ajustes, ciudad); `inicio` = la portada; `modos` = el menú de modos; `idioma`, `club` = pantallas de la entrada.
var _pantalla := ""

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.MINIMO if OS.get_environment("MEDIO") == "" else Calidad.MEDIO)   ## (10-11) el nivel también por argumento: `-- baja`, `-- medio`…
	Calidad.ahorro_menu_media = OS.get_environment("AHORRO_MEDIA") == "1"   ## (10-11) AHORRO_MEDIA=1: el ahorro del menú también en MEDIA
	Calidad.sin_msaa = OS.get_environment("SIN_MSAA") != ""
	_pantalla = OS.get_environment("PANTALLA")
	match _pantalla.get_slice(":", 0):
		"inicio":
			_p = load("res://escenas/inicio.tscn").instantiate()
			add_child(_p)
			return
		"idioma", "pais", "config":
			var ant := {"idioma": PantallaIdioma, "pais": PantallaPais}
			_p = (ant[_pantalla] as GDScript).new() if ant.has(_pantalla) else PantallaConfigClub.new()
			add_child(_p)
			add_child(AhorroMenu.new())
			return
		"modos":
			_p = PantallaModos.new()
			add_child(_p)
			add_child(AhorroMenu.new())   ## como el que lleva el orquestador de la entrada
			return
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 5 and _p.has_method("_refrescar"):
		var m := Mundo.new()
		var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"   ## (10-11) PAIS=ESP CLUB=5: otro país y otro club
		m.generar([pais], 4711)
		m.tomar_el_mando(m.ligas[0].clubes[int(OS.get_environment("CLUB")) % m.ligas[0].clubes.size()].id)
		_p.set("mundo", m)
		_p.call("_refrescar")
	if _n == 30 and _pantalla.begins_with("lateral:"):
		var id := _pantalla.get_slice(":", 1)
		for mn: Dictionary in MenuLateral.MENUS:
			if String(mn["id"]) == id:
				PantallaMenu.abrir(_p as Principal, mn)
	if _n == 120:
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
	if _n > 120 and _t0 > 0 and Time.get_ticks_msec() - _t0 > 3000:
		print("MENU %s en 3 s (bajo consumo=%s): %d fotogramas dibujados" % [_pantalla if _pantalla != "" else "central", str(OS.low_processor_usage_mode), _dibujados])
		if OS.get_environment("FOTO") != "":
			get_viewport().get_texture().get_image().save_jpg(OS.get_environment("FOTO"), 0.85)   ## lo que se ve con la pantalla quieta
		get_tree().quit()
