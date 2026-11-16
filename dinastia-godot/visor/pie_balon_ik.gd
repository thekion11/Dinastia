class_name PieBalonIK
extends SkeletonModifier3D
## EL PIE AL BALÓN (H1 del informe AAA, 16-11-2026): cinemática inversa de dos huesos (`thigh_*` → `calf_*` → `foot_*`) para que el
## pie del jugador que toca el balón llegue a él cuando controla, conduce o patea, en lugar de quedarse a un palmo como dicta el clip.
## Resuelta a mano como `BrazosIK` (el `TwoBoneIK3D` del motor no movía este esqueleto tipo Unreal). Va DESPUÉS de la animación y
## de la mirada; solo cambia lo que se ve: el motor del partido no lee estos huesos (la huella de `pruebas/igualdad_motor.gd` no cambia).
## Lo gobierna `AnimacionCercana`: pone `balon`, `cuerpo` y `peso` (0-1, suavizado) y lo apaga (`active = false`) cuando no toca.
## Determinista: no usa azar, solo la pose del clip y las posiciones del balón y del jugador en ese fotograma.

const RADIO_BALON := 0.11
## El tobillo queda detrás del balón (visto desde el cuerpo) a esta distancia de su centro: el empeine/interior del pie lo toca.
const SEPARACION := 0.07
## Más allá de esto (m, del tobillo del clip al objetivo) no se estira la pierna: el pie volvería a quedar raro.
const ALCANCE := 0.55

var balon: Node3D
var cuerpo: Node3D
var peso := 0.0
## "l" o "r": el pie del toque. Se elige el más cercano al balón cuando el peso vuelve a empezar desde cero.
var lado := ""

func _process_modification() -> void:
	var esq := get_skeleton()
	if esq == null or peso <= 0.001 or balon == null or cuerpo == null or not is_instance_valid(balon) or not esq.is_inside_tree():
		return
	var g := esq.global_transform
	var a_esq := g.affine_inverse()
	if lado == "" or peso < 0.02:
		lado = _pie_cercano(esq, g)
	var i1 := esq.find_bone("thigh_" + lado)
	var i2 := esq.find_bone("calf_" + lado)
	var i3 := esq.find_bone("foot_" + lado)
	if i1 < 0 or i2 < 0 or i3 < 0:
		return
	var tobillo_g := g * esq.get_bone_global_pose(i3).origin
	## El objetivo: detrás del balón visto desde el cuerpo, a la altura del tobillo del clip (o algo más si el balón va levantado).
	var bp := balon.global_position
	var hacia_cuerpo := cuerpo.global_position - bp
	hacia_cuerpo.y = 0.0
	if hacia_cuerpo.length() < 0.01:
		return
	var obj := bp + hacia_cuerpo.normalized() * (RADIO_BALON + SEPARACION)
	obj.y = maxf(tobillo_g.y, bp.y - RADIO_BALON * 0.5)
	if obj.distance_to(tobillo_g) > ALCANCE:
		return
	var t := a_esq * tobillo_g.lerp(obj, clampf(peso, 0.0, 1.0))
	var p1 := esq.get_bone_global_pose(i1)
	var p3 := esq.get_bone_global_pose(i3)
	var a := p1.origin
	var b := esq.get_bone_global_pose(i2).origin
	var c := p3.origin
	var l1 := a.distance_to(b)
	var l2 := b.distance_to(c)
	if l1 < 0.001 or l2 < 0.001:
		return
	var hacia := t - a
	var d := clampf(hacia.length(), absf(l1 - l2) + 0.005, l1 + l2 - 0.005)
	if hacia.length() < 0.001:
		return
	var dir := hacia.normalized()
	## La rodilla: en el plano que ya formaba la pierna (si iba recta, hacia delante del cuerpo).
	var polo := (b - a) - dir * (b - a).dot(dir)
	if polo.length() < 0.01:
		var frente := a_esq.basis * cuerpo.global_basis.z
		polo = frente - dir * frente.dot(dir)
	if polo.length() < 0.0001:
		return
	polo = polo.normalized()
	var x := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var alto := sqrt(maxf(0.0, l1 * l1 - x * x))
	var rodilla := a + dir * x + polo * alto
	var pie := a + dir * d
	var giro1 := Quaternion((b - a).normalized(), (rodilla - a).normalized())
	esq.set_bone_global_pose(i1, Transform3D(Basis(giro1) * p1.basis, a))
	var p2 := esq.get_bone_global_pose(i2)
	var c2 := esq.get_bone_global_pose(i3).origin
	var giro2 := Quaternion((c2 - p2.origin).normalized(), (pie - p2.origin).normalized())
	esq.set_bone_global_pose(i2, Transform3D(Basis(giro2) * p2.basis, p2.origin))
	## El pie conserva la orientación que traía el clip (la planta no se tuerce al estirar la pierna).
	esq.set_bone_global_pose(i3, Transform3D(p3.basis, esq.get_bone_global_pose(i3).origin))

func _pie_cercano(esq: Skeleton3D, g: Transform3D) -> String:
	var il := esq.find_bone("foot_l")
	var ir := esq.find_bone("foot_r")
	if il < 0 or ir < 0:
		return "r"
	var bp := balon.global_position
	var dl := (g * esq.get_bone_global_pose(il).origin).distance_squared_to(bp)
	var dr := (g * esq.get_bone_global_pose(ir).origin).distance_squared_to(bp)
	return "l" if dl < dr else "r"
