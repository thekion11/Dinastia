extends SceneTree
## REVISIÓN AUTOMÁTICA de los ciclos de 100STYLE ya retargeteados (sesión 10, 11-11-2026). Para cada clip mide, sobre nuestro esqueleto y
## a la altura real del jugador (1,8 m):
##  · PATINAJE: el cuerpo avanza a la velocidad de la etiqueta y se mira la velocidad MUNDIAL del pie en apoyo (debería ser ~0).
##    Se calcula también la velocidad que anula el patinaje (la de los pies) y se vuelca en el catálogo como `velocidad_ms`.
##  · BRAZOS EN EL CUERPO: distancia mínima de la mano y del codo al eje de la columna (pelvis→cuello) durante el ciclo.
##  · SALTO DE CIERRE: diferencia de pose entre el último cuadro y el primero (para el bucle).
##   godot --headless --path . --script res://herramientas/estilo100_revisar.gd
var LIB := "res://terceros/estilo100/biblioteca/100style.res"   ## con ESTILO100_NOMBRE=otro → otro.res
var CATALOGO := "res://terceros/estilo100/catalogos/animaciones_catalogo_100style.json"
const MIN_MANO := 0.12
const MIN_CODO := 0.11
const MAX_PATINAJE_MIN := 0.60   ## aviso si el pie en apoyo se desliza más que esto y más que la propia velocidad
const UMBRAL_APOYO := 0.03   ## m sobre el punto más bajo de ese pie en el ciclo

var esq: Skeleton3D
var ap: AnimationPlayer
var fichas := {}

func _pos(hueso: String) -> Vector3:
	return esq.global_transform * esq.get_bone_global_pose(esq.find_bone(hueso)).origin

func _dist_segmento(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.000001), 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _initialize() -> void:
	var nom := OS.get_environment("ESTILO100_NOMBRE")
	if nom != "":
		LIB = "res://terceros/estilo100/biblioteca/%s.res" % nom
		CATALOGO = "res://terceros/estilo100/catalogos/animaciones_catalogo_%s.json" % nom
	var d := FutbolistaQ.crear(1.8, "male")
	root.add_child(d["nodo"])
	await process_frame
	FutbolistaQ.terminar(d)
	await process_frame
	esq = d["esqueleto"]
	ap = d["anim"]
	ap.add_animation_library("x100", load(LIB))
	var cat: Array = JSON.parse_string(FileAccess.get_file_as_string(CATALOGO))
	for f: Dictionary in cat:
		fichas[f["nombre"]] = f
	var malos := 0
	var revisados := 0
	var filas: Array[String] = []
	for ficha: Dictionary in cat:
		var nombre: String = ficha["nombre"]
		var anim: Animation = ap.get_animation("x100/" + nombre)
		var n := int(ficha["cuadros"])
		var tipo := String(ficha["tipo"])
		var dt := 1.0 / float(ficha["fps"])
		var piso := [Vector3.ZERO]
		var r := {"mano": 9.0, "codo": 9.0}
		var bi: Array = []   # [pie_izq(pos), pie_der(pos)] por cuadro (marco del modelo, sin mover el cuerpo)
		var min_y := [9.0, 9.0, 9.0, 9.0]
		for k in n + 1:
			ap.play("x100/" + nombre)
			ap.seek(float(k) * dt, true)
			ap.advance(0.0)
			var pi := _pos("pelvis")
			var cu := _pos("neck_01")
			var pl := _pos("ball_l")
			var pr := _pos("ball_r")
			var tl := _pos("foot_l")
			var tr := _pos("foot_r")
			bi.append([pl, pr, tl, tr])
			for q in 4:
				min_y[q] = minf(min_y[q], [pl, pr, tl, tr][q].y)
			for lado in ["l", "r"]:
				r["mano"] = minf(r["mano"], _dist_segmento(_pos("hand_" + lado), pi, cu))
				r["codo"] = minf(r["codo"], _dist_segmento(_pos("lowerarm_" + lado), pi, cu))
		ap.stop()
		## Pies: en apoyo (ball a < 4 cm sobre su mínimo) la velocidad del pie respecto al cuerpo es la que hay que cancelar avanzando.
		var dir_mov: Vector2 = Vector2.ZERO
		var ang := deg_to_rad(float(ficha["angulo_mov_grados"]))
		if tipo != "reposo":
			dir_mov = Vector2(sin(ang), cos(ang))   # (izquierda, adelante)
		var rel := 0.0
		var m := 0
		for lado in 4:
			for k in n:
				var a: Vector3 = bi[k][lado]
				var b: Vector3 = bi[k + 1][lado]
				if a.y - min_y[lado] < UMBRAL_APOYO and b.y - min_y[lado] < UMBRAL_APOYO:
					var v := Vector2(b.x - a.x, b.z - a.z) / dt   # el pie se mueve «hacia atrás» respecto al cuerpo cuando avanza
					rel += -v.dot(dir_mov) if tipo != "reposo" else 0.0
					m += 1
		var v_pies := (rel / float(m)) if m > 0 else 0.0
		var resid := 0.0
		if tipo != "reposo" and m > 0:
			for lado in 4:
				for k in n:
					var a2: Vector3 = bi[k][lado]
					var b2: Vector3 = bi[k + 1][lado]
					if a2.y - min_y[lado] < UMBRAL_APOYO and b2.y - min_y[lado] < UMBRAL_APOYO:
						var vv := Vector2(b2.x - a2.x, b2.z - a2.z) / dt + dir_mov * v_pies
						resid += vv.length()
			resid /= float(m)
		ficha["velocidad_pies_ms"] = snappedf(v_pies, 0.01)
		ficha["patinaje_ms"] = snappedf(resid, 0.01)
		ficha["min_dist_mano_torso_m"] = snappedf(r["mano"], 0.001)
		ficha["min_dist_codo_torso_m"] = snappedf(r["codo"], 0.001)
		ficha["revision"] = "ok"
		var motivos: Array[String] = []
		if r["mano"] < MIN_MANO:
			motivos.append("mano en el cuerpo %.3f" % r["mano"])
		if r["codo"] < MIN_CODO:
			motivos.append("codo en el cuerpo %.3f" % r["codo"])
		if tipo != "reposo" and resid > maxf(MAX_PATINAJE_MIN, v_pies):
			motivos.append("patina %.2f m/s" % resid)
		ficha["velocidad_cadera_ms"] = ficha["velocidad_ms"]
		if tipo != "reposo" and m > 0 and v_pies > 0.2:
			ficha["velocidad_ms"] = ficha["velocidad_pies_ms"]   # la velocidad que no patina (la de los pies)
		if not motivos.is_empty():
			ficha["revision"] = "aviso: " + ", ".join(motivos)
			malos += 1
		revisados += 1
		if not nombre.ends_with("_espejo"):
			filas.append("%-34s v_etiqueta=%.2f v_pies=%.2f patina=%.2f mano=%.3f codo=%.3f %s" % [nombre, float(ficha["velocidad_ms"]),
					v_pies, resid, r["mano"], r["codo"], "" if motivos.is_empty() else "  <== " + ", ".join(motivos)])
	for s in filas:
		print(s)
	var f := FileAccess.open(CATALOGO, FileAccess.WRITE)
	f.store_string(JSON.stringify(cat, "\t"))
	f.close()
	print("revisados ", revisados, "  con aviso ", malos)
	quit(0)
