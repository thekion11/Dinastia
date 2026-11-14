class_name BrazosIK
extends SkeletonModifier3D
## LOS DOS BRAZOS HACIA DOS PUNTOS (14-11-2026): cinemática inversa de dos huesos, resuelta a mano, para que un
## personaje del juego (esqueleto tipo Unreal: `upperarm_*`, `lowerarm_*`, `hand_*`) lleve las manos a un objeto:
## el galardón que toma del pedestal (`GalaPremio3D`) o la cámara de un fotógrafo. (El `TwoBoneIK3D` del motor no
## movía estos brazos.) Va DESPUÉS de la animación; `influence` (0-1) lo mezcla con ella. Por brazo: el hombro
## no se mueve, el codo se dobla hacia donde ya apuntaba y la mano llega al punto (o hasta donde dé el brazo).

var derecha: Node3D
var izquierda: Node3D

func _process_modification() -> void:
	var esq := get_skeleton()
	if esq == null or not esq.is_inside_tree():
		return
	var a_esq := esq.global_transform.affine_inverse()
	for par: Array in [["r", derecha], ["l", izquierda]]:
		var destino: Node3D = par[1]
		if destino == null or not is_instance_valid(destino) or not destino.is_inside_tree():
			continue
		var i1 := esq.find_bone("upperarm_" + String(par[0]))
		var i2 := esq.find_bone("lowerarm_" + String(par[0]))
		var i3 := esq.find_bone("hand_" + String(par[0]))
		if i1 < 0 or i2 < 0 or i3 < 0:
			continue
		var t := a_esq * destino.global_position
		var p1 := esq.get_bone_global_pose(i1)
		var a := p1.origin
		var b := esq.get_bone_global_pose(i2).origin
		var c := esq.get_bone_global_pose(i3).origin
		var l1 := a.distance_to(b)
		var l2 := b.distance_to(c)
		if l1 < 0.001 or l2 < 0.001:
			continue
		var hacia := t - a
		var d := clampf(hacia.length(), absf(l1 - l2) + 0.005, l1 + l2 - 0.005)
		var dir := hacia.normalized() if hacia.length() > 0.001 else Vector3.FORWARD
		## El codo: en el plano que ya formaba el brazo (si iba recto, hacia abajo y atrás).
		var polo := (b - a) - dir * (b - a).dot(dir)
		if polo.length() < 0.02:
			polo = Vector3(0, -1, -0.4) - dir * Vector3(0, -1, -0.4).dot(dir)
		polo = polo.normalized()
		var x := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
		var alto := sqrt(maxf(0.0, l1 * l1 - x * x))
		var codo := a + dir * x + polo * alto
		var mano := a + dir * d
		## El brazo gira en el hombro hasta que el codo queda en su sitio.
		var giro1 := Quaternion((b - a).normalized(), (codo - a).normalized())
		esq.set_bone_global_pose(i1, Transform3D(Basis(giro1) * p1.basis, a))
		## Y el antebrazo gira en el codo hasta que la mano llega.
		var p2 := esq.get_bone_global_pose(i2)
		var c2 := esq.get_bone_global_pose(i3).origin
		var giro2 := Quaternion((c2 - p2.origin).normalized(), (mano - p2.origin).normalized())
		esq.set_bone_global_pose(i2, Transform3D(Basis(giro2) * p2.basis, p2.origin))
