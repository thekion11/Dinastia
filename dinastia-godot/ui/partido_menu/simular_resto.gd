class_name SimularResto
extends RefCounted
## «SIMULAR EL RESTO» CON EL SIMULADOR CALIBRADO (17-11-2026, decisión de Auditoría). Antes lo jugaba C4 en piloto automático a toda velocidad y salían
## goleadas (8-0, 3-6); ahora lo que falta lo juega `Partido.simular_minuto` (el mismo simulador de la liga) desde el marcador, el minuto, las tarjetas,
## los cambios y los expulsados del momento: lo que pasó en el 3D se conserva tal cual. En la 1.ª parte para en el DESCANSO (allí el resumen deja seguir
## simulando, volver a jugar o hacer cambios); en la 2.ª, hasta el final. El camino viejo (C4) queda detrás de SIMULAR_CON_C4=1, para pruebas.
## Lo usan `VistaEstadio._simular_resto_motor` (marca el partido y cierra el 3D) y `PartidoVivo` al volver del 3D (`tras_3d`).

const META := "simular_ya"

static func usar_c4() -> bool:
	return OS.get_environment("SIMULAR_CON_C4") == "1"

## Simula lo que falta: hasta el 45 (si `hasta_descanso`) o hasta el final. El 3D ya no lleva el reloj.
static func simular(p: Partido, hasta_descanso: bool) -> void:
	p.motor_externo = false
	while not p.terminado_ya and (not hasta_descanso or p.minuto < 45):
		p.simular_minuto()

## Al volver del 3D: si se pidió «Simular el resto», se simula ya (la pantalla del partido sigue: descanso o final, como siempre).
static func tras_3d(vivo: Node) -> void:
	var p: Partido = vivo.get("partido")
	if p == null or not p.has_meta(META):
		return
	p.remove_meta(META)
	simular(p, p.has_meta("simulando_resto") and bool(p.get_meta("simulando_resto")))
	if vivo.has_method("_refrescar"):
		vivo.call("_refrescar")
