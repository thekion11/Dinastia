extends BaseIdea
## BANCO ESPECIALIZADO «personajes_3d», FASE 2 (4-11-2026, megarreforma de los bancos): los cuerpos, el pelo y las animaciones, medidos.
## Lo corre `herramientas/bancos_especiales.py personajes_3d`.
##   1. Anatomía y escala: 2 cuerpos × 4 alturas: estatura pedida, proporción de piernas y brazos, anchura de hombros, simetría izquierda-derecha.
##   2. Animaciones: las 5 imprescindibles existen, duran lo debido, todas sus pistas apuntan a huesos que existen, sin claves vacías ni números rotos,
##      los ciclos cierran (primera y última pose iguales) y los pies no se hunden ni vuelan al andar y correr.
##   3. Pelo y cara: los 24 cortes en los dos cuerpos: la malla del pelo queda sobre la cabeza (ni corrida, ni por debajo del cuello), ojos y cejas dentro de la cabeza.
##   4. LOD: los modelos de personaje se importan con niveles de detalle.
const ALTURAS := [1.55, 1.70, 1.80, 1.95]
const IMPRESCINDIBLES := ["caminar", "correr", "parado", "trotar", "sentado"]
const CICLOS := ["caminar", "correr", "trotar"]

func _probar() -> void:
	_titulo("BANCO PERSONAJES_3D (fase 2): anatomía, animaciones, pelo y cara, LOD")
	var padre := Node3D.new()
	add_child(padre)
	for cuerpo in ["male", "female"]:
		for alt in ALTURAS:
			await _anatomia(padre, cuerpo, alt)
	for cuerpo in ["male", "female"]:
		await _animaciones(padre, cuerpo)
	for cuerpo in ["male", "female"]:
		await _pelo_y_cara(padre, cuerpo)
	_lod()
	padre.free()

func _crear(padre: Node3D, cuerpo: String, altura: float, pelo := "") -> Dictionary:
	var asp := {"cuerpo": cuerpo, "altura": altura}
	if pelo != "":
		asp["pelo"] = pelo
	var d: Dictionary = PersonajeDT.crear(padre, asp)
	for i in 2:
		await get_tree().process_frame
	return d

func _hueso(esq: Skeleton3D, nombre: String) -> Vector3:
	var i := esq.find_bone(nombre)
	return (esq.global_transform * esq.get_bone_global_pose(i)).origin if i >= 0 else Vector3(INF, INF, INF)

## ---- 1. anatomía
func _anatomia(padre: Node3D, cuerpo: String, altura: float) -> void:
	var d: Dictionary = await _crear(padre, cuerpo, altura)
	var esq: Skeleton3D = FutbolistaQ.esqueleto_de(d["nodo"])
	var etq := "%s %.2f m" % [cuerpo, altura]
	if esq == null:
		_comprobar(false, "%s: tiene esqueleto" % etq)
		return
	esq.reset_bone_poses()
	var cabeza := _hueso(esq, "Head")
	var pie := _hueso(esq, "ball_l")
	var cadera := _hueso(esq, "pelvis")
	var hombro_i := _hueso(esq, "upperarm_l")
	var hombro_d := _hueso(esq, "upperarm_r")
	var mano := _hueso(esq, "hand_l")
	var muslo_i := _hueso(esq, "thigh_l")
	var muslo_d := _hueso(esq, "thigh_r")
	var talla := cabeza.y - pie.y + 0.11   ## de la planta a la coronilla (medido: la coronilla queda 11 cm sobre el hueso de la cabeza y la bola del pie ~3 cm sobre la planta)
	var piernas := (cadera.y - pie.y) / talla
	var brazo := hombro_i.distance_to(mano) / talla
	var hombros := hombro_i.distance_to(hombro_d) / talla
	var simetria := absf((muslo_i.x - cadera.x) + (muslo_d.x - cadera.x))
	print("  %-12s talla %.2f m · piernas %.2f · brazo %.2f · hombros %.2f · asimetría %.3f m" % [etq, talla, piernas, brazo, hombros, simetria])
	_comprobar(absf(talla - altura) <= altura * 0.04, "%s: estatura real %.2f m (±4 %%)" % [etq, talla])
	_comprobar(piernas > 0.45 and piernas < 0.60, "%s: cadera a %.0f %% de la estatura (45-60 %%, en una persona real ~53 %%)" % [etq, piernas * 100.0])
	_comprobar(brazo > 0.25 and brazo < 0.45, "%s: brazo (hombro a mano) %.0f %% de la estatura" % [etq, brazo * 100.0])
	_comprobar(hombros > 0.12 and hombros < 0.32, "%s: anchura de hombros %.0f %% de la estatura" % [etq, hombros * 100.0])
	_comprobar(simetria < 0.02, "%s: simétrico izquierda-derecha (%.3f m)" % [etq, simetria])
	(d["nodo"] as Node).queue_free()

