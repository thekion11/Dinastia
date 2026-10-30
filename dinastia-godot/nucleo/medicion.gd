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

var _informe := PackedStringArray()
var _parte := ""
var _t_parte := 0.0
var _frames: PackedFloat32Array = PackedFloat32Array()
var _ult := 0
var _mundo: Mundo
var _vista: Node
var _paso := 0

static func pedida() -> bool:
	return "--medir" in OS.get_cmdline_user_args()

static func empezar(arbol: SceneTree) -> void:
	var m := Medicion.new()
	m.name = "Medicion"
	m.process_mode = Node.PROCESS_MODE_ALWAYS
	arbol.root.add_child.call_deferred(m)

func _ready() -> void:
	_linea("DINASTÍA %s · Godot %s · %s" % [ProjectSettings.get_setting("application/config/version", ""),
		Engine.get_version_info()["string"], Time.get_datetime_string_from_system()])
	_linea("GPU: %s (%s) · CPU: %s, %d hilos · SO: %s" % [RenderingServer.get_video_adapter_name(),
		RenderingServer.get_video_adapter_vendor(), OS.get_processor_name(), OS.get_processor_count(), OS.get_name()])
	_linea("Renderizador: %s · Calidad: %s · Ventana: %s" % [RenderingServer.get_current_rendering_method(),
		str(Calidad.elegida), str(get_viewport().get_visible_rect().size)])
	_linea("Extensión C++: %s" % ("activa" if Nativo.obj() != null else "NO (se usa GDScript)"))
	_linea("Arranque hasta ver el menú: %d ms" % int(Engine.get_meta("menu_ms", Time.get_ticks_msec())))
	_linea("Menú completo (partida en curso, perfil, álbum): %d ms" % Time.get_ticks_msec())
	_empezar_parte("menú")

func _linea(t: String) -> void:
	_informe.append(t)
	print("MEDICION ", t)

func _empezar_parte(nombre: String) -> void:
	_parte = nombre
	_t_parte = 0.0
	_frames = PackedFloat32Array()
	_ult = Time.get_ticks_usec()

## Cronometra una carga (el tiempo que la función bloquea el juego).
func _cargar(nombre: String, f: Callable) -> void:
	var t := Time.get_ticks_usec()
	f.call()
	_linea("Carga %-22s %7d ms" % [nombre, (Time.get_ticks_usec() - t) / 1000])

func _process(delta: float) -> void:
	var ahora := Time.get_ticks_usec()
	_frames.append((ahora - _ult) / 1000.0)
	_ult = ahora
	_t_parte += delta
	if _frames.size() <= 3:
		if _frames.size() > 1:
			_linea("  fotograma %d de «%s»: %.0f ms" % [_frames.size() - 1, _parte, _frames[-1]])
		return
	if _t_parte < SEGUNDOS_POR_PARTE:
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
				_vista = VistaEstadio.new()
				get_tree().root.add_child(_vista)
				_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))
				var rig: CameraRig = _vista.get("_rig")
				if rig != null:
					rig.switch_to(maxi(0, rig.camera_names.find("Principal (TV)"))))
			_empezar_parte("estadio (cámara TV)")
		2:
			_vista.queue_free()
			_cargar("abrir la ciudad", func() -> void:
				_vista = VistaCiudad.new()
				get_tree().root.add_child(_vista)
				_vista.abrir(_mundo.mi_club(), _mundo.obras, _mundo.ciudad, _mundo.perfil_estadio_de(_mundo.mi_club())))
			_empezar_parte("ciudad")
		_:
			_terminar()

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
	_linea("%-22s FPS medios %5.1f · 1 %% más lento %5.1f FPS · peor fotograma %6.0f ms · %d fotogramas"
		% [_parte, 1000.0 / media, 1000.0 / maxf(peor_1, 0.001), f[-1], f.size()])

func _terminar() -> void:
	DirAccess.make_dir_recursive_absolute("user://mediciones")
	var ruta := "user://mediciones/medicion_%s.txt" % Time.get_datetime_string_from_system().replace(":", "-")
	var a := FileAccess.open(ruta, FileAccess.WRITE)
	if a != null:
		a.store_string("\n".join(_informe) + "\n")
		a.close()
	print("MEDICION informe en ", ProjectSettings.globalize_path(ruta))
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(ruta))
	get_tree().quit()
