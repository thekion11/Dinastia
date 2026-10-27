extends Node
## SONDA DE ANATOMÍA Y MOVIMIENTO (pasadas P1/P2 del plan §2.2e, 26-10-2026).
##   godot --headless --path . res://pruebas/sonda_movimiento.tscn
## Mide el cuerpo base del juego contra proporciones humanas medias (altura en
## cabezas, anchura de hombros, brazo y pierna respecto a la altura) y la velocidad
## natural de los clips de andar y correr (lo que recorre el pie apoyado por
## segundo) frente a las velocidades reales del paseo: la diferencia es lo que
## patina el pie. Solo imprime; no cambia nada.

## Medias humanas (adulto): fracción de la altura total.
## Medias humanas (adulto, fracción de la altura): cabeza 1/7,5; hombros (biacromial) 0,245; hombro→muñeca 0,34;
## cadera→tobillo 0,48; antebrazo/brazo 0,80; pantorrilla/muslo 0,95.
const HUMANO := {"cabeza": 1.0 / 7.5, "hombros": 0.245, "brazo": 0.34, "pierna": 0.48, "antebrazo_sobre_brazo": 0.80, "pantorrilla_sobre_muslo": 0.95}
const VELOCIDADES := {"caminar": 1.7, "caminar_normal": 1.7, "caminar_agachado": 1.7, "caminar_trote": 3.0, "correr": 5.0}

func _ready() -> void:
	await get_tree().process_frame
	for cuerpo: String in ["male", "female"]:
		var raiz := Node3D.new()
		add_child(raiz)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var asp := PersonajeDT.aleatorio(rng)
		## Complexión neutra: lo que se mide es el modelo base, no una complexión al azar.
		for k: String in PersonajeDT.ASPECTO_NEUTRO:
			asp[k] = 0.0
		asp.erase("ropa")
		asp["cuerpo"] = cuerpo
		asp["altura"] = 1.78 if cuerpo == "male" else 1.66
		var d := PersonajeDT.crear(raiz, asp, Color.BLUE, Color.WHITE)
		if d.is_empty():
			print("sin modelo ", cuerpo)
			continue
		await get_tree().process_frame
		_anatomia(cuerpo, d)
		_clips(cuerpo, d)
		raiz.queue_free()
	get_tree().quit()

func _pos(esq: Skeleton3D, hueso: String) -> Vector3:
	var i := esq.find_bone(hueso)
	if i < 0:
		return Vector3.INF
	return esq.global_transform * esq.get_bone_global_pose(i).origin

func _alto(d: Dictionary) -> float:
	var top := -INF
	var bajo := INF
	for mi in (d["nodo"] as Node3D).find_children("*", "MeshInstance3D", true, false):
		## Solo el cuerpo del modelo (no pelo, gorras ni accesorios colgados).
		if not (mi as MeshInstance3D).mesh is ArrayMesh or mi.get_parent() != d["esqueleto"]:
			continue
		var aabb: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		top = maxf(top, aabb.end.y)
		bajo = minf(bajo, aabb.position.y)
	return top - bajo

