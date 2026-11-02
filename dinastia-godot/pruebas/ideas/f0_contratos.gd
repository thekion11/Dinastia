extends BaseIdea
## f0 · EL CONTRATO DE LAS PANTALLAS (fase 0, plan §7.2; 31-10-2026): todas las pantallas del menú central
## son `PantallaBase`, declaran sus secciones y cada sección se abre por `abrir()` sin errores; `cerrar()`
## emite `cerrada`; una sección que no existe devuelve false (y no tumba nada).

func _probar() -> void:
	_titulo("f0: contrato abrir(contexto) / cerrar() / señal en las pantallas")
	var m := _mundo(3101)
	PedidoPartida.mundo_pregenerado = m
	var pr: Principal = (load("res://escenas/principal.tscn") as PackedScene).instantiate()
	add_child(pr)
	var pantallas := ["_ui_plantel", "_ui_ficha", "_ui_despacho", "_ui_club_vida", "_ui_club_estadio", "_ui_cantera", "_ui_legado",
		"_ui_ciudad", "_ui_editor", "_ui_opciones", "_ui_ajustes", "_ui_identidad", "_ui_gente", "_ui_finanzas", "_ui_elegir_club"]
	var sin_contrato: Array[String] = []
	var fallidas: Array[String] = []
	var n := 0
	for nombre: String in pantallas:
		var pa: Variant = pr.get(nombre)
		if not (pa is PantallaBase) or (pa as PantallaBase).secciones().is_empty():
			sin_contrato.append(nombre)
			continue
		for sec: String in (pa as PantallaBase).secciones():
			if sec == "elegir_club":
				continue   ## abre una ventana modal: la prueba su propio recorrido
			if not (pa as PantallaBase).abrir(sec, {"club": m.mi_club()}):
				fallidas.append("%s/%s" % [nombre, sec])
			n += 1
	_comprobar(sin_contrato.is_empty(), "las 15 pantallas del menú central cumplen el contrato %s" % [sin_contrato])
	_comprobar(fallidas.is_empty() and n >= 30, "%d secciones se abren por `abrir()` %s" % [n, fallidas])
	var cerrada := [false]
	pr._ui_plantel.cerrada.connect(func() -> void: cerrada[0] = true)
	pr._ui_plantel.cerrar()
	_comprobar(cerrada[0], "cerrar() emite la señal `cerrada`")
	_comprobar(not pr._ui_plantel.abrir("no_existe"), "una sección que no existe devuelve false sin romper nada")
	pr.queue_free()
	PedidoPartida.mundo_pregenerado = null
