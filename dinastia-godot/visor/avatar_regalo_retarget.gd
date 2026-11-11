class_name AvatarRegaloRetarget
extends SkeletonModifier3D
## Pasa las animaciones del cuerpo del juego (esqueleto Quaternius, tipo Unreal) al esqueleto Mixamo del
## avatar regalo (73 huesos, `Hips`, `Spine`… `LeftHandIndex1`…). Solo copia ROTACIONES globales medidas contra el
## reposo de cada esqueleto (los dos están en T) y el desplazamiento de la cadera escalado por su altura: así
## sirve aunque las proporciones sean otras. Los huesos sin pareja (torsión del antebrazo, cuello 1-2, ojos)
## se quedan en su reposo. Es el mismo principio de `RetargetFutbolQ`, con nombres distintos y sin copiar posiciones.

## hueso del esqueleto de origen (Quaternius) → hueso del avatar (Mixamo). Padres antes que hijos.
const MAPA := {
	"pelvis": "Hips", "spine_01": "Spine", "spine_02": "Spine1", "spine_03": "Spine2", "neck_01": "Neck", "Head": "Head",
	"thigh_l": "LeftUpLeg", "calf_l": "LeftLeg", "foot_l": "LeftFoot", "ball_l": "LeftToeBase",
	"thigh_r": "RightUpLeg", "calf_r": "RightLeg", "foot_r": "RightFoot", "ball_r": "RightToeBase",
	"clavicle_l": "LeftShoulder", "upperarm_l": "LeftArm", "lowerarm_l": "LeftForeArm", "hand_l": "LeftHand",
	"clavicle_r": "RightShoulder", "upperarm_r": "RightArm", "lowerarm_r": "RightForeArm", "hand_r": "RightHand",
}
const DEDOS := {"thumb": "Thumb", "index": "Index", "middle": "Middle", "ring": "Ring", "pinky": "Pinky"}

var origen: Skeleton3D
var _pares: Array[Dictionary] = []
var _ratio_cadera := 1.0

func configurar(esq_origen: Skeleton3D) -> void:
	origen = esq_origen
	_pares.clear()
	var destino := get_skeleton()
	if origen == null or destino == null:
		return
	var mapa := MAPA.duplicate()
	for lado: String in ["l", "r"]:
		for d: String in DEDOS:
			for n in [1, 2, 3]:
				mapa["%s_0%d_%s" % [d, n, lado]] = "%sHand%s%d" % ["Left" if lado == "l" else "Right", DEDOS[d], n]
	## Orden: el del esqueleto de destino (los padres siempre van antes que los hijos).
	var por_destino := {}
	for k: String in mapa:
		var i_o := origen.find_bone(k)
		var i_d := destino.find_bone(String(mapa[k]))
		if i_o >= 0 and i_d >= 0:
			por_destino[i_d] = i_o
	var ids := por_destino.keys()
	ids.sort()
	for i_d: int in ids:
		_pares.append({"o": int(por_destino[i_d]), "d": i_d,
			"rest_o": origen.get_bone_global_rest(int(por_destino[i_d])).basis.orthonormalized(),
			"rest_d": destino.get_bone_global_rest(i_d).basis.orthonormalized()})
	var cad_o := origen.find_bone("pelvis")
	var cad_d := destino.find_bone("Hips")
	if cad_o >= 0 and cad_d >= 0:
		var ho := origen.get_bone_global_rest(cad_o).origin.y * origen.global_basis.get_scale().y
		var hd := destino.get_bone_global_rest(cad_d).origin.y * destino.global_basis.get_scale().y
		_ratio_cadera = hd / ho if absf(ho) > 0.01 else 1.0

func pares() -> int:
	return _pares.size()

func _process_modification() -> void:
	var destino := get_skeleton()
	if origen == null or destino == null or not origen.is_inside_tree() or not destino.is_inside_tree():
		return
	var b_o := origen.global_basis.orthonormalized()
	var b_d_inv := destino.global_basis.orthonormalized().inverse()
	for par: Dictionary in _pares:
		var io: int = par["o"]
		var id: int = par["d"]
		var pose_o: Transform3D = origen.get_bone_global_pose(io)
		var delta_mundo: Basis = (b_o * pose_o.basis.orthonormalized()) * (b_o * (par["rest_o"] as Basis)).inverse()
		var rot_mundo: Basis = delta_mundo * (destino.global_basis.orthonormalized() * (par["rest_d"] as Basis))
		var rot_esq: Basis = b_d_inv * rot_mundo
		var padre := destino.get_bone_parent(id)
		var rot_local: Basis = rot_esq
		if padre >= 0:
			rot_local = destino.get_bone_global_pose(padre).basis.orthonormalized().inverse() * rot_esq
		destino.set_bone_pose_rotation(id, rot_local.get_rotation_quaternion())
		if destino.get_bone_name(id) == "Hips":
			var rest_o: Transform3D = origen.get_bone_global_rest(io)
			var dp: Vector3 = b_o * (pose_o.origin - rest_o.origin) * origen.global_basis.get_scale().y * _ratio_cadera
			var rest_d: Transform3D = destino.get_bone_global_rest(id)
			destino.set_bone_pose_position(id, rest_d.origin + b_d_inv * dp / maxf(destino.global_basis.get_scale().y, 0.0001))
