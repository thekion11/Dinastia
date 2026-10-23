class_name RuedaPrensaEscena3D
extends "res://ui/rueda_prensa_escena3d_p2.gd"
## (Parte 3 de 3 de `rueda_prensa_escena3d.gd`.)

func _process(delta: float) -> void:
	if _dt_3d_pendiente and is_inside_tree():
		_montar_dt_3d()
	_gesticular_dt(delta)
	_t += delta
	## Un corte cada varios segundos, siempre volviendo al plano de trabajo
	## entre los otros dos -que es donde de verdad se lee la pregunta y las
	## respuestas-, en vez de recorrer los tres en fila.
	var ciclo := fmod(_t, 9.0)
	var plano_activo := 0
	if ciclo > 7.5:
		plano_activo = 2
	elif ciclo > 5.0:
		plano_activo = 1
	if _camara != null:
		var d: Dictionary = PLANOS[plano_activo]
		var desde: Vector3 = d["pos"]
		var hacia: Vector3 = d["mira"]
		var fov_dest: float = d["fov"]
		## Deriva mínima DENTRO de cada plano -una entrevista es casi fija,
		## pero un corte seco entre posiciones estáticas se lee como
		## diapositivas, no como una retransmisión-.
		var deriva := Vector3(sin(_t * 0.18) * 0.04, sin(_t * 0.13) * 0.02, 0.0)
		var k := clampf(delta * 4.0, 0.0, 1.0)
		_cam_pos = _cam_pos.lerp(desde + deriva, k)
		_cam_mira = _cam_mira.lerp(hacia, k)
		_camara.fov = lerpf(_camara.fov, fov_dest, k)
		_camara.look_at_from_position(_cam_pos, _cam_mira, Vector3.UP)
	if _dt_cabeza != null:
		## Un asentimiento apenas perceptible: sin ningún movimiento, la cabeza
		## esférica se lee como un maniquí en cuanto se detiene la cámara.
		_dt_cabeza.rotation.x = sin(_t * 0.7) * 0.02
	if _dt_quad != null:
		## El retrato es un plano fijo: sin nada, se lee como una foto pegada
		## en cuanto la cámara se aleja lo suficiente para notarlo (el plano
		## general y el lateral). Un balanceo mínimo -sin rotar, que
		## deformaría la imagen de forma rara- da la sensación de que el
		## presentador respira sin necesitar un rig 3D.
		_dt_quad.position.y = 1.12 + sin(_t * 0.9) * 0.006
	## Manos quietas del todo se leen tan a maniquí como la cabeza sin
	## asentir: un vaivén mínimo -desfasado entre las dos, para que no se
	## muevan como una sola pieza- da un ligero apoyo de peso al hablar.
	for i in _dt_brazos.size():
		_dt_brazos[i].position.y = sin(_t * 0.8 + float(i) * 1.7) * 0.006
