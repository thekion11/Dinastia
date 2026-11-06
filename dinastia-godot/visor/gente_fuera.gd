class_name GenteFuera
extends RefCounted
## ULTRA BAJA Y BAJA SIN LA GENTE DE FUERA DEL CAMPO (6-11-2026, meta de ULTRA BAJA < 130 llamadas de dibujo; decisión del dueño: se pueden
## recortar cosas visibles en esos dos niveles si se dice). Esconde todo esqueleto que no sea de un jugador o árbitro en juego: suplentes sentados,
## cuerpo técnico, camarógrafos, recogepelotas, mascota… (37 en el estadio de prueba). Medido con `medir_partido -- minimo` (SIN_GENTE_FUERA):
## 279 → 249 llamadas de dibujo, 378 k → 334 k triángulos, 331 → 300 objetos. Los cambios no se ven afectados: el que entra se crea nuevo con
## `spawn_team`. En MEDIA y más nada cambia. Se aplica una vez, al sacar a los 22.
static func aplica(nivel: int) -> bool:
	return nivel <= Calidad.BAJA

static func ocultar(vista: Node, en_campo: Array) -> int:
	var propios := {}
	for f: Dictionary in en_campo:
		if f.get("node") != null:
			propios[f["node"]] = true
	var ocultos := 0
	for esq in vista.find_children("*", "Skeleton3D", true, false):
		var x: Node = esq
		var es_campo := false
		while x != null and x != vista:
			if propios.has(x):
				es_campo = true
				break
			x = x.get_parent()
		if not es_campo:
			(esq as Node3D).visible = false
			ocultos += 1
	return ocultos