## ---- 2. animaciones
func _animaciones(padre: Node3D, cuerpo: String) -> void:
	var d: Dictionary = await _crear(padre, cuerpo, 1.80)
	var ap: AnimationPlayer = d["anim"]
	var esq: Skeleton3D = FutbolistaQ.esqueleto_de(d["nodo"])
	var lista := ap.get_animation_list()
	for nombre in IMPRESCINDIBLES:
		_comprobar(lista.has(nombre), "%s: animación «%s» presente" % [cuerpo, nombre])
	var sin_hueso := 0
	var rotas := 0
	var vacias := 0
	var largos_mal := 0
	var total_pistas := 0
	for nombre in lista:
		var a := ap.get_animation(nombre)
		if a.length < 0.2 or a.length > 8.0:
			largos_mal += 1
		for t in a.get_track_count():
			total_pistas += 1
			var ruta := a.track_get_path(t)
			var base := ap.get_node_or_null(NodePath(String(ruta.get_concatenated_names())))
			if base == null:
				sin_hueso += 1
			elif ruta.get_subname_count() > 0 and base is Skeleton3D and (base as Skeleton3D).find_bone(String(ruta.get_concatenated_subnames())) < 0:
				sin_hueso += 1
			if a.track_get_key_count(t) == 0:
				vacias += 1
			for k in mini(a.track_get_key_count(t), 8):
				var v: Variant = a.track_get_key_value(t, k)
				if (v is Vector3 and not (is_finite((v as Vector3).x) and is_finite((v as Vector3).y) and is_finite((v as Vector3).z))) or (v is Quaternion and not (is_finite((v as Quaternion).x) and is_finite((v as Quaternion).w))):
					rotas += 1
	print("  %s: %d animaciones, %d pistas; sin hueso %d, vacías %d, con números rotos %d, duración absurda %d" % [cuerpo, lista.size(), total_pistas, sin_hueso, vacias, rotas, largos_mal])
	_comprobar(sin_hueso == 0, "%s: todas las pistas apuntan a un hueso que existe (%d sin)" % [cuerpo, sin_hueso])
	_comprobar(vacias == 0 and rotas == 0, "%s: sin pistas vacías ni valores rotos (%d / %d)" % [cuerpo, vacias, rotas])
	_comprobar(largos_mal == 0, "%s: todas duran entre 0,2 y 8 s (%d fuera)" % [cuerpo, largos_mal])
	for nombre in CICLOS:
		if not lista.has(nombre):
			continue
		var a := ap.get_animation(nombre)
		_comprobar(a.loop_mode != Animation.LOOP_NONE, "%s «%s»: es un ciclo (loop)" % [cuerpo, nombre])
		## Cierra: la pose de pelvis al principio y al final del ciclo casi iguales.
		var gap := 0.0
		var n := 0
		for t in a.get_track_count():
			if a.track_get_type(t) == Animation.TYPE_ROTATION_3D and a.track_get_key_count(t) >= 2:
				var q0: Quaternion = a.track_get_key_value(t, 0)
				var q1: Quaternion = a.track_get_key_value(t, a.track_get_key_count(t) - 1)
				gap += q0.angle_to(q1)
				n += 1
		var medio := gap / maxf(1.0, float(n))
		_comprobar(medio < 0.25, "%s «%s»: el ciclo cierra (diferencia media entre primera y última pose %.3f rad)" % [cuerpo, nombre, medio])
		## Pies: altura de la bola del pie a lo largo del ciclo.
		ap.play(nombre)
		var ymin := INF
		var ymax := -INF
		for k in 12:
			ap.seek(a.length * float(k) / 12.0, true)
			esq.force_update_all_bone_transforms()
			for hueso in ["ball_l", "ball_r"]:
				var y := _hueso(esq, hueso).y
				ymin = minf(ymin, y)
				ymax = maxf(ymax, y)
		print("    %s «%s»: pies entre %.3f y %.3f m" % [cuerpo, nombre, ymin, ymax])
		_comprobar(ymin > -0.12 and ymax < 0.9, "%s «%s»: los pies ni se hunden ni vuelan (%.2f..%.2f m)" % [cuerpo, nombre, ymin, ymax])
		ap.stop()
	(d["nodo"] as Node).queue_free()

