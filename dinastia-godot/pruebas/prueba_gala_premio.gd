extends Node
## LAS ENTREGAS DE PREMIOS DE «LA RUTA» EN 3D (`GalaPremio3D`): monta la de CADA premio, cada una con un club de otro
## país (regla 34), la deja correr hasta la celebración y comprueba que hay jugadores 3D, galardón y cámara. Con
## SALIDA=<carpeta> guarda una foto de cada una (a los 3 s, alargando las manos, y a los 6 s, celebrando).
##   xvfb-run -a godot --path . --rendering-driver vulkan --resolution 1280x720 res://pruebas/prueba_gala_premio.tscn
var _fallos := 0

func _comprobar(ok: bool, que: String) -> void:
	print(("  ok    " if ok else "  FALLO ") + que)
	if not ok:
		_fallos += 1

func _ready() -> void:
	var salida := OS.get_environment("SALIDA")
	var m := Mundo.new()
	m.generar(["ESP", "ARG", "GER", "BRA", "ITA", "FRA", "ENG", "CHI"], 20261113)
	var puestos := ["DC", "MC", "POR", "DFC", "ED", "MCO", "LI", "MCD"]
	var k := 0
	var ids: Array = CarreraPremios.PREMIOS.keys()
	var sin_guion: Array = ids.filter(func(x: String) -> bool: return not GalaGuiones.GUIONES.has(x))
	_comprobar(sin_guion.is_empty(), "hay un guion por premio (faltan: %s)" % str(sin_guion))
	ids.append_array(["trofeo_liga", "trofeo_copa", "trofeo_continental", "trofeo_otro"])
	for id: String in ids:
		var liga: Liga = m.ligas[(k * 3) % m.ligas.size()]
		var club: Club = liga.clubes[(k * 5 + 2) % liga.clubes.size()]
		var j: Jugador = club.plantilla[(k * 7) % club.plantilla.size()]
		if id in ["muro", "portero_liga"]:
			for o: Jugador in club.plantilla:
				if o.es_portero():
					j = o
		var g = load("res://visor/gala_premio3d.gd").crear_gala(id, {"jugador": j, "club": club, "liga": liga.nombre, "pais": liga.pais, "mundo": m, "titulo": liga.nombre})
		_comprobar(g != null, "«%s»: se monta (%s, %s)" % [id, club.nombre, liga.pais])
		if g == null:
			k += 1
			continue
		g.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(g)
		await get_tree().create_timer(3.1).timeout
		if salida != "":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_jpg("%s/gala_%02d_%s_a.jpg" % [salida, k, id], 0.88)
		await get_tree().create_timer(3.0).timeout
		_comprobar(g.jugadores >= 2 and g._objeto != null and g._fase == 3 and g.fotografos >= 2, "  %d jugadores 3D (%d fotógrafos), galardón «%s» y ya lo celebra" % [g.jugadores, g.fotografos, g.guion["objeto"]])
		_comprobar(g._ik != null and g._ik.influence > 0.9 and g._objeto.position.distance_to(g._pedestal) > 0.4, "  lo tomó del pedestal con las dos manos")
		if salida != "":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_jpg("%s/gala_%02d_%s_b.jpg" % [salida, k, id], 0.88)
		g.queue_free()
		await get_tree().process_frame
		k += 1
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit()
