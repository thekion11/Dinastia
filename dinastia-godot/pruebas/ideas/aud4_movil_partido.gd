extends BaseIdea
## A4-INT · los MENÚS DEL PARTIDO en el móvil (2400×1080 y 1280×720 a 400 ppp; castellano, alemán y polaco): la pantalla del partido en vivo (inicio, primer tiempo, descanso, final), el informe del rival y el resumen:
## sin botones de menos de 7 mm, sin controles fuera de la ventana y sin textos recortados que no deban.
var _p: Principal

func _frames(n: int = 2) -> void:
	for i in n:
		await get_tree().process_frame

func _probar() -> void:
	_titulo("AUDITORÍA 4 · INTERFAZ · menús del partido en el móvil")
	_respaldar_user()
	var idioma_antes := Idiomas.idioma
	var m := _mundo(20261104)
	PedidoPartida.mundo_pregenerado = m
	for ventana: Vector2i in [Vector2i(2400, 1080), Vector2i(1280, 720)]:
		for idi: String in ["es", "de", "pl"]:
			AyudaMovil.poner(ventana, get_window())
			Idiomas.idioma = idi
			_p = load("res://escenas/principal.tscn").instantiate()
			add_child(_p)
			await _frames(8)
			for t in get_tree().root.find_children("*", "Tutorial", true, false):
				(t as Tutorial)._terminar(false)
			CapasTutorial.poner_activas(false)
			_p._autoguardado = false
			var alto := EscalaMovil.alto_toque(_p)
			var par := m.proximo_partido()
			var partido := Partido.new(par[1], par[0])
			var rival: Club = par[1] if par[0] == m.mi_club() else par[0]
			var inf := InformeRival.mostrar(_p, partido, m.mi_club(), m.liga_de(rival), m)
			await _frames(10)
			var etapa0 := "%dx%d %s" % [ventana.x, ventana.y, idi]
			_revisar_pantalla(etapa0 + " informe del rival", inf, alto)
			inf.queue_free()
			await _frames(3)
			var vivo := PartidoVivo.new()
			vivo.con_3d = false
			vivo.set_anchors_preset(Control.PRESET_FULL_RECT)
			_p.add_child(vivo)
			vivo.abrir(partido, m.mi_club(), m.vestuario, false, m.roles)
			await _frames(6)
			var etapa := "%dx%d %s" % [ventana.x, ventana.y, idi]
			_revisar(etapa + " inicio", _p, alto, vivo)
			for cj in vivo.find_children("*", "CajonAjustes", true, false):
				(cj as CajonAjustes).abrir(false)
				await _frames(8)
				_revisar_pantalla(etapa + " pausa/ajustes (cajón)", cj as Control, alto)
				(cj as CajonAjustes).cerrar(false)
				await _frames(4)
			for i in 30:
				partido.simular_minuto()
			await _frames(6)
			_revisar(etapa + " min 30", _p, alto, vivo)
			while partido.minuto < 46 and not partido.terminado_ya:
				partido.simular_minuto()
			await _frames(8)
			_revisar(etapa + " descanso", _p, alto, vivo)
			while not partido.terminado_ya:
				partido.simular_minuto()
			await _frames(10)
			_revisar(etapa + " final", _p, alto, vivo)
			var res := ResumenPartido.mostrar(_p, partido, m.mi_club(), false, false)
			await _frames(12)
			_revisar_pantalla(etapa + " resumen del partido", res, alto)
			## LA SALA DEL VAR (la revisión, con su rótulo y la decisión) sobre un campo mínimo.
			var vc := SubViewportContainer.new()
			vc.set_anchors_preset(Control.PRESET_FULL_RECT)
			vc.stretch = true
			_p.add_child(vc)
			var vp := SubViewport.new()
			vp.size = Vector2i(1600, 900)
			vc.add_child(vp)
			var mundo3d := Node3D.new()
			vp.add_child(mundo3d)
			var cam := Camera3D.new()
			cam.position = Vector3(30, 20, 30)
			mundo3d.add_child(cam)
			cam.look_at(Vector3(0, 0, 30), Vector3.UP)
			var sala := SalaVAR.abrir(_p, mundo3d.get_world_3d(), Vector3(0, 0, 31), 67, Idiomas.t("Revisión del gol: posible fuera de juego"), false)
			var peor: Array[String] = []
			for k in 8:
				await get_tree().create_timer(0.8).timeout
				peor.append_array(AyudaMovil.problemas(sala, alto).filter(func(x: String) -> bool: return not x.begins_with("cortado")))
			_comprobar(peor.is_empty(), "%s sala del VAR: toques/fuera de pantalla: %d %s" % [etapa, peor.size(), str(peor.slice(0, 3))])
			_p.queue_free()
			await _frames(4)
			AyudaMovil.quitar(get_window())
	Idiomas.idioma = idioma_antes
	_restaurar_user()

func _revisar(etapa: String, raiz: Node, alto: float, vivo: Control) -> void:
	var botones := vivo.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return (b as Control).is_visible_in_tree()).size()
	_comprobar(botones >= 4, "%s: la pantalla del partido se ve (%d botones visibles, tamaño %s)" % [etapa, botones, str(vivo.size)])
	var pr := AyudaMovil.problemas(raiz, alto)
	var tactiles := pr.filter(func(s: String) -> bool: return s.begins_with("toque") or s.begins_with("botón fuera") or s.begins_with("botón por debajo") or s.begins_with("texto fuera") or s.begins_with("texto por debajo"))
	_comprobar(tactiles.is_empty(), "%s: toques/fuera de pantalla: %d %s" % [etapa, tactiles.size(), str(tactiles.slice(0, 4))])
	var cortados := pr.filter(func(s: String) -> bool: return s.begins_with("cortado"))
	_linea("      %s: %d textos recortados %s" % [etapa, cortados.size(), str(cortados.slice(0, 3))])

func _revisar_pantalla(etapa: String, pantalla: Control, alto: float) -> void:
	var botones := pantalla.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return (b as Control).is_visible_in_tree()).size()
	var pr := AyudaMovil.problemas(pantalla, alto)
	var graves := pr.filter(func(x: String) -> bool: return x.begins_with("toque") or x.begins_with("botón fuera") or x.begins_with("botón por debajo") or x.begins_with("texto fuera") or x.begins_with("texto por debajo"))
	_comprobar(botones >= 1 and graves.is_empty(), "%s: %d botones, toques/fuera de pantalla: %d %s" % [etapa, botones, graves.size(), str(graves.slice(0, 4))])
	var cortados := pr.filter(func(x: String) -> bool: return x.begins_with("cortado"))
	_linea("      %s: %d textos recortados %s" % [etapa, cortados.size(), str(cortados.slice(0, 3))])
