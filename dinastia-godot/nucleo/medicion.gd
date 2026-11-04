class_name Medicion
extends Node
## MEDICIÓN EN EL EQUIPO DEL JUGADOR (30-10-2026, rendimiento). En el contenedor de desarrollo no
## hay GPU (la imagen se dibuja en la CPU): la fluidez real solo se puede medir en un PC de verdad.
## Lanzando el juego exportado con  DINASTIA.exe -- --medir  (o `herramientas/medir_mi_pc.bat`) se
## recorre solo: el menú, crear un mundo, abrir el estadio con la cámara de TV, la ciudad, y deja
## un informe en `user://mediciones/` (en Windows: %APPDATA%/Godot/app_userdata/DINASTIA/mediciones)
## con los tiempos de carga, los FPS medios, el 1 % más lento y el peor fotograma de cada parte.
## No guarda partida ni toca ajustes.

const SEGUNDOS_POR_PARTE := 8.0
## Modo largo (`--benchmark` o el botón de Ajustes): el partido dura varios minutos para ver si el
## rendimiento cae por calor (primer tercio frente al último) y se apaga el vsync para medir de verdad.
const SEG_LARGO_PARTIDO := 180.0
const SEG_LARGO_OTRAS := 20.0
const ESCALAS_BARRIDO := [0.35, 0.5, 0.7, 1.0]
const SEG_BARRIDO := 10.0
## Se pone a true desde el botón de Ajustes (sin argumentos de línea de comandos; vale en Android).
static var forzada := false
## R7 (3-11): la prueba está corriendo y la pantalla está BLOQUEADA (ver `_montar_bloqueo`): nada del menú de detrás responde.
static var en_curso := false
static var largo := false
var _vsync_antes := DisplayServer.VSYNC_ENABLED
var _max_fps_antes := 0
var _json := {"partes": []}
var _muestras := []   ## una por cada ~30 fotogramas: ms de CPU, llamadas, triángulos, objetos
var _tercios := PackedFloat32Array()

var _informe := PackedStringArray()
var _parte := ""
var _t_parte := 0.0
var _frames: PackedFloat32Array = PackedFloat32Array()
var _ult := 0
var _mundo: Mundo
var _vista: Node
var _paso := 0
var _capa_bloqueo: CanvasLayer
var _rotulo_bloqueo: Label
var _salir_con_atras_antes := true
var _escala_antes := 0.5

static func pedida() -> bool:
	var a := OS.get_cmdline_user_args()
	return forzada or "--medir" in a or "--benchmark" in a

static func es_largo() -> bool:
	return largo or "--benchmark" in OS.get_cmdline_user_args()

static func empezar(arbol: SceneTree) -> void:
	var m := Medicion.new()
	m.name = "Medicion"
	m.process_mode = Node.PROCESS_MODE_ALWAYS
	arbol.root.add_child.call_deferred(m)

