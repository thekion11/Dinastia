extends Node3D
## DIAGNÓSTICO (pani, 25-10-2026): vuelca la librería entera del futbolista
## (nombre, duración, bucle) y mide la VELOCIDAD NATURAL de cada clip de
## locomoción: cuánto avanza el pie de apoyo por segundo. Si el motor lo mueve a
## otra velocidad con `speed_scale` = 1, los pies patinan.
##   godot --headless --path . res://pruebas/ideas/pani_diag_clips.tscn

const LOCO := ["caminar", "trotar", "correr", "conducir", "conducir_mocap", "conducir_espejo", "trotar_atras", "marcar", "marcar_espejo",
	"portero_lateral_der", "portero_lateral_izq", "caminar_normal", "caminar_trote", "agachado_avanza", "caminar_formal"]

func _ready() -> void:
	var d := FutbolistaQ.crear(1.8, "male")
	add_child(d["nodo"])
	FutbolistaQ.terminar(d, true)
	var esq: Skeleton3D = d["esqueleto"]
	var ap: AnimationPlayer = d["anim"]
	var nodo: Node3D = d["nodo"]
	var lista := ap.get_animation_list()
	print("TOTAL ", lista.size())
	for n: String in lista:
		if OS.get_environment("VOLCAR") != "":
			break
		var a := ap.get_animation(n)
		print("CLIP %s %.2f %d" % [n, a.length, a.loop_mode])
	var il := esq.find_bone("ball_l")
	var ir := esq.find_bone("ball_r")
	for n: String in LOCO:
		if not ap.has_animation(n):
			print("LOCO %s NO EXISTE" % n)
			continue
		var a := ap.get_animation(n)
		ap.play(n)
		var muestras := 120
		var pl: Array[Vector3] = []
		var pr: Array[Vector3] = []
		for k in muestras + 1:
			ap.seek(a.length * k / muestras, true)
			var inv := nodo.global_transform.affine_inverse()
			pl.append(inv * (esq.global_transform * esq.get_bone_global_pose(il)).origin)
			pr.append(inv * (esq.global_transform * esq.get_bone_global_pose(ir)).origin)
		var dt := a.length / muestras
		if OS.get_environment("VOLCAR") == n:
			for k in muestras + 1:
				print("M %d l=(%.3f,%.3f,%.3f) r=(%.3f,%.3f,%.3f)" % [k, pl[k].x, pl[k].y, pl[k].z, pr[k].x, pr[k].y, pr[k].z])
		var res := []
		for pie: Array in [pl, pr]:
			var ym := 9.0
			for q: Vector3 in pie:
				ym = minf(ym, q.y)
			var vs: Array[float] = []
			var ks: Array[int] = []
			for k in muestras:
				if (pie[k] as Vector3).y < ym + 0.025:
					var dv: Vector3 = ((pie[k + 1] as Vector3) - (pie[k] as Vector3)) / dt
					vs.append(Vector2(dv.x, dv.z).length())
					ks.append(k)
			vs.sort()
			res.append("med=%.2f n=%d desde=%.2f ym=%.3f" % [vs[vs.size() / 2] if not vs.is_empty() else -1.0, vs.size(), float(ks[0]) / muestras if not ks.is_empty() else -1.0, ym])
		print("LOCO %s dur=%.3f  IZQ %s  DER %s" % [n, a.length, res[0], res[1]])
	print("===== FIN. 0 fallos =====")
	get_tree().quit()
