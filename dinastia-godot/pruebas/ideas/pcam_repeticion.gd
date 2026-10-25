extends BaseIdea
## LA REALIZACIÓN DE LA REPETICIÓN Y LOS INSERTOS (25-10-2026, pulido de la retransmisión).
## Una jugada de gol sintética (conducción, remate a los 4 s, balón en la red) grabada por la
## `Repeticion` de verdad, y luego repetida fotograma a fotograma:
##   · encuentra el remate (momento clave) y planifica varios planos con cortes (M-134), con la
##     cámara de la línea de gol en una de cada dos (M-135);
##   · cámara lenta FLUIDA (interpola entre los cuadros de 20 Hz) y en rampa (más lenta en el remate);
##   · ninguna cámara dentro de la grada, y el balón en cuadro en casi todos los fotogramas;
##   · al acabar, cada uno exactamente en su sitio y la cámara de antes en pantalla; `saltar()`.
## Y los planos de inserto del `CameraRig` (la tarjeta, el cartel del añadido) y su vuelta.

const DT := 1.0 / 60.0
var _terminadas := 0

func _jugador(raiz: Node3D, pos: Vector3) -> Dictionary:
	var n := Node3D.new()
	raiz.add_child(n)
	n.position = pos
	var ap := AnimationPlayer.new()
	n.add_child(ap)
	var anim := Animation.new()
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_LINEAR
	var lib := AnimationLibrary.new()
	lib.add_animation("correr", anim)
	ap.add_animation_library("", lib)
	ap.play("correr")
	return {"node": n, "anim": ap}

## Graba una jugada de gol hacia +Z: conduce 4 s, remata y el balón entra.
func _grabar_gol(repe: Repeticion, js: Array, balon: Node3D) -> float:
	var t := 0.0
	var t_remate := 4.0
	while t < 4.6:
		t += 0.05
		var b: Vector3
		if t < t_remate:
			b = Vector3(3.0 - t * 0.5, 0.11, 20.0 + t * 6.0)
		else:
			## A 25 m/s hasta la red (z = 52,8) y luego la red lo frena (sigue un poco).
			var u := (t - t_remate) * 25.0
			if u > 8.8:
				u = 8.8 + minf((u - 8.8) * 0.04, 1.4)
			b = Vector3(1.0 - u * 0.1, 0.11 + minf(u, 8.8) * 0.08, 44.0 + u)
		balon.position = b
		for i in js.size():
			(js[i]["node"] as Node3D).position = Vector3(float(i) * 3.0 - 4.5, 0, b.z - 2.0 - float(i))
			(js[i]["anim"] as AnimationPlayer).advance(0.05)
		repe._process(0.05)
	return t_remate