func _ready() -> void:
	largo = es_largo()
	## Sin vsync ni tope de FPS: lo que se mide es el tiempo de fotograma, no los 60/90 Hz de la pantalla.
	_vsync_antes = DisplayServer.window_get_vsync_mode()
	_max_fps_antes = Engine.max_fps
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_json["version"] = ProjectSettings.get_setting("application/config/version", "")
	_json["godot"] = Engine.get_version_info()["string"]
	_escala_antes = Calidad.escala_minimo
	_json["fecha"] = Time.get_datetime_string_from_system()
	_json["gpu"] = RenderingServer.get_video_adapter_name()
	_json["gpu_vendor"] = RenderingServer.get_video_adapter_vendor()
	_json["cpu"] = OS.get_processor_name()
	_json["hilos"] = OS.get_processor_count()
	_json["so"] = OS.get_name()
	_json["modelo"] = OS.get_model_name()
	_json["ram_mb"] = int(OS.get_memory_info().get("physical", 0)) / 1048576
	_json["renderizador"] = RenderingServer.get_current_rendering_method()
	_json["modo"] = "largo" if largo else "corto"
	var hz := DisplayServer.screen_get_refresh_rate()
	_json["pantalla_hz"] = 0.0 if (is_nan(hz) or hz < 0.0) else hz   ## Xvfb/sin pantalla devuelve NaN
	_linea("Modo: %s · vsync apagado · pantalla %.0f Hz" % [_json["modo"], _json["pantalla_hz"]])
	_linea("DINASTÍA %s · Godot %s · %s" % [ProjectSettings.get_setting("application/config/version", ""),
		Engine.get_version_info()["string"], Time.get_datetime_string_from_system()])
	_linea("GPU: %s (%s) · CPU: %s, %d hilos · SO: %s" % [RenderingServer.get_video_adapter_name(),
		RenderingServer.get_video_adapter_vendor(), OS.get_processor_name(), OS.get_processor_count(), OS.get_name()])
	_linea("Renderizador: %s · Calidad: %s · Ventana: %s" % [RenderingServer.get_current_rendering_method(),
		str(Calidad.elegida), str(get_viewport().get_visible_rect().size)])
	_linea("Extensión C++: %s" % ("activa" if Nativo.obj() != null else "NO (se usa GDScript)"))
	_linea("Paquete real (caras): %s · base real disponible: %s · fotos: %d" % [PaqueteReal.montado if PaqueteReal.montado != "" else "no",
		"sí" if Datos.hay_pack_real() else "no", DirAccess.get_files_at("res://recursos/caras_reales_256").size()])
	_linea("Arranque hasta ver el menú: %d ms" % int(Engine.get_meta("menu_ms", Time.get_ticks_msec())))
	_linea("Menú completo (partida en curso, perfil, álbum): %d ms" % Time.get_ticks_msec())
	_montar_bloqueo()
	_empezar_parte("menú")

func _linea(t: String) -> void:
	_informe.append(t)
	print("MEDICION ", t)

func _empezar_parte(nombre: String) -> void:
	_parte = nombre
	if is_instance_valid(_rotulo_bloqueo):
		_rotulo_bloqueo.text = "PRUEBA DE RENDIMIENTO EN CURSO · %s\nSe recorre sola: no toques nada. (Unos minutos.)" % nombre
	_t_parte = 0.0
	_frames = PackedFloat32Array()
	_ult = Time.get_ticks_usec()

## Cronometra una carga (el tiempo que la función bloquea el juego).
func _cargar(nombre: String, f: Callable) -> void:
	var t := Time.get_ticks_usec()
	f.call()
	_linea("Carga %-22s %7d ms" % [nombre, (Time.get_ticks_usec() - t) / 1000])

## (4-11, A4-REND) La parte «ciudad» medía también la CARGA: `abrir` construye por etapas entre fotogramas y, hasta que
## `completa` es verdadero, la ciudad se dibuja sin agrupar ni ocluir (9.273 llamadas y 13,5 M de triángulos en esos
## fotogramas). Según lo lenta que fuera la máquina, esos fotogramas entraban más o menos en la media y el presupuesto
## daba FALLO unas veces y 0 fallos otras. Ahora la parte no empieza a contar hasta que la ciudad está completa
## (con tope de 180 s por si nunca lo estuviera) y la espera se anota.
var _espera_ciudad := 0.0

func _ciudad_lista() -> bool:
	var c: Variant = _vista.get("_ciudad") if _vista != null else null
	return c == null or bool(c.get("completa"))

