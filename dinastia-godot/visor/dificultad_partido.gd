class_name DificultadPartido
extends RefCounted
## LA DIFICULTAD DE LA CPU EN EL PARTIDO JUGABLE DE LA CARRERA (caza de fallos, 4-11-2026). La dificultad (8 categorías, orden 14 del dueño) solo la aplicaba el
## partido en que manejas a todo un equipo (`VistaEstadio`: `equipo_cpu()` salía de `control_equipo`); en el partido de la carrera y «jugar partido» (un solo jugador)
## `equipo_cpu()` era -1 y el nivel elegido no hacía NADA. Ahora el equipo RIVAL es la CPU con el nivel guardado en los ajustes (el mismo que se cicla en el estadio).
## Debutante (la normal) no cambia nada: es el motor calibrado de siempre.

static func aplicar(motor: MotorJugable, es_local_usuario: bool) -> void:
	if motor == null:
		return
	motor.equipo_cpu_fijo = 1 if es_local_usuario else 0
	motor.dificultad_cpu = VistaEstadio.dificultad_cpu_guardada()
	motor.fijar_dificultad(motor.dificultad_cpu)
