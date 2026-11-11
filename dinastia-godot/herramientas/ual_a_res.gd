extends SceneTree
## UAL 1 + UAL 2 (Quaternius, CC0) → biblioteca de clips útiles para el partido + catálogo (sesión 10, 11-11-2026).
## Clips elegidos: locomoción (andar, trote, SPRINT, agachado), saltos, caídas/golpes, celebración/reacciones, deslizamiento y lanzamiento.
## Mide la velocidad REAL de los ciclos de locomoción (pie en apoyo sobre el esqueleto a 1,8 m) para etiquetarlos.
##   UAL1_GLB=…/UAL1_Standard.glb UAL2_GLB=…/UAL2_Standard.glb godot --headless --path . --script res://herramientas/ual_a_res.gd
const SALIDA := "res://terceros/ual/ual_extra.res"
const CATALOGO := "res://terceros/ual/animaciones_catalogo_ual.json"
const UMBRAL_APOYO := 0.03
## [archivo 1|2, clip, tipo, bucle]
const ELEGIDOS := [
	[1, "Walk_Loop", "marcha", true], [1, "Walk_Formal_Loop", "marcha", true], [1, "Jog_Fwd_Loop", "carrera", true],
	[1, "Sprint_Loop", "sprint", true], [1, "Crouch_Fwd_Loop", "marcha_agachado", true], [2, "Walk_Carry_Loop", "marcha", true],
	[1, "Idle_Loop", "reposo", true], [1, "Idle_Talking_Loop", "reposo", true], [2, "Idle_FoldArms_Loop", "reposo", true],
	[2, "Idle_No_Loop", "reaccion", true], [2, "Yes", "reaccion", false], [1, "Crouch_Idle_Loop", "reposo", true],
	[1, "Jump_Start", "salto_despegue", false], [1, "Jump_Loop", "salto_aire", true], [1, "Jump_Land", "salto_aterrizaje", false],
	[2, "NinjaJump_Start", "salto_despegue", false], [2, "NinjaJump_Idle_Loop", "salto_aire", true], [2, "NinjaJump_Land", "salto_aterrizaje", false],
	[1, "Roll", "caida_voltereta", false], [1, "Hit_Chest", "golpe_recibido", false], [1, "Hit_Head", "golpe_recibido", false],
	[2, "Hit_Knockback", "caida_empujon", false], [1, "Death01", "caida_suelo", false], [2, "LayToIdle", "levantarse", false],
	[2, "Slide_Start", "entrada_deslizante", false], [2, "Slide_Loop", "entrada_deslizante", true], [2, "Slide_Exit", "entrada_deslizante", false],
	[1, "Dance_Loop", "celebracion", true], [1, "Interact", "reaccion", false], [2, "OverhandThrow", "saque_de_banda", false],
	[1, "Punch_Jab", "disputa_empujon", false], [1, "Push_Loop", "disputa_empujon", true], [2, "ClimbUp_1m", "trepar", false]]

var esq: Skeleton3D
var ap: AnimationPlayer

func _pos(h: String) -> Vector3:
	return esq.global_transform * esq.get_bone_global_pose(esq.find_bone(h)).origin

func _initialize() -> void:
	var anims: Array = []   # [clip, tipo, bucle, Animation]
	var escenas := {}
	for i in [1, 2]:
		var ruta := OS.get_environment("UAL%d_GLB" % i)
		var doc := GLTFDocument.new()
		var estado := GLTFState.new()
		if ruta == "" or doc.append_from_file(ruta, estado) != OK:
			print("ERROR: UAL%d_GLB=%s" % [i, ruta])
			quit(1)
			return
		escenas[i] = doc.generate_scene(estado)
	var lib := AnimationLibrary.new()
	var tabla := {}
	for e: Array in ELEGIDOS:
		var p := (escenas[e[0]] as Node).find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		var clave: String = e[1]
		if not p.has_animation(clave):
			print("FALTA ", clave)
			continue
		var a: Animation = p.get_animation(clave).duplicate(true)
		a.loop_mode = Animation.LOOP_LINEAR if bool(e[3]) else Animation.LOOP_NONE
		var nombre := "ual%d_%s" % [e[0], clave]
		lib.add_animation(nombre, a)
		tabla[nombre] = e
	for i in [1, 2]:
		(escenas[i] as Node).free()
	DirAccess.make_dir_recursive_absolute(SALIDA.get_base_dir())
	print("guardar: ", ResourceSaver.save(lib, SALIDA, ResourceSaver.FLAG_COMPRESS))
	var d := FutbolistaQ.crear(1.8, "male")
	root.add_child(d["nodo"])
	await process_frame
	FutbolistaQ.terminar(d)
	await process_frame
	esq = d["esqueleto"]
	ap = d["anim"]
	ap.add_animation_library("u", lib)
	var catalogo := []
	for nombre: String in tabla:
		var e: Array = tabla[nombre]
		var a := ap.get_animation("u/" + nombre)
		var fps := 30.0
		var n := maxi(2, int(a.length * fps))
		var ficha := {"nombre": nombre, "clip": e[1], "fuente": "Quaternius Universal Animation Library %d" % e[0], "licencia": "CC0 1.0", "tipo": e[2],
			"duracion_s": snappedf(a.length, 0.001), "bucle": bool(e[3]), "fps": 30, "cuadro_toque_balon": null}
		if ["marcha", "carrera", "sprint", "marcha_agachado"].has(e[2]):
			var pts: Array = []
			var miny := [9.0, 9.0, 9.0, 9.0]
			for k in n + 1:
				ap.play("u/" + nombre)
				ap.seek(minf(float(k) / fps, a.length), true)
				ap.advance(0.0)
				var q := [_pos("ball_l"), _pos("ball_r"), _pos("foot_l"), _pos("foot_r")]
				pts.append(q)
				for j in 4:
					miny[j] = minf(miny[j], (q[j] as Vector3).y)
			var rel := 0.0
			var m := 0
			for j in 4:
				for k in n:
					var p0: Vector3 = pts[k][j]
					var p1: Vector3 = pts[k + 1][j]
					if p0.y - miny[j] < UMBRAL_APOYO and p1.y - miny[j] < UMBRAL_APOYO:
						rel += -(p1.z - p0.z) * fps
						m += 1
			ficha["velocidad_ms"] = snappedf(rel / float(m), 0.01) if m > 0 else 0.0
			ap.stop()
		catalogo.append(ficha)
	catalogo.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return String(x["nombre"]) < String(y["nombre"]))
	var f := FileAccess.open(CATALOGO, FileAccess.WRITE)
	f.store_string(JSON.stringify(catalogo, "\t"))
	f.close()
	for c in catalogo:
		print(c["nombre"], " ", c["tipo"], " ", c["duracion_s"], " s ", c.get("velocidad_ms", ""))
	quit(0)