func _probar() -> void:
	_titulo("RETRANSMISIÓN: LA REPETICIÓN CON VARIOS PLANOS, CÁMARA LENTA FLUIDA Y LOS INSERTOS")
	## 1) El momento clave, en datos sueltos.
	var ts := PackedFloat32Array()
	var bs := PackedVector3Array()
	for k in 120:
		var tt := float(k) * 0.05
		ts.append(tt)
		bs.append(Vector3(0, 0, tt * 5.0) if tt < 3.0 else Vector3(0, 0, 15.0 + (tt - 3.0) * 26.0))
	var tk0 := Repeticion.momento_clave(ts, bs, 0.0, 6.0)
	_comprobar(absf(tk0 - 2.95) < 0.06, "el momento clave es el golpeo (%.2f s, esperado ≈2,95)" % tk0)
	var bs2 := PackedVector3Array()
	for k in 120:
		bs2.append(Vector3(0, 0, float(k) * 0.05 * 5.0))
	_comprobar(Repeticion.momento_clave(ts, bs2, 0.0, 6.0) < 0.0, "sin golpeo (solo conducción) no hay momento clave")

	## 2) Una repetición de gol de verdad.
	var raiz := Node3D.new()
	add_child(raiz)
	var vivo := Camera3D.new()
	raiz.add_child(vivo)
	vivo.position = Vector3(40, 17, 0)
	vivo.current = true
	var balon := Node3D.new()
	raiz.add_child(balon)
	var js: Array = []
	for i in 4:
		js.append(_jugador(raiz, Vector3.ZERO))
	var repe := Repeticion.new()
	raiz.add_child(repe)
	repe.set_process(false)
	repe.setup(js, balon)
	repe.dx = 43.5
	repe.dz = 62.5
	repe.terminada.connect(func() -> void: _terminadas += 1)
	var t_remate := _grabar_gol(repe, js, balon)
	repe.congelar = true   ## como la realización del gol: deja de grabar
	var en_vivo: Array = []
	for f: Dictionary in js:
		en_vivo.append((f["node"] as Node3D).global_position)
	var bal_vivo := balon.global_position
	_comprobar(repe.reproducir(6.0), "arranca la repetición del gol")
	var nombres: Array = []
	for p: Dictionary in repe.planos:
		nombres.append(String(p["n"]))
	_comprobar(repe.es_gol and absf(repe.t_clave - (t_remate - 0.05)) < 0.11, "reconoce el gol y el remate (t clave %.2f, remate %.2f)" % [repe.t_clave, t_remate])
	_comprobar(nombres.size() >= 3 and nombres[0] == "tele" and nombres.has("remate") and (nombres.has("arco") or nombres.has("linea")),
		"varios planos con cortes: %s" % str(nombres))
	var rem: Dictionary = repe.planos[nombres.find("remate")]
	_comprobar(float(rem["vel"]) < float(repe.planos[0]["vel"]), "el remate va más lento que el armado (%.2f < %.2f)" % [float(rem["vel"]), float(repe.planos[0]["vel"])])
	var vistos: Array = []
	var quietos := 0
	var pasos := 0
	var en_cuadro := 0
	var en_grada: Array = []
	var antes := balon.global_position
	var real := 0.0
	var asp := 16.0 / 9.0
	var tam := get_viewport().get_visible_rect().size
	if tam.y > 1.0:
		asp = tam.x / tam.y
	while repe.reproduciendo and real < 30.0:
		repe._process(DT)
		real += DT
		if not repe.reproduciendo:
			break
		if repe.plano_actual != "" and (vistos.is_empty() or vistos[-1] != repe.plano_actual):
			vistos.append(repe.plano_actual)
		var cam := get_viewport().get_camera_3d()
		if repe._rep_t < repe._rep_hasta and cam != vivo:
			pasos += 1
			if balon.global_position.distance_to(antes) < 0.0005:
				quietos += 1
			var s := CameraRig.en_cuadro(cam.global_position, cam.global_position - cam.global_basis.z, cam.fov, asp, balon.global_position)
			if absf(s.x) < 0.95 and absf(s.y) < 0.95:
				en_cuadro += 1
			var p := cam.global_position
			if absf(p.x) > repe.dx - 6.5 or absf(p.z) > repe.dz - 6.4 or p.y < 0.8:
				en_grada.append("%s %s" % [repe.plano_actual, str(p.snapped(Vector3.ONE * 0.1))])
		antes = balon.global_position
	_comprobar(vistos == nombres, "los planos salen en su orden, con un corte entre cada uno (%s)" % str(vistos))
	_comprobar(pasos > 0 and float(quietos) / float(pasos) < 0.05, "cámara lenta fluida: el balón se mueve en casi todos los fotogramas (%d quietos de %d)" % [quietos, pasos])
	_comprobar(pasos > 0 and float(en_cuadro) / float(pasos) > 0.9, "el balón en cuadro en la repetición (%d de %d fotogramas)" % [en_cuadro, pasos])
	_comprobar(en_grada.is_empty(), "ninguna cámara dentro de la grada ni bajo el césped %s" % str(en_grada.slice(0, 4)))
	_comprobar(real > 7.0 and real < 14.0, "dura lo de una repetición de tele (%.1f s reales)" % real)
	var peor := 0.0
	for i in js.size():
		peor = maxf(peor, (js[i]["node"] as Node3D).global_position.distance_to(en_vivo[i]))
	peor = maxf(peor, balon.global_position.distance_to(bal_vivo))
	_comprobar(not repe.reproduciendo and _terminadas == 1 and peor < 0.001, "al acabar, cada uno en su sitio (desvío %.4f m) y avisa una vez (%d)" % [peor, _terminadas])
	_comprobar(get_viewport().get_camera_3d() == vivo, "vuelve la cámara de antes")
	_comprobar(repe.get_children().filter(func(c: Node) -> bool: return c is Camera3D and not c.is_queued_for_deletion()).is_empty(), "las cámaras de la repetición se borran")

	## 3) La siguiente alterna el plano final (detrás del arco ↔ línea de gol) y se puede saltar
	## (con barrido de entrada y salida).
	repe.congelar = false
	_grabar_gol(repe, js, balon)
	repe.congelar = true
	var m := _mundo(2500)
	var ui := Control.new()
	add_child(ui)
	repe.ui_barrido = ui
	repe.club_barrido = m.mi_club()
	_comprobar(repe.reproducir(6.0, true), "la segunda repetición arranca (con barrido)")
	var finales: Array = []
	for p: Dictionary in repe.planos:
		finales.append(String(p["n"]))
	_comprobar(finales.has("linea"), "la segunda usa la cámara de la línea de gol (%s)" % str(finales))
	repe._process(DT)
	_comprobar(get_viewport().get_camera_3d() == vivo, "con el barrido de entrada, el corte espera a que la franja tape la pantalla")
	for i in 30:
		repe._process(DT)
	_comprobar(get_viewport().get_camera_3d() != vivo, "tras medio barrido, ya en la repetición")
	repe.saltar()
	var t_salto := 0.0
	while repe.reproduciendo and t_salto < 3.0:
		repe._process(DT)
		t_salto += DT
	_comprobar(not repe.reproduciendo and t_salto < 0.5 and _terminadas == 2, "saltarla la acaba enseguida (%.2f s)" % t_salto)
	_comprobar(get_viewport().get_camera_3d() == vivo, "tras saltarla, la cámara de antes")
	ui.queue_free()

	## 4) Los insertos del rig.
	var rig := CameraRig.new()
	add_child(rig)
	rig.set_process(false)
	rig.build_for(49.0, 68.0, 13.0)
	rig.switch_to(0)
	var tv: Camera3D = rig.cameras[0]
	var arb := Node3D.new()
	raiz.add_child(arb)
	arb.position = Vector3(-6.0, 0, 12.0)
	var inf := Node3D.new()
	raiz.add_child(inf)
	inf.position = Vector3(-5.0, 0, 13.5)
	_comprobar(rig.inserto_tarjeta(arb, inf), "corta a la tarjeta")
	var ic := get_viewport().get_camera_3d()
	var s_arb := CameraRig.en_cuadro(ic.global_position, ic.global_position - ic.global_basis.z, ic.fov, asp, arb.global_position + Vector3(0, 1.7, 0))
	var s_inf := CameraRig.en_cuadro(ic.global_position, ic.global_position - ic.global_basis.z, ic.fov, asp, inf.global_position + Vector3(0, 1.0, 0))
	_comprobar(rig.inserto == "tarjeta" and ic != tv and absf(s_arb.x) < 0.8 and absf(s_arb.y) < 0.8 and absf(s_inf.x) < 0.8,
		"plano corto con el árbitro y el amonestado en cuadro (%s, %s)" % [str(s_arb.snapped(Vector2.ONE * 0.01)), str(s_inf.snapped(Vector2.ONE * 0.01))])
	_comprobar(ic.global_position.x > arb.global_position.x, "desde el lado de la tribuna principal (no cruza el eje)")
	for i in 150:
		rig._process(DT)
	_comprobar(rig.inserto == "" and get_viewport().get_camera_3d() == tv, "a los 2,3 s vuelve a la transmisión")
	var cuarto := Node3D.new()
	raiz.add_child(cuarto)
	cuarto.position = Vector3(CuartoArbitro.X_BANDA, 0, 1.6)
	_comprobar(rig.inserto_cartel(cuarto), "corta al cartel del añadido")
	ic = get_viewport().get_camera_3d()
	var s_c := CameraRig.en_cuadro(ic.global_position, ic.global_position - ic.global_basis.z, ic.fov, asp, cuarto.global_position + Vector3(-0.2, CuartoArbitro.ALTO_ARRIBA, 0))
	_comprobar(absf(s_c.x) < 0.5 and absf(s_c.y) < 0.5, "el cartel, en el centro del plano (%s)" % str(s_c.snapped(Vector2.ONE * 0.01)))
	rig.switch_to(1)
	_comprobar(rig.inserto == "" and get_viewport().get_camera_3d() == rig.cameras[1], "cambiar de cámara corta el inserto")
	rig.switch_to(3)
	_comprobar(not rig.inserto_tarjeta(arb, inf), "con la cámara subjetiva no se corta a ningún inserto")
	rig.switch_to(0)
	vivo.current = true
	_comprobar(not rig.inserto_tarjeta(arb, inf), "con otra cámara en pantalla (realización, repetición) no se corta")
	rig.free()
	raiz.queue_free()
