class_name BenchmarkManager
extends Node
## BANCO AUTOMÁTICO DE RENDIMIENTO (5-11-2026). Se añade a CUALQUIER escena (o se usa `benchmark.tscn`), hace que el juego corra
## solo durante BENCH_DURACION segundos (60 por defecto), apunta una fila CSV por fotograma en `perf_log.csv` y al terminar cierra
## el juego con `get_tree().quit()`. Sin intervención: ni teclado ni ratón.
##
## Ajustes (variable de entorno BENCH_X o argumento de usuario `-- --x=valor`; gana el argumento):
##   escenario  partido (por defecto) | ciudad | menu | gestion | museo | minijuego | actual (no monta nada: mide la escena que lo lleva)
##   duracion   segundos de la fase de juego (60 en «partido»; 20 en el resto de escenarios)
##   calidad    minima | media | alta | ultra  (por defecto la que dé el juego)
##   salida     ruta del CSV (por defecto `perf_log.csv` en la carpeta del proyecto; en un juego exportado, junto al ejecutable)
##   semilla    semilla del mundo ficticio (4711)
##   adaptativa 0|1  la calidad adaptativa del juego (apagada por defecto: así se mide el coste real de cada calidad)
##   ligero     0|1  «Partido ligero» de Ajustes
##   calentar   segundos de calentamiento tras montar, que NO cuentan (2)
##   limite     segundos máximos de pared para montar+medir; si se pasa, cierra con error (240)
##
## Qué guarda en cada fotograma (columna → fuente):
##   fps / fps_inst        Engine.get_frames_per_second() y 1/delta real
##   ms_fotograma          delta real (reloj de pared, no el escalado)
##   ms_motor / pasos_motor   tiempo REAL del `MotorJugable.paso` de ese fotograma (los 22 jugadores + balón + árbitros, 60 pasos por segundo de
##                         juego; lo mide `VistaEstadio._paso_motor` en Engine.get_meta) y cuántos pasos hubo. El motor NO corre en
##                         `_physics_process` (VistaEstadio lo mueve desde `_process`), por eso hace falta esta medida directa
##   ms_motor_jugador      ms_motor ÷ 22 (solo en «partido»; en el resto 0)
##   ms_fisica_medido      tiempo REAL de todos los _physics_process de ese fotograma (dos sondas con prioridad extrema, una antes y otra
##                         después de todos los nodos): el balón, la interpolación, el motor del minijuego…
##   ms_fisica_monitor     Performance.TIME_PHYSICS_PROCESS (medida de contraste; el monitor del motor se refresca ~1 vez por segundo)
##   mem_estatica_mb       OS.get_static_memory_usage(); mem_pico_mb su máximo
##   llamadas, triangulos, objetos, vram_mb   lo que el juego le pide a la gráfica (en --headless valen 0: no hay renderizador)
## Sin GPU (llvmpipe, headless) los FPS y los ms de dibujo NO valen como absolutos; sí valen la CPU, la física, la memoria y lo que se
## le pide a la gráfica para comparar versiones y calidades (CLAUDE.md, orden 19).
##
##   godot --headless --path dinastia-godot res://pruebas/benchmark/benchmark.tscn -- --escenario=partido --calidad=media

const JUGADORES := 22
const COLUMNAS := ["t", "fotograma", "fase", "escenario", "calidad", "fps", "fps_inst", "ms_fotograma", "ms_proceso", "ms_fisica_monitor",
	"ms_fisica_medido", "ticks_fisica", "ms_motor", "pasos_motor", "ms_motor_jugador", "mem_estatica_mb", "mem_pico_mb", "llamadas", "triangulos", "objetos", "nodos", "vram_mb"]
const NOMBRES_CALIDAD := {-1: "minima", 0: "media", 1: "alta", 2: "ultra"}

## Sonda de física: dos instancias con prioridad extrema miden lo que tardan, juntos, todos los _physics_process del árbol.
class Sonda extends Node:
	var abre := true
	var inicio_us := 0
	var acumulado_us := 0
	var ticks := 0
	var par: Sonda
	func _physics_process(_d: float) -> void:
		if abre:
			inicio_us = Time.get_ticks_usec()
		elif par != null:
			acumulado_us += Time.get_ticks_usec() - par.inicio_us
			ticks += 1

var escenario := "partido"
var duracion := 60.0
var calentar := 2.0
var limite := 240.0
var ruta_csv := ""
var _esc: BenchmarkEscenarios
var _entrada: Sonda
var _salida: Sonda
var _archivo: FileAccess
var _t_pared0 := 0.0       ## segundos de pared desde que arrancó el gestor
var _t_fase := 0.0         ## segundos de la fase actual (calentar/medir)
var _fase := "carga"
var _frame := 0
var _filas := 0
var _t_prev_us := 0
var _ult_ticks := 0
var _ult_us_motor := 0
var _ult_pasos_motor := 0
var _fin := false

## Lee un ajuste: argumento de usuario `--nombre=valor` o variable BENCH_NOMBRE.
static func ajuste(nombre: String, defecto: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % nombre):
			return a.substr(nombre.length() + 3)
	var v := OS.get_environment("BENCH_" + nombre.to_upper())
	return v if v != "" else defecto

