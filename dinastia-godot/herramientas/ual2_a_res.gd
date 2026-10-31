extends SceneTree
## UAL2 → .res (31-10-2026): la «Universal Animation Library 2» de Quaternius (CC0, mismo esqueleto de 65 huesos que la UAL1) trae
## 43 clips nuevos. El .glb pesa 8 MB y los .glb van por LFS (que desde las sesiones en la nube no se puede subir): esta
## herramienta lo lee desde FUERA del proyecto y guarda solo los clips ELEGIDOS en una AnimationLibrary .res (archivo normal).
##   UAL2_GLB=/ruta/UAL2_Standard.glb godot --headless --path . --script res://herramientas/ual2_a_res.gd
## Origen: «Universal Animation Library 2 [Standard]», quaternius.itch.io (copia en github.com/NafisRayan/Animate-Rigged-Humanoid-No-Blender).
const SALIDA := "res://assets/characters/quaternius/anims_ual2/ual2_elegidos.res"
const ELEGIDOS := ["Idle_FoldArms_Loop", "Idle_TalkingPhone_Loop", "Idle_No_Loop", "Yes", "Walk_Carry_Loop", "Consume",
	"Idle_Rail_Loop", "Idle_Rail_Call", "Slide_Start", "Slide_Loop", "Slide_Exit", "OverhandThrow", "Hit_Knockback",
	"LayToIdle", "ClimbUp_1m", "Chest_Open", "Farm_Watering"]

func _init() -> void:
	var ruta := OS.get_environment("UAL2_GLB")
	var doc := GLTFDocument.new()
	var estado := GLTFState.new()
	if ruta == "" or doc.append_from_file(ruta, estado) != OK:
		print("ERROR: no se pudo leer UAL2_GLB=", ruta)
		quit(1)
		return
	var escena := doc.generate_scene(estado)
	var aps := escena.find_children("*", "AnimationPlayer", true, false)
	if aps.is_empty():
		print("ERROR: sin AnimationPlayer")
		quit(1)
		return
	var ap := aps[0] as AnimationPlayer
	var salida := AnimationLibrary.new()
	for nombre: String in ELEGIDOS:
		var clave := nombre
		if not ap.has_animation(clave) and ap.has_animation(nombre.trim_suffix("_Loop")):
			clave = nombre.trim_suffix("_Loop")
		if not ap.has_animation(clave):
			print("FALTA ", nombre)
			continue
		var a: Animation = ap.get_animation(clave).duplicate(true)
		a.loop_mode = Animation.LOOP_LINEAR if nombre.ends_with("_Loop") else Animation.LOOP_NONE
		salida.add_animation(nombre, a)
		print("ok ", nombre, "  ", snappedf(a.length, 0.01), " s  ", a.get_track_count(), " pistas  ej. ", a.track_get_path(0) if a.get_track_count() > 0 else "")
	print("guardar: ", ResourceSaver.save(salida, SALIDA, ResourceSaver.FLAG_COMPRESS))
	escena.free()
	quit(0)
