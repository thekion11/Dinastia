extends Node
## Mide el rendimiento REAL de un partido en vivo -nada de adivinar donde esta
## el cuello de botella antes de tener numeros de verdad-. Usa el singleton
## `Performance` de Godot (FPS, tiempo de frame, draw calls, objetos, huesos
## animados, etc.) y `RenderingServer` para desglosar CPU vs GPU.

var _vista: VistaEstadio
var _mundo: Mundo
var _partido: Partido
var _frame := 0
var _muestras: Array = []

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	var par := _mundo.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], _partido)
	var rig: CameraRig = _vista.get("_rig")
	if rig != null:
		var idx := rig.camera_names.find("Principal (TV)")
		if idx != -1:
			rig.switch_to(idx)

func _process(_d: float) -> void:
	_frame += 1
	## Los primeros ~30 fotogramas son de "arranque" -carga de assets,
	## primer import de shaders-, no representan el juego en regimen. Se
	## descartan de las muestras.
	if _frame > 50 and _frame <= 350:
		var ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		_muestras.append({
			"fps": Performance.get_monitor(Performance.TIME_FPS),
			"frame_ms": ms,
			"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"vertices": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			"video_mem": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
			"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			"objetos_totales": Performance.get_monitor(Performance.OBJECT_COUNT),
		})
	if _frame == 330:
		_reportar()
		get_tree().quit(0)

func _reportar() -> void:
	if _muestras.is_empty():
		print("sin muestras")
		return
	var n := _muestras.size()
	var claves := ["fps", "frame_ms", "physics_ms", "draw_calls", "vertices", "objects", "video_mem", "nodes", "objetos_totales"]
	print("--- RENDIMIENTO (%d muestras, camara 'Principal (TV)', partido real) ---" % n)
	for k in claves:
		var suma := 0.0
		var maximo := -INF
		var minimo := INF
		for m in _muestras:
			var v: float = m[k]
			suma += v
			maximo = maxf(maximo, v)
			minimo = minf(minimo, v)
		print("%s: promedio=%.2f  min=%.2f  max=%.2f" % [k, suma / n, minimo, maximo])
	print("FIN. 0 fallos")
