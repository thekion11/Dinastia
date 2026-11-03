extends BaseIdea
## PLANTEL: LAS FILAS DE FILTROS Y LA LEYENDA SE REUSAN (2-11, rendimiento). Llevan emojis (darles forma cuesta ~40 ms por repintado):
## se crean una vez y el repintado solo les cambia el texto. Esta prueba comprueba que no se duplican, que el orden es el de siempre
## y que los filtros siguen funcionando con los MISMOS botones.

func _pintar(lista: VBoxContainer, c: Club, m: Mundo) -> void:
	PanelPlantel.pintar(lista, c, m, "ovr", true, Color.GREEN, func(col: Color) -> Color: return col,
		func(g: GridContainer, j: Jugador, columnas: Array, _colores: Array) -> void:
			for i in columnas.size():
				var l := Label.new()
				l.text = String(columnas[i])
				g.add_child(l),
		func(_k: String) -> void: pass)

func _ready() -> void:
	await get_tree().process_frame
	_titulo("PLANTEL: FILAS FIJAS")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var c: Club = m.ligas[0].clubes[0]
	m.mi_club_id = c.id
	var lista := VBoxContainer.new()
	add_child(lista)
	_pintar(lista, c, m)
	var filtros := lista.get_child(1)
	var estado := lista.get_child(2)
	var n1 := lista.get_child_count()
	for i in 3:
		_pintar(lista, c, m)
	_comprobar(lista.get_child_count() == n1, "repintar no añade hijos (%d -> %d)" % [n1, lista.get_child_count()])
	_comprobar(lista.get_child(1) == filtros and lista.get_child(2) == estado, "las filas de filtros son las mismas de antes")
	_comprobar(lista.get_child(3) is GridContainer, "tras los filtros viene la rejilla")
	_comprobar(lista.get_child(lista.get_child_count() - 1) is Label and (lista.get_child(lista.get_child_count() - 1) as Label).text.contains("capitán"), "la leyenda queda la última")
	var filas_todos := (lista.get_child(3) as GridContainer).get_child_count()
	## Pulsar «Defensas»: el repintado usa los mismos botones y la rejilla cambia.
	var b_def := (filtros.get_child(2) as Button)
	b_def.pressed.emit()
	await get_tree().process_frame
	_comprobar(lista.get_child(1) == filtros and (filtros.get_child(2) as Button).button_pressed, "tras pulsar Defensas, el mismo botón queda encendido")
	var filas_def := (lista.get_child(3) as GridContainer).get_child_count()
	_comprobar(filas_def < filas_todos, "la rejilla se reduce a la línea elegida (%d -> %d celdas)" % [filas_todos, filas_def])
	_comprobar(not (filtros.get_child(0) as Button).button_pressed, "«Todos» se apaga")
	_comprobar(lista.get_child(lista.get_child_count() - 1) is Label, "y la leyenda sigue siendo la última")
	## FILAS DE JUGADOR REUSADAS: la misma fila sigue siendo el mismo nodo si no cambió nada; si cambia un dato, solo se rehace esa.
	(filtros.get_child(0) as Button).pressed.emit()   ## de nuevo «Todos»
	await get_tree().process_frame
	var antes: Array = (lista.get_child(3) as GridContainer).get_children()
	_pintar(lista, c, m)
	var despues: Array = (lista.get_child(3) as GridContainer).get_children()
	_comprobar(antes == despues, "repintar sin cambios deja las MISMAS %d celdas, en el mismo orden" % despues.size())
	var j0: Jugador = c.plantilla[0]
	j0.ovr += 1
	_pintar(lista, c, m)
	var tras: Array = (lista.get_child(3) as GridContainer).get_children()
	var iguales := 0
	for n: Node in antes:
		if tras.has(n):
			iguales += 1
	_comprobar(tras.size() == antes.size() and iguales == antes.size() - 6, "cambiar a un jugador rehace solo su fila (%d de %d celdas intactas)" % [iguales, antes.size()])
	j0.ovr -= 1
	## EL PLANIFICADOR: sus bloques se reusan mientras no cambie nada, sobreviven al repintado del plantel y se rehacen si pasa la semana.
	var texto := func(tam: int, col: Color) -> Label:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", tam)
		l.add_theme_color_override("font_color", col)
		return l
	PanelPlanificacion.pintar(lista, m, texto, Callable())
	var hijos_plan: Array = lista.get_children()
	_pintar(lista, c, m)
	PanelPlanificacion.pintar(lista, m, texto, Callable())
	var tras_plan: Array = lista.get_children()
	var plan_igual := true
	for n: Node in hijos_plan:
		if n.has_meta(PanelPlantel.META_AJENO) and not tras_plan.has(n):
			plan_igual = false
	_comprobar(plan_igual and tras_plan.size() == hijos_plan.size(), "el planificador conserva sus nodos al repintar el plantel y a sí mismo (%d hijos)" % tras_plan.size())
	m.semana += 1
	PanelPlanificacion.pintar(lista, m, texto, Callable())
	var cambia := false
	for n: Node in lista.get_children():
		if n.has_meta(PanelPlantel.META_AJENO) and not hijos_plan.has(n):
			cambia = true
	_comprobar(cambia and lista.get_child_count() == hijos_plan.size(), "al pasar la semana el planificador se rehace entero (%d hijos)" % lista.get_child_count())
	## Plantel vacío: no quedan filas fijas colgando.
	var vacio := Club.new()
	_pintar(lista, vacio, m)
	var sin_ajenos := 0
	for n: Node in lista.get_children():
		if not n.has_meta(PanelPlantel.META_AJENO):
			sin_ajenos += 1
	_comprobar(sin_ajenos == 1, "con el plantel vacío solo queda el aviso propio (%d hijos propios)" % sin_ajenos)
	_pintar(lista, c, m)
	sin_ajenos = 0
	for n: Node in lista.get_children():
		if not n.has_meta(PanelPlantel.META_AJENO):
			sin_ajenos += 1
	_comprobar(sin_ajenos == n1, "y al volver a tener plantel se rehace entero (%d)" % sin_ajenos)
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
