class_name RendimientoAdaptativo
extends Node
## CALIDAD ADAPTATIVA DEL PARTIDO 3D (25-9-2026).
##
## El objetivo del análisis externo: "asegurar un mínimo de 40 FPS en hardware
## modesto" (8 GB DDR3, gráfica integrada: se medían 44-50 de media y 20 de
## mínimo). Los tirones de CPU ya se quitaron por otro lado -música y sonidos
## compuestos en segundo plano, equipación sin teñir texturas, pantalla gigante
## a ritmo de marcador-, y lo que queda es trabajo de la GRÁFICA, que depende
## de la máquina y no se puede fijar desde aquí.
##
## Así que se mide EN la máquina del jugador: cada segundo se mira la media de
## FPS de los últimos cuatro, y si cae por debajo de 40 se baja UN escalón de lo
## que más le cuesta a una integrada, en este orden -de lo que menos se nota a
## lo que más-:
##   1. oclusión ambiental (SSAO),
##   2. sombras más cortas y con dos cascadas en vez de cuatro,
##   3. butacas cercanas con la malla liviana (la grada llena del 29-9-2026
##      cuesta vértices, que es lo que el reescalado no alivia),
##   4. render 3D al 80% con reescalado FSR,
##   5. render 3D al 67%.
## Nunca vuelve a subir en el mismo partido (subir y bajar se nota más que
## quedarse), y al cerrar el estadio devuelve la escala de render a 1.

signal escalon_aplicado(escalon: int, descripcion: String)

const OBJETIVO_FPS := 40.0
const SEG_CALENTAR := 3.0
const MUESTRAS := 4
const ESCALONES := [
	"sin oclusión ambiental",
	"sombras más cortas",
	"butacas cercanas livianas",
	"render 3D al 80% (FSR)",
	"render 3D al 67% (FSR)",
]

var raiz3d: Node3D
var escalon := 0
var activo := true
var _t := 0.0
var _t_muestra := 0.0
var _muestras: Array[float] = []

func _process(delta: float) -> void:
	if not activo or escalon >= ESCALONES.size():
		return
	_t += delta
	if _t < SEG_CALENTAR:
		return
	_t_muestra += delta
	if _t_muestra < 1.0:
		return
	_t_muestra = 0.0
	_muestras.append(Engine.get_frames_per_second())
	if _muestras.size() > MUESTRAS:
		_muestras.pop_front()
	if _muestras.size() < MUESTRAS:
		return
	var suma := 0.0
	for f in _muestras:
		suma += f
	if suma / float(_muestras.size()) < OBJETIVO_FPS:
		bajar()
		## Se vuelve a medir desde cero: el escalón nuevo tarda un par de
		## fotogramas en notarse y la media vieja lo arrastraría.
		_muestras.clear()

## Aplica el siguiente escalón. Público para poder probarlo sin depender de
## los FPS de la máquina donde corre la prueba.
func bajar() -> void:
	if escalon >= ESCALONES.size():
		return
	escalon += 1
	match escalon:
		1:
			for we in _todos(raiz3d, "WorldEnvironment"):
				var env: Environment = (we as WorldEnvironment).environment
				if env != null:
					env.ssao_enabled = false
					env.ssil_enabled = false
		2:
			for l in _todos(raiz3d, "DirectionalLight3D"):
				var d := l as DirectionalLight3D
				if d.shadow_enabled:
					d.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
					d.directional_shadow_max_distance = minf(d.directional_shadow_max_distance, 120.0)
		3:
			for n in raiz3d.find_children("ButacasCerca*", "MultiMeshInstance3D", true, false):
				var mmi := n as MultiMeshInstance3D
				if mmi.multimesh != null:
					mmi.multimesh.mesh = StadiumBuilder._malla_butaca_lejos()
		4:
			_escala(0.8)
		5:
			_escala(0.67)
	escalon_aplicado.emit(escalon, String(ESCALONES[escalon - 1]))

func _escala(e: float) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
	vp.scaling_3d_scale = e

func _exit_tree() -> void:
	## El viewport es el de la ventana entera: si no se devuelve, el resto del
	## juego seguiría renderizando 3D a menos resolución.
	if escalon >= 4:
		var vp := get_viewport()
		if vp != null:
			vp.scaling_3d_scale = 1.0
			vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR

static func _todos(n: Node, clase: String) -> Array[Node]:
	var out: Array[Node] = []
	if n == null:
		return out
	if n.is_class(clase):
		out.append(n)
	for h in n.get_children():
		out.append_array(_todos(h, clase))
	return out
