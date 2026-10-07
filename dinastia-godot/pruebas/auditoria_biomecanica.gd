extends Node3D
## AUDITORÍA BIOMECÁNICA (25-9-2026). Pedido del usuario: "comprueba que los
## movimientos tengan realismo biológico humano".
##
##   godot --headless --path . res://pruebas/auditoria_biomecanica.tscn
##
## Recorre CADA animación de la librería del futbolista cuadro a cuadro (30 fps)
## y mide contra los rangos articulares humanos, no a ojo:
##  - rodilla y codo: bisagras. Flexión hasta 160°, NUNCA hacia atrás (más de 12° de
##    hiperextensión) y poco giro fuera de la bisagra (valgo/varo, torsión).
##  - cadera: flexión hasta 150° y abducción hasta 80° (rangos PASIVOS de un
##    deportista: el portero que se estira o el festejo con la rodilla al
##    pecho, ambos de captura real, llegan a 147° y 73°), extensión 35°,
##    aducción 35°. Medidas contra la PELVIS, no contra el pecho.
##  - tobillo 65°, muñeca 85°, cuello+cabeza 90°, columna (3 vértebras) 110°.
##  - pies que atraviesan el césped.
##  - velocidades imposibles: un hueso que gira más de 40 rad/s (~2300°/s) es un
##    salto de pose, no un movimiento -ni el remate más violento llega-.
## El "hacia dónde dobla" de rodillas y codos se CALIBRA con el mocap de carrera
## de la Universal Animation Library: es captura de una persona real.

const FPS := 30.0
const LADOS := ["l", "r"]
var _esq: Skeleton3D
var _ap: AnimationPlayer
var _i := {}
var _eje_bisagra := {}   ## hueso -> eje local de flexión (calibrado)
var _suelo := {}         ## hueso -> altura mínima en reposo
var _problemas := 0
var _signo_frente := 1.0
var _pelvis_arriba := Vector3.UP     ## en el marco local de la pelvis
var _pelvis_frente := Vector3.BACK

func _ready() -> void:
	var d := FutbolistaQ.crear(1.8, "male")
	add_child(d["nodo"])
	FutbolistaQ.terminar(d, true)
	_esq = d["esqueleto"]
	_ap = d["anim"]
	for n: String in ["pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "Head",
			"thigh_l", "calf_l", "foot_l", "ball_l", "thigh_r", "calf_r", "foot_r", "ball_r",
			"upperarm_l", "lowerarm_l", "hand_l", "upperarm_r", "lowerarm_r", "hand_r"]:
		_i[n] = _esq.find_bone(n)
	_calibrar()
	var solo := OS.get_environment("SOLO")
	var nombres := _ap.get_animation_list()
	for n: String in nombres:
		if n == "RESET" or (solo != "" and n != solo):
			continue
		_auditar(n)
	print("===== AUDITORÍA: %d animaciones con problemas =====" % _problemas)
	get_tree().quit()

func _pos(n: String) -> Vector3:
	return (_esq.global_transform * _esq.get_bone_global_pose(_i[n])).origin

func _local_delta(n: String) -> Quaternion:
	var b: int = _i[n]
	return _esq.get_bone_rest(b).basis.get_rotation_quaternion().inverse() * _esq.get_bone_pose_rotation(b)

func _poner(anim: String, t: float) -> void:
	_ap.play(anim)
	_ap.seek(t, true)
	_ap.pause()

func _calibrar() -> void:
	## Eje de bisagra: promedio del eje de rotación local ponderado por el
	## ángulo, sobre la carrera real (rodillas y codos doblan mucho).
	var acum := {}
	for h: String in ["calf_l", "calf_r", "lowerarm_l", "lowerarm_r"]:
		acum[h] = Vector3.ZERO
	for anim: String in ["correr", "trotar"]:
		var largo := _ap.get_animation(anim).length
		var t := 0.0
		while t < largo:
			_poner(anim, t)
			for h: String in acum:
				var q := _local_delta(h)
				if q.w < 0.0:
					q = -q
				var ang := q.get_angle()
				if ang > 0.05:
					acum[h] += q.get_axis() * ang
			t += 1.0 / FPS
	for h: String in acum:
		_eje_bisagra[h] = (acum[h] as Vector3).normalized()
	_poner("parado", 0.0)
	for h: String in ["foot_l", "foot_r", "ball_l", "ball_r"]:
		_suelo[h] = _pos(h).y
	_calibrar_planos()
	_pelvis_arriba = _base_pelvis().inverse() * (_pos("spine_03") - _pos("pelvis")).normalized()
	var marco := _marco()
	_signo_frente = 1.0 if (_pos("ball_l") - _pos("foot_l")).dot(marco[2]) >= 0.0 else -1.0
	print("calibración: rodilla_l %s  codo_l %s  suelo pie %.3f punta %.3f" % [
		_eje_bisagra["calf_l"], _eje_bisagra["lowerarm_l"], _suelo["foot_l"], _suelo["ball_l"]])

