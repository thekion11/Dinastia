class_name SueloAnim
extends RefCounted
## PIES QUE NO ATRAVIESAN EL CÉSPED (31-10-2026, auditoría biomecánica: 236 de 246 avisos eran un pie o una punta 4-29 cm bajo el
## suelo en tiros, voleas, regates, barridas y trotes). Al construir la librería (`AnimQuaternius._construir`) se recorre cada clip a
## 30 fps con cinemática directa desde sus pistas (sin reproducirlo): si el pie o la punta más bajos quedan por debajo de su altura
## en «parado» (la misma referencia que `pruebas/auditoria_biomecanica`), se SUBE la pelvis justo eso, suavizado (máximo de ±2
## cuadros y media de ±2) para que no dé tirones. Tope 30 cm. Un clip corregido lleva la meta `suelo_ok` y no se toca dos veces.
## TUMBADO O SENTADO (pelvis por debajo del 60 % de su altura de pie) el pie puede apoyarse de lado y el tobillo queda más bajo
## que de pie: la referencia pasa a `APOYO_LADO` (si no, se subía el cuerpo tumbado y flotaba sobre el césped).
const FPS := 30.0
const PIES := ["foot_l", "foot_r", "ball_l", "ball_r"]
const TOLERANCIA := 0.005
const TOPE := 0.30
const APOYO_LADO := {"foot_l": 0.05, "foot_r": 0.05, "ball_l": 0.02, "ball_r": 0.02}
const PELVIS_BAJA := 0.6

## Corrige todos los clips de `lib`. Devuelve cuántos cambió.
static func corregir(lib: AnimationLibrary, esq: Skeleton3D, prefijo: String) -> int:
	if not lib.has_animation("parado") or OS.get_environment("SIN_SUELO_ANIM") != "":
		return 0
	var ref := _alturas(lib.get_animation("parado"), esq, prefijo, 0.0)
	var n := 0
	for nombre: StringName in lib.get_animation_list():
		var a := lib.get_animation(nombre)
		if a.has_meta("suelo_ok"):
			continue
		a.set_meta("suelo_ok", true)
		var c := CodoAnim.corregir_clip(a, esq, prefijo)   ## y codos que no pasan de 145° (31-10)
		if corregir_clip(a, esq, prefijo, ref) or c:
			n += 1
	return n

static func corregir_clip(a: Animation, esq: Skeleton3D, prefijo: String, ref: Dictionary) -> bool:
	var pelvis := esq.find_bone("pelvis")
	if pelvis < 0 or a.length <= 0.0:
		return false
	var cuadros := maxi(2, ceili(a.length * FPS) + 1)
	var sube := PackedFloat32Array()
	sube.resize(cuadros)
	var hay := false
	for k in cuadros:
		var h := _alturas(a, esq, prefijo, minf(float(k) / FPS, a.length))
		var baja := ref.has("pelvis") and float(h.get("pelvis", 1.0)) < float(ref["pelvis"]) * PELVIS_BAJA
		var peor := 0.0
		for b: String in PIES:
			if h.has(b) and ref.has(b):
				var r0: float = minf(float(ref[b]), float(APOYO_LADO[b])) if baja else float(ref[b])
				peor = maxf(peor, r0 - float(h[b]))
		sube[k] = clampf(peor - TOLERANCIA, 0.0, TOPE) if peor > TOLERANCIA else 0.0
		hay = hay or sube[k] > 0.0
	if not hay:
		return false
	## Suavizado: el máximo de la vecindad (no se queda corto) y luego la media (sin tirones).
	var mx := PackedFloat32Array()
	mx.resize(cuadros)
	for k in cuadros:
		var m := 0.0
		for d in range(-2, 3):
			m = maxf(m, sube[clampi(k + d, 0, cuadros - 1)])
		mx[k] = m
	var ruta := NodePath("%s:pelvis" % prefijo)
	var padre := esq.get_bone_parent(pelvis)
	var pista := a.find_track(ruta, Animation.TYPE_POSITION_3D)
	var nuevas: Array = []
	for k in cuadros:
		var tk := minf(float(k) / FPS, a.length)
		var s := 0.0
		for d in range(-2, 3):
			s += mx[clampi(k + d, 0, cuadros - 1)]
		var arriba := Vector3(0.0, s / 5.0, 0.0)
		var base: Vector3 = a.position_track_interpolate(pista, tk) if pista >= 0 else esq.get_bone_rest(pelvis).origin
		## «Arriba» es el del esqueleto: se pasa al espacio del padre de la pelvis (la raíz puede venir girada).
		var g_padre := _global(a, esq, prefijo, padre, tk) if padre >= 0 else Transform3D.IDENTITY
		nuevas.append([tk, base + g_padre.basis.inverse() * arriba])
	if pista < 0:
		pista = a.add_track(Animation.TYPE_POSITION_3D)
		a.track_set_path(pista, ruta)
	while a.track_get_key_count(pista) > 0:
		a.track_remove_key(pista, 0)
	for nv: Array in nuevas:
		a.position_track_insert_key(pista, float(nv[0]), nv[1])
	## LINEAL (01-11, fallo encontrado en el barrido de pruebas): con claves cada 1/30 s la cúbica no suaviza nada, y en un
	## clip en bucle con el último tramo más corto (0,52 s → 0,50 y 0,52) se disparaba al dar la vuelta: la pelvis de la
	## guardia lateral del portero bajaba a −821 m durante 0,03 s (el portero desaparecía un instante).
	a.track_set_interpolation_type(pista, Animation.INTERPOLATION_LINEAR)
	return true

## Altura (y del esqueleto) de pies y puntas en el instante `tk` del clip.
static func _alturas(a: Animation, esq: Skeleton3D, prefijo: String, tk: float) -> Dictionary:
	var r := {}
	var cache := {}
	for b: String in PIES + ["pelvis"]:
		var i := esq.find_bone(b)
		if i >= 0:
			r[b] = _global(a, esq, prefijo, i, tk, cache).origin.y
	return r

## Pose global (espacio del esqueleto) del hueso `i` en `tk`, desde las pistas del clip (o el reposo si no tiene).
static func _global(a: Animation, esq: Skeleton3D, prefijo: String, i: int, tk: float, cache := {}) -> Transform3D:
	if cache.has(i):
		return cache[i]
	var nombre := esq.get_bone_name(i)
	var reposo := esq.get_bone_rest(i)
	var ruta := NodePath("%s:%s" % [prefijo, nombre])
	var pp := a.find_track(ruta, Animation.TYPE_POSITION_3D)
	var pr := a.find_track(ruta, Animation.TYPE_ROTATION_3D)
	var ps := a.find_track(ruta, Animation.TYPE_SCALE_3D)
	var pos: Vector3 = a.position_track_interpolate(pp, tk) if pp >= 0 else reposo.origin
	var rot: Quaternion = a.rotation_track_interpolate(pr, tk) if pr >= 0 else reposo.basis.get_rotation_quaternion()
	var esc: Vector3 = a.scale_track_interpolate(ps, tk) if ps >= 0 else reposo.basis.get_scale()
	var local := Transform3D(Basis(rot).scaled(esc), pos)
	var padre := esq.get_bone_parent(i)
	var g := (_global(a, esq, prefijo, padre, tk, cache) * local) if padre >= 0 else local
	cache[i] = g
	return g
