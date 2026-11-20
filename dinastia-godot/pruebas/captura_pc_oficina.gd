extends Node
## SENTARSE AL PC en la Oficina del DT REAL del club (18-11): fotos de cada fase de `PcAnimacion` con la cámara en primera persona.
## PAIS=ESP CLUB=3 (regla 34: variar el club). SALIDA=<carpeta> (JPG).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 960x540 res://pruebas/captura_pc_oficina.tscn
var _vista: VistaEstadio
var _ex: ExploradorEstadio
var _n := 0

func _ready() -> void:
	var m := Mundo.new()
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	m.generar([pais], 77)
	var club: Club = m.ligas[0].clubes[int(OS.get_environment("CLUB")) % m.ligas[0].clubes.size()]
	PersonajeDT.club_usuario = club.id
	var pl: Array = []
	for j: Jugador in club.plantilla:
		pl.append([pl.size() + 1, Nombres.visible(j.nombre)])
	EdificioClub.ctx = {"inst": {"park": 5, "med": 7, "video": 6, "museo": 6}, "dentro": {"sala_prensa": "television"},
		"plantilla": pl, "titulos": 4, "presidente": "Presidente Ficticio", "club": club, "pais": club.pais}
	if OS.get_environment("CALIDAD") != "":   ## el relleno decorativo de las salas no se pone en la calidad mínima
		Calidad.elegida = int(OS.get_environment("CALIDAD"))
		Calidad.aplicar_viewport(get_viewport(), Calidad.elegida)
	var perfil := EstadioPropio.new().perfil(club)
	perfil["niveles"] = 2
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, 0.85, null, null, perfil)

func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var carpeta := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "user://pc"
	DirAccess.make_dir_recursive_absolute(carpeta)
	get_viewport().get_texture().get_image().save_jpg(carpeta.path_join(nombre + ".jpg"), 0.9)

func _process(_d: float) -> void:
	_n += 1
	if _n != 10:
		return
	_vista.recorrer()
	_ex = _vista._explorador
	_ex.set_physics_process(false)
	_ex.set_process_unhandled_input(false)
	_ex.planta = 1
	_ex.en_viaje = false
	for z: Dictionary in _ex.zonas:
		if int(z.get("planta", 0)) == 1 and String(z["nombre"]) == "Oficina del DT":
			var r: Rect2 = z["r"]
			var punto := Vector3(r.get_center().x, RecorridoClub.y_de(1), r.get_center().y + 0.9)
			_ex.cuerpo.position = punto + Vector3(0, 0, 1.2)
			_ex.rumbo = PI
			_ex.paso(Vector2.ZERO, false, 0.0)
			_ex._colocar_camara(1.0)
			_correr(punto)
			return
	print("NO HAY OFICINA")
	get_tree().quit(1)

func _correr(punto: Vector3) -> void:
	set_process(false)
	await get_tree().create_timer(0.5).timeout
	await _foto("0_de_pie")
	var r0 := _ex.rumbo
	var p0 := _ex.cuerpo.position
	_ex.rumbo = PI * 0.5   ## mirando a la pared del sofá (cuadros y reloj)
	_ex.cuerpo.position = p0 + Vector3(-1.6, 0, -0.6)
	_ex._colocar_camara(1.0)
	await _foto("0b_pared_sofa")
	_ex.rumbo = PI + 0.5   ## y la mesa de lado (ratón, taza, libros)
	_ex.cuerpo.position = p0 + Vector3(1.2, 0, 0.3)
	_ex._colocar_camara(1.0)
	_ex.camara.look_at(punto + Vector3(0, 0.75, -1.35), Vector3.UP)
	await _foto("0c_mesa_de_lado")
	_ex.rumbo = r0
	_ex.cuerpo.position = p0
	_ex._colocar_camara(1.0)
	var a := PcAnimacion.new()
	add_child(a)
	var fin := [false]
	var coro := func() -> void:
		await a.sentarse(_ex, punto)
		fin[0] = true
	coro.call()
	var t := 0.0
	var fases := {0.35: "1_pasos", 1.0: "2_sentado", 1.6: "3_pantalla", 2.3: "4_acercando"}
	while not fin[0] and t < 10.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		for k in fases.keys():
			if t >= k and fases[k] != "":
				await _foto(String(fases[k]))
				fases[k] = ""
	print("SENTARSE %.1f s" % t)
	await a.revelar()
	await a.levantarse()
	await _foto("5_de_pie_otra_vez")
	print("FIN")
	get_tree().quit()