func _base_pelvis() -> Basis:
	return (_esq.global_transform * _esq.get_bone_global_pose(_i["pelvis"])).basis.orthonormalized()

## Marco de la PELVIS: [arriba, lado (hacia la derecha), frente]. La cadera se
## mide contra la pelvis y no contra el pecho: medida contra el pecho, cada
## grado de flexión lumbar (agacharse) se contaba como flexión de cadera.
func _marco() -> Array:
	var arriba := (_base_pelvis() * _pelvis_arriba).normalized()
	var lado := (_pos("thigh_r") - _pos("thigh_l"))
	lado = (lado - arriba * lado.dot(arriba)).normalized()
	return [arriba, lado, lado.cross(arriba) * _signo_frente]

## Bisagra por POSICIONES (rodilla: muslo-pierna-tobillo; codo: brazo-
## antebrazo-mano), independiente de cómo guarde cada clip sus giros. La normal
## del plano de flexión se lleva al marco LOCAL del hueso proximal (el muslo gira
## con la pierna, así que ahí la bisagra es fija) y se compara con la normal
## calibrada en la carrera real: mismo sentido = flexión, sentido contrario =
## la articulación dobla al revés. Devuelve (flexión con signo, desvío del
## plano en grados).
const CADENAS := {"rodilla_l": ["thigh_l", "calf_l", "foot_l"], "rodilla_r": ["thigh_r", "calf_r", "foot_r"],
	"codo_l": ["upperarm_l", "lowerarm_l", "hand_l"], "codo_r": ["upperarm_r", "lowerarm_r", "hand_r"]}
var _normal_local := {}

func _normal_en_proximal(c: Array) -> Array:
	var a := _pos(c[0])
	var b := _pos(c[1])
	var d := _pos(c[2])
	var u := (b - a).normalized()
	var v := (d - b).normalized()
	var ang := rad_to_deg(u.angle_to(v))
	var base: Basis = (_esq.global_transform * _esq.get_bone_global_pose(_i[c[0]])).basis.orthonormalized()
	var n := u.cross(v)
	if n.length() < 0.0001:
		return [ang, Vector3.ZERO]
	return [ang, (base.inverse() * n).normalized()]

func _calibrar_planos() -> void:
	for k: String in CADENAS:
		var acum := Vector3.ZERO
		for anim: String in ["correr", "trotar"]:
			var largo := _ap.get_animation(anim).length
			var t := 0.0
			while t < largo:
				_poner(anim, t)
				var r := _normal_en_proximal(CADENAS[k])
				if float(r[0]) > 35.0:
					acum += r[1]
				t += 1.0 / FPS
		_normal_local[k] = acum.normalized()

func _bisagra_pos(k: String) -> Vector2:
	var r := _normal_en_proximal(CADENAS[k])
	var ang: float = r[0]
	if ang < 8.0:
		return Vector2(ang, 0.0)
	var c: float = (r[1] as Vector3).dot(_normal_local[k])
	## Con poca flexión el plano está mal definido (la pierna casi recta):
	## el desvío solo se mide pasados 25°.
	var desvio := rad_to_deg(acos(clampf(absf(c), 0.0, 1.0))) if ang > 25.0 else 0.0
	return Vector2(ang if c >= 0.0 else -ang, desvio)

func _bisagra(h: String) -> Vector2:
	## x = flexión con signo (negativa = hacia atrás), y = giro fuera del eje.
	var q := _local_delta(h)
	if q.w < 0.0:
		q = -q
	var ang := rad_to_deg(q.get_angle())
	if ang < 0.01:
		return Vector2.ZERO
	var c := q.get_axis().dot(_eje_bisagra[h])
	return Vector2(ang * c, ang * sqrt(maxf(0.0, 1.0 - c * c)))

