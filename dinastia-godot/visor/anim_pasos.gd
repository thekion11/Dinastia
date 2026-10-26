class_name AnimPasos
extends RefCounted
## LOS PIES QUE NO PATINAN (pani, 25-10-2026). Pedido: «ULTRA PULIDO de cómo se
## mueven los jugadores: transiciones sin saltos, sin patinar los pies».
##
## Medido con `pruebas/ideas/pani_diag_clips.gd` y, en el partido de verdad, con
## `pruebas/ideas/pani_sonda_pies.gd`: el clip «Jog_Fwd» de la Universal Animation
## Library lleva el pie de apoyo hacia atrás a 6,6 m/s (y «Sprint» a 10 m/s),
## pero el motor del partido los reproduce a 3,4 y 7 m/s (`ciclo` en
## `MotorJugable`): el pie plantado resbalaba 3,8 m/s por el césped. El ciclo
## tiene un vuelo muy largo y un apoyo muy corto (0,12 s), así que no basta con
## frenar el clip entero (quedaría a cámara lenta): se REPARTE el tiempo dentro
## del ciclo -el apoyo se estira hasta que el pie va a la velocidad del cuerpo y
## el vuelo se acorta- con la cadencia de un corredor real.
##
## Todo se calcula con cinemática directa sobre las pistas del clip (sin árbol de
## escena), en el espacio del esqueleto y a la escala de un jugador de 1,80 m.

const MUESTRAS := 240
## El pie «apoya» cuando está a menos de esto de su punto más bajo en el ciclo.
const UMBRAL_APOYO := 0.025
const ALTURA_REF := 1.80

## clip -> [velocidad del pie de apoyo con speed_scale 1 (m/s), duración del
## ciclo (s)]. Las velocidades son las del `ciclo` de `MotorJugable` (el motor
## pone speed_scale = velocidad / ciclo): si cambian allí, cambian aquí. Las
## cadencias son las de un futbolista real a esa velocidad (2,4 pasos/s al
## trote, 3,2 al sprint; hacia atrás y con el balón, algo más cortos).
const CICLOS := {"trotar": [3.4, 0.85], "correr": [7.0, 0.62], "trotar_atras": [2.6, 0.80], "conducir": [3.6, 0.80]}

## clip -> fase (0-1) en la que apoya el pie izquierdo. La rellena la
## construcción de la librería; `AnimTransiciones` la usa para que, al pasar de
## trotar a correr, la pierna que está en el aire siga en el aire.
static var fases: Dictionary = {}

## Pose global (espacio del esqueleto) de todos los huesos en el instante `t`.
static func _pose(anim: Animation, esq: Skeleton3D, pistas: Dictionary, t: float) -> Array:
	var n := esq.get_bone_count()
	var g: Array = []
	g.resize(n)
	for i in n:
		var reposo := esq.get_bone_rest(i)
		var q := reposo.basis.get_rotation_quaternion()
		var o := reposo.origin
		var pi: Array = pistas.get(i, [-1, -1])
		if int(pi[0]) >= 0:
			q = anim.rotation_track_interpolate(int(pi[0]), t)
		if int(pi[1]) >= 0:
			o = anim.position_track_interpolate(int(pi[1]), t)
		var local := Transform3D(Basis(q), o)
		var pa := esq.get_bone_parent(i)
		g[i] = local if pa < 0 else (g[pa] as Transform3D) * local
	return g

## hueso -> [pista de rotación, pista de posición]
static func _pistas(anim: Animation, esq: Skeleton3D) -> Dictionary:
	var r := {}
	for t in anim.get_track_count():
		var ruta := str(anim.track_get_path(t))
		var i := esq.find_bone(ruta.substr(ruta.rfind(":") + 1))
		if i < 0:
			continue
		var par: Array = r.get(i, [-1, -1])
		match anim.track_get_type(t):
			Animation.TYPE_ROTATION_3D: par[0] = t
			Animation.TYPE_POSITION_3D: par[1] = t
		r[i] = par
	return r

