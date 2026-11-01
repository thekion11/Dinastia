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
