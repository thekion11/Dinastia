extends Node
## MICROBENCHMARK de `PuertaAnimada._process` (13-11, sesión 16, optimización de código): construye el edificio del club, y con la cámara lejos
## (todas las puertas cerradas y quietas, el caso de casi todo el partido) y luego cerca (abriéndose) cronometra N llamadas.
##   godot --headless --path . res://pruebas/micro_puertas.tscn      (CPU de GDScript: vale en headless; no es tiempo de fotograma)
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["ENG"], 77)
	var club: Club = m.ligas[0].clubes[4]
	PersonajeDT.club_usuario = club.id
	EdificioClub.ctx = {"inst": {"park": 5, "med": 7, "video": 6, "museo": 6}, "plantilla": [], "titulos": 4, "club": club, "pais": club.pais}
	var perfil := EstadioPropio.new().perfil(club)
	perfil["niveles"] = 2
	var v := VistaEstadio.new()
	add_child(v)
	v.abrir(club, 0.85, null, null, perfil)
	for i in 10:
		await get_tree().process_frame
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	cam.position = Vector3(500, 300, 500)
	await get_tree().process_frame
	var puertas: Array = get_tree().root.find_children("*", "PuertaAnimada", true, false)
	print("MICRO puertas=", puertas.size())
	if puertas.is_empty():
		get_tree().quit()
		return
	for p in puertas:
		(p as PuertaAnimada)._process(10.0)   ## que lleguen al estado cerrado
	var n := 3000
	var t0 := Time.get_ticks_usec()
	for k in n:
		for p in puertas:
			(p as PuertaAnimada)._process(0.016)
	var us := float(Time.get_ticks_usec() - t0) / float(n)
	print("MICRO_QUIETAS us por fotograma (todas las puertas): %.2f" % us)
	## Las ángulos finales no deben cambiar con el código nuevo: se imprime la firma.
	var firma := 0.0
	for p in puertas:
		firma += (p as PuertaAnimada).rotation.y
	print("MICRO_FIRMA cerradas ", snappedf(firma, 0.0001))
	cam.global_position = (puertas[0] as Node3D).global_position + Vector3(0, 1.6, 0)
	for k in 5:
		for p in puertas:
			(p as PuertaAnimada)._process(0.1)
	firma = 0.0
	for p in puertas:
		firma += (p as PuertaAnimada).rotation.y
	print("MICRO_FIRMA con camara cerca (5 pasos de 0,1 s) ", snappedf(firma, 0.0001))
	get_tree().quit()