static func nivel_de_nombre(nombre: String, defecto: int) -> int:
	match nombre.to_lower():
		"minima", "minimo", "mínima", "mínimo": return Calidad.MINIMO
		"media", "medio": return Calidad.MEDIO
		"alta", "alto": return Calidad.ALTO
		"ultra": return Calidad.ULTRA
	return defecto

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   ## el minijuego pausa el árbol: el gestor sigue midiendo
	escenario = ajuste("escenario", "partido").to_lower()
	duracion = float(ajuste("duracion", "60" if escenario == "partido" else "20"))
	calentar = float(ajuste("calentar", "2"))
	limite = float(ajuste("limite", "240"))
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Calidad.adaptativa = ajuste("adaptativa", "0") == "1"
	Calidad.partido_ligero = ajuste("ligero", "0") == "1"
	var pedido := ajuste("calidad", "")
	if pedido != "":
		Calidad.elegida = nivel_de_nombre(pedido, Calidad.elegida)
	ruta_csv = ajuste("salida", "")
	if ruta_csv == "":
		ruta_csv = ProjectSettings.globalize_path("res://") + "perf_log.csv" if OS.has_feature("editor") else OS.get_executable_path().get_base_dir() + "/perf_log.csv"
	_archivo = FileAccess.open(ruta_csv, FileAccess.WRITE)
	if _archivo == null:
		push_error("BENCHMARK: no se puede escribir %s (error %d)" % [ruta_csv, FileAccess.get_open_error()])
		get_tree().quit(2)
		return
	_archivo.store_line(",".join(COLUMNAS))
	_entrada = Sonda.new()
	_salida = Sonda.new()
	_entrada.abre = true
	_salida.abre = false
	_salida.par = _entrada
	for s: Sonda in [_entrada, _salida]:
		s.process_mode = Node.PROCESS_MODE_ALWAYS
	_entrada.process_physics_priority = -100000
	_salida.process_physics_priority = 100000
	add_child(_entrada)
	add_child(_salida)
	_esc = BenchmarkEscenarios.new(self)
	if escenario != "actual":
		_esc.montar(escenario)
	_t_prev_us = Time.get_ticks_usec()
	print("BENCHMARK inicio escenario=%s calidad=%s duracion=%.0f s salida=%s render=%s" % [escenario, NOMBRES_CALIDAD.get(Calidad.elegida, "?"), duracion, ruta_csv, RenderingServer.get_current_rendering_method()])

func _process(delta: float) -> void:
	if _fin:
		return
	var ahora_us := Time.get_ticks_usec()
	var dt_real := float(ahora_us - _t_prev_us) / 1.0e6
	_t_prev_us = ahora_us
	_frame += 1
	Engine.max_fps = 0   ## la pantalla principal fija su propio tope de FPS: aquí no (se mide sin techo)
	_t_pared0 += dt_real
	_esc.paso(dt_real)
	if _fase == "carga":
		if escenario == "actual" or _esc.listo():
			_fase = "calentar"
			_t_fase = 0.0
			print("BENCHMARK escena lista tras %.1f s" % _t_pared0)
	else:
		_t_fase += dt_real
		if _fase == "calentar" and _t_fase >= calentar:
			_fase = "juego"
			_t_fase = 0.0
	## Las filas se guardan desde la carga (fase «carga» y «calentar» se pueden descartar al analizar): así se ve cuánto tarda en montarse.
	var ticks := _salida.ticks
	var fisica_us := _salida.acumulado_us
	_salida.acumulado_us = 0
	var ms_fisica := float(fisica_us) / 1000.0
	var us_motor := int(Engine.get_meta(&"us_motor", 0))
	var pasos_motor := int(Engine.get_meta(&"pasos_motor", 0))
	var ms_motor := float(us_motor - _ult_us_motor) / 1000.0
	var n_pasos := pasos_motor - _ult_pasos_motor
	_ult_us_motor = us_motor
	_ult_pasos_motor = pasos_motor
	var fila := [
		"%.4f" % _t_fase if _fase == "juego" else "%.4f" % -1.0,
		str(_frame), _fase, escenario, NOMBRES_CALIDAD.get(Calidad.elegida, "?"),
		"%.1f" % Engine.get_frames_per_second(), "%.1f" % (1.0 / maxf(dt_real, 0.000001)), "%.3f" % (dt_real * 1000.0),
		"%.3f" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0),
		"%.3f" % (Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0),
		"%.3f" % ms_fisica, str(ticks - _ult_ticks), "%.3f" % ms_motor, str(n_pasos),
		"%.4f" % (ms_motor / float(JUGADORES) if escenario == "partido" else 0.0),
		"%.1f" % (OS.get_static_memory_usage() / 1048576.0), "%.1f" % (OS.get_static_memory_peak_usage() / 1048576.0),
		"%.0f" % Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"%.0f" % Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"%.0f" % Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"%.0f" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"%.1f" % (Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0)]
	_ult_ticks = ticks
	_archivo.store_line(",".join(PackedStringArray(fila)))
	_filas += 1
	if _filas % 120 == 0:
		_archivo.flush()
	if _fase == "juego" and _t_fase >= duracion:
		_terminar(0)
	elif _t_pared0 >= limite:
		push_error("BENCHMARK: pasó el límite de %.0f s sin completar la medición (fase %s)" % [limite, _fase])
		_terminar(3)

func _terminar(codigo: int) -> void:
	_fin = true
	_archivo.flush()
	_archivo.close()
	print("BENCHMARK fin: %d filas en %s (código %d)" % [_filas, ruta_csv, codigo])
	get_tree().paused = false
	get_tree().quit(codigo)
