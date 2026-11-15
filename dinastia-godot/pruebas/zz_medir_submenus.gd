extends Node
## CUÁNTO TARDA ENTRAR EN CADA SUBMENÚ (15-11-2026, meta del dueño: que los menús no tarden). Con pantalla (xvfb + opengl3):
##   xvfb-run -a godot --rendering-driver opengl3 --path . res://pruebas/zz_medir_submenus.tscn
## MENUS=plantel,competiciones (por defecto, cuatro), REPOSO=1 (antes, 3 s de precarga como en el juego), PAIS=ESP CLUB=6.
## Por submenú: «elegir» (armar y refrescar) y «hasta verse» (hasta el primer fotograma dibujado). La primera entrada es la cara.
var _p: Principal

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 5:
		await get_tree().process_frame
	var m := Mundo.new()
	m.generar([OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "ESP"], 4711)
	m.tomar_el_mando(m.ligas[0].clubes[int(OS.get_environment("CLUB") if OS.get_environment("CLUB") != "" else "6") % m.ligas[0].clubes.size()].id)
	for s in 4:
		m.avanzar_semana()
	_p.set("mundo", m)
	_p.call("_refrescar")
	for i in 30:
		await get_tree().process_frame
	if OS.get_environment("LOGROS") != "":   ## LOGROS=1: las piezas de la pestaña de logros
		var lg := _p.mundo.logros
		for r in 2:
			var q0 := Time.get_ticks_usec(); lg.revisar_largos(); var q1 := Time.get_ticks_usec(); lg.catalogo_largo(); var q2 := Time.get_ticks_usec()
			print("LARGOS r%d revisar %d · catálogo %d ms" % [r, (q1 - q0) / 1000, (q2 - q1) / 1000])
		var a := Time.get_ticks_usec(); Logros.perfil_leer(); var b := Time.get_ticks_usec()
		var cat := lg.catalogo(); var c := Time.get_ticks_usec()
		var caja := VBoxContainer.new(); add_child(caja)
		ListaLogrosLargo.pintar(caja, lg, _p._texto); var d := Time.get_ticks_usec()
		lg.goleadores_historicos(5); var e := Time.get_ticks_usec()
		_p._pantalla_perezosa("club_vida"); var f := Time.get_ticks_usec()
		_p._pantalla_perezosa("club_vida")._pintar_logros(); var g := Time.get_ticks_usec()
		print("LOGROS perfil %d · catálogo %d (%d) · largo plazo %d · goleadores %d · crear pantalla %d · pintar todo %d ms" % [(b - a) / 1000, (c - b) / 1000, cat.size(), (d - c) / 1000, (e - d) / 1000, (f - e) / 1000, (g - f) / 1000])
	if OS.get_environment("ESCUDO") != "":   ## ESCUDO=1: cuánto cuesta pintar un escudo nuevo
		var t0 := Time.get_ticks_usec()
		for c: Club in _p.mundo.ligas[0].clubes:
			Escudo.textura(c, 20)
		print("ESCUDO %d clubes a 20 px: %d ms" % [_p.mundo.ligas[0].clubes.size(), (Time.get_ticks_usec() - t0) / 1000])
	if OS.get_environment("REPOSO") != "":
		CalentarLetras.lanzar(_p)
		for k in 16:
			MenuGuardado.precargar(_p)
			await get_tree().create_timer(0.5).timeout
	var menus := (OS.get_environment("MENUS") if OS.get_environment("MENUS") != "" else "plantel,competiciones,dinero,historia").split(",")
	for id: String in menus:
		var pm: PantallaMenu = _p._menu_lateral.abrir_menu(id)
		for i in 5:
			await get_tree().process_frame
		var subs: Array = pm._menu["subs"]
		for k in subs.size():
			if (subs[k] as Dictionary).has("accion"):
				continue
			var t := Time.get_ticks_usec()
			pm.elegir(k)
			var t1 := Time.get_ticks_usec()
			await RenderingServer.frame_post_draw
			print("SUBMENU %s/%s: elegir %d ms · hasta verse %d ms" % [id, String(subs[k].get("secc", subs[k].get("label", "?"))), (t1 - t) / 1000, (Time.get_ticks_usec() - t) / 1000])
			for i in 8:
				await get_tree().process_frame
		pm.cerrar()
		for i in 20:
			await get_tree().process_frame
	get_tree().quit()
