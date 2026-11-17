extends SceneTree
## MIXAMO → NUESTRO ESQUELETO (17-11-2026, punto 7 de `docs/04_auditorias/COMPARACION_REFERENCIAS_PARTIDO_2026-11-16.md`; Mixamo
## aprobado por el dueño, orden 57). La descarga de Mixamo pide cuenta de Adobe: la hace el DUEÑO en su equipo, con la lista de
## `docs/04_auditorias/DORSALES_ANIM_2026-11-17.md` (FBX, «Without Skin», 30 fps, «In Place» en las carreras). Los FBX NO van al
## repositorio: se dejan en una carpeta cualquiera y esta herramienta los convierte en UNA biblioteca `.res` para el cuerpo
## Quaternius (eso sí va al repo, como `anims_league/league.res`):
##   godot --headless --path . --script res://herramientas/mixamo_a_res.gd -- /ruta/a/los/fbx
##   (sin ruta: user://mixamo/). Salida: res://assets/characters/quaternius/anims_mixamo/mixamo.res
## Cómo: lee cada FBX en tiempo de ejecución (`FBXDocument`, sin importarlo al proyecto), pasa los nombres `mixamorig:*` a los
## nuestros (`MAPA`) y hornea a 30 fps con el retarget GLOBAL de siempre (`RetargetFutbolQ`: pose de cada hueso respecto a SU reposo
## aplicada sobre el reposo del nuestro; los dos esqueletos están en T). La pelvis conserva la altura y pierde el avance (lo pone el
## motor). Cada clip se llama como su archivo, en minúsculas y con «_» (p. ej. «Fast Run.fbx» → «fast_run»).
## Probado con un FBX del pack de fútbol de Quaternius (mismos nombres que los nuestros, `MIXAMO_PRUEBA=1`); con un FBX de Mixamo
## real queda por probar en cuanto el dueño los baje.
const SALIDA := "res://assets/characters/quaternius/anims_mixamo/mixamo.res"
const FPS := 30.0
## Mixamo → esqueleto tipo Unreal del cuerpo Quaternius.
const MAPA := {"Hips": "pelvis", "Spine": "spine_01", "Spine1": "spine_02", "Spine2": "spine_03", "Neck": "neck_01", "Head": "Head",
	"LeftShoulder": "clavicle_l", "LeftArm": "upperarm_l", "LeftForeArm": "lowerarm_l", "LeftHand": "hand_l",
	"RightShoulder": "clavicle_r", "RightArm": "upperarm_r", "RightForeArm": "lowerarm_r", "RightHand": "hand_r",
	"LeftUpLeg": "thigh_l", "LeftLeg": "calf_l", "LeftFoot": "foot_l", "LeftToeBase": "ball_l",
	"RightUpLeg": "thigh_r", "RightLeg": "calf_r", "RightFoot": "foot_r", "RightToeBase": "ball_r"}
## Dedos: «LeftHandIndex1» → «index_01_l».
const DEDOS := {"Thumb": "thumb", "Index": "index", "Middle": "middle", "Ring": "ring", "Pinky": "pinky"}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var carpeta := String(args[0]) if args.size() > 0 else "user://mixamo/"
	var archivos: Array[String] = []
	var d := DirAccess.open(carpeta)
	if d == null:
		printerr("MIXAMO: no existe la carpeta ", carpeta)
		quit(1)
		return
	for f in d.get_files():
		if f.to_lower().ends_with(".fbx"):
			archivos.append(carpeta.path_join(f))
	archivos.sort()
	var lib := AnimationLibrary.new()
	var hechos := 0
	for ruta in archivos:
		var a := convertir(ruta)
		if a == null:
			printerr("MIXAMO: sin clip en ", ruta)
			continue
		var clave := ruta.get_file().get_basename().to_lower().replace(" ", "_").replace("-", "_")
		lib.add_animation(clave, a)
		hechos += 1
		print("MIXAMO %s  %.2f s" % [clave, a.length])
	if hechos == 0:
		printerr("MIXAMO: ningún clip convertido")
		quit(1)
		return
	var salida := OS.get_environment("MIXAMO_SALIDA") if OS.get_environment("MIXAMO_SALIDA") != "" else SALIDA
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(salida.get_base_dir()))
	var err := ResourceSaver.save(lib, salida, ResourceSaver.FLAG_COMPRESS)
	print("MIXAMO: %d clips en %s (%s)" % [hechos, salida, error_string(err)])
	quit(0 if err == OK else 1)

