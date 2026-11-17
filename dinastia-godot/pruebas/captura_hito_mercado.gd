extends Node
## CAPTURAS del hito del último día del mercado y de su diálogo de confirmación, con clubes de países distintos:
##   herramientas/captura.sh res://pruebas/captura_hito_mercado.tscn      Salida: pruebas/capturas/hito_<país>_{mercado,dialogo}.png

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/capturas"))
	var n := 0
	for pais: String in ["CHI", "ENG", "JPN"]:
		var m := Mundo.new()
		var ps: Array[String] = [pais]
		m.generar(ps, 300 + n)
		m.tomar_el_mando(m.ligas[0].clubes[2 + n].id)
		n += 1
		var h := MercadoHitoPantalla.mostrar(self, m.mi_club())
		await get_tree().create_timer(2.3).timeout
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://pruebas/capturas/hito_%s_mercado.png" % pais))
		h.queue_free()
		if n == 1:
			var d := ConfirmarHito.mostrar(self, Idiomas.t("Avanzarás al día siguiente. El mercado de fichajes cerrará. ¿Quieres continuar?"))
			await get_tree().create_timer(1.2).timeout
			await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://pruebas/capturas/hito_%s_dialogo.png" % pais))
			d.queue_free()
	get_tree().quit()
