class_name PosturaQ
extends SkeletonModifier3D
## POSTURA Y ANATOMÍA DE LOS PEATONES (P1-P3 «MEJORAR», 27-10-2026, orden del dueño: «hombros, cuello y manos»). Los clips del pack
## dejan las manos abiertas y rígidas, los hombros cuadrados y el cuello recto, igual en todos. Este modificador (se aplica DESPUÉS de la
## animación, así vale para andar, esperar o gesticular) suma a cada persona, según su semilla:
##   - MANOS RELAJADAS: los dedos se doblan un poco, más en la falange del medio y la punta, y el pulgar menos;
##   - HOMBROS: caídos y algo adelantados, cada persona en su medida (los de más edad, más encogidos);
##   - CUELLO: el tronco y el cuello adelantados una pizca (de 1 a 6°, hasta 14° en 1 de cada 12), como la gente que va mirando por dónde pisa.
## LA MIRADA AL FRENTE (revisión del líder, 27-10): el adelanto del cuello es leve (1-6°) y la cabeza se NIVELA: tras sumar la inclinación
## del cuerpo se mide hacia dónde mira y se corrige un 85 % del cabeceo, así que se mira a la altura del horizonte aunque el clip incline el
## tronco. Solo 1 de cada 12 personas (`PROB_BAJA`) conserva la cabeza gacha de verdad (la del móvil, la que va pensando).
## Son rotaciones fijas sobre la pose: unas 24 asignaciones de hueso por fotograma y solo para los peatones que se dibujan.
const DEDOS := ["index", "middle", "ring", "pinky"]
## Doblez (grados) de la 1.ª, 2.ª y 3.ª falange de un dedo y del pulgar, a media relajación.
const CURVA := [14.0, 22.0, 16.0]
const CURVA_PULGAR := [6.0, 8.0, 6.0]
## LA MANO DEL ATLETA (31-10, veredicto del dueño «mejorar»): el clip del futbolista cierra índice y pulgar en círculo (el gesto «OK») y
## sumarle doblez daba un puño apretado. En el atleta los dedos NO siguen al clip: se ponen sobre el reposo en una mano relajada de
## verdad (cada dedo más doblado que el anterior, hacia el meñique; la falange del medio, la que más; el pulgar casi en reposo: doblado se cierra en círculo con el índice y estirado se abre de lado).
const MANO_ATLETA := {"index": [26.0, 36.0, 17.0], "middle": [38.0, 50.0, 24.0], "ring": [45.0, 56.0, 27.0], "pinky": [52.0, 60.0, 30.0], "thumb": [2.0, 6.0, 6.0]}
const PROB_BAJA := 0.08
const NIVELA := 0.85

static var eje_dedos := Vector3.RIGHT
static var eje_hombro := Vector3.FORWARD
static var eje_cuello := Vector3.RIGHT

var _huesos: PackedInt32Array = PackedInt32Array()
var _giros: Array[Quaternion] = []
var _fijos: PackedInt32Array = PackedInt32Array()   ## huesos que no siguen al clip: su giro es reposo × `_fijos_q`
var _fijos_q: Array[Quaternion] = []
var _cabeza := -1
var _nivelar := true

## Pone el modificador a la persona `nodo` (una vez). `semilla` fija sus medidas. `atleta` (futbolistas, 31-10): mano
## relajada fija (`MANO_ATLETA`, no sigue al clip), hombros apenas caídos (1-4°), cuello casi recto (0-2°) y siempre mirando al frente: un deportista no va encorvado.
static func poner(nodo: Node, semilla: int, atleta := false) -> PosturaQ:
	var esq := FutbolistaQ.esqueleto_de(nodo)
	if esq == null or esq.get_node_or_null("PosturaQ") != null:
		return null
	var m := PosturaQ.new()
	m.name = "PosturaQ"
	esq.add_child(m)
	m.configurar(esq, semilla, atleta)
	return m

func configurar(esq: Skeleton3D, semilla: int, atleta := false) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla ^ 0x51ed
	var relaja := rng.randf_range(0.6, 1.4)
	_nivelar = rng.randf() >= PROB_BAJA or atleta
	var cuello := rng.randf_range(1.0, 6.0) if _nivelar else rng.randf_range(6.0, 14.0)
	_cabeza = esq.find_bone("Head")
	var hombro := rng.randf_range(4.0, 12.0)
	if atleta:
		cuello *= 0.35
		hombro *= 0.33
	_anadir(esq, "spine_03", eje_cuello, cuello * 0.3)
	_anadir(esq, "neck_01", eje_cuello, cuello * 0.4)
	_anadir(esq, "Head", eje_cuello, cuello * 0.3)
	for lado in ["l", "r"]:
		var signo := 1.0 if lado == "l" else -1.0
		_anadir(esq, "clavicle_" + lado, eje_hombro, hombro * signo)
		if atleta:
			var suelta := rng.randf_range(0.85, 1.15)
			for dedo: String in MANO_ATLETA:
				for f in 3:
					_fijar(esq, "%s_0%d_%s" % [dedo, f + 1, lado], eje_dedos, float(MANO_ATLETA[dedo][f]) * suelta)
			continue
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

func _fijar(esq: Skeleton3D, hueso: String, eje: Vector3, grados: float) -> void:
	var i := esq.find_bone(hueso)
	if i < 0:
		return
	_fijos.append(i)
	_fijos_q.append(esq.get_bone_rest(i).basis.get_rotation_quaternion() * Quaternion(eje, deg_to_rad(grados)))

func _process_modification() -> void:
	var esq := get_skeleton()
	if esq == null:
		return
	for k in _fijos.size():
		esq.set_bone_pose_rotation(_fijos[k], _fijos_q[k])
	for k in _huesos.size():
		esq.set_bone_pose_rotation(_huesos[k], esq.get_bone_pose_rotation(_huesos[k]) * _giros[k])
	if _nivelar and _cabeza >= 0:
		_nivelar_cabeza(esq)

## Cabeceo de la cabeza respecto al reposo (+ = mira abajo) en el espacio del esqueleto.
func cabeceo(esq: Skeleton3D) -> float:
	var q := esq.get_bone_global_pose(_cabeza).basis * esq.get_bone_global_rest(_cabeza).basis.inverse()
	return asin(clampf((q * Vector3.BACK).y, -1.0, 1.0)) * -1.0

func _nivelar_cabeza(esq: Skeleton3D) -> void:
	var ang := cabeceo(esq)   ## > 0: mira hacia abajo
	var padre := esq.get_bone_parent(_cabeza)
	var g := esq.get_bone_global_pose(_cabeza).basis
	var nuevo := Basis(Vector3.RIGHT, -ang * NIVELA) * g   ## girar sobre X del esqueleto: +θ baja la mirada
	var local := esq.get_bone_global_pose(padre).basis.inverse() * nuevo
	esq.set_bone_pose_rotation(_cabeza, local.get_rotation_quaternion())
