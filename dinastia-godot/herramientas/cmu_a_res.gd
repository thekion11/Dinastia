extends SceneTree
## CMU → NUESTRO ESQUELETO (sesión 10, 11-11-2026). Clips de `herramientas/cmu_clips.py` (CMU Graphics Lab Motion Capture Database, uso libre
## comercial citando la fuente) → AnimationLibrary .res y catálogo. Retarget por DIRECCIÓN como `estilo100_a_res.gd`, pero el reposo del BVH
## de CMU no es una T: la T es el cuadro 0 (`q0`). Con G0 = giro global de cada articulación en esa T y G el del cuadro, el hueso nuestro queda en
##   global_nuestro = (G · G0⁻¹) · Q · reposo_global_nuestro      (Q lleva la dirección de nuestro hueso en T a la del origen en T)
##   CMU_JSON=/ruta/cmu.json godot --headless --path . --script res://herramientas/cmu_a_res.gd
const SALIDA := "res://terceros/cmu/biblioteca/cmu.res"
const CATALOGO := "res://terceros/cmu/catalogos/animaciones_catalogo_cmu.json"
const PRE := "Armature/Skeleton3D:"
const CM := 5.644   ## cm por unidad del BVH
const MAPA := {
	"Hips": ["pelvis", "Spine", "spine_01"], "LowerBack": ["spine_01", "Spine", "spine_02"], "Spine": ["spine_02", "Spine1", "spine_03"],
	"Spine1": ["spine_03", "Neck1", "neck_01"], "Neck": ["neck_01", "Head", "Head"], "Head": ["Head", "", ""],
	"RightShoulder": ["clavicle_r", "RightArm", "upperarm_r"], "RightArm": ["upperarm_r", "RightForeArm", "lowerarm_r"],
	"RightForeArm": ["lowerarm_r", "RightHand", "hand_r"], "RightHand": ["hand_r", "", ""],
	"LeftShoulder": ["clavicle_l", "LeftArm", "upperarm_l"], "LeftArm": ["upperarm_l", "LeftForeArm", "lowerarm_l"],
	"LeftForeArm": ["lowerarm_l", "LeftHand", "hand_l"], "LeftHand": ["hand_l", "", ""],
	"RightUpLeg": ["thigh_r", "RightLeg", "calf_r"], "RightLeg": ["calf_r", "RightFoot", "foot_r"],
	"RightFoot": ["foot_r", "RightToeBase", "ball_r"], "RightToeBase": ["ball_r", "", ""],
	"LeftUpLeg": ["thigh_l", "LeftLeg", "calf_l"], "LeftLeg": ["calf_l", "LeftFoot", "foot_l"],
	"LeftFoot": ["foot_l", "LeftToeBase", "ball_l"], "LeftToeBase": ["ball_l", "", ""]}
var esq: Skeleton3D
var reposo_g := {}
var nombres: Array = []
var padres: Array = []
var idx := {}

func _init() -> void:
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("CMU_JSON")))
	if not doc is Dictionary:
		print("ERROR: sin CMU_JSON")
		quit(1)
		return
	var d := FutbolistaQ.crear(1.8, "male")
	esq = d["esqueleto"]
	for i in esq.get_bone_count():
		reposo_g[esq.get_bone_name(i)] = esq.get_bone_global_rest(i)
	for j: Dictionary in doc["juntas"]:
		nombres.append(String(j["nombre"]))
		padres.append(int(j["padre"]))
	for i in nombres.size():
		idx[nombres[i]] = i
	var lib := AnimationLibrary.new()
	var catalogo := []
	var n := 0
	for clip: Dictionary in doc["clips"]:
		if float(clip["duracion"]) < 0.4 and bool(clip["bucle"]):
			print("descartado (ciclo demasiado corto): ", clip["nombre"])
			continue
		for espejo in ([false, true] if bool(clip["espejo"]) else [false]):
			var nombre := "cmu_" + String(clip["nombre"]).replace(".", "_") + ("_espejo" if espejo else "")
			lib.add_animation(nombre, _convertir(clip, espejo))
			catalogo.append(_ficha(clip, nombre, espejo))
		n += 1
	DirAccess.make_dir_recursive_absolute(SALIDA.get_base_dir())
	DirAccess.make_dir_recursive_absolute(CATALOGO.get_base_dir())
	print("clips: ", n, " (+ espejos)  guardar: ", ResourceSaver.save(lib, SALIDA, ResourceSaver.FLAG_COMPRESS))
	var f := FileAccess.open(CATALOGO, FileAccess.WRITE)
	f.store_string(JSON.stringify(catalogo, "\t"))
	f.close()
	(d["nodo"] as Node).free()
	quit(0)

func _ficha(c: Dictionary, nombre: String, espejo: bool) -> Dictionary:
	var f := c.duplicate()
	for k in ["q", "q0", "offsets", "alto_cadera_cm"]:
		f.erase(k)
	f["nombre"] = nombre
	f["licencia"] = "CMU Graphics Lab Motion Capture Database: «free for use in research and commercial projects worldwide»; citar mocap.cs.cmu.edu"
	f["duracion_s"] = f["duracion"]
	f.erase("duracion")
	if espejo:
		for k in ["angulo_mov", "giro_cuerpo_grados", "desplazamiento_izquierda_m"]:
			if f.has(k) and f[k] != null:
				f[k] = -float(f[k])
		if f.get("cambio_direccion_rad") != null:
			f["cambio_direccion_rad"] = -float(f["cambio_direccion_rad"])
		if f.has("apoyos_D"):
			var t: Variant = f["apoyos_D"]
			f["apoyos_D"] = f["apoyos_I"]
			f["apoyos_I"] = t
			f["pie_en_aire_inicio"] = "I" if f["pie_en_aire_inicio"] == "D" else "D"
		if f.has("golpeos"):
			for g: Dictionary in f["golpeos"]:
				g["pie"] = "I" if g["pie"] == "D" else "D"
	f["cuadro_toque_balon"] = null
	if f.has("golpeos") and not (f["golpeos"] as Array).is_empty() and String(f["tipo"]) == "patada_balon":
		var mejor: Dictionary = f["golpeos"][0]
		for g: Dictionary in f["golpeos"]:
			if float(g["velocidad_pie_ms"]) > float(mejor["velocidad_pie_ms"]):
				mejor = g
		f["cuadro_toque_balon"] = mejor["cuadro"]
		f["pie_que_golpea"] = mejor["pie"]
	return f

