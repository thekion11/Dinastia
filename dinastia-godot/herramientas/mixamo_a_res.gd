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
## real (18-11, «Soccer Header»): arreglada la elección de la animación (ver `_la_animacion`).
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
		if _giro_maximo(a) < 0.01:
			printerr("MIXAMO: sin movimiento (¿es el modelo del personaje?) en ", ruta)
			continue
		var clave := ruta.get_file().get_basename().to_lower().replace(" ", "_").replace("-", "_").replace("(", "").replace(")", "")
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

## Mayor giro (rad) de cualquier hueso respecto al primer cuadro: 0 = el clip está quieto (p. ej. el FBX del propio muñeco, sin animación).
static func _giro_maximo(a: Animation) -> float:
	var mx := 0.0
	for i in a.get_track_count():
		if a.track_get_type(i) != Animation.TYPE_ROTATION_3D:
			continue
		var q0: Quaternion = a.rotation_track_interpolate(i, 0.0)
		var t := 0.0
		while t < a.length:
			mx = maxf(mx, q0.angle_to(a.rotation_track_interpolate(i, t)))
			t += 0.1
	return mx

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
			## (18-11) Las PISTAS de la animación siguen apuntando al hueso con su nombre de Mixamo: sin cambiarlas, no movían ningún hueso (clip quieto).
			var anim := ap.get_animation(_la_animacion(ap))
			for i in anim.get_track_count():
				var ruta_p := String(anim.track_get_path(i))
				var k := ruta_p.rfind(":")
				if k >= 0:
					var hueso := ruta_p.substr(k + 1)
					var nombre_n := nombre_nuestro(hueso)
					anim.track_set_path(i, NodePath(ruta_p.substr(0, k + 1) + (nombre_n if nombre_n != "" else "x_" + hueso)))
		r = _hornear(ap, _la_animacion(ap), esq_o, esq_d)
	raiz.queue_free()
	return r

## (18-11) Un FBX de Mixamo trae DOS animaciones: «Take 001» (vacía, 0 pistas) y «mixamo_com» (la de verdad). Se toma la que más pistas tiene.
static func _la_animacion(ap: AnimationPlayer) -> String:
	var mejor := ""
	var pistas := -1
	for n in ap.get_animation_list():
		var c := ap.get_animation(n).get_track_count()
		if c > pistas:
			pistas = c
			mejor = String(n)
	return mejor

## (18-11) `RetargetFutbolQ.aplicar()` lee `get_bone_global_pose` del origen, y con un FBX de Mixamo esa pose global se queda en el reposo aunque
## la pose LOCAL cambie (clip quieto). Aquí se calcula la global a mano (padre × local) y se hace la misma cuenta que `aplicar()`.
static func _global_fk(esq: Skeleton3D, i: int, cache: Dictionary) -> Transform3D:
	if cache.has(i):
		return cache[i]
	var padre := esq.get_bone_parent(i)
	var g := esq.get_bone_pose(i) if padre < 0 else _global_fk(esq, padre, cache) * esq.get_bone_pose(i)
	cache[i] = g
	return g

static func _aplicar_fk(ret: RetargetFutbolQ, esq_o: Skeleton3D) -> void:
	var cache := {}
	var dest := ret.destino
	var glob_d := {}   ## globales del DESTINO que vamos fijando (el getter del esqueleto da valores obsoletos también aquí)
	var raiz_animada := _global_fk(esq_o, ret._raiz_origen, cache) if ret._raiz_origen >= 0 else Transform3D.IDENTITY
	var inv_raiz_animada := raiz_animada.affine_inverse()
	var inv_raiz_reposo := ret._reposo_raiz_origen.affine_inverse()
	for par in ret._pares:
		var pose_modelo: Transform3D = inv_raiz_animada * _global_fk(esq_o, int(par["origen"]), cache)
		var reposo_modelo: Transform3D = inv_raiz_reposo * (par["reposo_origen"] as Transform3D)
		var desvio: Transform3D = pose_modelo * reposo_modelo.affine_inverse()
		var reposo_destino_modelo: Transform3D = ret._reposo_raiz_destino.affine_inverse() * (par["reposo_destino"] as Transform3D)
		var nueva: Transform3D = ret._reposo_raiz_destino * (desvio * reposo_destino_modelo)
		var i := int(par["destino"])
		var padre := dest.get_bone_parent(i)
		var g_padre := _global_fk(dest, padre, glob_d) if padre >= 0 else Transform3D.IDENTITY
		var local := g_padre.affine_inverse() * nueva
		dest.set_bone_pose_rotation(i, local.basis.orthonormalized().get_rotation_quaternion())
		glob_d[i] = nueva

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
		_aplicar_fk(ret, esq_o)
		for i in esq_d.get_bone_count():
			a.rotation_track_insert_key(pistas[i], t, esq_d.get_bone_pose_rotation(i))
		## La pelvis: solo su altura (en el espacio del esqueleto, Y arriba como el glTF); el avance lo pone el motor.
		var cache_d := {}
		var g0 := esq_d.get_bone_global_rest(ip).origin
		## Altura de la cadera: la del ORIGINAL (FK propia) escalada a nuestra estatura. La que sale del retarget mezcla el giro de la cadera con la altura.
		var cache_o := {}
		var io := esq_o.find_bone("pelvis")
		var go := _global_fk(esq_o, io, cache_o).origin
		var go0 := esq_o.get_bone_global_rest(io).origin
		var g := Vector3(g0.x, g0.y + (go.y - go0.y) * (g0.y / go0.y), g0.z)
		var padre := esq_d.get_bone_parent(ip)
		var pg := _global_fk(esq_d, padre, cache_d) if padre >= 0 else Transform3D.IDENTITY
		a.position_track_insert_key(pp, t, pg.affine_inverse() * Vector3(g0.x, g.y, g0.z))
		t += 1.0 / FPS
	return a
