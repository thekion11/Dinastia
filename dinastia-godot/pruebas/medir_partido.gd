extends Node
## MEDICIÓN DEL PARTIDO 3D QUE NO DEPENDE DE LA GRÁFICA (25-9-2026).
##
##   godot --path . --rendering-driver vulkan --resolution 1280x720 \
##         res://pruebas/medir_partido.tscn [-- medio|alto|ultra]
##
## `diagnostico_fps_partido.gd` mide FPS, y los FPS dependen de la máquina: en
## un servidor sin GPU (render por software) salen 3, y en una Intel UHD 45. Lo
## que SÍ se puede comparar entre máquinas y entre versiones del código es lo
## que el juego le PIDE a la gráfica y a la CPU en cada fotograma:
##   * llamadas de dibujo y triángulos -lo que más castiga a una integrada-,
##   * objetos 3D visibles,
##   * tiempo total del fotograma (en un servidor sin GPU es casi todo render
##     por software: sirve para comparar versiones, no máquinas),
##   * memoria de vídeo.
## Se mide con la cámara de TV, con el partido corriendo, tras dejar que el
## estadio termine de montarse.

const CALENTAR := 40
const MUESTRAS := 120

var _vista: VistaEstadio
var _n := 0
var _llamadas: Array[float] = []
var _triangulos: Array[float] = []
var _objetos: Array[float] = []
var _proceso: Array[float] = []

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ALTO)
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))

func _process(_d: float) -> void:
	_n += 1
	if _n == 5:
		(_vista.get("_rig") as CameraRig).switch_to(0)
	if _n < CALENTAR:
		return
	_llamadas.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_triangulos.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	_objetos.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	_proceso.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	if _llamadas.size() >= MUESTRAS:
		print("MEDICION calidad=%d  llamadas=%.0f  triangulos=%.0f  objetos=%.0f  fotograma=%.2f ms (peor %.2f)  vram=%.0f MB" % [
			Calidad.elegida, _media(_llamadas), _media(_triangulos), _media(_objetos),
			_media(_proceso), _proceso.max(),
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])
		get_tree().quit()

func _media(a: Array[float]) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / maxf(1.0, float(a.size()))
