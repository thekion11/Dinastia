class_name OcultarEstadioDentro
extends RefCounted
## DENTRO DEL EDIFICIO DEL CLUB, EL ESTADIO DE FUERA NO SE DIBUJA (10-11-2026, rendimiento en móvil). Medido con `pruebas/medir_club.tscn` (ULTRA BAJA, Compatibilidad, CHI): a pie por las plantas
## -2, -1, 1 y 2 el club pedía ~850 llamadas y 1,1 M de triángulos porque la cámara (sin oclusión) dibujaba también las gradas, la hinchada, las torres de focos y el entorno que quedan DETRÁS de las
## paredes de la sala. Sin ellos: ~340-370 llamadas y ~130 k triángulos (fotograma relativo −60 %), con la sala idéntica (capturas antes/después en el informe).
## Se ocultan los hijos de primer nivel del estadio (`_raiz3d`) que no son luces, cámara, el edificio (`TunelVestuario`), la calle (`Exterior`) ni la fachada (`Fachada`): lo único que se ve por la
## ventana trasera. Solo en las plantas distintas de la 0 (la 0 tiene el túnel y el campo a la vista). Se guarda lo que estaba visible antes y se devuelve tal cual al salir al campo o del recorrido.

const CONSERVAR := ["TunelVestuario", "Exterior", "Fachada"]
const META := "estadio_oculto_dentro"

## Llamar cada vez que se refresca la zona del recorrido (barato: solo actúa al entrar o salir de las plantas interiores).
static func actualizar(explorador: Node3D, planta: int) -> void:
	var dentro := planta != 0
	var ocultos: Dictionary = explorador.get_meta(META, {})
	if dentro == not ocultos.is_empty():
		return
	if dentro:
		var raiz := explorador.get_parent()
		if raiz == null:
			return
		for h in raiz.get_children():
			if not (h is Node3D) or h is Light3D or h is Camera3D or h == explorador or String(h.name) in CONSERVAR:
				continue
			ocultos[h] = (h as Node3D).visible
			(h as Node3D).visible = false
		explorador.set_meta(META, ocultos)
	else:
		devolver(explorador)

## Deja el estadio como estaba (también al cerrar el recorrido).
static func devolver(explorador: Node3D) -> void:
	var ocultos: Dictionary = explorador.get_meta(META, {})
	for h: Variant in ocultos:
		if is_instance_valid(h):
			(h as Node3D).visible = bool(ocultos[h])
	explorador.set_meta(META, {})
