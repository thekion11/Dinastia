extends Node
## Captura de la pantalla «Ligas activas» (10-11): PC (todas marcadas) y móvil (país del juego + 5 grandes), en el idioma pedido con IDIOMA=en.
##   OUT=carpeta IDIOMA=es|en herramientas/captura.sh res://pruebas/captura_ligas_activas.tscn
func _ready() -> void:
	var dir := OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/fotos_ligas"
	DirAccess.make_dir_recursive_absolute(dir)
	if OS.get_environment("IDIOMA") != "":
		Idiomas.idioma = OS.get_environment("IDIOMA")
	for caso: String in ["pc", "movil"]:
		var p := LigasActivasPantalla.new()
		add_child(p)
		if caso == "movil":
			p._atajo("grandes")
		for _i in 8:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/ligas_activas_%s.jpg" % [dir, caso], 0.9)
		p.queue_free()
		await get_tree().process_frame
	print("FIN")
	get_tree().quit()
