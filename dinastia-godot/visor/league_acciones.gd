class_name LeagueAcciones
extends RefCounted
## MÁS VIDA EN EL PARTIDO (11-11-2026, fase 4d; tabla de la sesión 10 en `docs/04_auditorias/anim_acciones_por_momento.md`). Solo la usa
## `MotorLeague._anim`: cambia QUÉ clip se ve en un momento, nunca posiciones, velocidades ni reglas.
##  · FALTA LEVE: el que pierde un choque de hombros no siempre trastabilla igual: una de cada tres veces recibe el golpe en el pecho
##    (`Hit_Chest`, 0,33 s) o en la cabeza (`Hit_Head`, 0,43 s) de la UAL (CC0). El reparto sale del id del jugador y de cuántos
##    golpes lleva (determinista: el mismo partido repite lo mismo).
## La disputa aérea de la tabla (`Jump_*`) NO se engancha aún: pide que el motor levante al jugador en el aire y hoy el cabezazo no
## despega a nadie (anotado en el plan §11).
static var activa := OS.get_environment("LS_ACCIONES") != "0"

## El nombre de clip que se reproduce en lugar de `nombre` para el jugador `p` (o el mismo).
static func variante(p: Dictionary, nombre: String) -> String:
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
