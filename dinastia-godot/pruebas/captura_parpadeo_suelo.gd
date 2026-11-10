extends Node
## PARPADEO DEL SUELO (z-fighting) en una sala del edificio del club (10-11, sesión 7). Pone la cámara en varias poses (cerca, rasante,
## desde el pasillo) y en cada una toma dos fotos con la cámara movida 2 mm: en una superficie estable las dos son casi iguales; si dos
## superficies coplanares se pelean, cambian miles de píxeles. Imprime el porcentaje de píxeles que cambian de más (descontando el movimiento
## real de la imagen con una tercera foto de referencia) y guarda las fotos en SALIDA (prefijo).
##   SALA="Despacho del presidente" PLANTA=1 CLUB=2 PAIS=ESP SALIDA=/ruta/prefijo herramientas/captura.sh res://pruebas/captura_parpadeo_suelo.tscn --png
var _vista: VistaEstadio
var _ex: ExploradorEstadio
var _n := 0
var _poses: Array = []
var _k := 0
var _fase := 0
var _fotos: Array[Image] = []
var _sala := "Despacho del presidente"
var _planta := 1

func _ready() -> void:
	if OS.get_environment("SALA") != "":
		_sala = OS.get_environment("SALA")
	if OS.get_environment("PLANTA") != "":
		_planta = int(OS.get_environment("PLANTA"))
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	var m := Mundo.new()
	m.generar([pais], 77)
	var club: Club = m.ligas[0].clubes[int(OS.get_environment("CLUB")) % m.ligas[0].clubes.size()]
	PersonajeDT.club_usuario = club.id
	var pl: Array = []
	for j: Jugador in club.plantilla:
		pl.append([pl.size() + 1, Nombres.visible(j.nombre)])
	EdificioClub.ctx = {"inst": {"park": 5, "med": 7, "video": 6, "museo": 6}, "dentro": {"sala_prensa": "television"}, "plantilla": pl, "titulos": 4, "presidente": "Presidente Ficticio"}
	var perfil := EstadioPropio.new().perfil(club)
	perfil["niveles"] = 2
	if OS.get_environment("CALIDAD") != "":   ## nivel de calidad (-3 ULTRA BAJA … 3 ULTRA ALTA); sin esto, el de defecto
		Calidad.elegida = int(OS.get_environment("CALIDAD"))
		Calidad.aplicar_viewport(get_viewport(), Calidad.elegida)
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, 0.85, null, null, perfil)

func _pose_lista(r: Rect2, y0: float) -> void:
	var c := r.get_center()
	## [posición de cámara, punto al que mira]
	_poses = [
		[Vector3(c.x, y0 + 1.7, r.end.y - 0.3), Vector3(c.x, y0, r.position.y)],               ## desde la puerta hacia el fondo
		[Vector3(c.x, y0 + 0.5, r.end.y - 0.3), Vector3(c.x, y0, r.position.y)],               ## rasante
		[Vector3(c.x, y0 + 3.0, c.y), Vector3(c.x, y0, c.y + 0.5)],                            ## desde el techo
		[Vector3(r.position.x + 0.5, y0 + 1.7, c.y), Vector3(r.end.x, y0, c.y)],               ## de lado
		[Vector3(c.x, y0 + 1.7, r.position.y + 0.3), Vector3(c.x, y0, r.end.y)],               ## desde el fondo
		[Vector3(c.x, y0 + 1.5, r.end.y + 1.6), Vector3(c.x, y0, r.position.y + 2.0)],         ## desde el pasillo, por la puerta
		[Vector3(c.x - 2.0, y0 + 1.5, r.end.y + 1.4), Vector3(c.x + 2.0, y0, r.end.y - 0.5)],  ## rasante cruzando el umbral
	]

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_vista.recorrer()
		_ex = _vista._explorador
		_ex.set_physics_process(false)
		_ex.set_process(false)
		_ex.cuerpo.visible = false
		for z: Dictionary in _ex.zonas:
			if int(z.get("planta", 0)) == _planta and String(z["nombre"]) == _sala and (z["r"] as Rect2).size.y > 3.0:
				_pose_lista(z["r"], RecorridoClub.y_de(_planta))
		_ex.planta = _planta
		_ex.en_viaje = false
		return
	if _n < 12 or _poses.is_empty():
		return
	## Tres fotos por pose: A, A+2 mm, A+4 mm (la 3.ª descuenta el avance real de la imagen).
	var p: Array = _poses[_k]
	var cam := _ex.camara
	cam.global_position = p[0] + Vector3(0.002 * _fase, 0, 0)
	cam.look_at(p[1] + Vector3(0.002 * _fase, 0, 0), Vector3.UP)
	if _n % 3 != 0:
		return
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	_fotos.append(img)
	if OS.get_environment("SALIDA") != "":
		img.save_png("%s_%d_%d.png" % [OS.get_environment("SALIDA"), _k, _fase])
	_fase += 1
	if _fase == 3:
		var d1 := _dif(_fotos[-3], _fotos[-2])
		var d2 := _dif(_fotos[-2], _fotos[-1])
		print("POSE %d  cambian %.2f %% (A→B) y %.2f %% (B→C)  ruido=%.2f %%" % [_k, d1, d2, absf(d1 - d2)])
		_fase = 0
		_k += 1
		if _k >= _poses.size():
			print("FIN PARPADEO")
			get_tree().quit()

## Porcentaje de píxeles cuyo color cambia más de 12/255 en algún canal.
func _dif(a: Image, b: Image) -> float:
	var da := a.get_data()
	var db := b.get_data()
	var cambia := 0
	var total := da.size() / 3
	for i in total:
		var m := maxi(maxi(absi(da[i * 3] - db[i * 3]), absi(da[i * 3 + 1] - db[i * 3 + 1])), absi(da[i * 3 + 2] - db[i * 3 + 2]))
		if m > 12:
			cambia += 1
	return 100.0 * float(cambia) / float(total)