## ---- 3. pelo y cara
func _pelo_y_cara(padre: Node3D, cuerpo: String) -> void:
	var mal: Array[String] = []
	var revisados := 0
	for corte in PeloQ.DE_CORTE.keys():
		var d: Dictionary = await _crear(padre, cuerpo, 1.80, String(corte))
		var esq: Skeleton3D = FutbolistaQ.esqueleto_de(d["nodo"])
		esq.reset_bone_poses()
		esq.force_update_all_bone_transforms()
		var cabeza := _hueso(esq, "Head")
		var cuello := _hueso(esq, "neck_01")
		var pecho := _hueso(esq, "spine_03")
		for m in (d["nodo"] as Node).find_children("Hair_*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			if mi.mesh == null:
				continue
			revisados += 1
			var caja := mi.global_transform * mi.get_aabb()
			var c := caja.get_center()
			var largo := String(mi.name).begins_with("Hair_Long")
			var corrido := Vector2(c.x - cabeza.x, c.z - cabeza.z).length()
			if corrido > 0.30:
				mal.append("%s %s: pelo corrido %.2f m de la cabeza" % [cuerpo, corte, corrido])
			if caja.position.y < (pecho.y - 0.15 if largo else cuello.y - 0.12):
				mal.append("%s %s: el pelo baja hasta y=%.2f (cuello %.2f)" % [cuerpo, corte, caja.position.y, cuello.y])
			if caja.end.y < cabeza.y + 0.05:
				mal.append("%s %s: el pelo no llega a la coronilla (%.2f, cabeza %.2f)" % [cuerpo, corte, caja.end.y, cabeza.y])
			if caja.size.x > 0.75 or caja.size.z > 0.75 or caja.size.y > 0.9:
				mal.append("%s %s: pelo enorme %s" % [cuerpo, corte, str(caja.size.snapped(Vector3.ONE * 0.01))])
		for nombre in ["Eyes", "Eyebrows"]:
			for m in (d["nodo"] as Node).find_children(nombre + "*", "MeshInstance3D", true, false):
				var mi := m as MeshInstance3D
				if mi.mesh == null:
					continue
				var c := (mi.global_transform * mi.get_aabb()).get_center()
				if c.distance_to(cabeza) > 0.30:
					mal.append("%s %s: %s fuera de la cabeza (%.2f m)" % [cuerpo, corte, nombre, c.distance_to(cabeza)])
		(d["nodo"] as Node).queue_free()
	for l in mal.slice(0, 8):
		print("    ", l)
	print("  %s: %d mallas de pelo revisadas en %d cortes, %d fallos" % [cuerpo, revisados, PeloQ.DE_CORTE.size(), mal.size()])
	_comprobar(revisados >= 20, "%s: se revisaron mallas de pelo (%d)" % [cuerpo, revisados])
	_comprobar(mal.is_empty(), "%s: los %d cortes de pelo y las cejas y ojos quedan sobre y dentro de la cabeza%s" % [cuerpo, PeloQ.DE_CORTE.size(), "" if mal.is_empty() else ": " + str(mal.slice(0, 3))])

## ---- 4. LOD
func _lod() -> void:
	var total := 0
	var con := 0
	var sin: Array[String] = []
	for ruta in ["res://assets/characters/quaternius/Superhero_Male_FullBody.gltf", "res://assets/characters/quaternius/Superhero_Female_FullBody.gltf"]:
		var imp := FileAccess.get_file_as_string(ruta + ".import")
		_comprobar(imp.contains("meshes/generate_lods=true"), "%s se importa con LOD" % ruta.get_file())
	for dir in ["res://assets/characters"]:
		for f in _archivos(dir):
			if f.ends_with(".glb.import") or f.ends_with(".gltf.import"):
				total += 1
				if FileAccess.get_file_as_string(f).contains("meshes/generate_lods=true"):
					con += 1
				elif sin.size() < 5:
					sin.append(f.get_file())
	print("  modelos de personaje con LOD: %d de %d %s" % [con, total, str(sin)])
	_comprobar(total > 50 and float(con) >= 0.95 * float(total), "al menos el 95 %% de los modelos de personaje con LOD (%d de %d)" % [con, total])

func _archivos(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_archivos(dir.path_join(d)))
	return out
