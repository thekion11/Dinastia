class_name TroteCmu
extends RefCounted
## EL TROTE DE CAPTURA REAL (17-11-2026). El dueño pidió animaciones de Mixamo, pero Mixamo exige iniciar sesión con una cuenta de
## Adobe en un navegador (imposible desde la nube) y sus términos no dejan redistribuir los archivos sueltos. La alternativa libre que
## ya estaba en el juego es la base CMU (Carnegie Mellon, libre también para uso comercial; `anims_cmu/cmu_uso.res`): sus 12 ciclos de
## carrera reales (+ espejos, 3,1-4,3 m/s) dan a cada jugador SU manera de trotar en lugar del mismo clip para los 22.
##  · Reparto por jugador (`repartir`, con el id): 1 de cada `ORIGINAL_CADA` sigue con el trote de siempre; el resto lleva uno de los
##    24 (12 + espejos). Se monta SOLO donde ya se monta lo cercano (`AnimacionCercana`: de MEDIA hacia arriba y sin «Partido ligero»):
##    en el móvil por defecto no existe y no cuesta nada.
##  · Sin patinar: cada clip lleva la velocidad a la que pisa su pie de apoyo con escala 1 (`CLIPS`, medida con `AnimPasos.medir` en
##    el cuerpo de 1,80 m) y `CicloCarrera.escala_jugador` reparte la escala sobre esa velocidad. La mocap tiene más cadencia que el
##    trote de siempre: para no acelerarla más de `HI` veces, el que lleva uno lento pasa a correr un poco antes (`umbral_correr`,
##    4,6-5,2 m/s) y vuelve a trotar por debajo de `A_TROTAR` (lo que el «correr» cubre sin patinar: 7,0 × 0,6 = 4,2 m/s).
##  · Pies en el césped: la retarget de CMU dejaba los pies flotando 5-21 cm (el sujeto de la captura es más alto que el nuestro);
##    la pelvis baja lo que flotaba (`CLIPS[2]`).
##  · El paso en fase: la fase del pie izquierdo de cada clip va a `AnimPasos.fases` (al pasar a correr, la pierna en el aire sigue
##    en el aire, como con los de siempre).
## Solo cambia lo que se VE (qué clip y a qué velocidad): el motor lee «trotar» en `anim_actual` como siempre; la huella de
## `pruebas/igualdad_motor.gd` no cambia (el banco lo compara con y sin). `TROTE_CMU=0` lo apaga (capturas «antes»).

static var encendida: bool = OS.get_environment("TROTE_CMU") != "0"
const BIBLIOTECA := "res://assets/characters/quaternius/anims_cmu/cmu_uso.res"
const PREFIJO := "trote_cmu_"
## clip → [velocidad del pie de apoyo con escala 1 (m/s), fase en que apoya el pie izquierdo (0-1), pie flotando (m, a 1,80 m)].
const CLIPS := {
	"cmu_09_06_ciclo": [3.62, 0.54, 0.102], "cmu_09_06_ciclo_espejo": [3.59, 0.94, 0.111],
	"cmu_127_03_ciclo": [3.61, 0.11, 0.097], "cmu_127_03_ciclo_espejo": [3.22, 0.70, 0.091],
	"cmu_127_06_ciclo": [4.30, 0.07, 0.208], "cmu_127_06_ciclo_espejo": [4.01, 0.46, 0.207],
	"cmu_127_07_ciclo": [4.33, 0.65, 0.177], "cmu_127_07_ciclo_espejo": [4.32, 0.93, 0.165],
	"cmu_35_17_ciclo": [3.11, 0.97, 0.134], "cmu_35_17_ciclo_espejo": [3.11, 0.47, 0.139],
	"cmu_35_18_ciclo": [3.15, 0.83, 0.126], "cmu_35_18_ciclo_espejo": [3.16, 0.27, 0.128],
	"cmu_35_19_ciclo": [3.34, 0.85, 0.133], "cmu_35_19_ciclo_espejo": [3.35, 0.38, 0.139],
	"cmu_35_20_ciclo": [3.42, 0.97, 0.119], "cmu_35_20_ciclo_espejo": [3.42, 0.53, 0.121],
	"cmu_35_21_ciclo": [3.50, 0.95, 0.115], "cmu_35_21_ciclo_espejo": [3.50, 0.46, 0.117],
	"cmu_35_23_ciclo": [3.31, 0.90, 0.095], "cmu_35_23_ciclo_espejo": [3.31, 0.53, 0.099],
	"cmu_35_24_ciclo": [3.43, 0.92, 0.123], "cmu_35_24_ciclo_espejo": [3.43, 0.58, 0.124],
	"cmu_35_25_ciclo": [3.46, 0.81, 0.047], "cmu_35_25_ciclo_espejo": [3.46, 0.26, 0.052]}
const ORIGINAL_CADA := 6
const HI := 1.45            ## lo más que se acelera un clip de mocap (el más lento llega a ×1,48: nadie corre antes de 4,6 m/s)
const A_CORRER_MIN := 4.6   ## m/s
const A_TROTAR := 4.25      ## m/s: de correr a trotar (por encima de lo más lento que el «correr» pisa sin patinar)
const V_MIN := 1.87         ## m/s: lo más lento a lo que se estira un trote (como el de siempre: 3,4 × 0,55)

