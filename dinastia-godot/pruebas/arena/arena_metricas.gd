class_name ArenaMetricas
extends Node
## MÉTRICAS DE LA ARENA (3-11): lo que el juego le pide a la gráfica y a la CPU en cada fotograma, con el reloj de verdad (no el acelerado).
## Cada segundo guarda una fila (CSV en /tmp/arena_<modo>.csv): FPS medios y mínimos, tiempo de fotograma, de proceso y de física,
## llamadas de dibujo, triángulos, objetos 3D, nodos y memoria de vídeo. Al terminar imprime la mediana de cada columna.
## En una máquina sin GPU (llvmpipe) el tiempo no vale entre máquinas: comparar llamadas, triángulos y memoria (CLAUDE.md, orden 19).

const COLUMNAS := ["fps_medio", "fps_min", "ms_fotograma", "ms_proceso", "ms_fisica", "llamadas", "triangulos", "objetos", "nodos", "vram_mb", "hilos"]

var modo := "arena"
var _t := 0.0
var _n := 0
var _suma_dt := 0.0
var _peor_dt := 0.0
var filas: Array = []
var _archivo: FileAccess

func iniciar(nombre_modo: String) -> void:
	modo = nombre_modo
	process_mode = Node.PROCESS_MODE_ALWAYS
	var ruta := OS.get_environment("ARENA_CSV")
	if ruta == "":
		ruta = "/tmp/arena_%s.csv" % modo
	_archivo = FileAccess.open(ruta, FileAccess.WRITE)
	if _archivo != null:
		_archivo.store_line("segundo," + ",".join(COLUMNAS))

func _process(delta: float) -> void:
	## `delta` ya viene multiplicado por Engine.time_scale: se mide con el reloj de pared.
	var real := delta / maxf(Engine.time_scale, 0.0001)
	_t += real
	_n += 1
	_suma_dt += real
	_peor_dt = maxf(_peor_dt, real)
	if _t < 1.0:
		return
	var fila := {
		"fps_medio": float(_n) / _suma_dt,
		"fps_min": 1.0 / maxf(_peor_dt, 0.0001),
		"ms_fotograma": 1000.0 * _suma_dt / float(_n),
		"ms_proceso": 1000.0 * Performance.get_monitor(Performance.TIME_PROCESS),
		"ms_fisica": 1000.0 * Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
		"llamadas": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"triangulos": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"objetos": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"nodos": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"vram_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"hilos": float(hilos_del_proceso()),
	}
	filas.append(fila)
	if _archivo != null:
		var cols: PackedStringArray = []
		for c: String in COLUMNAS:
			cols.append("%.2f" % float(fila[c]))
		_archivo.store_line("%d,%s" % [filas.size(), ",".join(cols)])
		_archivo.flush()
	_t = 0.0
	_n = 0
	_suma_dt = 0.0
	_peor_dt = 0.0

## La última fila, en una línea (para el rótulo).
func resumen_corto() -> String:
	if filas.is_empty():
		return "midiendo…"
	var f: Dictionary = filas[filas.size() - 1]
	return "%.0f FPS (mín %.0f) · %.1f ms · %d llamadas · %.2f M triáng. · %d objetos · %.0f MB vídeo" % [f["fps_medio"], f["fps_min"],
		f["ms_fotograma"], int(f["llamadas"]), float(f["triangulos"]) / 1.0e6, int(f["objetos"]), f["vram_mb"]]

## Mediana de cada columna (se ignora el primer segundo: calentamiento).
func medianas() -> Dictionary:
	var out := {}
	var util := filas.slice(1) if filas.size() > 2 else filas
	for c: String in COLUMNAS:
		var v: Array = []
		for f: Dictionary in util:
			v.append(float(f[c]))
		v.sort()
		out[c] = v[v.size() / 2] if not v.is_empty() else 0.0
	return out

func imprimir_resumen() -> void:
	var m := medianas()
	print("ARENA %s · %d s medidos · medianas:" % [modo, filas.size()])
	for c: String in COLUMNAS:
		print("  %-14s %.2f" % [c, m[c]])

## Hilos del proceso (Linux y Android: /proc/self/task); 0 donde no existe. R5: los subprocesos que de verdad corren durante el partido.
static func hilos_del_proceso() -> int:
	var d := DirAccess.open("/proc/self/task")
	return d.get_directories().size() if d != null else 0

## Nombre de cada hilo y cuántos hay con ese nombre (comm del kernel; los de Godot se nombran: «WorkerThread», «Audio»…).
static func hilos_por_nombre() -> Dictionary:
	var out := {}
	var d := DirAccess.open("/proc/self/task")
	if d == null:
		return out
	for id: String in d.get_directories():
		var fa := FileAccess.open("/proc/self/task/%s/comm" % id, FileAccess.READ)
		var n := fa.get_line().strip_edges() if fa != null else "?"
		out[n] = int(out.get(n, 0)) + 1
	return out

## CPU consumida por cada hilo hasta ahora (ticks del kernel, 1/100 s): {tid: [nombre, utime+stime]}. Se resta una muestra de otra para ver
## qué hilos trabajan durante el partido y cuáles están parados (R5).
static func cpu_por_hilo() -> Dictionary:
	var out := {}
	var d := DirAccess.open("/proc/self/task")
	if d == null:
		return out
	for id: String in d.get_directories():
		var f := FileAccess.open("/proc/self/task/%s/stat" % id, FileAccess.READ)
		if f == null:
			continue
		var linea := f.get_line()
		var a := linea.find("(")
		var b := linea.rfind(")")
		if a < 0 or b < 0:
			continue
		var campos := linea.substr(b + 2).split(" ")
		out[id] = [linea.substr(a + 1, b - a - 1), int(campos[11]) + int(campos[12])]
	return out
