class_name TroteCmu
extends RefCounted
## EL TROTE DE CAPTURA REAL (17-11-2026). APAGADO POR DEFECTO (`TROTE_CMU=1` lo enciende): el dueño dejó el realismo de los
## jugadores para después; queda listo y probado en el banco. El dueño pidió animaciones de Mixamo, pero Mixamo exige iniciar sesión
## con una cuenta de Adobe en un navegador (imposible desde la nube) y sus términos no dejan redistribuir los archivos sueltos. La
## alternativa libre que ya estaba en el juego es la base CMU (Carnegie Mellon, libre también para uso comercial; `anims_cmu/cmu_uso.res`):
## sus 12 ciclos de carrera reales (+ espejos, 3,1-4,3 m/s) dan a cada jugador SU manera de trotar en lugar del mismo clip para los 22.
##  · SIN TOCAR LA DECISIÓN NI LA ESCALA DEL MOTOR (que en `main` hace C++, `animar_jugadores`): el motor sigue pidiendo «trotar» y
##    poniendo su escala (velocidad / 3,4 m/s, `CicloCarrera`). Cada clip CMU se re-cronometra en el propio recurso para que su pie de
##    apoyo vaya a 3,4 m/s con escala 1 (como el «trotar» de siempre: con la misma escala, no patina) y, al montar al jugador, una señal
##    de su AnimationPlayer (`current_animation_changed`) cambia «trotar» por su variante en el mismo fotograma.
##  · Reparto por jugador (`repartir`, con el id): 1 de cada `ORIGINAL_CADA` sigue con el trote de siempre; el resto lleva uno de los
##    24 (12 + espejos). Se monta SOLO donde ya se monta lo cercano (`AnimacionCercana`: de MEDIA hacia arriba y sin «Partido ligero»).
##  · Pies en el césped: la retarget de CMU dejaba los pies flotando 5-21 cm (el sujeto de la captura es más alto que el nuestro);
##    la pelvis baja lo que flotaba (`CLIPS[2]`).
##  · El paso en fase: la fase del pie izquierdo de cada clip va a `AnimPasos.fases`.
## Solo cambia lo que se VE: la huella de `pruebas/igualdad_motor.gd` no cambia (el banco lo compara con y sin).

static var encendida: bool = OS.get_environment("TROTE_CMU") == "1"
const BIBLIOTECA := "res://assets/characters/quaternius/anims_cmu/cmu_uso.res"
const PREFIJO := "trote_cmu_"
const V_TROTE := 3.4   ## m/s: la del «trotar» de siempre (`CicloCarrera.CICLO`); cada clip CMU se re-cronometra a ella
## clip → [velocidad del pie de apoyo con escala 1 (m/s, sin re-cronometrar), fase en que apoya el pie izquierdo (0-1), pie flotando
## (m, a 1,80 m)], medidos con `AnimPasos.medir` en el cuerpo de 1,80 m.
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

## El clip de CMU que le toca a un id ("" = el trote de siempre).
static func base_de(id: String) -> String:
	var h := absi(("trote:" + id).hash())
	if h % ORIGINAL_CADA == 0:
		return ""
	var claves := CLIPS.keys()
	return String(claves[(h / ORIGINAL_CADA) % claves.size()])

## Le da al jugador su trote (una vez; los que entran de cambio, al verlos `AnimacionCercana`). Deja en `p["trote_cmu"]` [clip] o []
## (el de siempre).
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
	p["trote_cmu"] = [clave]
	if not ap.has_meta("trote_cmu"):
		ap.set_meta("trote_cmu", clave)
		ap.current_animation_changed.connect(TroteCmu._al_cambiar.bind(ap, clave))
	if String(ap.current_animation) == "trotar":
		ap.play(clave, 0.2)

## «trotar» acaba de empezar: en su lugar, la variante del jugador (misma escala, que el motor pone después).
static func _al_cambiar(nuevo: String, ap: AnimationPlayer, clave: String) -> void:
	if nuevo == "trotar" and is_instance_valid(ap) and ap.has_animation(clave):
		ap.play(clave, 0.2)

## Mete el clip (una vez por biblioteca) re-cronometrado a `V_TROTE`, con las pistas reapuntadas al esqueleto, los pies en el
## césped y en bucle.
static func asegurar(ap: AnimationPlayer, esq: Skeleton3D, base: String, clave: String) -> bool:
	if ap.has_animation(clave):
		return true
	if esq == null or not ap.has_animation("correr") or ap.get_animation("correr").get_track_count() == 0 or not ap.has_animation_library(""):
		return false
	var lib := load(BIBLIOTECA) as AnimationLibrary
	if lib == null or not lib.has_animation(base):
		return false
	var prefijo := String(ap.get_animation("correr").track_get_path(0)).get_slice(":", 0)
	var a := _copia(lib.get_animation(base), prefijo, _bajada(esq, float(CLIPS[base][2])), float(CLIPS[base][0]) / V_TROTE)
	ap.get_animation_library("").add_animation(clave, a)
	AnimPasos.fases[clave] = float(CLIPS[base][1])   ## re-cronometrar a la par no cambia la fase
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
## (no se pueden editar): se rehacen con sus mismas claves (23 pistas de ~20 claves; una vez por clip y biblioteca). `tiempo`: el
## factor de los tiempos (velocidad natural / `V_TROTE`: con escala 1 el pie de apoyo va a 3,4 m/s).
static func _copia(src: Animation, prefijo: String, baja: Vector3, tiempo := 1.0) -> Animation:
	var a := Animation.new()
	a.length = src.length * tiempo
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
			var tk := src.track_get_key_time(i, k) * tiempo
			if tipo == Animation.TYPE_ROTATION_3D:
				a.rotation_track_insert_key(nt, tk, src.track_get_key_value(i, k))
			else:
				a.position_track_insert_key(nt, tk, (src.track_get_key_value(i, k) as Vector3) - (baja if hueso == "pelvis" else Vector3.ZERO))
	return a
