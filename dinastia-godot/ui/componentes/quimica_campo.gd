class_name QuimicaCampo
extends RefCounted
## Dibuja la QUÍMICA sobre el campo de la plantilla (`PlantillaPes`): una línea entre cada jugador y su vecino de la misma línea (ordenados de izquierda
## a derecha), verde si se entienden, amarilla si a medias y roja si no (`QuimicaLinea`). Va debajo de las caras (el padre se dibuja antes que los hijos).

## `campo`: el Control del campo; sus hijos Button son las fichas de `once`, en el mismo orden.
static func dibujar(campo: Control, once: Array, m: Mundo) -> void:
	var fichas: Array = campo.get_children().filter(func(n: Node) -> bool: return n is Button and not n.is_queued_for_deletion())
	var por_grupo := {}
	for i in mini(fichas.size(), once.size()):
		var j: Jugador = once[i]
		var g := PesosPuesto.grupo(j.pos_e)
		if g in ["DEF", "MED", "DEL"]:
			if not por_grupo.has(g):
				por_grupo[g] = []
			var b := fichas[i] as Control
			(por_grupo[g] as Array).append([j, b.position + b.size * 0.5 - Vector2(0, 8)])
	for g: String in por_grupo:
		var fila: Array = por_grupo[g]
		fila.sort_custom(func(x: Array, y: Array) -> bool: return (x[1] as Vector2).x < (y[1] as Vector2).x)
		for k in range(fila.size() - 1):
			var v := QuimicaLinea.par(m, fila[k][0], fila[k + 1][0])
			var c := QuimicaLinea.color(v)
			campo.draw_line(fila[k][1], fila[k + 1][1], Color(0, 0, 0, 0.45), 7.0)
			campo.draw_line(fila[k][1], fila[k + 1][1], Color(c, 0.9), 4.0)
