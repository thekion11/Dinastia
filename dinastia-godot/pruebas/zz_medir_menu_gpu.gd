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
	_fase_estilo()
	_fase_mundo()
	_fase_pantalla()
	_fase_sombra()
	if _n == 120:
		_fase_medir()
	_fase_cierre()


## Estilo del menú (ESTILO_MENU=pildora|compacto|barra), en el fotograma 4.
func _fase_estilo() -> void:
	if _n == 4 and OS.get_environment("ESTILO_MENU") != "":   ## (15-11) ESTILO_MENU=pildora|compacto|barra
		_p.set("_estilo_menu", OS.get_environment("ESTILO_MENU"))


## El mundo de la medición (PAIS y CLUB), en el fotograma 5.
func _fase_mundo() -> void:
	if _n == 5 and _p.has_method("_refrescar"):
		var m := Mundo.new()
		var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"   ## (10-11) PAIS=ESP CLUB=5: otro país y otro club
		m.generar([pais], 4711)
		m.tomar_el_mando(m.ligas[0].clubes[int(OS.get_environment("CLUB")) % m.ligas[0].clubes.size()].id)
		_p.set("mundo", m)
		_p.call("_refrescar")


## Abre el menú lateral pedido (PANTALLA=lateral:<id>) en el fotograma 30 y anota cuánto tarda en verse.
func _fase_pantalla() -> void:
	if _n == 30 and _pantalla.begins_with("lateral:"):
		var id := _pantalla.get_slice(":", 1)
		for mn: Dictionary in MenuLateral.MENUS:
			if String(mn["id"]) == id:
				var t_abrir := Time.get_ticks_usec()
				PantallaMenu.abrir(_p as Principal, mn)
				var t_montar := Time.get_ticks_usec()
				await RenderingServer.frame_post_draw
				print("MENU apertura %s: montar %d ms · hasta verse %d ms" % [id, (t_montar - t_abrir) / 1000, (Time.get_ticks_usec() - t_abrir) / 1000])


## Prueba de las cajas sin sombra (SIN_SOMBRA_CAJAS), en el fotograma 110.
func _fase_sombra() -> void:
	if _n == 110 and OS.get_environment("SIN_SOMBRA_CAJAS") != "":   ## (15-11) prueba: las cajas sin sombra, ¿cuántas llamadas ahorra?
		_quitar_sombra_cajas()


## Quita la sombra de todas las cajas planas del menú y las vuelve a dibujar.
func _quitar_sombra_cajas() -> void:
	for c in get_tree().root.find_children("*", "Control", true, false):
		for nombre: String in ["panel", "normal", "hover", "pressed", "focus"]:
			if (c as Control).has_theme_stylebox(nombre):
				var sb := (c as Control).get_theme_stylebox(nombre)
				if sb is StyleBoxFlat:
					(sb as StyleBoxFlat).shadow_size = 0
		(c as Control).queue_redraw()


## La medición del fotograma 120: llamadas, objetos, 3D vivo, lo que procesa y el censo (si se pide).
func _fase_medir() -> void:
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
	_medir_3d_y_canvas()
	_medir_procesos()
	if OS.get_environment("CENSO") != "":   ## (15-11) qué rompe el agrupado de dibujo en 2D: sombras de texto y de cajas, texturas distintas
		_medir_censo()
	_dibujados = 0
	RenderingServer.frame_post_draw.connect(func() -> void: _dibujados += 1)
	_t0 = Time.get_ticks_msec()


## Los nodos 3D visibles, los SubViewports que siempre se actualizan y los dibujos 2D animados.
func _medir_3d_y_canvas() -> void:
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


## Quién está procesando en cada fotograma.
func _medir_procesos() -> void:
	var quien := []
	for x in get_tree().root.find_children("*", "", true, false):
		if x.is_processing():
			quien.append(str(x.get_path()).get_file() + ":" + x.get_class())
	print("MENU procesan: ", quien)


## El censo de etiquetas, cajas, texturas y clases (CENSO=1).
func _medir_censo() -> void:
	var lab := 0
	var lab_sombra := 0
	var cajas_sombra := 0
	var cajas := 0
	var texs := {}
	var por_clase := {}
	for c in get_tree().root.find_children("*", "Control", true, false):
		if not (c as Control).is_visible_in_tree():
			continue
		por_clase[c.get_class()] = int(por_clase.get(c.get_class(), 0)) + 1
		if c is Label:
			lab += 1
			if _censo_sombra_etiqueta(c as Label):
				lab_sombra += 1
		var cc := _censo_caja(c as Control)
		cajas += cc.x
		cajas_sombra += cc.y
		if c is TextureRect and (c as TextureRect).texture != null:
			texs[(c as TextureRect).texture.get_rid()] = true
	print("MENU censo: etiquetas %d (con sombra %d) · cajas planas %d (con sombra %d) · texturas distintas %d · por clase %s" % [lab, lab_sombra, cajas, cajas_sombra, texs.size(), str(por_clase)])


## ¿Tiene sombra la etiqueta (la del tema o la de sus ajustes de etiqueta)?
func _censo_sombra_etiqueta(l: Label) -> bool:
	return l.get_theme_color("font_shadow_color").a > 0.01 or (l.label_settings != null and l.label_settings.shadow_color.a > 0.01 and l.label_settings.shadow_size > 0)


## Las cajas planas del control: [cuántas, cuántas con sombra].
func _censo_caja(c: Control) -> Vector2i:
	var n := 0
	var con := 0
	for nombre: String in ["panel", "normal"]:
		if c.has_theme_stylebox(nombre):
			var sb := c.get_theme_stylebox(nombre)
			if sb is StyleBoxFlat:
				n += 1
				if (sb as StyleBoxFlat).shadow_size > 0:
					con += 1
	return Vector2i(n, con)


## Al cabo de 3 s desde la medición: anota los fotogramas dibujados, guarda la foto si se pide y sale.
func _fase_cierre() -> void:
	if _n > 120 and _t0 > 0 and Time.get_ticks_msec() - _t0 > 3000:
		print("MENU %s en 3 s (bajo consumo=%s): %d fotogramas dibujados" % [_pantalla if _pantalla != "" else "central", str(OS.low_processor_usage_mode), _dibujados])
		if OS.get_environment("FOTO") != "":
			get_viewport().get_texture().get_image().save_jpg(OS.get_environment("FOTO"), 0.85)   ## lo que se ve con la pantalla quieta
		get_tree().quit()