## Arriba del esqueleto y metros por unidad, desde el reposo (pie → cabeza).
static func _marco(esq: Skeleton3D) -> Array:
	var cab := esq.get_bone_global_rest(esq.find_bone("Head")).origin
	var pie := esq.get_bone_global_rest(esq.find_bone("ball_l")).origin
	var arriba := (cab - pie).normalized()
	var alto := (cab - pie).dot(arriba) + 0.12
	return [arriba, ALTURA_REF / maxf(alto, 0.01)]

## Lo que hace el clip con los pies: velocidad del pie de apoyo (m/s), fracción
## del ciclo con algún pie apoyado, máscara de apoyo por muestra y la fase
## (0-1) en la que apoya el pie izquierdo.
static func medir(anim: Animation, esq: Skeleton3D) -> Dictionary:
	var pistas := _pistas(anim, esq)
	var marco := _marco(esq)
	var arriba: Vector3 = marco[0]
	var k: float = marco[1]
	var ib := [esq.find_bone("ball_l"), esq.find_bone("ball_r")]
	var pos: Array = [[], []]
	for m in MUESTRAS + 1:
		var g := _pose(anim, esq, pistas, anim.length * m / MUESTRAS)
		for lado in 2:
			(pos[lado] as Array).append((g[ib[lado]] as Transform3D).origin * k)
	var dt := anim.length / MUESTRAS
	var apoyo: Array[bool] = []
	apoyo.resize(MUESTRAS)
	apoyo.fill(false)
	var vels: Array[float] = []
	var fase_izq := -1.0
	var bajo_min := [INF, INF]
	for lado in 2:
		for q: Vector3 in pos[lado]:
			bajo_min[lado] = minf(bajo_min[lado], q.dot(arriba))
	for lado in 2:
		var p: Array = pos[lado]
		for m in MUESTRAS:
			if (p[m] as Vector3).dot(arriba) < float(bajo_min[lado]) + UMBRAL_APOYO:
				apoyo[m] = true
				var d: Vector3 = (p[m + 1] as Vector3) - (p[m] as Vector3)
				d -= arriba * d.dot(arriba)
				vels.append(d.length() / dt)
				var antes := (p[(m + MUESTRAS - 1) % MUESTRAS] as Vector3).dot(arriba) < float(bajo_min[lado]) + UMBRAL_APOYO
				if lado == 0 and not antes and fase_izq < 0.0:
					fase_izq = float(m) / MUESTRAS
	vels.sort()
	var n_apoyo := 0
	for a: bool in apoyo:
		n_apoyo += 1 if a else 0
	return {"vel": vels[vels.size() / 2] if not vels.is_empty() else 0.0, "apoyo": float(n_apoyo) / MUESTRAS,
		"mascara": apoyo, "fase_izq": maxf(fase_izq, 0.0), "suelo": minf(bajo_min[0], bajo_min[1])}

## Re-muestrea un clip en bucle con un tiempo que corre distinto en el apoyo y
## en el vuelo: con speed_scale 1, el pie apoyado va a `v_obj` m/s y el ciclo
## dura `dur_obj` s. El vuelo nunca se acorta a menos del 40 % (si no da, el
## ciclo sale algo más largo).
static func ajustar(anim: Animation, esq: Skeleton3D, v_obj: float, dur_obj: float) -> Animation:
	var med := medir(anim, esq)
	var v_nat: float = med["vel"]
	if v_nat <= 0.05 or v_obj <= 0.05:
		return anim
	var t_ap := anim.length * float(med["apoyo"])
	var t_vu := anim.length - t_ap
	var s_ap := v_nat / v_obj
	var s_vu := clampf((dur_obj - s_ap * t_ap) / maxf(t_vu, 0.001), 0.4, 3.0)
	var mascara: Array[bool] = med["mascara"]
	var w: Array[float] = []
	for m in MUESTRAS:
		w.append(s_ap if mascara[m] else s_vu)
	## Sin cambios bruscos de ritmo: media móvil circular de ±3 muestras.
	var suave: Array[float] = []
	for m in MUESTRAS:
		var s := 0.0
		for j in range(-3, 4):
			s += w[(m + j + MUESTRAS) % MUESTRAS]
		suave.append(s / 7.0)
	## Tiempo nuevo acumulado en cada muestra original.
	var acum: Array[float] = [0.0]
	var dt := anim.length / MUESTRAS
	for m in MUESTRAS:
		acum.append(acum[m] + suave[m] * dt)
	return remuestrear(anim, acum)

