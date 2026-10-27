class_name PosturaQ
extends SkeletonModifier3D
## POSTURA Y ANATOMÍA DE LOS PEATONES (P1-P3 «MEJORAR», 27-10-2026, orden del dueño: «hombros, cuello y manos»). Los clips del pack
## dejan las manos abiertas y rígidas, los hombros cuadrados y el cuello recto, igual en todos. Este modificador (se aplica DESPUÉS de la
## animación, así vale para andar, esperar o gesticular) suma a cada persona, según su semilla:
##   - MANOS RELAJADAS: los dedos se doblan un poco, más en la falange del medio y la punta, y el pulgar menos;
##   - HOMBROS: caídos y algo adelantados, cada persona en su medida (los de más edad, más encogidos);
##   - CUELLO: la cabeza adelantada una pizca (de 3 a 14° repartidos entre dorsal, cuello y cabeza), como la gente que va mirando por dónde pisa.
## Son rotaciones fijas sobre la pose: unas 24 asignaciones de hueso por fotograma y solo para los peatones que se dibujan.
const DEDOS := ["index", "middle", "ring", "pinky"]
## Doblez (grados) de la 1.ª, 2.ª y 3.ª falange de un dedo y del pulgar, a media relajación.
const CURVA := [14.0, 22.0, 16.0]
const CURVA_PULGAR := [6.0, 8.0, 6.0]

static var eje_dedos := Vector3.RIGHT
static var eje_hombro := Vector3.FORWARD
static var eje_cuello := Vector3.RIGHT

var _huesos: PackedInt32Array = PackedInt32Array()
var _giros: Array[Quaternion] = []

## Pone el modificador a la persona `nodo` (una vez). `semilla` fija sus medidas.
static func poner(nodo: Node, semilla: int) -> PosturaQ:
	var esq := FutbolistaQ.esqueleto_de(nodo)
	if esq == null or esq.get_node_or_null("PosturaQ") != null:
		return null
	var m := PosturaQ.new()
	m.name = "PosturaQ"
	esq.add_child(m)
	m.configurar(esq, semilla)
	return m

func configurar(esq: Skeleton3D, semilla: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla ^ 0x51ed
	var relaja := rng.randf_range(0.6, 1.4)
	var cuello := rng.randf_range(3.0, 14.0)
	var hombro := rng.randf_range(4.0, 12.0)
	_anadir(esq, "spine_03", eje_cuello, cuello * 0.3)
	_anadir(esq, "neck_01", eje_cuello, cuello * 0.4)
	_anadir(esq, "Head", eje_cuello, cuello * 0.3)
	for lado in ["l", "r"]:
		var signo := 1.0 if lado == "l" else -1.0
		_anadir(esq, "clavicle_" + lado, eje_hombro, hombro * signo)
		for dedo in DEDOS:
			for f in 3:
				_anadir(esq, "%s_0%d_%s" % [dedo, f + 1, lado], eje_dedos, CURVA[f] * relaja)
		for f in 3:
			_anadir(esq, "thumb_0%d_%s" % [f + 1, lado], eje_dedos, CURVA_PULGAR[f] * relaja)

func _anadir(esq: Skeleton3D, hueso: String, eje: Vector3, grados: float) -> void:
	var i := esq.find_bone(hueso)
	if i < 0:
		return
	_huesos.append(i)
	_giros.append(Quaternion(eje, deg_to_rad(grados)))

func _process_modification() -> void:
	var esq := get_skeleton()
	if esq == null:
		return
	for k in _huesos.size():
		esq.set_bone_pose_rotation(_huesos[k], esq.get_bone_pose_rotation(_huesos[k]) * _giros[k])
