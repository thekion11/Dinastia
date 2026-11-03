class_name PendienteClub
extends RefCounted
## EL CONTEXTO DEL EDIFICIO DEL CLUB, PENDIENTE (3-11-2026, memoria del menú). El menú avisa del mundo y del club en cada refresco; hasta hoy llamaba a
## `EdificioClub.fijar_ctx`, y eso compilaba el edificio, la galería, el museo y el recorrido (~17 MB) al abrir el juego aunque no se entre al edificio.
## Ahora solo se anota aquí (sin dependencias, referencias débiles) y `EdificioClub` lo aplica la primera vez que alguien lee `ctx` o `mundo_ref`.
static var mundo_ref: WeakRef = null
static var club_ref: WeakRef = null

static func fijar(mundo: Mundo, club: Club) -> void:
	if mundo == null or club == null:
		return
	mundo_ref = weakref(mundo)
	club_ref = weakref(club)

static func limpiar() -> void:
	mundo_ref = null
	club_ref = null
