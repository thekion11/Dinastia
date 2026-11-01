class_name LeagueAnim
extends RefCounted
## CICLOS DE LEAGUE-SOCCER (01-11-2026, misión del dueño; Apache 2.0, ver `terceros/league_soccer/`). El motor de origen anima un
## PASO y espeja el siguiente: aquí se unen el paso y su espejo (ya convertidos a nuestro esqueleto por
## `herramientas/league_anim_a_res.gd`) en un ciclo en bucle. Lo usa `AnimQuaternius._construir` en lugar del clip del pack.
## «correr» = el paso estable de sprint (1,68 m en 0,24 s: 7,0 m/s, la velocidad de referencia de `AnimPasos.CICLOS`).
## Comparado de lado con el «Sprint» del pack (`pruebas/captura_league_carrera`): erguido, braceo corto y apoyos naturales,
## frente a un torso muy echado y piernas recogidas como en un salto. `SIN_LEAGUE=1` vuelve al del pack.
const CICLOS := {"correr": "ls_movement__sprint__000_idlelevel1"}

static func ciclo(clave: String, prefijo: String) -> Animation:
	if not CICLOS.has(clave) or OS.get_environment("SIN_LEAGUE") != "":
		return null
	var a: Animation = AnimQuaternius.cargar_real(String(CICLOS[clave]), prefijo)
	var b: Animation = AnimQuaternius.cargar_real(String(CICLOS[clave]) + "_espejo", prefijo)
	if a == null or b == null:
		return null
	var sal := a.duplicate(true) as Animation
	for i in b.get_track_count():
		var j := sal.find_track(b.track_get_path(i), b.track_get_type(i))
		if j < 0:
			continue
		for k in b.track_get_key_count(i):
			var tk := b.track_get_key_time(i, k)
			if tk > 0.0001:   ## la primera clave del espejo coincide con la última del paso
				sal.track_insert_key(j, a.length + tk, b.track_get_key_value(i, k))
	sal.length = a.length + b.length
	sal.loop_mode = Animation.LOOP_LINEAR
	return sal

## GOLPEOS (01-11, segunda tanda, comparados de lado con `pruebas/captura_comparar`): clave → [clip, contacto (s), sustituye].
## Recortados para empezar justo antes del contacto (el motor saca el balón al empezar el gesto, como en los recortes del mocap).
## «tiro_carrera» SUSTITUYE al hecho a mano (que queda como «tiro_carrera_mano»: se encorvaba y giraba de espaldas al rematar);
## «pase_carrera» es nuevo: el pase al correr (el «pase» del mocap es un toque parado, que sigue para los pases sin carrera).
## La barrida de League-Soccer NO entra: acaba tumbado boca arriba del todo; la de la UAL2 se ve mejor.
const GOLPEOS := {"tiro_carrera": ["ls_shot__sprint__030", 0.17, true], "pase_carrera": ["ls_pass__sprint__000", 0.27, false]}
const ANTES_CONTACTO := 0.04

static func golpeos(lib: AnimationLibrary, esq: Skeleton3D, prefijo: String) -> void:
	if OS.get_environment("SIN_LEAGUE") != "":
		return
	var rp := esq.get_bone_rest(esq.find_bone("pelvis")).origin
	for clave: String in GOLPEOS:
		var g: Array = GOLPEOS[clave]
		for lado in ["", "_espejo"]:
			var base: Animation = AnimQuaternius.cargar_real(String(g[0]) + lado, prefijo)
			if base == null:
				continue
			var a := AnimQuaternius.recortar(base, maxf(float(g[1]) - ANTES_CONTACTO, 0.0) / base.length, 1.0, false, true, rp)
			var nombre: String = clave + lado
			if lib.has_animation(nombre):
				if bool(g[2]) and not lib.has_animation(clave + "_mano" + lado):
					lib.add_animation(clave + "_mano" + lado, lib.get_animation(nombre))
				lib.remove_animation(nombre)
			lib.add_animation(nombre, a)
