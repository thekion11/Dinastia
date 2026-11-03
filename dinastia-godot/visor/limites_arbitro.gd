class_name LimitesArbitro
extends RefCounted
## P3 (3-11): LÍMITES FÍSICOS DE LOS ÁRBITROS, de verdad. Antes solo estaba limitado a dónde QUERÍAN ir (`MotorJugable._mover_arbitros`), no a dónde
## PODÍAN estar: el árbitro atravesaba a los jugadores. Ahora, cada fotograma:
##  · dentro del recinto (el árbitro de campo, dentro del césped; los jueces de línea, a un paso de la banda);
##  · el árbitro de campo no entra en las áreas chicas ni en las porterías (5,5 m × 18,3 m + la red);
##  · los jueces de línea nunca pisan el césped de juego: siempre por fuera de la banda, cada uno de su lado;
##  · nadie atraviesa a un jugador: si un cuerpo está a menos de `SEPARACION`, el árbitro cede y se aparta por la línea que los une.
## Se prueba en `pruebas/ideas/p3_arbitros.tscn` (un partido de 8 minutos de IA contra IA) y a ojo en la arena (`ARENA=arbitro` / `partido`).

const SEPARACION := 1.0
const AREA_CHICA_Z := 6.0     ## m desde la línea de fondo
const AREA_CHICA_X := 9.5     ## medio ancho del área chica con margen

## Dónde esperan los árbitros en la tanda de penales: el principal al borde del área chica y un asistente en la línea de gol (fuera del plano
## del lanzador), el otro en la mitad.
static func objetivo_tanda(id: String) -> Vector3:
	match id:
		"arbitro":
			return Vector3(-7.5, 0, MotorJugable.LARGO - 12.0)
		"linea_a":
			return Vector3(-36.5, 0, 0.0)
	return Vector3(MotorJugable.PALO + 2.2, 0, MotorJugable.LARGO - 0.3)

static func limitar(jugadores: Array, id: String, p: Vector3) -> Vector3:
	p.y = 0.0
	if id == "arbitro":
		p.x = clampf(p.x, -MotorJugable.ANCHO + 0.5, MotorJugable.ANCHO - 0.5)
		p.z = clampf(p.z, -MotorJugable.LARGO + 0.5, MotorJugable.LARGO - 0.5)
		if absf(p.x) < AREA_CHICA_X and absf(p.z) > MotorJugable.LARGO - AREA_CHICA_Z:
			p.z = signf(p.z) * (MotorJugable.LARGO - AREA_CHICA_Z)
	else:
		p.x = (-1.0 if id == "linea_a" else 1.0) * clampf(absf(p.x), MotorJugable.ANCHO + 0.8, MotorJugable.ANCHO + 4.0)
		p.z = clampf(p.z, -MotorJugable.LARGO - 1.5, MotorJugable.LARGO + 1.5)
	for q: Dictionary in jugadores:
		var n := q.get("node") as Node3D
		if not is_instance_valid(n):
			continue
		var d := Vector2(p.x - n.position.x, p.z - n.position.z)
		var dist := d.length()
		if dist < SEPARACION:
			var dir := d / dist if dist > 0.001 else Vector2(1, 0)
			p.x += dir.x * (SEPARACION - dist)
			p.z += dir.y * (SEPARACION - dist)
	return p
