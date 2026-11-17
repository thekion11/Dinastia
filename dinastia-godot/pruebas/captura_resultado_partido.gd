extends Node
## CAPTURAS del resultado, los momentos y el popup «Partido jugado» (avance por días), con partidos reales de clubes de países distintos:
##   herramientas/captura.sh res://pruebas/captura_resultado_partido.tscn --compat      Salida: pruebas/capturas/resultado_<país>_<pantalla>.png

func _foto(nombre: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://pruebas/capturas/resultado_%s.png" % nombre))

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/capturas"))
	for cfg: Array in [["CHI", 3], ["ESP", 5], ["BRA", 7]]:
		var m := Mundo.new()
		var ps: Array[String] = [String(cfg[0])]
		m.generar(ps, 40 + int(cfg[1]))
		var liga: Liga = m.ligas[0]
		m.tomar_el_mando(liga.clubes[int(cfg[1])].id)
		var mio := m.mi_club()
		var rival: Club = liga.clubes[(int(cfg[1]) + 6) % liga.clubes.size()]
		var p := Partido.new(mio, rival)
		MomentosPartido.registrar(p)
		p.preparar()
		while not p.terminado_ya:
			p.simular_minuto()
		var r := ResultadoPartido.mostrar(self, p, mio)
		await get_tree().create_timer(0.8).timeout
		await _foto("%s_resultado" % cfg[0])
		r.queue_free()
		var mo := MomentosPartido.mostrar(self, p, mio, "todas")
		await get_tree().create_timer(0.8).timeout
		await _foto("%s_momentos" % cfg[0])
		mo.queue_free()
		if cfg[0] == "CHI":
			var base := Control.new()
			add_child(base)
			var b := Button.new()
			b.text = "PARTIDO JUGADO ▲  %d-%d" % [p.goles_local, p.goles_visita]
			b.position = Vector2(1200, 960)
			b.size = Vector2(380, 60)
			base.add_child(b)
			var pop := PopupPartidoJugado.abrir(base, b)
			(pop._sub as Control).visible = true
			pop.reset_size()
			pop.position = Vector2(b.global_position.x + b.size.x - pop.size.x, b.global_position.y - pop.size.y - 8)
			await get_tree().create_timer(0.4).timeout
			await _foto("popup")
			base.queue_free()
	get_tree().quit()