## Un clip nuevo cuyo instante `acum[m]` muestra el original en `m/MUESTRAS`.
static func remuestrear(anim: Animation, acum: Array[float]) -> Animation:
	var total: float = acum[acum.size() - 1]
	var out := Animation.new()
	out.length = total
	out.loop_mode = anim.loop_mode
	var n_claves := maxi(8, int(ceil(total * 60.0)))
	for tr in anim.get_track_count():
		var tipo := anim.track_get_type(tr)
		if tipo != Animation.TYPE_ROTATION_3D and tipo != Animation.TYPE_POSITION_3D and tipo != Animation.TYPE_SCALE_3D:
			continue
		var nt := out.add_track(tipo)
		out.track_set_path(nt, anim.track_get_path(tr))
		out.track_set_interpolation_type(nt, anim.track_get_interpolation_type(tr))
		out.track_set_interpolation_loop_wrap(nt, anim.track_get_interpolation_loop_wrap(tr))
		var j := 0
		for c in n_claves + 1:
			var tn := total * c / n_claves
			while j < acum.size() - 2 and acum[j + 1] < tn:
				j += 1
			var f := (tn - acum[j]) / maxf(acum[j + 1] - acum[j], 0.000001)
			var to := clampf((j + clampf(f, 0.0, 1.0)) * anim.length / (acum.size() - 1), 0.0, anim.length)
			match tipo:
				Animation.TYPE_ROTATION_3D: out.rotation_track_insert_key(nt, tn, anim.rotation_track_interpolate(tr, to))
				Animation.TYPE_POSITION_3D: out.position_track_insert_key(nt, tn, anim.position_track_interpolate(tr, to))
				_: out.scale_track_insert_key(nt, tn, anim.scale_track_interpolate(tr, to))
	return out

## El clip al revés: un trote hacia delante pasado marcha atrás es un trote
## hacia atrás de verdad (el pie apoyado avanza mientras el cuerpo retrocede).
static func invertir(anim: Animation) -> Animation:
	var out := Animation.new()
	out.length = anim.length
	out.loop_mode = anim.loop_mode
	var n := maxi(8, int(ceil(anim.length * 60.0)))
	for tr in anim.get_track_count():
		var tipo := anim.track_get_type(tr)
		if tipo != Animation.TYPE_ROTATION_3D and tipo != Animation.TYPE_POSITION_3D and tipo != Animation.TYPE_SCALE_3D:
			continue
		var nt := out.add_track(tipo)
		out.track_set_path(nt, anim.track_get_path(tr))
		out.track_set_interpolation_type(nt, anim.track_get_interpolation_type(tr))
		out.track_set_interpolation_loop_wrap(nt, anim.track_get_interpolation_loop_wrap(tr))
		for c in n + 1:
			var t := anim.length * c / n
			var to := anim.length - t
			match tipo:
				Animation.TYPE_ROTATION_3D: out.rotation_track_insert_key(nt, t, anim.rotation_track_interpolate(tr, to))
				Animation.TYPE_POSITION_3D: out.position_track_insert_key(nt, t, anim.position_track_interpolate(tr, to))
				_: out.scale_track_insert_key(nt, t, anim.scale_track_interpolate(tr, to))
	return out

