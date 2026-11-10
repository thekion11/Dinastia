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
	return ciclo_de(String(CICLOS[clave]), prefijo)

## CONDUCIR COMO EN EL ORIGINAL (10-11, fase 4c de `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`): los dos ciclos estables
## con balón de League-Soccer (un paso con su toque + el espejo). Ref. de velocidad: 1,26 m en 0,25 s = 5,0 m/s («walk») y
## 1,68 m en 0,24 s = 7,0 m/s («sprint»). Solo los usa `MotorLeague` (el motor de siempre sigue con su «conducir»).
const CICLOS_CONDUCIR := {"conducir_ls": ["ls_ballcontrol__walk__000", 5.04], "conducir_ls_rapido": ["ls_ballcontrol__sprint__000", 7.0]}

static func conducir(lib: AnimationLibrary, prefijo: String) -> void:
	for clave: String in CICLOS_CONDUCIR:
		var a := ciclo_de(String(CICLOS_CONDUCIR[clave][0]), prefijo)
		if a != null and not lib.has_animation(clave):
			lib.add_animation(clave, a)

## ARRANQUES, FRENADAS Y GIROS DEL ORIGINAL (10-11, fase 4c): los clips de `LeagueMovimiento` (y sus espejos), con su nombre
## real, sin bucle. NO van en la biblioteca horneada (el motor de siempre no los usa): `LeagueLocomocion.preparar` los añade en
## el partido, una vez por biblioteca, cuando juega `MotorLeague`.
## Por TANDAS (`desde`, `cuantos`; devuelve por dónde seguir, o -1 al acabar): son ~100 clips y de una vez eran un tirón de
## ~0,2 s en mitad del partido. Al final, los ciclos con el cuerpo girado (las plantillas del original: trote a ±45/±135 grados,
## carrera suave a ±45).
static func movimiento(lib: AnimationLibrary, prefijo: String, desde := 0, cuantos := 100000) -> int:
	var tareas := tareas_movimiento()
	var hasta := mini(desde + cuantos, tareas.size())
	for k in range(desde, hasta):
		var tarea: Array = tareas[k]
		if lib.has_animation(String(tarea[0])):
			continue
		var a: Animation = load("res://visor/anim_quaternius.gd").cargar_real(String(tarea[1]), prefijo) if tarea.size() == 2 \
			else ciclo_de(String(tarea[1]), prefijo, String(tarea[2]))
		if a != null:
			if tarea.size() == 2:
				a.loop_mode = Animation.LOOP_NONE   ## (`cargar_real` ya devuelve una copia)
			lib.add_animation(String(tarea[0]), a)
	return hasta if hasta < tareas.size() else -1

static var _tareas: Array = []

## [nombre en la biblioteca, clip] o [nombre, paso derecho, paso izquierdo] (ciclo con el cuerpo girado).
static func tareas_movimiento() -> Array:
	if _tareas.is_empty():
		for c: Dictionary in LeagueMovimiento.clips():
			if not c.has("auto"):   ## (las intermedias se construyen al elegirlas: `LeagueAuto.construir`)
				_tareas.append([String(c["nombre"]), String(c["nombre"])])
		for vel: float in [LeagueMovimiento.DRIBBLE, LeagueMovimiento.WALK]:
			for g: float in [0.25, -0.25, 0.75, -0.75]:
				var par := LeagueMovimiento.plantilla(vel, g * PI)
				if not par.is_empty():
					_tareas.append(["ls_ciclo__" + String(par[0]), String(par[0]), String(par[1])])
	return _tareas

## Un ciclo en bucle: el paso de League y su espejo seguidos.
## `segundo`: el otro paso, si no es el espejo del primero (las plantillas con el cuerpo girado: el pie izquierdo es el espejo de
## la plantilla girada al otro lado).
static func ciclo_de(nombre_real: String, prefijo: String, segundo := "") -> Animation:
	var a: Animation = load("res://visor/anim_quaternius.gd").cargar_real(nombre_real, prefijo)
	var b: Animation = load("res://visor/anim_quaternius.gd").cargar_real(segundo if segundo != "" else nombre_real + "_espejo", prefijo)
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
## Tanda 3 (01-11): controles al recibir alto (los nuestros eran una reacción a un golpe y un aspaviento con la pierna), el
## tropiezo a la carrera con su levantarse desde boca abajo, y variantes de celebración y lamento (se suman, no sustituyen).
const GOLPEOS := {"tiro_carrera": ["ls_shot__sprint__030", 0.17, true], "pase_carrera": ["ls_pass__sprint__000", 0.27, false],
	"control_pecho": ["ls_trap__idle__highballs__000_chest", 0.39, false], "control_pie": ["ls_trap__idle__000_IB000", 0.20, false],
	"tropiezo": ["ls_trip__trip_t3__sprint__000", 0.04, false], "levantarse_boca_abajo": ["ls_movement_special__idle__special__000_stand_up_from_front", 0.04, false],
	"celebrar_ls": ["ls_celebration__happy_extreme__000_decel_decel", 0.04, false], "lamento_ls": ["ls_celebration__sad_normal__000", 0.04, false],
	## Tanda 4: los envíos largos hechos a mano levantaban el talón hasta el glúteo antes de golpear (`league_comparacion_centro_largo.jpg`).
	"centro": ["ls_highpass__walk__000_long", 0.41, true], "pase_largo": ["ls_highpass__idle__000_long", 0.57, true],
	"pase_bombeado": ["ls_highpass__idle__020", 0.25, true],
	## Tanda 5: el defensor que BLOQUEA un tiro con el cuerpo (antes no hacía ningún gesto), según la altura del balón. Descartados
	## (`league_bloqueos.jpg`): el rasante (se tira y se queda tumbado boca arriba) y el alto (levanta el brazo: sería mano).
	"bloqueo_rodilla": ["ls_deflect__idle__000_kneeheight_holdball", 0.09, false], "bloqueo_tronco": ["ls_deflect__idle__000_trunk_holdball", 0.10, false]}

## El gesto de bloqueo según la altura del balón (m).
static func bloqueo(altura: float) -> String:
	return "bloqueo_rodilla" if altura < 0.95 else "bloqueo_tronco"
const ANTES_CONTACTO := 0.04

static func golpeos(lib: AnimationLibrary, esq: Skeleton3D, prefijo: String) -> void:
	if OS.get_environment("SIN_LEAGUE") != "":
		return
	conducir(lib, prefijo)
	var rp := esq.get_bone_rest(esq.find_bone("pelvis")).origin
	for clave: String in GOLPEOS:
		var g: Array = GOLPEOS[clave]
		for lado in ["", "_espejo"]:
			var base: Animation = load("res://visor/anim_quaternius.gd").cargar_real(String(g[0]) + lado, prefijo)
			if base == null:
				continue
			var a = load("res://visor/anim_quaternius.gd").recortar(base, maxf(float(g[1]) - ANTES_CONTACTO, 0.0) / base.length, 1.0, false, true, rp)
			var nombre: String = clave + lado
			if lib.has_animation(nombre):
				if bool(g[2]) and not lib.has_animation(clave + "_mano" + lado):
					lib.add_animation(clave + "_mano" + lado, lib.get_animation(nombre))
				lib.remove_animation(nombre)
			lib.add_animation(nombre, a)
