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
	for lado: String in ["L", "R"]:
		_brazo_abajo("UpperArm." + lado, "LowerArm." + lado, 1.0 if lado == "L" else -1.0)
		_brazo_abajo("LowerArm." + lado, "Hand." + lado, 1.0 if lado == "L" else -1.0, 0.12)
	for n: String in ["Hips", "Chest", "Neck", "Head", "Torso"]:
		var i := esq.find_bone(n)
		if i >= 0:
			_hueso[n] = [i, esq.get_bone_pose_rotation(i)]

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