## Los pies al césped: baja (o sube) la pelvis en cada instante para que el pie
## más bajo quede a la altura del reposo. Para clips hechos a mano en los que la
## cadera baja más de lo que se doblan las piernas (la guardia del portero
## enterraba los pies 9 cm).
## `solo_subir`: para carreras (con vuelo): solo se corrige cuando el pie se
## mete bajo el césped; en el aire no se toca.
static func pies_al_suelo(anim: Animation, esq: Skeleton3D, solo_subir: bool = false) -> Animation:
	var pistas := _pistas(anim, esq)
	var ip := esq.find_bone("pelvis")
	if ip < 0 or int((pistas.get(ip, [-1, -1]) as Array)[1]) < 0:
		return anim
	var tr_pos: int = pistas[ip][1]
	var marco := _marco(esq)
	var arriba: Vector3 = marco[0]
	var suelo := esq.get_bone_global_rest(esq.find_bone("ball_l")).origin.dot(arriba)
	var ib := [esq.find_bone("ball_l"), esq.find_bone("ball_r")]
	var out := anim.duplicate(true) as Animation
	var n := maxi(8, int(ceil(anim.length * 30.0)))
	var claves: Array = []
	for c in n + 1:
		var t := anim.length * c / n
		var g := _pose(anim, esq, pistas, t)
		var bajo := minf((g[ib[0]] as Transform3D).origin.dot(arriba), (g[ib[1]] as Transform3D).origin.dot(arriba))
		## La corrección va en el espacio del padre de la pelvis.
		var pa := esq.get_bone_parent(ip)
		var arriba_local := arriba if pa < 0 else ((g[pa] as Transform3D).basis.inverse() * arriba)
		var dif := maxf(0.0, suelo - bajo) if solo_subir else suelo - bajo
		claves.append([t, anim.position_track_interpolate(tr_pos, t) + arriba_local * dif])
	while out.track_get_key_count(tr_pos) > 0:
		out.track_remove_key(tr_pos, 0)
	for cl: Array in claves:
		out.position_track_insert_key(tr_pos, float(cl[0]), cl[1])
	return out

## Un giro fijo añadido a un hueso en todo el clip (grados en sus ejes locales,
## los mismos que `AnimQuaternius._pista`: en la columna y el cuello, X positivo
## inclina hacia delante).
static func inclinar(anim: Animation, esq: Skeleton3D, hueso: String, grados: Vector3) -> void:
	var i := esq.find_bone(hueso)
	if i < 0:
		return
	var extra := Quaternion.from_euler(grados * PI / 180.0)
	var ruta := str(anim.track_get_path(0)).get_slice(":", 0) + ":" + hueso if anim.get_track_count() > 0 else ":" + hueso
	var tr := anim.find_track(NodePath(ruta), Animation.TYPE_ROTATION_3D)
	if tr < 0:
		tr = anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(tr, NodePath(ruta))
		anim.rotation_track_insert_key(tr, 0.0, esq.get_bone_rest(i).basis.get_rotation_quaternion())
	for k in anim.track_get_key_count(tr):
		var q: Quaternion = anim.track_get_key_value(tr, k)
		anim.track_set_key_value(tr, k, q * extra)

## Ajusta un clip de locomoción a su `CICLOS` y apunta su fase.
static func preparar(nombre: String, anim: Animation, esq: Skeleton3D) -> Animation:
	var r := anim
	if CICLOS.has(nombre):
		var c: Array = CICLOS[nombre]
		r = ajustar(anim, esq, float(c[0]), float(c[1]))
		## La media móvil del ritmo come un poco del estiramiento del apoyo
		## (en el sprint, cuyo apoyo es cortísimo, hasta un 15 %): una segunda
		## pasada sobre el resultado lo corrige.
		var v := float(medir(r, esq)["vel"])
		if absf(v - float(c[0])) > 0.04 * float(c[0]):
			r = ajustar(r, esq, float(c[0]), float(c[1]))
	## Sin el pie bajo el césped en el apoyo (el sprint lo metía 5 cm).
	r = pies_al_suelo(r, esq, true)
	fases[nombre] = float(medir(r, esq)["fase_izq"])
	return r
