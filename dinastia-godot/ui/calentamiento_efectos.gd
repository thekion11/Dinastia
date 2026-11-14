class_name CalentamientoEfectos
extends RefCounted
## CALENTAMIENTO DE EFECTOS DEL PARTIDO (13-11-2026, orden del dueño: tirones en el teléfono). En GLES3 móvil (y en Mesa) el driver COMPILA el sombreador la primera vez que algo se
## dibuja: el primer gol (confeti, bengalas, banderas) cuesta un tirón de ~130 ms que se nota justo en el momento más importante. Aquí cada efecto se dibuja UNA vez antes de que haga
## falta, 60 m POR DEBAJO del campo (el césped lo tapa: ningún píxel cambia) y con vida corta; se borra solo. Es código puro: no toca `Azar` ni la simulación.
## Va detrás de `activo` (encendido: medido en Mesa, el primer lanzamiento pasa de +130/+520 ms a sin pico y no cambia ningún píxel; falta confirmarlo en un teléfono. `CALENTAR_EFECTOS=0` lo apaga).
static var activo := true
const BAJO := 60.0   ## metros bajo el campo
static var _guardados: Array = []   ## los recursos del calentamiento SE QUEDAN: al borrarse el efecto se liberarían (con ellos el programa de sombreado) y el primer gol real volvería a pagarlos

static func encendido() -> bool:
	return activo and OS.get_environment("CALENTAR_EFECTOS") != "0"

## Al montar el partido (jugable o visor del estadio).
static func al_montar(raiz: Node3D) -> void:
	if encendido():
		calentar(raiz)

## Dibuja una vez, fuera de la vista, lo que luego aparece en el partido (los pasos se suman en `docs/04_auditorias/rendimiento_120fps.md`).
static func calentar(raiz: Node3D) -> void:
	## UNA sola vez por proceso: los recursos guardados ya mantienen el sombreado compilado; repetirlo en cada partido acumulaba ~33 objetos por partido (auditoría 4: fugas en 24 partidos).
	if raiz == null or not _guardados.is_empty() or not FestejoGrada.activo():
		return
	var c1 := Color(0.85, 0.12, 0.12)
	var c2 := Color(0.95, 0.95, 0.95)
	## Confeti y bengalas (el motivo «calentamiento» no pasa por el banquillo ni por las banderas del gol).
	var f := FestejoGrada.lanzar(raiz, c1, c2, "calentamiento", 0.3)
	if f != null:
		for p in f.get_children():
			if p is Node3D:
				(p as Node3D).position.y -= BAJO
		## Con su caja de visibilidad normal quedarían FUERA del encuadre (60 m bajo el campo) y el motor ni los actualizaría ni los dibujaría: se les da una caja enorme.
		for p in f.find_children("*", "GPUParticles3D", true, false):
			(p as GPUParticles3D).visibility_aabb = AABB(Vector3(-150, -150, -150), Vector3(300, 300, 300))
	## Banderas grandes del gol, en un solo sitio bajo el campo.
	var b := BanderasGrada.lanzar(raiz, c1, c2, [Vector3(0, -BAJO, 0)], 0.3)
	for n in [f, b]:
		if n != null:
			_guardar(n)

## Guarda los recursos (materiales, mallas) de `n` y de sus hijos.
static func _guardar(n: Node) -> void:
	for h in [n] + n.find_children("*", "", true, false):
		if h is GPUParticles3D:
			var p := h as GPUParticles3D
			_guardados.append_array([p.process_material, p.draw_pass_1, p.material_override])
			if p.draw_pass_1 != null:
				for i in p.draw_pass_1.get_surface_count():
					_guardados.append(p.draw_pass_1.surface_get_material(i))
		elif h is MeshInstance3D:
			var mi := h as MeshInstance3D
			_guardados.append_array([mi.mesh, mi.material_override])
			if mi.mesh != null:
				for i in mi.mesh.get_surface_count():
					_guardados.append(mi.get_active_material(i))
