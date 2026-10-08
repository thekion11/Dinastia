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
	if OS.get_environment("PARTES") != "":
		_partes()
		return
	_llamadas.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_triangulos.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	_objetos.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	_proceso.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	if _llamadas.size() >= MUESTRAS:
		if OS.get_environment("FOTO") != "":
			get_viewport().get_texture().get_image().save_png(OS.get_environment("FOTO"))
		print("MEDICION calidad=%d  llamadas=%.0f  triangulos=%.0f  objetos=%.0f  fotograma=%.2f ms (peor %.2f)  vram=%.0f MB" % [
			Calidad.elegida, _media(_llamadas), _media(_triangulos), _media(_objetos),
			_media(_proceso), _proceso.max(),
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])
		if OS.get_environment("DETALLE") != "":
			for f: Dictionary in Optimizar.informe(_vista, 25):
				print("DETALLE tris=%d piezas=%d corte=%.0f  %s" % [f["tris"], f["piezas"], f["corte"], f["clave"]])
		get_tree().quit()

func _media(a: Array[float]) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / maxf(1.0, float(a.size()))

## Con PARTES=1: apaga un grupo a la vez y mira cuánto baja el fotograma
## (triángulos y llamadas de verdad, con la cámara de TV).
var _parte := -1
var _ocultos: Array = []
var _base := Vector2.ZERO
const GRUPOS := ["butacas", "hinchas", "jugadores", "pelo", "sombras", "resto_multimesh"]

func _de_grupo(nombre: String) -> Array:
	var r := []
	for n in _vista.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var es_mm := g is MultiMeshInstance3D
		var mn := ""
		if es_mm and (g as MultiMeshInstance3D).multimesh != null and (g as MultiMeshInstance3D).multimesh.mesh != null:
			mn = (g as MultiMeshInstance3D).multimesh.mesh.resource_name
		match nombre:
			"butacas": if String(g.name).begins_with("Butacas"): r.append(g)
			"hinchas": if es_mm and not String(g.name).begins_with("Butacas") and (g as MultiMeshInstance3D).multimesh.instance_count > 200: r.append(g)
			"jugadores": if g.get_parent() is Skeleton3D: r.append(g)
			"pelo": if String(g.get_parent().name) == "PeloCapas" or String(g.name).begins_with("Pelo"): r.append(g)
			"resto_multimesh": if es_mm: r.append(g)
	return r

func _partes() -> void:
	var m := Vector2(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if (_n - CALENTAR) % 6 != 5:
		return
	if _parte == -1:
		_base = m
		print("PARTES base tris=%d llamadas=%d" % [m.x, m.y])
	else:
		print("PARTES sin %s: -%d tris  -%d llamadas" % [GRUPOS[_parte], _base.x - m.x, _base.y - m.y])
		for g in _ocultos:
			if g is GeometryInstance3D:
				g.visible = true
			else:
				for l in _vista.find_children("*", "DirectionalLight3D", true, false):
					l.shadow_enabled = true
		_ocultos.clear()
	_parte += 1
	if _parte >= GRUPOS.size():
		get_tree().quit()
		return
	if GRUPOS[_parte] == "sombras":
		for l in _vista.find_children("*", "DirectionalLight3D", true, false):
			l.shadow_enabled = false
		_ocultos = ["luz"]
	else:
		_ocultos = _de_grupo(GRUPOS[_parte])
		for g in _ocultos:
			g.visible = false
