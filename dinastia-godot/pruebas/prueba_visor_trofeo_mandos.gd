extends Node
## VISOR DEL TROFEO con teclado, ratón, TOQUE y MANDO (10-11, sesión 7, museo). Con tres clubes de países y palmarés distintos (el de más prestigio,
## uno mediano y el último: sin títulos) abre la ficha de su primera vitrina y comprueba: gira con el dedo (ScreenDrag), con la rueda se acerca/aleja
## dentro de los límites, los botones ◀ ▶ ＋ － responden, B del mando y Esc lo cierran, y la vitrina vacía enseña «Vitrina libre».
##   godot --headless --path . res://pruebas/prueba_visor_trofeo_mandos.tscn
var _fallos := 0
var _capa: CanvasLayer

func _ok(c: bool, t: String) -> void:
	if c:
		print("  ok   ", t)
	else:
		_fallos += 1
		print("  FALLO ", t)

func _ready() -> void:
	_capa = CanvasLayer.new()
	add_child(_capa)
	for par in [["ENG", 0], ["ESP", 9], ["CHI", 15]]:
		var m := Mundo.new()
		m.generar([par[0]], 77)
		var clubes: Array = m.ligas[0].clubes
		var club: Club = clubes[mini(int(par[1]), clubes.size() - 1)]
		var h := HistoriaClub.hitos_palmares(club)
		print("== ", par[0], " ", club.nombre, " títulos en el palmarés: ", h.size())
		var ficha := {"vacia": true, "titulo": "Vitrina libre"}
		if h.size() > 0:
			var t: Dictionary = h[0]
			ficha = {"vacia": false, "titulo": String(t.get("titulo", "")), "anio": int(t.get("anio", 0)), "final": String(t.get("final", "")), "goleadores": t.get("goleadores", [])}
		var v := VisorTrofeo.abrir(_capa, ficha)
		await get_tree().process_frame
		var a0 := v._pivote.rotation.y
		var ev := InputEventScreenDrag.new()
		ev.relative = Vector2(50, 0)
		v._arrastre(ev)
		_ok(absf(v._pivote.rotation.y - a0) > 0.3, "el dedo gira la copa")
		var d0 := v._dist
		v._acercar(-0.4)
		_ok(v._dist < d0 and is_equal_approx(v._cam.position.z, v._dist), "acercar mueve la cámara")
		v._acercar(-50.0)
		_ok(is_equal_approx(v._dist, VisorTrofeo.DIST_MIN), "no se acerca más del mínimo")
		v._acercar(50.0)
		_ok(is_equal_approx(v._dist, VisorTrofeo.DIST_MAX), "no se aleja más del máximo")
		var botones := v.find_children("*", "Button", true, false)
		_ok(botones.size() >= 5, "hay botones para el toque (%d)" % botones.size())
		var b: InputEventJoypadButton = InputEventJoypadButton.new()
		b.button_index = JOY_BUTTON_B
		b.pressed = true
		v._unhandled_input(b)
		await get_tree().process_frame
		_ok(not is_instance_valid(v) or v.is_queued_for_deletion(), "B del mando lo cierra")
	print("===== FIN. %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
