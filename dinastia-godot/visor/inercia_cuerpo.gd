class_name InerciaCuerpo
extends SkeletonModifier3D
## EL CUERPO QUE SIENTE LA INERCIA (17-11-2026, punto 7 de `docs/04_auditorias/COMPARACION_REFERENCIAS_PARTIDO_2026-11-16.md`). Los clips de
## carrera son los mismos en recta, en curva, al arrancar o al frenar: el futbolista giraba «sobre un raíl», tieso. Aquí, después de
## la animación y antes de la postura, la mirada y el pie al balón:
##  · LADEO EN LAS CURVAS Y CABECEO AL ARRANCAR/FRENAR: el cuerpo entero se inclina con la aceleración horizontal que lleva (la de
##    la curva, v·ω, hacia dentro; la de arrancar, hacia delante; la de frenar, hacia atrás), como un corredor real (ángulo ≈ a/g),
##    girando alrededor del punto del césped bajo la pelvis (los pies casi no se mueven). Topes: 13° de lado y 9° adelante/atrás.
##  · EL TORSO QUE SE ADELANTA AL GIRO: cuando el cuerpo aún mira a un lado y la marcha ya va hacia otro, el pecho se gira hacia la
##    marcha (hasta 28°, repartido entre las tres vértebras).
##  · EL CONTROL ORIENTADO: el medio segundo después de hacerse con el balón, el pecho se abre hacia donde sale el balón (su posición
##    0,3 s más adelante): se ve que el control ya lleva intención.
## Solo cambia lo que se VE: no escribe nada del motor (la huella de `pruebas/igualdad_motor.gd` no cambia). Lo gobierna
## `AnimacionCercana` (mismas calidades: de MEDIA hacia arriba, sin «Partido ligero»), solo para los jugadores cerca de la cámara.
## `INERCIA=0` lo apaga (capturas «antes»).

static var encendida: bool = OS.get_environment("INERCIA") != "0"
const G := 9.81
const LADEO_MAX := 0.231       ## tan(13°)
const CABECEO_MAX := 0.158     ## tan(9°)
const K_LADO := 0.85           ## parte de a/g que se ve de lado (los clips ya llevan algo de recogimiento)
const K_FONDO := 0.55          ## y adelante/atrás (el sprint ya va inclinado)
const TORSO_MAX := 0.49        ## rad (28°)
const RITMO_VEL := 12.0        ## 1/s: suavizado de la velocidad medida
const RITMO_ACC := 7.0         ## 1/s: y de la aceleración (sin temblores de un fotograma)
const RITMO_TORSO := 6.0
const CONTROL := 0.55          ## s que dura la apertura del control orientado
const SALTO := 1.5             ## m en un fotograma: lo han recolocado (saque, falta): sin inercia
const VERTEBRAS := [["spine_01", 0.25], ["spine_02", 0.35], ["spine_03", 0.4]]

var cuerpo: Node3D
## 0-1, suavizado por `AnimacionCercana` (0 = apagado: no cuesta).
var peso := 0.0
## Inclinación (tangente del ángulo) en el mundo, horizontal: hacia dónde se ladea la parte de arriba del cuerpo.
var inclina := Vector3.ZERO
## Giro del pecho (rad, alrededor de la vertical; + = hacia la izquierda del cuerpo).
var torso := 0.0

var _pos := Vector3.ZERO
var _vel := Vector3.ZERO
var _acc := Vector3.ZERO
var _hay := false
var _idx: PackedInt32Array = PackedInt32Array()

## Un fotograma de lo que mide (lo llama `AnimacionCercana` con el jugador cerca). `control_hacia`: punto hacia el que se abre el
## pecho (control orientado) o `Vector3.INF` si no toca. `girar_torso`: falso en la guardia, el repliegue y el desplazamiento lateral.
func seguir(delta: float, control_hacia: Vector3, girar_torso: bool) -> void:
	if not is_instance_valid(cuerpo) or delta <= 0.0:
		return
	var p := cuerpo.global_position
	p.y = 0.0
	if not _hay or p.distance_to(_pos) > SALTO:
		_hay = true
		_pos = p
		_vel = Vector3.ZERO
		_acc = Vector3.ZERO
		return
	var v := (p - _pos) / delta
	_pos = p
	var v_ant := _vel
	_vel = _vel.lerp(v, 1.0 - exp(-RITMO_VEL * delta))
	_acc = _acc.lerp((_vel - v_ant) / delta, 1.0 - exp(-RITMO_ACC * delta))
	var fr := Vector3(sin(cuerpo.global_rotation.y), 0.0, cos(cuerpo.global_rotation.y))
	var lado := Vector3(fr.z, 0.0, -fr.x)
	var a_fondo := clampf(_acc.dot(fr) / G * K_FONDO, -CABECEO_MAX, CABECEO_MAX)
	var a_lado := clampf(_acc.dot(lado) / G * K_LADO, -LADEO_MAX, LADEO_MAX)
	inclina = fr * a_fondo + lado * a_lado
	var meta := 0.0
	if girar_torso:
		var hacia := Vector3.ZERO
		if control_hacia != Vector3.INF:
			hacia = control_hacia - p
			hacia.y = 0.0
		elif _vel.length() > 1.5:
			hacia = _vel
		if hacia.length() > 0.3:
			var dif := angle_difference(atan2(fr.x, fr.z), atan2(hacia.x, hacia.z))
			if absf(dif) < 1.75:   ## más de 100°: va de espaldas (repliegue) o recula; el torso no se tuerce
				meta = clampf(dif * (0.7 if control_hacia != Vector3.INF else 0.5), -TORSO_MAX, TORSO_MAX)
	torso = lerpf(torso, meta, 1.0 - exp(-RITMO_TORSO * delta))

## Para las pruebas: la aceleración y la velocidad que lleva medidas.
func medidas() -> Array:
	return [_vel, _acc]

func olvidar() -> void:
	_hay = false
	inclina = Vector3.ZERO
	torso = 0.0

func _process_modification() -> void:
	var esq := get_skeleton()
	if esq == null or peso <= 0.001 or not is_instance_valid(cuerpo) or not esq.is_inside_tree():
		return
	if _idx.is_empty():
		_idx.append(esq.find_bone("pelvis"))
		for v: Array in VERTEBRAS:
			_idx.append(esq.find_bone(String(v[0])))
	if _idx[0] < 0:
		return
	var inv := esq.global_transform.affine_inverse()
	var arriba := (inv.basis * Vector3.UP).normalized()
	var lean := inv.basis * (inclina * peso)
	var lean_t := lean - arriba * lean.dot(arriba)
	if lean_t.length_squared() > 1e-8:
		lean_t = lean_t.normalized() * (inclina * peso).length()
		var q := Quaternion(arriba, (arriba + lean_t).normalized())
		var pel := esq.get_bone_global_pose(_idx[0])
		var suelo := inv * cuerpo.global_position
		var pivote := pel.origin - arriba * (pel.origin - suelo).dot(arriba)
		esq.set_bone_global_pose(_idx[0], Transform3D(Basis(q) * pel.basis, pivote + q * (pel.origin - pivote)))
	var giro := torso * peso
	if absf(giro) < 0.002:
		return
	for k in range(1, _idx.size()):
		if _idx[k] < 0:
			continue
		var b := esq.get_bone_global_pose(_idx[k])
		var qt := Quaternion(arriba, giro * float(VERTEBRAS[k - 1][1]))
		esq.set_bone_global_pose(_idx[k], Transform3D(Basis(qt) * b.basis, b.origin))
