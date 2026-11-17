extends Node
## CAPTURAS del DESCANSO y del RESULTADO FINAL (17-11, `ResumenPartidoCine`), con tres partidos de tres países (en España con pases, como si se hubiera
## jugado en el césped):  herramientas/captura.sh res://pruebas/captura_resumen_partido.tscn   Salida: pruebas/capturas/resumen_<país>_{descanso,final}.png

class VivoFalso extends Node:
	var partido: Partido
	var mi_club: Club
	func _salir_segunda() -> void:
		pass

func _foto(nombre: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://pruebas/capturas/resumen_%s.png" % nombre))
	print("captura ", nombre)

## Hasta que el retrato 3D de la figura esté dibujado (tope 2 min sin GPU).
func _esperar_retrato(capa: Node) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 120000:
		var falta := false
		for r in capa.find_children("*", "SubViewportContainer", true, false):
			falta = falta or r.get("hecho") == false
		if not falta:
			break
		await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/capturas"))
	for cfg: Array in [["CHI", 4], ["ESP", 8], ["MEX", 2]]:
		var m := Mundo.new()
		var ps: Array[String] = [String(cfg[0])]
		m.generar(ps, 60 + int(cfg[1]))
		var liga: Liga = m.ligas[0]
		m.tomar_el_mando(liga.clubes[int(cfg[1])].id)
		var mio := m.mi_club()
		var rival: Club = liga.clubes[(int(cfg[1]) + 7) % liga.clubes.size()]
		var p := Partido.new(rival, mio)
		MomentosPartido.registrar(p)
		p.preparar()
		while p.minuto < 45:
			p.simular_minuto()
		if cfg[0] == "ESP":
			p.set_meta("pases", [[188, 161], [159, 121]])
		var v := VivoFalso.new()
		v.partido = p
		v.mi_club = mio
		add_child(v)
		var d: Node = load("res://ui/partido_menu/descanso_partido.gd").mostrar(v)
		await _esperar_retrato(d)
		await _foto("%s_descanso" % cfg[0])
		d.queue_free()
		while not p.terminado_ya:
			p.simular_minuto()
		if cfg[0] == "ESP":
			p.set_meta("pases", [[402, 355], [338, 271]])
		var r := ResultadoPartido.mostrar(self, p, mio)
		await _esperar_retrato(r)
		await _foto("%s_final" % cfg[0])
		r.queue_free()
		v.queue_free()
	get_tree().quit()
