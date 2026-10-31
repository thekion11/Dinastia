extends Node
## M-348: dónde se van los ~3,5 s de la PRIMERA vez que se crea un personaje (cargar el modelo, armar el esqueleto, construir las animaciones) frente a la segunda.
##   godot --headless --path . res://pruebas/medir_frio_personaje.tscn
func _ready() -> void:
	## PRECALENTAR=1: antes de nada se lanza `PrecalentarAnim` y se espera su hilo; entonces la «primera» vez ya debe costar casi nada.
	if OS.get_environment("PRECALENTAR") != "":
		var t := Time.get_ticks_msec()
		var id := PrecalentarAnim.lanzar()
		var cuadros := 0
		while not WorkerThreadPool.is_task_completed(id):
			cuadros += 1
			await get_tree().process_frame
		WorkerThreadPool.wait_for_task_completion(id)
		print("MEDIDA precalentar (hilo): %d ms, con %d fotogramas del hilo principal mientras tanto" % [Time.get_ticks_msec() - t, cuadros])
	for vuelta in 2:
		var t0 := Time.get_ticks_msec()
		var d := FutbolistaQ.crear(1.9, "male")
		var t1 := Time.get_ticks_msec()
		add_child(d["nodo"])
		var t2 := Time.get_ticks_msec()
		FutbolistaQ.terminar(d, true)
		var t3 := Time.get_ticks_msec()
		print("MEDIDA personaje vuelta %d: crear %d ms, colgar %d ms, terminar (animaciones) %d ms" % [vuelta + 1, t1 - t0, t2 - t1, t3 - t2])
		(d["nodo"] as Node).queue_free()
	get_tree().quit()
