extends SceneTree
## 100STYLE → NUESTRO ESQUELETO (sesión 10, 11-11-2026). Ciclos de locomoción de «100STYLE» (Ian Mason, Sebastian Starke, Taku Komura;
## https://zenodo.org/records/8127870; CC BY 4.0: hay que citarlo en los créditos, ver `LICENCIAS.md`).
## Entrada: el JSON de `herramientas/estilo100_ciclos.py` (ciclos a 30 fps, rotaciones LOCALES). Salida: AnimationLibrary .res con cada ciclo
## y su espejo («…_espejo»), y el catálogo `datos/animaciones_catalogo_100style.json` (etiquetas para que el motor los elija por búsqueda).
##   ESTILO100_JSON=/ruta/ciclos.json godot --headless --path . --script res://herramientas/estilo100_a_res.gd
## Retarget por DIRECCIÓN (como `league_anim_a_res.gd`): el BVH usa los mismos ejes que nuestro esqueleto (Y arriba, mira a +Z, izquierda +X)
## y el reposo en T, así que el giro global de cada articulación de origen G se aplica a nuestro hueso con la corrección Q que lleva la
## dirección de reposo de nuestro hueso a la del origen:  global_nuestro = G · Q · reposo_global_nuestro.
var SALIDA := "res://assets/characters/quaternius/anims_100style/100style.res"   ## con ESTILO100_NOMBRE=otro → otro.res y su catálogo
var CATALOGO := "res://datos/animaciones_catalogo_100style.json"
const FPS := 30.0
const COSTE_MAX := 1.0
const ALTURA_CADERA_ORIGEN := 97.9   ## cm: altura de la cadera del origen de pie (patas rectas)
const PRE := "Armature/Skeleton3D:"
## articulación de origen → [hueso nuestro, hijo de origen (o dirección fija), hijo nuestro (o "" = sin corrección)]
const MAPA := {
	"Hips": ["pelvis", "Chest", "spine_01"], "Chest": ["spine_01", "Chest2", "spine_02"], "Chest2": ["spine_02", "Chest3", "spine_03"],
	"Chest4": ["spine_03", "Neck", "neck_01"], "Neck": ["neck_01", "Head", "Head"], "Head": ["Head", "", ""],
	"RightCollar": ["clavicle_r", "RightShoulder", "upperarm_r"], "RightShoulder": ["upperarm_r", "RightElbow", "lowerarm_r"],
	"RightElbow": ["lowerarm_r", "RightWrist", "hand_r"], "RightWrist": ["hand_r", "", ""],
	"LeftCollar": ["clavicle_l", "LeftShoulder", "upperarm_l"], "LeftShoulder": ["upperarm_l", "LeftElbow", "lowerarm_l"],
	"LeftElbow": ["lowerarm_l", "LeftWrist", "hand_l"], "LeftWrist": ["hand_l", "", ""],
	"RightHip": ["thigh_r", "RightKnee", "calf_r"], "RightKnee": ["calf_r", "RightAnkle", "foot_r"],
	"RightAnkle": ["foot_r", "RightToe", "ball_r"], "RightToe": ["ball_r", "", ""],
	"LeftHip": ["thigh_l", "LeftKnee", "calf_l"], "LeftKnee": ["calf_l", "LeftAnkle", "foot_l"],
	"LeftAnkle": ["foot_l", "LeftToe", "ball_l"], "LeftToe": ["ball_l", "", ""]}
var esq: Skeleton3D
var reposo_g := {}
var juntas: Array = []
var idx := {}
var rest_src := {}     ## articulación de origen → Transform3D global de reposo (rotación identidad, posición por offsets)
var corr := {}         ## articulación de origen → Quaternion Q

func _init() -> void:
	var ruta := OS.get_environment("ESTILO100_JSON")
	var nom := OS.get_environment("ESTILO100_NOMBRE")
	if nom != "":
		SALIDA = "res://assets/characters/quaternius/anims_100style/%s.res" % nom
		CATALOGO = "res://datos/animaciones_catalogo_%s.json" % nom
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not doc is Dictionary:
		print("ERROR: sin ESTILO100_JSON=", ruta)
		quit(1)
		return
	var d := FutbolistaQ.crear(1.8, "male")
	esq = d["esqueleto"]
	for i in esq.get_bone_count():
		reposo_g[esq.get_bone_name(i)] = esq.get_bone_global_rest(i)
	juntas = doc["juntas"]
	for i in juntas.size():
		idx[String(juntas[i]["nombre"])] = i
	_reposo_origen()
	for art: String in MAPA:
		var m: Array = MAPA[art]
		var q := Quaternion.IDENTITY
		if String(m[1]) != "" and String(m[2]) != "":
			var ds: Vector3 = ((rest_src[m[1]] as Vector3) - (rest_src[art] as Vector3)).normalized()
			var dn: Vector3 = ((reposo_g[m[2]] as Transform3D).origin - (reposo_g[m[0]] as Transform3D).origin).normalized()
			q = Quaternion(dn, ds)
		corr[art] = q
	var lib := AnimationLibrary.new()
	var catalogo := []
	var n := 0
	for clip: Dictionary in doc["clips"]:
		if float(clip["coste_cierre"]) > COSTE_MAX:
			print("descartado (cierre malo): ", clip["nombre"], " ", clip["coste_cierre"])
			continue
		for espejo in [false, true]:
			var nombre := "e100_" + String(clip["nombre"]) + ("_espejo" if espejo else "")
			lib.add_animation(nombre, _convertir(clip, espejo))
			var ficha := _ficha(clip, nombre, espejo)
			catalogo.append(ficha)
		n += 1
	DirAccess.make_dir_recursive_absolute(SALIDA.get_base_dir())
	print("ciclos: ", n, " (+ espejos)  guardar: ", ResourceSaver.save(lib, SALIDA, ResourceSaver.FLAG_COMPRESS))
	var f := FileAccess.open(CATALOGO, FileAccess.WRITE)
	f.store_string(JSON.stringify(catalogo, "\t"))
	f.close()
	(d["nodo"] as Node).free()
	quit(0)