func _process(delta: float) -> void:
	var ahora := Time.get_ticks_usec()
	if _parte == "ciudad" and _espera_ciudad < 180.0 and not _ciudad_lista():
		_espera_ciudad += delta
		_t_parte = 0.0
		_frames = PackedFloat32Array()
		_muestras = []
		_ult = ahora
		return
	if _parte == "ciudad" and _espera_ciudad > 0.0 and not _json.has("ciudad_espera_s"):
		_json["ciudad_espera_s"] = snappedf(_espera_ciudad, 0.1)
		_linea("La ciudad terminó de construirse a los %.1f s de abrirla: la medición empieza ahí" % _espera_ciudad)
	_frames.append((ahora - _ult) / 1000.0)
	_ult = ahora
	_t_parte += delta
	if _frames.size() % 30 == 0:
		_muestras.append([Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			float(OS.get_static_memory_usage()) / 1048576.0, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])
	if _frames.size() <= 3:
		if _frames.size() > 1:
			_linea("  fotograma %d de «%s»: %.0f ms" % [_frames.size() - 1, _parte, _frames[-1]])
		return
	if _t_parte < _duracion():
		return
	_cerrar_parte()
	if _paso == 0:
		_linea("Scripts compilados en segundo plano a los: %d ms" % int(Engine.get_meta("compilado_ms", -1)))
	_paso += 1
	match _paso:
		1:
			_cargar("crear el mundo", func() -> void:
				_mundo = Mundo.new()
				_mundo.generar(["CHI"], 777)
				_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id))
			_cargar("abrir el estadio", func() -> void:
				var par := _mundo.proximo_partido()
				_vista = load("res://ui/estadio.gd").new()
				get_tree().root.add_child(_vista)
				_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))
				var rig = _vista.get("_rig")
				if rig != null:
					rig.switch_to(maxi(0, rig.camera_names.find("Principal (TV)"))))
			_empezar_parte("estadio (cámara TV)")
		2, 3, 4, 5, 6, 7, 8, 9:
			## BARRIDO DE RESOLUCIÓN 3D (4-11, rendimiento móvil): el mismo estadio en MÍNIMA al 35/50/70/100 % para saber, con una
			## sola prueba en el teléfono, qué ajuste llega a 60 FPS (la gráfica del móvil manda: 3-11, GPU al 100 % y CPU al 0 %).
			## Las cuatro primeras CON el MSAA x2 de MÍNIMA y las cuatro siguientes SIN él (R01): lo que cuesta el suavizado de bordes en ESTE teléfono.
			var e: float = ESCALAS_BARRIDO[(_paso - 2) % 4]
			Calidad.sin_msaa = _paso >= 6
			Calidad.escala_minimo = e
			Calidad.aplicar_viewport(get_viewport(), Calidad.MINIMO)
			_empezar_parte("estadio MÍNIMA al %d %%%s" % [int(round(e * 100.0)), " sin MSAA" if Calidad.sin_msaa else ""])
		10:
			Calidad.sin_msaa = false
			_resumen_msaa()
			Calidad.escala_minimo = _escala_antes
			Calidad.aplicar_viewport(get_viewport(), Calidad.elegida)
			_vista.queue_free()
			_cargar("abrir la ciudad", func() -> void:
				_vista = CargaCiudad.de("VistaCiudad").new()
				get_tree().root.add_child(_vista)
				_vista.abrir(_mundo.mi_club(), _mundo.obras, _mundo.ciudad, _mundo.perfil_estadio_de(_mundo.mi_club())))
			_empezar_parte("ciudad")
		_:
			_terminar()

## Resumen del MSAA: por cada escala del barrido, los FPS con y sin él y lo que se gana al apagarlo.
func _resumen_msaa() -> void:
	var con_m := {}
	var sin_m := {}
	for d: Dictionary in _json["partes"]:
		var n := String(d["parte"])
		if not n.begins_with("estadio MÍNIMA al "):
			continue
		var esc := n.get_slice("%", 0).trim_prefix("estadio MÍNIMA al ").strip_edges()
		if n.ends_with("sin MSAA"):
			sin_m[esc] = float(d["fps_medio"])
		else:
			con_m[esc] = float(d["fps_medio"])
	for esc: String in con_m:
		if sin_m.has(esc):
			var gana := 100.0 * (float(sin_m[esc]) / maxf(float(con_m[esc]), 0.001) - 1.0)
			_linea("MSAA a %s %%: con %.1f FPS · sin %.1f FPS · apagarlo %s %.0f %%" % [esc, con_m[esc], sin_m[esc], "gana" if gana >= 0.0 else "pierde", absf(gana)])
			_json["msaa_" + esc] = {"con": con_m[esc], "sin": sin_m[esc], "gana_pct": snappedf(gana, 0.1)}

