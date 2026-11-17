class_name EscaparateFoco
extends RefCounted
## EL FOCO DEL MANDO EN EL ESCAPARATE (17-11-2026): con la disposición en mosaico, los vecinos de foco por defecto de Godot saltan a cualquier sitio. Aquí cada control enfocable de la capa
## (el «☰», las pestañas, los atajos, las tarjetas, los botones del pie) recibe como vecino de cada lado el más cercano EN ESA DIRECCIÓN (por el centro de su rectángulo): así el D-pad
## llega a todo y de forma predecible. Se llama con el diseño ya hecho (dos fotogramas después de pintar).

static func enfocables(raiz: Control) -> Array[Control]:
	var salida: Array[Control] = []
	for n in raiz.find_children("*", "Control", true, false):
		var c := n as Control
		if c.focus_mode == Control.FOCUS_ALL and c.is_visible_in_tree() and c.get_global_rect().size.x > 1.0 and not (c is LineEdit):
			salida.append(c)
	return salida

static func cablear(raiz: Control) -> void:
	var lista := enfocables(raiz)
	for a in lista:
		var ca := a.get_global_rect().get_center()
		var mejor := [null, null, null, null]   ## izquierda, derecha, arriba, abajo
		var coste := [1e12, 1e12, 1e12, 1e12]
		for b in lista:
			if b == a:
				continue
			var d := b.get_global_rect().get_center() - ca
			for k in 4:
				var eje := d.x if k < 2 else d.y
				var sentido := -1.0 if k % 2 == 0 else 1.0
				var p := eje * sentido
				if p < 4.0:
					continue
				var perp := absf(d.y if k < 2 else d.x)
				var ra := a.get_global_rect()
				var rb := b.get_global_rect()
				var cruza := (ra.position.y < rb.end.y and ra.end.y > rb.position.y) if k < 2 else (ra.position.x < rb.end.x and ra.end.x > rb.position.x)
				var c := p + perp * (1.0 if cruza else 4.0)
				if c < coste[k]:
					coste[k] = c
					mejor[k] = b
		var lados := [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]
		for k in 4:
			if mejor[k] != null:
				a.set_focus_neighbor(lados[k], a.get_path_to(mejor[k]))