## Posición global de reposo de cada articulación de origen (cm → m) con rotaciones nulas.
func _reposo_origen() -> void:
	for i in juntas.size():
		var o: Array = juntas[i]["offset"]
		var off := Vector3(float(o[0]), float(o[1]), float(o[2])) * 0.01
		var p := int(juntas[i]["padre"])
		rest_src[String(juntas[i]["nombre"])] = off + ((rest_src[String(juntas[p]["nombre"])] as Vector3) if p >= 0 else Vector3.ZERO)

## Ficha del catálogo: etiquetas para buscar el clip (el espejo cambia de signo el ángulo y de lado los pies).
func _ficha(c: Dictionary, nombre: String, espejo: bool) -> Dictionary:
	var s := -1.0 if espejo else 1.0
	var d_apoyos: Array = c["apoyos_I"] if espejo else c["apoyos_D"]
	var i_apoyos: Array = c["apoyos_D"] if espejo else c["apoyos_I"]
	var aire := String(c["pie_en_aire_inicio"])
	if espejo:
		aire = "I" if aire == "D" else "D"
	return {"nombre": nombre, "fuente": "100STYLE", "licencia": "CC BY 4.0", "estilo": c["estilo"], "tipo": c["tipo"],
		"cuadros": int(c["cuadros"]), "fps": int(c["fps"]), "duracion_s": float(c["cuadros"]) / FPS, "bucle": true,
		"velocidad_ms": c["velocidad_ms"], "angulo_mov_grados": float(c["angulo_mov"]) * s,
		"apoyos_pie_derecho": d_apoyos, "apoyos_pie_izquierdo": i_apoyos, "pie_en_aire_al_inicio": aire,
		"cuadro_toque_balon": null, "mueve_con_el_balon": false}

func _convertir(clip: Dictionary, espejo: bool) -> Animation:
	var n := int(clip["cuadros"])
	var J := juntas.size()
	var q: Array = clip["q"]
	var alto: Array = clip["alto_cadera_cm"]
	var largo := float(n) / FPS
	var a := Animation.new()
	a.length = largo
	a.loop_mode = Animation.LOOP_LINEAR
	var pistas := {}
	for art: String in MAPA:
		var i := a.add_track(Animation.TYPE_ROTATION_3D)
		a.track_set_path(i, NodePath(PRE + String(MAPA[art][0])))
		pistas[MAPA[art][0]] = i
	var pp := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(pp, NodePath(PRE + "pelvis"))
	for k in n + 1:
		var f := k % n
		var t := float(k) / FPS
		var g := {}
		for i in J:
			var nom := String(juntas[i]["nombre"])
			var fuente := _espejo_nombre(nom) if espejo else nom
			var o: int = (f * J + int(idx[fuente])) * 4
			var ql := Quaternion(float(q[o]), float(q[o + 1]), float(q[o + 2]), float(q[o + 3]))
			if espejo:
				ql = Quaternion(ql.x, -ql.y, -ql.z, ql.w)
			var p := int(juntas[i]["padre"])
			g[nom] = ((g[juntas[p]["nombre"]] as Quaternion) * ql) if p >= 0 else ql
		var objetivo := {}
		for art: String in MAPA:
			objetivo[MAPA[art][0]] = Basis((g[art] as Quaternion) * (corr[art] as Quaternion)) * (reposo_g[MAPA[art][0]] as Transform3D).basis
		var actual := {}
		for i in esq.get_bone_count():
			var nombre := esq.get_bone_name(i)
			var pi := esq.get_bone_parent(i)
			var bp: Basis = actual[esq.get_bone_name(pi)] if pi >= 0 else Basis.IDENTITY
			var bg: Basis = objetivo[nombre] if objetivo.has(nombre) else bp * esq.get_bone_rest(i).basis
			actual[nombre] = bg
			if pistas.has(nombre):
				a.rotation_track_insert_key(pistas[nombre], t, (bp.inverse() * bg).get_rotation_quaternion())
		var delta_y := (float(alto[f]) - ALTURA_CADERA_ORIGEN) * 0.01
		var ip := esq.find_bone("pelvis")
		var reposo_p := esq.get_bone_rest(ip).origin
		var g_raiz: Basis = (reposo_g[esq.get_bone_name(esq.get_bone_parent(ip))] as Transform3D).basis
		var escala := (reposo_g["pelvis"] as Transform3D).origin.y / (ALTURA_CADERA_ORIGEN * 0.01)
		a.position_track_insert_key(pp, t, reposo_p + g_raiz.inverse() * Vector3(0, delta_y * escala, 0))
	return a

func _espejo_nombre(n: String) -> String:
	if n.begins_with("Left"):
		return "Right" + n.substr(4)
	if n.begins_with("Right"):
		return "Left" + n.substr(5)
	return n