func _auditar(anim: String) -> void:
	var largo := _ap.get_animation(anim).length
	var peor := {}   ## métrica -> [valor, tiempo]
	var previo := {}
	var t := 0.0
	while t <= largo + 0.0001:
		_poner(anim, minf(t, largo))
		var m := {}
		for s: String in LADOS:
			var rod := _bisagra_pos("rodilla_" + s)
			var cod := _bisagra_pos("codo_" + s)
			m["rodilla_flexion_" + s] = rod.x
			m["rodilla_atras_" + s] = -rod.x
			m["rodilla_plano_" + s] = rod.y
			m["codo_flexion_" + s] = cod.x
			m["codo_atras_" + s] = -cod.x
			m["tobillo_" + s] = rad_to_deg(_local_delta("foot_" + s).get_angle())
			m["muneca_" + s] = rad_to_deg(_local_delta("hand_" + s).get_angle())
			m["pie_bajo_suelo_" + s] = (_suelo["foot_" + s] - _pos("foot_" + s).y) * 100.0
			m["punta_bajo_suelo_" + s] = (_suelo["ball_" + s] - _pos("ball_" + s).y) * 100.0
		## Cadera en el marco del tronco.
		var marco := _marco()
		var arriba: Vector3 = marco[0]
		var lado: Vector3 = marco[1]
		var frente: Vector3 = marco[2]
		for s: String in LADOS:
			var dv := (_pos("calf_" + s) - _pos("thigh_" + s)).normalized()
			var afuera := lado if s == "r" else -lado
			m["cadera_flexion_" + s] = rad_to_deg(atan2(dv.dot(frente), -dv.dot(arriba)))
			m["cadera_extension_" + s] = -m["cadera_flexion_" + s]
			m["cadera_abduccion_" + s] = rad_to_deg(asin(clampf(dv.dot(afuera), -1, 1)))
			m["cadera_aduccion_" + s] = -m["cadera_abduccion_" + s]
		m["cuello"] = rad_to_deg((_local_delta("neck_01") * _local_delta("Head")).get_angle())
		m["columna"] = rad_to_deg(_local_delta("spine_01").get_angle() + _local_delta("spine_02").get_angle()
			+ _local_delta("spine_03").get_angle())
		## Velocidad angular.
		var vmax := 0.0
		for h: String in _i:
			if h == "pelvis":
				continue
			var q := _esq.get_bone_pose_rotation(_i[h])
			if previo.has(h):
				var dq: Quaternion = (previo[h] as Quaternion).inverse() * q
				if dq.w < 0.0:
					dq = -dq
				vmax = maxf(vmax, dq.get_angle() * FPS)
			previo[h] = q
		m["vel_rad_s"] = vmax
		if OS.get_environment("DETALLE") != "":
			var fila := "    %.2f" % t
			for k: String in OS.get_environment("DETALLE").split(","):
				fila += " %s=%.0f" % [k, float(m.get(k, 0.0))]
			print(fila)
		for k: String in m:
			if not peor.has(k) or float(m[k]) > float(peor[k][0]):
				peor[k] = [m[k], t]
		t += 1.0 / FPS
	var limites := {
		"rodilla_flexion": 160.0, "rodilla_atras": 12.0,
		"codo_flexion": 150.0, "codo_atras": 12.0, "rodilla_plano": 30.0,
		"tobillo": 65.0, "muneca": 85.0, "pie_bajo_suelo": 4.0, "punta_bajo_suelo": 4.0,
		"cadera_flexion": 150.0, "cadera_extension": 35.0, "cadera_abduccion": 80.0, "cadera_aduccion": 35.0,
		"cuello": 90.0, "columna": 110.0, "vel_rad_s": 40.0,
	}
	var fallas: Array[String] = []
	for k: String in peor:
		var base := k.trim_suffix("_l").trim_suffix("_r")
		if limites.has(base) and float(peor[k][0]) > float(limites[base]):
			fallas.append("%s=%.0f@%.2fs(>%.0f)" % [k, peor[k][0], peor[k][1], limites[base]])
	if fallas.is_empty():
		print("  ok    %-18s %.2fs" % [anim, largo])
	else:
		_problemas += 1
		print("  MAL   %-18s %.2fs  %s" % [anim, largo, "  ".join(fallas)])