## El nombre nuestro de un hueso de Mixamo («mixamorig:LeftArm», «mixamorig_LeftArm» o «LeftArm»); "" si no se usa.
static func nombre_nuestro(hueso: String) -> String:
	var n := hueso
	for pre in ["mixamorig:", "mixamorig_", "mixamorig1:", "mixamorig1_"]:
		if n.begins_with(pre):
			n = n.substr(pre.length())
	if MAPA.has(n):
		return MAPA[n]
	for lado: String in ["Left", "Right"]:
		if n.begins_with(lado + "Hand"):
			var resto := n.substr((lado + "Hand").length())
			for k: String in DEDOS:
				if resto.begins_with(k) and resto.length() == k.length() + 1 and resto.right(1) in ["1", "2", "3"]:
					return "%s_0%s_%s" % [DEDOS[k], resto.right(1), "l" if lado == "Left" else "r"]
	return ""

## Un FBX → un clip para nuestro esqueleto (o null).
func convertir(ruta: String) -> Animation:
	var doc := FBXDocument.new()
	var st := FBXState.new()
	if doc.append_from_file(ruta, st) != OK:
		return null
	var escena := doc.generate_scene(st) as Node3D
	if escena == null:
		return null
	var raiz := Node3D.new()
	root.add_child(raiz)
	raiz.add_child(escena)
	var ap: AnimationPlayer = escena.find_children("*", "AnimationPlayer", true, false).front() if not escena.find_children("*", "AnimationPlayer", true, false).is_empty() else null
	var esq_o: Skeleton3D = escena.find_children("*", "Skeleton3D", true, false).front() if not escena.find_children("*", "Skeleton3D", true, false).is_empty() else null
	var molde := FutbolistaQ.crear(FutbolistaQ.ALTURA_BASE)
	var r: Animation = null
	if ap != null and esq_o != null and not molde.is_empty() and not ap.get_animation_list().is_empty():
		raiz.add_child(molde["nodo"])
		var esq_d: Skeleton3D = molde["esqueleto"]
		if OS.get_environment("MIXAMO_PRUEBA") != "1":
			for i in esq_o.get_bone_count():
				var nuevo := nombre_nuestro(esq_o.get_bone_name(i))
				esq_o.set_bone_name(i, nuevo if nuevo != "" else "x_" + esq_o.get_bone_name(i))
		r = _hornear(ap, String(ap.get_animation_list()[0]), esq_o, esq_d)
	raiz.queue_free()
	return r

func _hornear(ap: AnimationPlayer, nombre: String, esq_o: Skeleton3D, esq_d: Skeleton3D) -> Animation:
	var clip := ap.get_animation(nombre)
	var ret := RetargetFutbolQ.crear(esq_o, esq_d)
	var a := Animation.new()
	a.length = clip.length
	a.loop_mode = Animation.LOOP_LINEAR if clip.loop_mode != Animation.LOOP_NONE else Animation.LOOP_NONE
	var pistas := {}
	for i in esq_d.get_bone_count():
		var pr := a.add_track(Animation.TYPE_ROTATION_3D)
		a.track_set_path(pr, NodePath(":%s" % esq_d.get_bone_name(i)))
		pistas[i] = pr
	var ip := esq_d.find_bone("pelvis")
	var pp := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(pp, NodePath(":pelvis"))
	ap.play(nombre)
	var t := 0.0
	while t <= clip.length + 0.001:
		ap.seek(minf(t, clip.length), true)
		esq_d.reset_bone_poses()
		ret.aplicar()
		for i in esq_d.get_bone_count():
			a.rotation_track_insert_key(pistas[i], t, esq_d.get_bone_pose_rotation(i))
		## La pelvis: solo su altura (en el espacio del esqueleto, Y arriba como el glTF); el avance lo pone el motor.
		var g := esq_d.get_bone_global_pose(ip).origin
		var g0 := esq_d.get_bone_global_rest(ip).origin
		var padre := esq_d.get_bone_parent(ip)
		var pg := esq_d.get_bone_global_pose(padre) if padre >= 0 else Transform3D.IDENTITY
		a.position_track_insert_key(pp, t, pg.affine_inverse() * Vector3(g0.x, g.y, g0.z))
		t += 1.0 / FPS
	return a
