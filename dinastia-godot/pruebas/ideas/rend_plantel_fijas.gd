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
	## Plantel vacío: no quedan filas fijas colgando.
	var vacio := Club.new()
	_pintar(lista, vacio, m)
	_comprobar(lista.get_child_count() == 1, "con el plantel vacío solo queda el aviso (%d hijos)" % lista.get_child_count())
	_pintar(lista, c, m)
	_comprobar(lista.get_child_count() == n1, "y al volver a tener plantel se rehace entero (%d)" % lista.get_child_count())
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