## Con el clip de un trote CMU: a qué velocidad se pasa a correr.
static func umbral_correr(v: float) -> float:
	return clampf(v * HI, A_CORRER_MIN, CicloCarrera.A_CORRER)

## El clip de CMU que le toca a un id ("" = el trote de siempre).
static func base_de(id: String) -> String:
	var h := absi(("trote:" + id).hash())
	if h % ORIGINAL_CADA == 0:
		return ""
	var claves := CLIPS.keys()
	return String(claves[(h / ORIGINAL_CADA) % claves.size()])

## Le da al jugador su trote (una vez; los que entran de cambio, al verlos `AnimacionCercana`). Deja en `p["trote_cmu"]`
## [clip, velocidad, umbral a correr] o [] (el de siempre).
static func repartir(p: Dictionary) -> void:
	if p.has("trote_cmu"):
		return
	p["trote_cmu"] = []
	if not encendida or bool(p.get("por", false)):
		return   ## el portero tiene sus propios desplazamientos
	var base := base_de(String(p.get("id", "")))
	var ap: AnimationPlayer = p.get("anim")
	var nodo: Node = p.get("node")
	if base == "" or not is_instance_valid(ap) or not is_instance_valid(nodo):
		return
	var clave := PREFIJO + base
	if not asegurar(ap, FutbolistaQ.esqueleto_de(nodo), base, clave):
		return
	var v := float(CLIPS[base][0])
	p["trote_cmu"] = [clave, v, umbral_correr(v)]
	if String(p.get("anim_actual", "")) == "trotar":
		p["anim_actual"] = ""   ## que el próximo «trotar» ya sea el suyo

## El nombre del clip que se reproduce cuando el motor pide `nombre`.
static func clip(p: Dictionary, nombre: String) -> String:
	if nombre != "trotar":
		return nombre
	var t: Array = p.get("trote_cmu", [])
	return nombre if t.is_empty() else String(t[0])

## Mete el clip (una vez por biblioteca) con las pistas reapuntadas al esqueleto, los pies en el césped y en bucle.
static func asegurar(ap: AnimationPlayer, esq: Skeleton3D, base: String, clave: String) -> bool:
	if ap.has_animation(clave):
		return true
	if esq == null or not ap.has_animation("correr") or ap.get_animation("correr").get_track_count() == 0 or not ap.has_animation_library(""):
		return false
	var lib := load(BIBLIOTECA) as AnimationLibrary
	if lib == null or not lib.has_animation(base):
		return false
	var a := _copia(lib.get_animation(base), String(ap.get_animation("correr").track_get_path(0)).get_slice(":", 0), _bajada(esq, float(CLIPS[base][2])))
	ap.get_animation_library("").add_animation(clave, a)
	AnimPasos.fases[clave] = float(CLIPS[base][1])
	return true

## Lo que baja la pelvis para que el pie no flote: en las unidades del esqueleto, pasado al espacio de su padre (el hueso raíz, en
## reposo: los clips no lo animan).
static func _bajada(esq: Skeleton3D, flota: float) -> Vector3:
	var ip := esq.find_bone("pelvis")
	if ip < 0 or flota <= 0.0:
		return Vector3.ZERO
	var marco := AnimPasos._marco(esq)
	var baja: Vector3 = (marco[0] as Vector3) * (flota / float(marco[1]))
	var padre := esq.get_bone_parent(ip)
	return esq.get_bone_global_rest(padre).basis.inverse() * baja if padre >= 0 else baja

## Copia en bucle del clip, con las pistas reapuntadas a `prefijo` y la pelvis bajada. La biblioteca guarda las pistas comprimidas
## (no se pueden editar): se rehacen con sus mismas claves (23 pistas de ~20 claves; una vez por clip y biblioteca).
static func _copia(src: Animation, prefijo: String, baja: Vector3) -> Animation:
	var a := Animation.new()
	a.length = src.length
	a.loop_mode = Animation.LOOP_LINEAR
	for i in src.get_track_count():
		var tipo := src.track_get_type(i)
		if tipo != Animation.TYPE_ROTATION_3D and tipo != Animation.TYPE_POSITION_3D:
			continue
		var hueso := str(src.track_get_path(i)).get_slice(":", 1)
		var nt := a.add_track(tipo)
		a.track_set_path(nt, NodePath("%s:%s" % [prefijo, hueso]))
		a.track_set_interpolation_loop_wrap(nt, true)
		for k in src.track_get_key_count(i):
			var tk := src.track_get_key_time(i, k)
			if tipo == Animation.TYPE_ROTATION_3D:
				a.rotation_track_insert_key(nt, tk, src.track_get_key_value(i, k))
			else:
				a.position_track_insert_key(nt, tk, (src.track_get_key_value(i, k) as Vector3) - (baja if hueso == "pelvis" else Vector3.ZERO))
	return a
