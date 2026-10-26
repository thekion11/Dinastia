extends BaseIdea
## LOS PIES QUE NO PATINAN Y LOS CAMBIOS DE PASO EN FASE (pani, 25-10-2026).
## Comprueba `AnimPasos` (velocidad del pie de apoyo de cada clip de locomoción
## = la que usa el motor), el trote hacia atrás de verdad, la guardia lateral del
## portero sin pies enterrados y `AnimTransiciones` (el clip nuevo arranca en la
## misma fase del paso y la mezcla se conserva).

func _probar() -> void:
	_titulo("PASOS Y TRANSICIONES DEL PARTIDO 3D (pani)")
	var raiz := Node3D.new()
	add_child(raiz)
	var d := FutbolistaQ.crear(1.8, "male")
	raiz.add_child(d["nodo"])
	FutbolistaQ.terminar(d, true)
	var esq: Skeleton3D = d["esqueleto"]
	var ap: AnimationPlayer = d["anim"]
	for clip: String in AnimPasos.CICLOS:
		_comprobar(ap.has_animation(clip), "existe «%s»" % clip)
		if not ap.has_animation(clip):
			continue
		var m := AnimPasos.medir(ap.get_animation(clip), esq)
		var obj := float(AnimPasos.CICLOS[clip][0])
		_comprobar(absf(float(m["vel"]) - obj) < 0.08 * obj, "«%s»: el pie de apoyo va a %.2f m/s (el motor lo mueve a %.1f)" % [clip, m["vel"], obj])
		_comprobar(float(m["suelo"]) > -0.03, "«%s»: el pie no se hunde (%.3f m)" % [clip, m["suelo"]])
		_comprobar(AnimPasos.fases.has(clip), "«%s» tiene su fase apuntada" % clip)
	## Hacia dónde va el pie apoyado: hacia atrás al trotar, hacia delante al recular.
	_comprobar(_sentido_apoyo(ap.get_animation("trotar"), esq) < 0.0, "al trotar, el pie apoyado va hacia atrás")
	_comprobar(_sentido_apoyo(ap.get_animation("trotar_atras"), esq) > 0.0, "al trotar hacia atrás, el pie apoyado va hacia delante")
	for lado: String in ["der", "izq"]:
		var g := AnimPasos.medir(ap.get_animation("portero_lateral_" + lado), esq)
		_comprobar(float(g["suelo"]) > -0.02, "guardia lateral %s: pies sobre el césped (%.3f m)" % [lado, g["suelo"]])
	## Cambio de paso en fase.
	var t := AnimTransiciones.poner(ap, "jugador_prueba")
	_comprobar(t != null, "el jugador lleva su AnimTransiciones")
	ap.play("trotar")
	ap.advance(0.0)
	ap.advance(0.31)
	t.apuntar()
	var f_antes := AnimTransiciones.fase_de("trotar", ap.current_animation_position, ap.current_animation_length)
	var muslo := esq.find_bone("thigh_l")
	var pose_trote := esq.get_bone_pose_rotation(muslo)
	ap.play("correr", 0.2)
	var f_despues := AnimTransiciones.fase_de("correr", ap.current_animation_position, ap.current_animation_length)
	var dif := absf(wrapf(f_despues - f_antes, -0.5, 0.5))
	_comprobar(dif < 0.06, "correr arranca en la fase del trote (%.2f → %.2f)" % [f_antes, f_despues])
	ap.advance(0.05)
	var pose_mezcla := esq.get_bone_pose_rotation(muslo)
	var correr_puro := ap.get_animation("correr")
	var pista := correr_puro.find_track(NodePath(str(ap.get_path_to(esq)) + ":thigh_l"), Animation.TYPE_ROTATION_3D)
	var q_puro: Quaternion = correr_puro.rotation_track_interpolate(pista, ap.current_animation_position) if pista >= 0 else pose_mezcla
	_comprobar(pista >= 0 and pose_mezcla.angle_to(q_puro) > 0.002 and pose_mezcla.angle_to(pose_trote) < 1.0,
		"la mezcla de 0,2 s se conserva tras colocar la fase")
	## De un gesto a la carrera no hay fase que respetar: arranca normal.
	ap.play("patear", 0.1)
	ap.advance(0.2)
	ap.play("trotar", 0.2)
	_comprobar(ap.current_animation_position < 0.001, "tras un gesto, el trote empieza por el principio")
	## Respiración desfasada: dos jugadores no empiezan el «parado» igual.
	var d2 := FutbolistaQ.crear(1.8, "male")
	raiz.add_child(d2["nodo"])
	FutbolistaQ.terminar(d2, true)
	var ap2: AnimationPlayer = d2["anim"]
	ap2.play("parado")
	AnimTransiciones.poner(ap2, "otro_id")
	var ap3 := AnimationPlayer.new()
	var d3 := FutbolistaQ.crear(1.8, "male")
	raiz.add_child(d3["nodo"])
	FutbolistaQ.terminar(d3, true)
	ap3 = d3["anim"]
	ap3.play("parado")
	AnimTransiciones.poner(ap3, "un_tercero")
	_comprobar(absf(ap2.current_animation_position - ap3.current_animation_position) > 0.05, "cada jugador respira a su ritmo")

## Signo del avance del pie apoyado sobre el eje adelante (+Z) del modelo.
func _sentido_apoyo(anim: Animation, esq: Skeleton3D) -> float:
	var pistas := AnimPasos._pistas(anim, esq)
	var ib := esq.find_bone("ball_l")
	var s := 0.0
	var prev := Vector3.INF
	var ymin := INF
	var pos: Array[Vector3] = []
	for k in 121:
		pos.append((AnimPasos._pose(anim, esq, pistas, anim.length * k / 120.0)[ib] as Transform3D).origin)
		ymin = minf(ymin, pos[k].y)
	for k in 120:
		if pos[k].y < ymin + 0.02 and pos[k + 1].y < ymin + 0.02:
			s += pos[k + 1].z - pos[k].z
	return s