func _duracion() -> float:
	if _parte.contains("MÍNIMA al"):
		return SEG_BARRIDO
	if not largo:
		return SEGUNDOS_POR_PARTE
	return SEG_LARGO_PARTIDO if _parte.begins_with("estadio") else SEG_LARGO_OTRAS

func _media_col(c: int) -> float:
	var t := 0.0
	for m: Array in _muestras:
		t += float(m[c])
	return t / maxf(1.0, _muestras.size())

func _fps_de(f: Array) -> float:
	var t := 0.0
	for x: float in f:
		t += x
	return 1000.0 / maxf(0.001, t / maxf(1.0, f.size()))

func _cerrar_parte() -> void:
	var f := Array(_frames.slice(3))   ## sin los 3 primeros (ya informados aparte)
	f.sort()
	if f.is_empty():
		return
	var media := 0.0
	for x: float in f:
		media += x
	media /= f.size()
	var peor_1: float = f[int(f.size() * 0.99)]
	var d := {"parte": _parte, "fps_medio": snappedf(1000.0 / media, 0.1), "fps_p1": snappedf(1000.0 / maxf(peor_1, 0.001), 0.1),
		"fps_min": snappedf(1000.0 / maxf(f[-1], 0.001), 0.1), "peor_ms": snappedf(f[-1], 0.1), "fotogramas": f.size(),
		"cpu_ms": snappedf(_media_col(0), 0.01), "llamadas": int(_media_col(1)), "triangulos": int(_media_col(2)),
		"objetos": int(_media_col(3)), "memoria_mb": snappedf(_media_col(4), 0.1), "video_mb": snappedf(_media_col(5), 0.1)}
	if largo and _frames.size() > 90:
		## Calor: FPS del primer tercio de la parte frente al último (en orden de tiempo, no ordenado).
		var orden := Array(_frames.slice(3))
		var n := orden.size() / 3
		d["fps_primer_tercio"] = snappedf(_fps_de(orden.slice(0, n)), 0.1)
		d["fps_ultimo_tercio"] = snappedf(_fps_de(orden.slice(orden.size() - n)), 0.1)
		d["caida_pct"] = snappedf(100.0 * (1.0 - d["fps_ultimo_tercio"] / maxf(0.001, d["fps_primer_tercio"])), 0.1)
	_json["partes"].append(d)
	_muestras = []
	_linea("%-22s FPS medios %5.1f · 1 %% más lento %5.1f FPS · peor fotograma %6.0f ms · %d fotogramas"
		% [_parte, 1000.0 / media, 1000.0 / maxf(peor_1, 0.001), f[-1], f.size()])

func _terminar() -> void:
	_quitar_bloqueo()
	DisplayServer.window_set_vsync_mode(_vsync_antes)
	Engine.max_fps = _max_fps_antes
	DirAccess.make_dir_recursive_absolute("user://mediciones")
	var base := "user://mediciones/medicion_%s" % Time.get_datetime_string_from_system().replace(":", "-")
	var texto := "\n".join(_informe) + "\n"
	for par in [[base + ".txt", texto], [base + ".json", JSON.stringify(_json, "  ")]]:
		var a := FileAccess.open(par[0], FileAccess.WRITE)
		if a != null:
			a.store_string(par[1])
			a.close()
	var ruta := ProjectSettings.globalize_path(base + ".txt")
	print("MEDICION informe en ", ruta)
	print("MEDICION_JSON ", JSON.stringify(_json))   ## también sale por logcat en Android
	DisplayServer.clipboard_set(texto)
	if forzada:
		_mostrar_resultado(texto, ruta)   ## desde el botón: se queda en pantalla, sin adb
		return
	if OS.get_name() != "Android":
		OS.shell_show_in_file_manager(ruta)
	get_tree().quit()

