class_name LeagueAcciones
extends RefCounted
## MÁS VIDA EN EL PARTIDO (11-11-2026, fase 4d; tabla de la sesión 10 en `docs/04_auditorias/anim_acciones_por_momento.md`). Solo la usa
## `MotorLeague._anim`: cambia QUÉ clip se ve en un momento, nunca posiciones, velocidades ni reglas.
##  · FALTA LEVE: el que pierde un choque de hombros no siempre trastabilla igual: una de cada tres veces recibe el golpe en el pecho
##    (`Hit_Chest`, 0,33 s) o en la cabeza (`Hit_Head`, 0,43 s) de la UAL (CC0). El reparto sale del id del jugador y de cuántos
##    golpes lleva (determinista: el mismo partido repite lo mismo).
##  · CELEBRACIÓN DEL GOL (orden del líder, 11-11): 2 de cada 5 veces el «celebrar» del motor se sustituye por un baile o una alegría de
##    la base CMU (CC, `anims_cmu/cmu_uso.res`; solo los que se ven bien en `capturas_animaciones_2026-11-11/`: salsa en solitario,
##    alegría, risa y charleston), recortados a 6 s (los originales llegan a 15 s). Mismo reparto determinista por id.
## La disputa aérea de la tabla (`Jump_*`) NO se engancha aún: pide que el motor levante al jugador en el aire y hoy el cabezazo no
## despega a nadie (anotado en el plan §11).
static var activa := OS.get_environment("LS_ACCIONES") != "0"

const BIBLIOTECA_CMU := "res://assets/characters/quaternius/anims_cmu/cmu_uso.res"
const CELEBRACIONES_CMU := ["cmu_60_01", "cmu_60_02", "cmu_60_03", "cmu_60_04", "cmu_79_69", "cmu_79_70", "cmu_80_43", "cmu_93_03", "cmu_93_06"]
const MAX_CELEBRACION := 6.0

## El nombre de clip que se reproduce en lugar de `nombre` para el jugador `p` (o el mismo).
static func variante(p: Dictionary, nombre: String) -> String:
	if activa and nombre == "celebrar":
		return _celebracion(p, nombre)
	if not activa or not nombre.begins_with("duelo_empujado"):
		return nombre
	var n := int(p.get("ls_golpes", 0))
	p["ls_golpes"] = n + 1
	var turno := (String(p.get("id", "")).hash() + n) % 3
	if turno == 2:
		return nombre
	var clave := "golpe_pecho" if turno == 0 else "golpe_cabeza"
	var ap: AnimationPlayer = p.get("anim")
	var nodo: Node = p.get("node")
	if is_instance_valid(ap) and is_instance_valid(nodo) and AnimExtra.asegurar(ap, FutbolistaQ.esqueleto_de(nodo), clave):
		return clave
	return nombre

## Un baile o una alegría de CMU para el que celebra (o el mismo «celebrar»). Carga el clip una vez por biblioteca de animaciones.
static func _celebracion(p: Dictionary, nombre: String) -> String:
	var n := int(p.get("ls_celebra", 0))
	p["ls_celebra"] = n + 1
	var h := String(p.get("id", "")).hash() + n
	if h % 5 >= 2:
		return nombre
	var base := String(CELEBRACIONES_CMU[(h / 5) % CELEBRACIONES_CMU.size()])
	var clave := "ext_" + base
	var ap: AnimationPlayer = p.get("anim")
	if not is_instance_valid(ap) or not ap.has_animation("correr") or ap.get_animation("correr").get_track_count() == 0:
		return nombre
	if ap.has_animation(clave):
		return clave
	var lib := load(BIBLIOTECA_CMU) as AnimationLibrary
	if lib == null or not lib.has_animation(base):
		return nombre
	var a: Animation = lib.get_animation(base).duplicate(true)
	var prefijo := String(ap.get_animation("correr").track_get_path(0)).get_slice(":", 0)
	for i in a.get_track_count():
		a.track_set_path(i, NodePath("%s:%s" % [prefijo, str(a.track_get_path(i)).get_slice(":", 1)]))
	a.length = minf(a.length, MAX_CELEBRACION)
	a.loop_mode = Animation.LOOP_NONE
	ap.get_animation_library("").add_animation(clave, a)
	return clave