func _anatomia(cuerpo: String, d: Dictionary) -> void:
	var esq: Skeleton3D = d["esqueleto"]
	var ap: AnimationPlayer = d.get("anim")
	if ap != null:
		ap.pause()   ## sin `stop()`: borraría las escalas de hueso que se quieren medir
		esq.force_update_all_bone_transforms()
	var h := _alto(d)
	var cabeza := _pos(esq, "Head")
	var cuello := _pos(esq, "neck_01")
	var hombro_i := _pos(esq, "upperarm_l")
	var hombro_d := _pos(esq, "upperarm_r")
	var codo := _pos(esq, "lowerarm_l")
	var mano := _pos(esq, "hand_l")
	var cadera := _pos(esq, "thigh_l")
	var rodilla := _pos(esq, "calf_l")
	var pie := _pos(esq, "foot_l")
	## La cabeza: de la base del cráneo (hueso Head) a la coronilla (tope del cuerpo), más el mentón (≈ 3 cm bajo el hueso).
	var top := -INF
	for mi in (d["nodo"] as Node3D).find_children("*", "MeshInstance3D", true, false):
		if (mi as MeshInstance3D).mesh is ArrayMesh and mi.get_parent() == esq:
			top = maxf(top, ((mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()).end.y)
	var alto_cabeza := (top - cabeza.y) + 0.03
	for hb: String in ["clavicle_l", "upperarm_l", "lowerarm_l", "thigh_l", "calf_l"]:
		var i := esq.find_bone(hb)
		if i >= 0:
			var bx := esq.get_bone_global_rest(i).basis.x
			print("  eje X local de %-11s en el mundo: (%.2f, %.2f, %.2f)" % [hb, bx.x, bx.y, bx.z])
	print("  (pelvis %.2f · cuello %.2f · cabeza %.2f · coronilla %.2f · pies %.2f)" % [_pos(esq, "pelvis").y, cuello.y, cabeza.y, top, pie.y])
	var medidas := {
		"cabeza": alto_cabeza / h,
		"hombros": hombro_i.distance_to(hombro_d) / h,
		"brazo": (hombro_i.distance_to(codo) + codo.distance_to(mano)) / h,
		"pierna": (cadera.distance_to(rodilla) + rodilla.distance_to(pie)) / h,
		"antebrazo_sobre_brazo": codo.distance_to(mano) / maxf(hombro_i.distance_to(codo), 0.001),
		"pantorrilla_sobre_muslo": rodilla.distance_to(pie) / maxf(cadera.distance_to(rodilla), 0.001),
	}
	## POSTURA de pie («parado», a mitad del clip): separación de los pies y ángulo de la rodilla (humano relajado: pies a
	## 0,20-0,30 m para 1,78 m de altura; rodilla casi recta, > 170°).
	if ap != null and ap.has_animation("parado"):
		ap.play("parado")
		ap.seek(0.5, true)
		esq.force_update_all_bone_transforms()
		var fi := _pos(esq, "foot_l")
		var fd := _pos(esq, "foot_r")
		var ca := _pos(esq, "thigh_l")
		var ro := _pos(esq, "calf_l")
		var rodilla_ang := rad_to_deg((ca - ro).angle_to(fi - ro))
		print("  POSTURA parado: pies a %.2f m (%.2f de la altura) · rodilla %.0f° · tobillos a %.2f m del eje · pie a %.3f m del suelo" % [fi.distance_to(fd), fi.distance_to(fd) / h, rodilla_ang, absf(fi.x - fd.x) * 0.5, fi.y])
		ap.pause()
	print("\n=== ANATOMÍA %s · altura %.2f m · %.1f cabezas ===" % [cuerpo, h, 1.0 / maxf(medidas["cabeza"], 0.001)])
	for k: String in medidas:
		var v: float = medidas[k]
		var ref: float = HUMANO[k]
		print("  %-24s juego %.3f · humano %.3f · desvío %+.0f %%" % [k, v, ref, (v / ref - 1.0) * 100.0])

## Velocidad natural de cada clip: el pie apoyado (el más bajo) se desplaza hacia
## atrás a la velocidad del suelo; se toma la mediana de ese desplazamiento.
func _clips(cuerpo: String, d: Dictionary) -> void:
	var esq: Skeleton3D = d["esqueleto"]
	var ap: AnimationPlayer = d.get("anim")
	if ap == null:
		return
	print("=== CLIPS %s (velocidad natural del pie apoyado vs la del juego) ===" % cuerpo)
	for clip: String in VELOCIDADES:
		if not ap.has_animation(clip):
			print("  %-16s (no existe)" % clip)
			continue
		ap.play(clip)
		ap.speed_scale = 1.0
		var largo := ap.current_animation_length
		var dt := 1.0 / 60.0
		var vels: Array[float] = []
		var antes_i := Vector3.INF
		var antes_d := Vector3.INF
		var t := 0.0
		while t < largo:
			ap.seek(t, true)
			esq.force_update_all_bone_transforms()
			var pi := _pos(esq, "foot_l")
			var pd := _pos(esq, "foot_r")
			if antes_i != Vector3.INF:
				var apoyado_i := pi.y <= pd.y
				var p0: Vector3 = antes_i if apoyado_i else antes_d
				var p1: Vector3 = pi if apoyado_i else pd
				vels.append(Vector2(p1.x - p0.x, p1.z - p0.z).length() / dt)
			antes_i = pi
			antes_d = pd
			t += dt
		vels.sort()
		var natural: float = vels[vels.size() / 2] if not vels.is_empty() else 0.0
		var juego: float = VELOCIDADES[clip]
		print("  %-16s natural %.2f m/s · juego %.2f m/s · patina ×%.2f · largo %.2f s" % [clip, natural, juego, juego / maxf(natural, 0.01), largo])
	ap.stop()
