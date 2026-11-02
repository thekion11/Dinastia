class_name CodoAnim
extends RefCounted
## CODOS QUE NO SE DOBLAN DE MÁS (31-10-2026, auditoría biomecánica: gestos a mano con el codo a 175-180°, el antebrazo
## atravesando el brazo, en el silbato del árbitro, besar el escudo, la mano al oído, las manos a la cabeza, silbar con los dedos
## o pedir silencio; un codo humano llega a ~150°). Lo llama `SueloAnim.corregir` para cada clip. Las CLAVES de esos gestos están
## bien: es la interpolación ENTRE claves la que se pasa (medido: 179,7° a 0,63 s sin clave ahí). Por eso se muestrea a 30 fps y,
## si algún instante pasa de `TOPE`, la pista del antebrazo se reescribe a 30 fps (interpolación lineal) acercando la rotación a la
## de reposo (brazo recto) lo justo para quedarse en el tope. El doblez es el ángulo entre brazo y antebrazo, como en la auditoría.
const TOPE := 145.0
const FPS := 30.0
const LADOS := ["l", "r"]

## Devuelve true si cambió alguna pista.
static func corregir_clip(a: Animation, esq: Skeleton3D, prefijo: String) -> bool:
	var cambio := false
	for s: String in LADOS:
		var ante := esq.find_bone("lowerarm_" + s)
		var mano := esq.find_bone("hand_" + s)
		if ante < 0 or mano < 0:
			continue
		var pista := a.find_track(NodePath("%s:lowerarm_%s" % [prefijo, s]), Animation.TYPE_ROTATION_3D)
		if pista < 0 or a.length <= 0.0:
			continue
		## En el marco del brazo: el brazo va del hombro al codo (posición del antebrazo) y el antebrazo, del codo a la muñeca.
		var dir_brazo := esq.get_bone_rest(ante).origin
		var pm := a.find_track(NodePath("%s:hand_%s" % [prefijo, s]), Animation.TYPE_POSITION_3D)
		var reposo := esq.get_bone_rest(ante).basis.get_rotation_quaternion()
		var cuadros := maxi(2, ceili(a.length * FPS) + 1)
		var muestras: Array = []
		var pasa := false
		for k in cuadros:
			var tk := minf(float(k) / FPS, a.length)
			var q: Quaternion = a.rotation_track_interpolate(pista, tk)
			var hm: Vector3 = a.position_track_interpolate(pm, tk) if pm >= 0 else esq.get_bone_rest(mano).origin
			var d := doblez(dir_brazo, q, hm)
			if d > TOPE:
				pasa = true
				var f := TOPE / d
				for _i in 4:
					var c := reposo.slerp(q, f)
					var dc := doblez(dir_brazo, c, hm)
					if dc <= TOPE + 0.5:
						break
					f *= TOPE / dc
				q = reposo.slerp(q, f)
			muestras.append([tk, q])
		if not pasa:
			continue
		while a.track_get_key_count(pista) > 0:
			a.track_remove_key(pista, 0)
		a.track_set_interpolation_type(pista, Animation.INTERPOLATION_LINEAR)
		for m: Array in muestras:
			a.rotation_track_insert_key(pista, float(m[0]), m[1])
		cambio = true
	return cambio

## Ángulo (grados) entre el brazo (`dir_brazo`, en el marco del brazo) y el antebrazo girado `q` hacia la mano (`mano_local`).
static func doblez(dir_brazo: Vector3, q: Quaternion, mano_local: Vector3) -> float:
	return rad_to_deg(dir_brazo.angle_to(q * mano_local))