## Pantalla final con el informe, su ruta y «Cerrar» (vuelve al menú). Ya está copiado al portapapeles.
func _mostrar_resultado(texto: String, ruta: String) -> void:
	if is_instance_valid(_vista):
		_vista.queue_free()
	var capa := CanvasLayer.new()
	capa.layer = 100
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.06, 0.09, 0.96)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(fondo)
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.offset_left = 24
	caja.offset_right = -24
	caja.offset_top = 24
	caja.offset_bottom = -24
	capa.add_child(caja)
	var et := Label.new()
	et.text = "Informe guardado en:\n%s\n(copiado al portapapeles; mándalo tal cual)\n\n%s" % [ruta, texto]
	et.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	et.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.add_child(et)
	var b := Button.new()
	b.text = "Cerrar"
	b.custom_minimum_size = Vector2(0, 72)
	b.pressed.connect(func() -> void:
		forzada = false
		capa.get_tree().change_scene_to_file("res://escenas/inicio.tscn"))
	caja.add_child(b)
	get_tree().root.add_child(capa)
	queue_free()

## R7 (3-11, prueba del dueño: «el modo rendimiento se buggea y deja volver atrás y crear partida mientras corre»). Mientras la prueba recorre menú,
## estadio y ciudad, el menú de detrás SEGUÍA vivo: se podía pulsar «Crear partida», volver atrás o cambiar de pantalla, y la medición se mezclaba
## con lo que hiciera la persona. Ahora una capa por encima de todo (128) se come el ratón y el dedo; el teclado y el mando se tragan; el botón
## «atrás» de Android no cierra el juego; y solo queda un botón, «Cancelar la prueba», que restaura todo y vuelve al menú.
func _montar_bloqueo(forzar := false) -> void:
	if DisplayServer.get_name() == "headless" and not forzar:   ## sin pantalla no hay nadie que toque nada (`forzar`: la prueba)
		return
	en_curso = true
	_salir_con_atras_antes = get_tree().quit_on_go_back
	get_tree().quit_on_go_back = false
	_capa_bloqueo = CanvasLayer.new()
	_capa_bloqueo.layer = 128
	_capa_bloqueo.name = "BloqueoMedicion"
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.0)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	_capa_bloqueo.add_child(fondo)
	var barra := PanelContainer.new()
	barra.set_anchors_preset(Control.PRESET_TOP_WIDE)
	barra.mouse_filter = Control.MOUSE_FILTER_STOP
	_capa_bloqueo.add_child(barra)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	barra.add_child(fila)
	_rotulo_bloqueo = Label.new()
	_rotulo_bloqueo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rotulo_bloqueo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fila.add_child(_rotulo_bloqueo)
	var cancelar := Button.new()
	cancelar.text = "Cancelar la prueba"
	cancelar.custom_minimum_size = Vector2(0, 56)
	cancelar.pressed.connect(_cancelar)
	fila.add_child(cancelar)
	get_tree().root.add_child(_capa_bloqueo)

func _quitar_bloqueo() -> void:
	if not en_curso:
		return
	en_curso = false
	get_tree().quit_on_go_back = _salir_con_atras_antes
	if is_instance_valid(_capa_bloqueo):
		_capa_bloqueo.queue_free()

## Cancelar a mano: deja la pantalla y los ajustes como estaban y vuelve al menú, sin informe.
func _cancelar() -> void:
	_quitar_bloqueo()
	DisplayServer.window_set_vsync_mode(_vsync_antes)
	Engine.max_fps = _max_fps_antes
	forzada = false
	largo = false
	if not is_equal_approx(Calidad.escala_minimo, _escala_antes) or Calidad.sin_msaa:   ## cancelada en mitad del barrido de resolución o de MSAA
		Calidad.sin_msaa = false
		Calidad.escala_minimo = _escala_antes
		Calidad.aplicar_viewport(get_viewport(), Calidad.elegida)
	if is_instance_valid(_vista):
		_vista.queue_free()
	var arbol := get_tree()
	queue_free()
	arbol.change_scene_to_file("res://escenas/inicio.tscn")

## El teclado y el mando no llegan al menú de detrás mientras corre la prueba (el ratón y el dedo ya los para la capa).
func _input(e: InputEvent) -> void:
	if en_curso and (e is InputEventKey or e is InputEventJoypadButton or e is InputEventJoypadMotion or e is InputEventShortcut):
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	Calidad.sin_msaa = false   ## por si se sale de golpe en mitad del barrido de MSAA
	_quitar_bloqueo()

