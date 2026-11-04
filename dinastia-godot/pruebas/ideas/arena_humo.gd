extends BaseIdea
## HUMO DE LA ARENA DE PRUEBAS (P5, 3-11): cada modo de `pruebas/arena/arena.tscn` monta lo que dice y no deja errores; sin pantalla (las métricas
## de dibujo salen a 0 sin GPU, eso se mide con el renderizador de verdad: ver `pruebas/arena/LEEME.md`).

func _modo(modo: String, esperados_min: int, esperados_max: int) -> void:
	OS.set_environment("ARENA", modo)
	OS.set_environment("CAMARAS", "2")
	OS.set_environment("DURACION", "0")
	var arena: Node = load("res://pruebas/arena/arena.tscn").instantiate()
	add_child(arena)
	for i in 20:
		await get_tree().process_frame
	var n: int = (arena.get("_lista") as Array).size()
	_comprobar(n >= esperados_min and n <= esperados_max, "ARENA=%s monta %d figuras (esperadas %d-%d)" % [modo, n, esperados_min, esperados_max])
	var cam: ArenaCamaras = arena.get("_camaras")
	_comprobar(cam != null and cam.camaras.size() == 4 and cam.contenedores[0].visible and cam.contenedores[1].visible and not cam.contenedores[2].visible,
		"ARENA=%s: 2 de las 4 cámaras visibles" % modo)
	arena.queue_free()
	await get_tree().process_frame

func _ready() -> void:
	await get_tree().process_frame
	_titulo("ARENA DE PRUEBAS: modos")
	var escala := Engine.time_scale
	await _modo("cancha", 0, 0)
	await _modo("jugador", 1, 1)
	await _modo("arbitro", 4, 4)
	await _modo("balon", 1, 1)
	await _modo("porteria", 2, 2)
	await _modo("partido", 25, 25)
	Engine.time_scale = escala
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
