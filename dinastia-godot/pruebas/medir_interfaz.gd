extends Node
## COSTE DE REPINTAR LA INTERFAZ (bucle de optimización, 13-10-2026): carga una
## partida, y cronometra `_refrescar()` (lo que ocurre al avanzar una semana)
## en la portada y tras visitar varias pestañas. Sin gráfica es solo CPU de
## crear y colocar controles.
##   godot --headless --path . res://pruebas/medir_interfaz.tscn
var _p: Node
var _n := 0

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _medir(que: String, veces := 5) -> void:
	var t0 := Time.get_ticks_usec()
	for i in veces:
		_p.call("_refrescar")
	print("MEDIDA %-28s %.1f ms por repintado" % [que, (Time.get_ticks_usec() - t0) / 1000.0 / veces])

func _pieza(nombre: String, f: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	for i in 5:
		f.call()
	print("PIEZA %-28s %.1f ms" % [nombre, (Time.get_ticks_usec() - t0) / 5000.0])

func _process(_d: float) -> void:
	_n += 1
	if _n == 5:
		var m := Mundo.new()
		m.generar(["CHI", "ARG"], 4711)
		m.tomar_el_mando(m.ligas[0].clubes[0].id)
		_p.set("mundo", m)
		_p.call("_refrescar")
	if _n == 10:
		_medir("portada (tras iniciar)")
		for i in 6:
			_p.call("avanzar_semana_ui") if _p.has_method("avanzar_semana_ui") else null
	if _n == 20:
		_medir("repintado en caliente")
		var c: Club = _p.mundo.mi_club()
		var liga: Liga = _p.call("_liga_de", c)
		_pieza("PanelObjetivos.refrescar", func() -> void: _p.get("_panel_obj").refrescar())
		_pieza("escudo cabecera", func() -> void: _p.call("_escudo", c, 44).queue_free())
		_pieza("TablaCompeticion.pintar", func() -> void:
			TablaCompeticion.pintar(_p.get("_lista_tabla"), _p.mundo, liga, c, {"suave": Color.GRAY, "texto": Color.WHITE, "acento": Color.GREEN, "verde": Color.GREEN, "rojo": Color.RED, "oro": Color.YELLOW, "escala": 1.0}))
		_pieza("_pintar_plantel", func() -> void: _p.get("_ui_plantel")._pintar_plantel(c))
		_pieza("_pintar_inicio", func() -> void: _p.get("_ui_legado")._pintar_inicio(c))
		_pieza("_pintar_despacho", func() -> void: _p.get("_ui_despacho")._pintar_despacho())
		_pieza("_ver_ficha", func() -> void: _p.call("_ver_ficha", _p.call("_jugador_de_la_semana", c)))
		_pieza("_traducir_pantalla", func() -> void: _p.call("_traducir_pantalla", _p))
		_pieza("_pintar_dias", func() -> void: _p.call("_pintar_dias"))
		_pieza("_actualizar_badges", func() -> void: _p.call("_actualizar_badges"))
		_pieza("panel_mercado", func() -> void: _p.get("_panel_mercado").inicializar(_p.mundo, {"acento": Color.GREEN, "texto": Color.WHITE, "suave": Color.GRAY, "verde": Color.GREEN, "rojo": Color.RED, "oro": Color.YELLOW}, null) if _p.get("_panel_mercado") != null else null)
		_pieza("_aplicar_tema", func() -> void: _p.call("_aplicar_tema"))
		_pieza("_pintar_pendientes", func() -> void: _p.call("_pintar_pendientes") if _p.has_method("_pintar_pendientes") else null)
		get_tree().quit()