func _espejo_nombre(n: String) -> String:
	if n.begins_with("Left"):
		return "Right" + n.substr(4)
	if n.begins_with("Right"):
		return "Left" + n.substr(5)
	if n == "LHipJoint":
		return "RHipJoint"
	if n == "RHipJoint":
		return "LHipJoint"
	return n

func _q(arr: Array, k: int, espejo: bool, nom: String) -> Quaternion:
	var fuente := _espejo_nombre(nom) if espejo else nom
	var o := (k * nombres.size() + int(idx[fuente])) * 4
	var q := Quaternion(float(arr[o]), float(arr[o + 1]), float(arr[o + 2]), float(arr[o + 3]))
	return Quaternion(q.x, -q.y, -q.z, q.w) if espejo else q

func _convertir(clip: Dictionary, espejo: bool) -> Animation:
	var n := int(clip["cuadros"])
	var J := nombres.size()
	var q: Array = clip["q"]
	var q0: Array = clip["q0"]
	var offs: Array = clip["offsets"]
	var alto: Array = clip["alto_cadera_cm"]
	var fps := float(clip["fps"])
	var a := Animation.new()
	var bucle := bool(clip["bucle"])
	a.length = float(n) / fps
	a.loop_mode = Animation.LOOP_LINEAR if bucle else Animation.LOOP_NONE
	var pistas := {}
	for art: String in MAPA:
		var i := a.add_track(Animation.TYPE_ROTATION_3D)
		a.track_set_path(i, NodePath(PRE + String(MAPA[art][0])))
		pistas[MAPA[art][0]] = i
	var pp := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(pp, NodePath(PRE + "pelvis"))
	## Pose en T del origen: giros globales y posiciones (con los desplazamientos de la articulación gemela si es el espejo).
	var g0 := {}
	var p0 := {}
	for i in J:
		var nom: String = nombres[i]
		var ql := _q(q0, 0, espejo, nom)
		var fuente := _espejo_nombre(nom) if espejo else nom
		var o: Array = offs[int(idx[fuente])]
		var off := Vector3(float(o[0]), float(o[1]), float(o[2]))
		if espejo:
			off.x = -off.x
		var p: int = padres[i]
		g0[nom] = ((g0[nombres[p]] as Quaternion) * ql) if p >= 0 else ql
		p0[nom] = (p0[nombres[p]] as Vector3 + (g0[nombres[p]] as Quaternion) * off) if p >= 0 else Vector3.ZERO
	var corr := {}
	for art: String in MAPA:
		var m: Array = MAPA[art]
		var qc := Quaternion.IDENTITY
		if String(m[1]) != "" and String(m[2]) != "":
			var ds: Vector3 = ((p0[m[1]] as Vector3) - (p0[art] as Vector3)).normalized()
			var dn: Vector3 = ((reposo_g[m[2]] as Transform3D).origin - (reposo_g[m[0]] as Transform3D).origin).normalized()
			qc = Quaternion(dn, ds)
		corr[art] = qc
	var alto_t := float(clip["alto_t_cm"])
	var ip := esq.find_bone("pelvis")
	var reposo_p := esq.get_bone_rest(ip).origin
	var g_raiz: Basis = (reposo_g[esq.get_bone_name(esq.get_bone_parent(ip))] as Transform3D).basis
	var escala := (reposo_g["pelvis"] as Transform3D).origin.y / (alto_t * 0.01)
	for k in (n + 1 if bucle else n):
		var f := k % n
		var t := float(k) / fps
		var g := {}
		for i in J:
			var nom: String = nombres[i]
			var ql := _q(q, f, espejo, nom)
			var p: int = padres[i]
			g[nom] = ((g[nombres[p]] as Quaternion) * ql) if p >= 0 else ql
		var objetivo := {}
		for art: String in MAPA:
			var delta: Quaternion = (g[art] as Quaternion) * (g0[art] as Quaternion).inverse()
			objetivo[MAPA[art][0]] = Basis(delta * (corr[art] as Quaternion)) * (reposo_g[MAPA[art][0]] as Transform3D).basis
		var actual := {}
		for i in esq.get_bone_count():
			var nombre := esq.get_bone_name(i)
			var pi := esq.get_bone_parent(i)
			var bp: Basis = actual[esq.get_bone_name(pi)] if pi >= 0 else Basis.IDENTITY
			var bg: Basis = objetivo[nombre] if objetivo.has(nombre) else bp * esq.get_bone_rest(i).basis
			actual[nombre] = bg
			if pistas.has(nombre):
				a.rotation_track_insert_key(pistas[nombre], t, (bp.inverse() * bg).get_rotation_quaternion())
		var delta_y := (float(alto[f]) - alto_t) * 0.01
		a.position_track_insert_key(pp, t, reposo_p + g_raiz.inverse() * Vector3(0, delta_y * escala, 0))
	return a
