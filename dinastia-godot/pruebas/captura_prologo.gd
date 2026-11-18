extends Node
## EL PRÓLOGO TAL COMO SE VE (18-11): una foto de la presentación aérea y una de CADA paso del guion (con el cuadro de diálogo del mentor),
## con la cámara en primera persona. PAIS=ESP CLUB=3 (regla 34: varía el club y el país), SALIDA=<carpeta> (JPG), CALIDAD=-3..3 (por defecto 0 = MEDIA),
## SOLO=vestuario,oficina (claves de `PrologoPasos`).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_prologo.tscn
var _p: PrologoDT
var _salida := ""

func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(_salida)
	get_viewport().get_texture().get_image().save_jpg(_salida.path_join(nombre + ".jpg"), 0.9)
	print("FOTO ", nombre)

func _ready() -> void:
	_salida = OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "user://prologo"
	Calidad.elegida = int(OS.get_environment("CALIDAD")) if OS.get_environment("CALIDAD") != "" else Calidad.MEDIO
	var m := Mundo.new()
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	m.generar([pais], 4242)
	m.tomar_el_mando(m.ligas[0].clubes[int(OS.get_environment("CLUB")) % m.ligas[0].clubes.size()].id)
	set_meta("mundo", m)
	PedidoPartida.mundo_pregenerado = m
	PedidoPartida.modo_elegido = "dt"
	PedidoPartida.dt_nombre_elegido = "Míster Prueba"
	PrologoDT.rapido = false
	_p = (load("res://escenas/prologo.tscn") as PackedScene).instantiate()
	add_child(_p)
	await get_tree().create_timer(1.5).timeout
	while not _p._listo and not (is_instance_valid(_p) and _p.hud != null and _p.hud.visible and _p.vista != null):
		await get_tree().process_frame
	await get_tree().create_timer(1.2).timeout
	await _foto("00_presentacion_aerea")
	while not _p._listo:
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	var solo := OS.get_environment("SOLO").split(",", false)
	for i in PrologoPasos.PASOS.size():
		var clave := String(PrologoPasos.PASOS[i]["clave"])
		if not solo.is_empty() and not (clave in solo):
			continue
		await _paso(i, clave)
	print("FIN")
	get_tree().quit()

func _paso(i: int, clave: String) -> void:
	var e: ExploradorCiudad = _p.explorador
	var p: Dictionary = PrologoPasos.PASOS[i]
	_p._ir_al_paso(i)
	var fuera := bool(p.get("fuera", false))
	if not fuera:
		if String(e.get("estado")) != "estadio":
			e._entrar_al_estadio()
			await get_tree().create_timer(1.0).timeout
		if int(e.get("_planta")) != int(p["planta"]):
			e._ir_a_planta(int(p["planta"]))
			await get_tree().create_timer(3.0).timeout
		e.cuerpo.position = _p.destino + Vector3(0, 0, 2.4)
	else:
		e.cuerpo.position = _p.puerta + Vector3(0, 0, 7.0 if clave == "llegada" else 3.0)
	e.rumbo = PI
	e.cuerpo.rotation.y = PI
	e._colocar_camara(1.0)
	_p._hablar()
	await get_tree().create_timer(1.5).timeout
	await _foto("%02d_%s" % [i + 1, clave])
