class_name IdleProcedural
extends Node
## UN REPOSO VIVO PARA MODELOS SIN ANIMACIONES (2-11-2026): los «Modular Men/Women» de Quaternius (CC0)
## vienen en T y sin ningún clip, con un esqueleto de 49-51 huesos distinto al del juego. En vez de
## retargetear una biblioteca entera, se les pone: los brazos caídos junto al cuerpo (una vez, a partir de
## la dirección real de cada hueso en reposo), la respiración del pecho, un leve balanceo de cabeza y el
## cambio de peso de la cadera. Todo por código, sin archivos.

var esq: Skeleton3D
var _t := 0.0
var _hueso := {}          ## nombre → [índice, rotación base de pose]

func configurar(e: Skeleton3D) -> void:
	esq = e
	_t = randf() * 6.0
	## Tres convenciones de nombres: Quaternius modular («UpperArm.L»), VRM («leftUpperArm») y Mixamo («mixamorig:LeftArm»).
	var conv := 0
	if esq.find_bone("leftUpperArm") >= 0:
		conv = 1
	elif esq.find_bone("mixamorig:LeftArm") >= 0:
		conv = 2
	for lado: String in ["L", "R"]:
		var s := 1.0 if lado == "L" else -1.0
		var nombres := ["UpperArm." + lado, "LowerArm." + lado, "Hand." + lado]
		if conv == 1:
			var p := "left" if lado == "L" else "right"
			nombres = [p + "UpperArm", p + "LowerArm", p + "Hand"]
		elif conv == 2:
			var q := "mixamorig:Left" if lado == "L" else "mixamorig:Right"
			nombres = [q + "Arm", q + "ForeArm", q + "Hand"]
		## En VRM/Mixamo el lado «izquierdo» del personaje queda en el +X del modelo mirando a +Z o a -Z según el
		## exportador: se decide por la posición real de la mano.
		var ih := esq.find_bone(nombres[2])
		## Un antebrazo mal nombrado en el modelo («rightLoweArm» en los avatares Numinia): es el padre de la mano.
		if esq.find_bone(nombres[1]) < 0 and ih >= 0 and esq.get_bone_parent(ih) >= 0:
			nombres[1] = esq.get_bone_name(esq.get_bone_parent(ih))
		if ih >= 0 and conv != 0:
			s = signf((esq.global_transform * esq.get_bone_global_pose(ih).origin).x) if absf((esq.global_transform * esq.get_bone_global_pose(ih).origin).x) > 0.01 else s
		_brazo_abajo(nombres[0], nombres[1], s)
		_brazo_abajo(nombres[1], nombres[2], s, 0.12)
	var mapa := {"Hips": ["Hips", "hips", "mixamorig:Hips"], "Chest": ["Chest", "chest", "mixamorig:Spine2"],
		"Neck": ["Neck", "neck", "mixamorig:Neck"], "Head": ["Head", "head", "mixamorig:Head"]}
	for n: String in mapa:
		for cand: String in mapa[n]:
			var i := esq.find_bone(cand)
			if i >= 0:
				_hueso[n] = [i, esq.get_bone_pose_rotation(i)]
				break

## Gira el hueso `nom` para que apunte hacia abajo (algo pegado al cuerpo), midiendo su dirección real.
func _brazo_abajo(nom: String, hijo: String, lado: float, apertura := 0.18) -> void:
	var i := esq.find_bone(nom)
	var h := esq.find_bone(hijo)
	if i < 0 or h < 0:
		return
	## Todo en el espacio del esqueleto, con la pose ACTUAL (el brazo ya girado arrastra al antebrazo).
	var gi := esq.get_bone_global_pose(i)
	var gh := esq.get_bone_global_pose(h)
	var actual := (gh.origin - gi.origin).normalized()
	var mundo_abajo := Vector3(lado * apertura, -1.0, 0.04).normalized()
	var objetivo := (esq.global_transform.basis.inverse() * mundo_abajo).normalized()
	var q := Quaternion(actual, objetivo)
	var nueva := Basis(q) * gi.basis
	var padre := esq.get_bone_parent(i)
	var pb := esq.get_bone_global_pose(padre).basis if padre >= 0 else Basis.IDENTITY
	esq.set_bone_pose_rotation(i, (pb.inverse() * nueva).get_rotation_quaternion())
	esq.force_update_all_bone_transforms()   ## el siguiente hueso (antebrazo) lee la pose ya girada

func _process(delta: float) -> void:
	if esq == null:
		return
	_t += delta
	_mover("Chest", Vector3(sin(_t * 1.6) * 0.018, 0, 0))
	_mover("Head", Vector3(sin(_t * 0.7) * 0.03, sin(_t * 0.45) * 0.06, 0))
	_mover("Hips", Vector3(0, 0, sin(_t * 0.5) * 0.015))

func _mover(n: String, euler: Vector3) -> void:
	if not _hueso.has(n):
		return
	var par: Array = _hueso[n]
	esq.set_bone_pose_rotation(int(par[0]), (par[1] as Quaternion) * Quaternion.from_euler(euler))
