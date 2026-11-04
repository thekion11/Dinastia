extends BaseIdea
## A4-REND-004 (4-11-2026): los carteles 3D solo existen cerca de la cámara, pero TODO cartel que esté dentro de su rango de
## visión (+ margen) existe siempre: el jugador ve lo mismo que antes. También: se sueltan lejos, mantienen sus propiedades y
## con la cámara lejos no queda ninguno.
func _probar() -> void:
	_titulo("CARTELES PEREZOSOS")
	var raiz := Node3D.new()
	add_child(raiz)
	var r := RotulosPerezosos.new()
	r._todos = false   ## en headless el gestor crea todos; aquí se fuerza el modo de pantalla
	raiz.add_child(r)
	var cam := Camera3D.new()
	raiz.add_child(cam)
	cam.current = true
	seed(11)
	for i in 600:
		r.anadir({"texto": "Cartel %d" % i, "pos": Vector3(randf_range(-800, 800), 4.0, randf_range(-800, 800)), "giro": randf() * TAU,
			"rango": 110.0 if i % 2 == 0 else 70.0, "font_size": 34, "pixel_size": 0.0055, "outline_size": 0, "ancho": 420.0})
	cam.global_position = Vector3(0, 2, 0)
	for k in 12:
		await get_tree().create_timer(0.25).timeout
	var vivos := 0
	var faltan := 0
	for i in r._esp.size():
		var e: Dictionary = r._esp[i]
		var d := cam.global_position.distance_to(e["pos"])
		if r._vivo[i] != null: vivos += 1
		if d <= float(e["rango"]) and r._vivo[i] == null: faltan += 1
	_comprobar(faltan == 0, "todo cartel dentro de su rango de visión existe (faltan %d)" % faltan)
	_comprobar(vivos > 0 and vivos < 300, "solo existen los cercanos (%d de 600)" % vivos)
	var l0: Label3D = null
	for i in r._esp.size():
		if r._vivo[i] != null:
			l0 = r._vivo[i]
			break
	_comprobar(l0 != null and l0.font_size == 34 and is_equal_approx(l0.pixel_size, 0.0055) and l0.outline_size == 0 and l0.width == 420.0, "el cartel creado conserva sus propiedades")
	## Se va lejos: se sueltan todos (histéresis incluida).
	cam.global_position = Vector3(5000, 2, 5000)
	for k in 12:
		await get_tree().create_timer(0.25).timeout
	var quedan := 0
	for i in r._esp.size():
		if r._vivo[i] != null: quedan += 1
	_comprobar(quedan == 0, "con la cámara lejos no queda ninguno (%d)" % quedan)
	## Vuelve: reaparecen.
	cam.global_position = Vector3(0, 2, 0)
	for k in 12:
		await get_tree().create_timer(0.25).timeout
	var faltan2 := 0
	for i in r._esp.size():
		if cam.global_position.distance_to(r._esp[i]["pos"]) <= float(r._esp[i]["rango"]) and r._vivo[i] == null: faltan2 += 1
	_comprobar(faltan2 == 0, "al volver reaparecen los cercanos (faltan %d)" % faltan2)
