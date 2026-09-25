extends Node
## Compara la posicion de reposo de "pelvis"/"root" en nuestro esqueleto
## contra el primer fotograma de esos mismos huesos en el clip real de
## futbol, para confirmar (o descartar) un desfase de posicion absoluta.

func _ready() -> void:
	var d := FutbolistaQ.crear(1.80)
	add_child(d["nodo"])
	FutbolistaQ.terminar(d)
	var esq: Skeleton3D = d["esqueleto"]
	for hueso in ["root", "pelvis", "spine_01", "thigh_l"]:
		var i := esq.find_bone(hueso)
		if i >= 0:
			var t := esq.get_bone_rest(i)
			var padre := esq.get_bone_parent(i)
			var nombre_padre := esq.get_bone_name(padre) if padre >= 0 else "(ninguno)"
			print("NUESTRO reposo ", hueso, " padre=", nombre_padre, " pos=", t.origin, " rot(euler,deg)=", t.basis.get_euler() * 180.0 / PI)

	var packed: PackedScene = load("res://assets/characters/quaternius/anims_futbol/09_Power_Kick_ue5.fbx")
	var nodo: Node3D = packed.instantiate()
	add_child(nodo)
	var esq_origen := _buscar_esq(nodo)
	for hueso in ["root", "pelvis", "spine_01", "thigh_l"]:
		var i := esq_origen.find_bone(hueso)
		if i >= 0:
			var t := esq_origen.get_bone_rest(i)
			var padre := esq_origen.get_bone_parent(i)
			var nombre_padre := esq_origen.get_bone_name(padre) if padre >= 0 else "(ninguno)"
			print("ORIGEN reposo ", hueso, " padre=", nombre_padre, " pos=", t.origin, " rot(euler,deg)=", t.basis.get_euler() * 180.0 / PI)
	var ap := _buscar_ap(nodo)
	var lib := ap.get_animation_library("")
	var anim: Animation = lib.get_animation("clip")
	for i in anim.get_track_count():
		var ruta := str(anim.track_get_path(i))
		if ruta.ends_with(":root") or ruta.ends_with(":pelvis"):
			if anim.track_get_type(i) == Animation.TYPE_POSITION_3D:
				print("CLIP POS ", ruta, " t=0 -> ", anim.position_track_interpolate(i, 0.0))
			elif anim.track_get_type(i) == Animation.TYPE_ROTATION_3D:
				var q0: Quaternion = anim.rotation_track_interpolate(i, 0.0)
				print("CLIP ROT ", ruta, " t=0 -> euler(deg)=", q0.get_euler() * 180.0 / PI)
	get_tree().quit(0)

func _buscar_esq(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := _buscar_esq(c)
		if r:
			return r
	return null

func _buscar_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _buscar_ap(c)
		if r:
			return r
	return null
