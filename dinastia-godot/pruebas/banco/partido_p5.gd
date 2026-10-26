extends "res://pruebas/banco/partido_p4.gd"
## [Banco · grupo «partido» · capa 5/6] Generado al partir el banco por grupos (26-10).


## Tramo 2 de 2 de `_probar_tanda_c` (la norma de 450 líneas la troceó).
func _probar_tanda_c_2(m: Mundo, c, o, mf: Mundo, cj, yo, cj3):
	_comprobar(cj3.caps == cj.caps and cj3.pj_carrera == 1 and cj3.goles_carrera == 1, "la selección y los totales se guardan")
	cj.club(mf).soltar(yo)
	## EL RETIRO Y EL PASO A ENTRENADOR, en un mundo aparte (cambia el mando).
	var mr := Mundo.new()
	mr.generar(["CHI"], 4242)
	var cjr := CarreraJugador.crear(mr, "Prueba Veterano", "MC", false, 7)
	mr.carrera_jugador = cjr
	var vet := cjr.jugador(mr)
	vet.edad = 34
	cjr.fama = 60
	cjr.retiro_anunciado = true
	_comprobar(cjr.toca_retirarse(mr), "si anunciaste el retiro, toca colgar las botas")
	var ofs := cjr.ofertas_de_banquillo(mr)
	_comprobar(not ofs.is_empty() and ofs.size() <= 3, "al retirarte te ofrecen banquillos (%d)" % ofs.size())
	if not ofs.is_empty():
		_comprobar(cjr.pasar_a_entrenador(mr, ofs[0]) and mr.mi_club_id == (ofs[0] as Club).id and cjr.retirado,
			"te retiras y diriges a %s en el mismo mundo" % (ofs[0] as Club).nombre)
		_comprobar(mr.roles.nombre == "Prueba Veterano" and mr.roles.rol == Roles.DT, "el entrenador eres tú, con tu nombre de jugador")
	## LAS BUTACAS DE LOS RIVALES, de los colores de su club (no el verde del visor).
	var riv_b: Club = mf.ligas[0].clubes[1]
	## Las del club, salvo que su estadio real tenga colores propios (`asientos`).
	var tab_est: Variant = Datos.tabla("ESTADIO_CLUB")
	var propios: bool = tab_est is Dictionary and (tab_est as Dictionary).has(riv_b.nombre) and ((tab_est as Dictionary)[riv_b.nombre] as Dictionary).has("asientos")
	_comprobar(propios or String(riv_b.perfil_estadio().get("asiento1", "")) == riv_b.color1, "las butacas de un rival llevan los colores de su club (o los de su estadio real)")
	if propios:
		_comprobar(String(riv_b.perfil_estadio().get("asiento1", "")) == String(((tab_est as Dictionary)[riv_b.nombre] as Dictionary)["asientos"][0]), "el estadio con colores propios los aplica")
	## LOS OBJETIVOS EN EL BORDE: directiva, confianza, próximo partido y misiones del mentor.
	PanelObjetivos.ruta = "user://objetivos_banco.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PanelObjetivos.ruta))
	var objs := PanelObjetivos.lista(mf, "dt")
	var mis_obj: Array = objs.filter(func(o: Dictionary) -> bool: return bool(o.get("mentor", false)))
	_comprobar(objs.size() >= 4 and String(objs[0]["icono"]) == "🏆" and not bool(objs[0]["hecho"]), "los objetivos: la meta de la directiva, sin cumplir antes de jugar (%d)" % objs.size())
	_comprobar(mis_obj.size() >= 3 and mis_obj.all(func(o: Dictionary) -> bool: return not bool(o["hecho"])), "las misiones del mentor salen en el panel, pendientes")
	PanelObjetivos.marcar_mision("dt", String(mis_obj[0]["texto"]))
	_comprobar(bool(PanelObjetivos.lista(mf, "dt").filter(func(o: Dictionary) -> bool: return String(o["texto"]) == String(mis_obj[0]["texto"]))[0]["hecho"]), "una misión cumplida queda tachada y se guarda")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PanelObjetivos.ruta))
	## LA PRESENTACIÓN EN EL ESTADIO: tres planos por tiempo; cerrar avisa una vez.
	var cin := CinematicaFichaje.new()
	_comprobar(cin.plano(1.0) == 1 and cin.plano(5.0) == 2 and cin.plano(9.0) == 3, "la cinemática del fichaje tiene tres planos")
	var avisos_cin := [0]
	cin.terminada.connect(func() -> void: avisos_cin[0] += 1)
	cin.cerrar()
	cin.cerrar()
	_comprobar(avisos_cin[0] == 1, "saltar la cinemática avisa una sola vez")
	## META (bloque 50): cromos, museo global, mundo heredado.
	var sobres_antes := int(Meta.leer()["sobres"])
	mf.roles.sumar_trofeo("Copa de Prueba")
	var dm := Meta.leer()
	_comprobar(int(dm["sobres"]) == sobres_antes + 1 and String((dm["museo"] as Array)[0]["titulo"]) == "Copa de Prueba", "un título va al museo global y da un sobre")
	var rng_m := RandomNumberGenerator.new()
	rng_m.seed = 5
	var salen := Meta.abrir_sobre(mf, rng_m)
	_comprobar(salen.size() == Meta.POR_SOBRE and int(Meta.leer()["sobres"]) == sobres_antes, "abrir un sobre da %d cromos y gasta el sobre" % Meta.POR_SOBRE)
	_comprobar((Meta.leer()["cromos"] as Dictionary).size() >= 1, "los cromos quedan en el álbum")
	var cm0: Club = mf.clubes.values()[0]
	var rep_real := cm0.rep
	cm0.rep = 97
	Meta.fin_de_temporada(mf)
	cm0.rep = rep_real
	_comprobar(Meta.hay_legado(), "al cerrar la temporada se guarda el mundo para heredar")
	var mh := Mundo.new()
	Meta.heredar_proximo = true
	mh.generar(["CHI"], 12)
	var cm_h: Club = null
	for c_h: Club in mh.clubes.values():
		if c_h.nombre == cm0.nombre:
			cm_h = c_h
	_comprobar(cm_h != null and cm_h.rep == 97 and not Meta.heredar_proximo, "el mundo heredado arranca con la reputación de la última partida")
	## FONDO DE INVERSIÓN: comprar, tope del 49 %, dividendos, vender, guardar.
	var fi := FondoInversion.new()
	fi.caja = 1000000000
	var otros: Array = mf.clubes.values().filter(func(x: Club) -> bool: return x.id != mf.mi_club_id)
	var obj: Club = otros[0]
	_comprobar(fi.comprar(mf, obj, 0.25) == "" and is_equal_approx(float(fi.cartera[obj.id]), 0.25), "el fondo compra un 25 %")
	fi.comprar(mf, obj, 0.4)
	_comprobar(float(fi.cartera[obj.id]) <= FondoInversion.MAX_PCT + 0.0001 and fi.comprar(mf, obj, 0.1) != "", "nunca pasa del 49 % de un club")
	_comprobar(fi.comprar(mf, mf.mi_club(), 0.1) != "", "no compra su propio club")
	mf.semana = 4
	var div := fi.semana(mf)
	_comprobar(div >= 0 and fi.dividendos_totales == div and fi.historia.size() == 1, "cada cuatro semanas reparte dividendos (%s)" % _dinero(div))
	var fi2 := FondoInversion.new()
	fi2.desde_dic(fi.a_dic())
	_comprobar(fi2.caja == fi.caja and fi2.cartera.size() == 1 and fi2.dividendos_totales == fi.dividendos_totales, "el fondo se guarda con la partida")
	var caja_antes := fi.caja
	_comprobar(fi.vender(mf, obj, 1.0) == "" and fi.cartera.is_empty() and fi.caja > caja_antes, "vender todo devuelve caja y vacía la cartera")
	## Cantera.
	var ec := m.eventos_cantera
	var hubo := false
	for sem in 60:
		ec.semana(m.academia, c, 2026, sem)
		if not ec.pendiente.is_empty():
			hubo = true
			break
	_comprobar(hubo, "la academia trae asuntos para decidir")
	if hubo:
		var r = ec.resolver("a", m.academia, c)
		_comprobar(not r.is_empty() and ec.pendiente.is_empty(), "el asunto de la academia se resuelve")
	_comprobar(ec.visitar(m.academia, 2026, 70) == "" and ec.visitar(m.academia, 2026, 70) != "", "una visita a la academia por semana")
	## Ramas.
	m.hinchada.ramas["femenino"] = true
	var res = m.hinchada.temporada_ramas(c, 2026)
	_comprobar(res.size() == 1 and int(res[0]["puesto"]) >= 1 and int(res[0]["puesto"]) <= 12, "la rama femenina termina en un puesto (%d.º)" % int(res[0]["puesto"]))
	_comprobar(int(m.hinchada.anios_rama["femenino"]) == 1, "la rama suma temporadas")
	## Ficha.
	var cuenta := {}
	for j: Jugador in m.jugadores():
		var pd := j.pierna_debil()
		cuenta[pd] = int(cuenta.get(pd, 0)) + 1
	_comprobar(cuenta.size() == 5 and int(cuenta.get(2, 0)) + int(cuenta.get(3, 0)) > int(cuenta.get(5, 0)) * 5, "pierna débil de 1 a 5, casi todos 2-3: %s" % str(cuenta))
	var j0: Jugador = c.plantilla[0]
	j0.premios.append({"anio": 2026, "premio": "Equipo ideal de la temporada"})
	_comprobar(Partida._dic_a_jugador(Partida._jugador_a_dic(j0)).premios.size() == 1, "los premios se guardan")

func _probar_tanda_c() -> void:
	var _r1 = _probar_tanda_c_1()
	var m: Mundo = _r1[0]
	var c = _r1[1]
	var o = _r1[2]
	var mf: Mundo = _r1[3]
	var cj = _r1[4]
	var yo = _r1[5]
	var cj3 = _r1[6]
	_probar_tanda_c_2(m, c, o, mf, cj, yo, cj3)

## LA TRANSMISIÓN INTELIGENTE Y LAS ESTADÍSTICAS A PEDIDO (16-10-2026).
## La cámara se prueba sin pintar nada: se le dan balones sintéticos a 60 Hz y
## se mide lo que hace (dónde está, cuánto corre, cuánto cierra o abre).
## LOS ARREGLOS RÁPIDOS DEL PARTIDO CON MOTOR (17-10-2026): árbitro que
## contrasta (M-072), gestos y tarjeta en la mano (M-106), cartel del cuarto
## árbitro (M-139), red que se ondula (M-149), festejo de la grada (M-050) y
## líneas del fuera de juego en la sala VAR (M-118).
func _probar_arreglos_partido_motor() -> void:
	_titulo("PARTIDO 3D: ÁRBITRO, CARTEL, RED, FESTEJO Y LÍNEA VAR")
	## M-072: contra un equipo de negro el árbitro no va de negro; estable.
	var kn := {"c1": "#101010"}
	var kr := {"c1": "#d01818"}
	var a1 := Puente3D.kit_arbitro(kn, kr, 77)
	_comprobar(String(a1["nombre"]) != "negro", "árbitro: contra negro y rojo no va de negro (%s)" % a1["nombre"])
	_comprobar(Puente3D.kit_arbitro(kn, kr, 77)["nombre"] == a1["nombre"], "árbitro: la misma camiseta para el mismo partido")
	var cl := Color(String(a1["c1"]))
	var peor := minf(Puente3D.contraste_camiseta(cl, Color("#101010")), Puente3D.contraste_camiseta(cl, Color("#d01818")))
	_comprobar(peor > Puente3D.contraste_camiseta(Color("#111216"), Color("#101010")) + 0.3, "árbitro: contrasta más que el negro de siempre (%.2f)" % peor)
	var a2 := Puente3D.kit_arbitro({"c1": "#f4f4f4"}, {"c1": "#2a9a3a"}, 5)
	_comprobar(String(a2["nombre"]) in ["negro", "rojo", "rosa", "naranja"], "árbitro: contra blanco y verde, uno oscuro o vivo (%s)" % a2["nombre"])
	## M-106: los gestos del árbitro en el motor real (cola con reloj propio).
	var motor := MotorJugable.new()
	add_child(motor)
	motor.set_physics_process(false)
	var arb_nodo := Node3D.new()
	add_child(arb_nodo)
	var ap := AnimationPlayer.new()
	arb_nodo.add_child(ap)
	var lib := AnimationLibrary.new()
	for clip in ["parado", "trotar", "correr", "arbitro_silbato", "senalar_falta", "mostrar_tarjeta", "arbitro_amonestar_hablar", "arbitro_tiempo_anadido"]:
		var an := Animation.new()
		an.length = 1.0
		lib.add_animation(clip, an)
	ap.add_animation_library("", lib)
	motor.arbitros = [{"id": "arbitro", "node": arb_nodo, "anim": ap, "arbitro": true}]
	var bal := Node3D.new()
	add_child(bal)
	motor.balon = bal
	var gestos: Array = []
	motor.gesto_arbitro.connect(func(g: String) -> void: gestos.append(g))
	motor.call("_gesto_arbitro", "arbitro_silbato", 0.0, 0.9)
	motor.call("_gesto_arbitro", "mostrar_tarjeta", 1.0, 1.5, {"tarjeta": "amarilla"})
	for i in 40:
		motor.call("_mover_arbitros", 0.05)
	_comprobar(gestos.has("silbato") and gestos.has("mostrar_tarjeta"), "árbitro: pita y enseña la tarjeta (%s)" % str(gestos))
	_comprobar(String(motor.arbitros[0].get("anim_actual", "")) == "mostrar_tarjeta", "árbitro: está con el gesto de la tarjeta")
	motor.queue_free()
	arb_nodo.queue_free()
	bal.queue_free()
	## M-139: el cartel lleva los minutos por las dos caras.
	var cartel := CuartoArbitro.cartel(4)
	var textos := 0
	for l in cartel.find_children("*", "Label3D", true, false):
		if (l as Label3D).text == "+4":
			textos += 1
	_comprobar(textos == 2, "cuarto árbitro: «+4» por las dos caras (%d)" % textos)
	cartel.free()
	## M-149: la red se abomba hacia fuera desde donde entra el balón.
	var raiz := Node3D.new()
	add_child(raiz)
	var poste := StandardMaterial3D.new()
	StadiumBuilder._add_goal(raiz, 52.5, poste, Color.WHITE)
	StadiumBuilder._add_goal(raiz, -52.5, poste, Color.WHITE)
	_comprobar(RedArco.golpe(raiz, Vector3(1.0, 1.2, 53.3)), "red: el gol encuentra su arco")
	var fondo: MeshInstance3D = null
	for m in raiz.find_children("RedFondo", "MeshInstance3D", true, false):
		if (m as MeshInstance3D).global_position.z > 0.0:
			fondo = m
	var fz := float((fondo.material_override as ShaderMaterial).get_shader_parameter("fuerza")) if fondo != null else 0.0
	_comprobar(fz > 0.3, "red: el paño de fondo recibe la onda (fuerza %.2f)" % fz)
	_comprobar((fondo.mesh as QuadMesh).subdivide_width >= 16 if fondo != null else false, "red: el paño está subdividido para ondularse")
	raiz.queue_free()
	## M-118: el tramo de la línea se recorta al monitor.
	var sala := SalaVAR.new()
	var rec: Array = sala.call("_recortar", Vector2(-3, 0), Vector2(3, 0.2), Vector2(1, 0.5))
	_comprobar(rec.size() == 2 and absf((rec[0] as Vector2).x + 1.0) < 0.01 and absf((rec[1] as Vector2).x - 1.0) < 0.01, "VAR: la línea se recorta al borde del monitor")
	_comprobar((sala.call("_recortar", Vector2(-3, 2), Vector2(3, 2), Vector2(1, 0.5)) as Array).is_empty(), "VAR: una línea fuera del monitor no se dibuja")
	sala.free()
	## M-050: con el motor ligero no hay festejo.
	var ligero := Calidad.motor_ligero
	Calidad.motor_ligero = true
	_comprobar(not FestejoGrada.activo(), "festejo: apagado con el motor ligero")
	Calidad.motor_ligero = ligero


func _probar_transmision_y_estadisticas() -> void:
	_titulo("PARTIDO 3D: CÁMARA DE TRANSMISIÓN INTELIGENTE Y ESTADÍSTICAS")
	var dt := 1.0 / 60.0
	## 1) En TODOS los estadios y alturas: dentro del cuenco, sin tirones.
	var fuera: Array = []
	var tirones: Array = []
	var techo: Array = []
	for forma: String in ["ingles", "rect", "herradura", "caldera", "oval", "dos", "principal", "cuenco"]:
		var g := StadiumBuilder.geom_de_forma(forma)
		for n in [1, 2, 3, 5]:
			var alto := StadiumBuilder.ALTURA_PIE + float(n) * StadiumBuilder.subida_bandeja() + float(n - 1) * StadiumBuilder.FRENTE_BANDEJA
			var rig := CameraRig.new()
			add_child(rig)
			rig.set_process(false)
			rig.build_for(float(g["dx"]), float(g["dz"]), alto)
			var cam: Camera3D = rig.cameras[0]
			var antes := Vector3.INF
			var fov_antes := -1.0
			var max_v := 0.0
			var max_fov := 0.0
			for i in 1500:
				var tt := float(i) * dt
				## Un balón que va y viene de área a área, con un salto a mitad
				## (saque de centro tras un gol) y una ocasión.
				var b := Vector3(sin(tt * 0.7) * 30.0, 0.1, sin(tt * 0.45) * 50.0)
				if i >= 700 and i < 760:
					b = Vector3(0, 0.1, 0)
				rig.pista_estado = "juego"
				rig.pista_ataca = 1.0 if cos(tt * 0.45) >= 0.0 else -1.0
				if i == 1000:
					rig.pista_ocasion = 1.4
				rig._transmision(cam, b, dt)
				var p := cam.global_position
				if p.x > float(g["dx"]) - 6.9 or absf(p.z) > CameraRig.CARRO_Z_MAX + 0.01 or p.y > 24.01 or p.y < 8.99:
					fuera.append("%s/%d" % [forma, n])
					break
				var losa := alto + 0.4
				if p.y > losa - 1.15 and p.y < losa + 1.6:
					techo.append("%s/%d y=%.1f" % [forma, n, p.y])
					break
				if antes != Vector3.INF:
					max_v = maxf(max_v, p.distance_to(antes) / dt)
					max_fov = maxf(max_fov, absf(cam.fov - fov_antes) / dt)
				antes = p
				fov_antes = cam.fov
			if max_v > CameraRig.CARRO_VMAX * 1.25 or max_fov > CameraRig.ZOOM_VMAX * 1.1:
				tirones.append("%s/%d v=%.1f fov=%.1f" % [forma, n, max_v, max_fov])
			rig.free()
	_comprobar(fuera.is_empty(), "la transmisión no sale de su raíl en ningún estadio (x fija en el cuenco, |z| ≤ 38) %s" % str(fuera))
	_comprobar(techo.is_empty(), "la cámara nunca queda a la altura de la losa del techo %s" % str(techo))
	_comprobar(tirones.is_empty(), "sin tirones: el carro ≤ %.0f m/s y el zoom ≤ %.0f°/s, también tras un salto del balón %s" % [CameraRig.CARRO_VMAX * 1.25, CameraRig.ZOOM_VMAX * 1.1, str(tirones)])
	## 2) Lo que lee de la jugada.
	var rig2 := CameraRig.new()
	add_child(rig2)
	rig2.set_process(false)
	rig2.build_for(49.0, 68.0, 13.0)
	var c2: Camera3D = rig2.cameras[0]
	rig2.pista_estado = "juego"
	rig2.pista_ataca = 1.0
	for i in 60:
		rig2._transmision(c2, Vector3(0, 0.1, -5.0), dt)
	var fov_medio := c2.fov
	_comprobar(rig2.trans_plano == "normal" and absf(fov_medio - CameraRig.FOV_TRANSMISION) < 1.0, "en el medio del campo, plano normal (%s, %.1f°)" % [rig2.trans_plano, fov_medio])
	for i in 240:
		rig2._transmision(c2, Vector3(5.0, 0.1, 40.0), dt)
	_comprobar(rig2.trans_plano == "area" and c2.fov < CameraRig.FOV_TRANSMISION - 4.0, "con la jugada en el área el plano se cierra (%s, %.1f°)" % [rig2.trans_plano, c2.fov])
	rig2.pista_ocasion = 1.4
	rig2._transmision(c2, Vector3(5.0, 0.1, 40.0), dt)
	_comprobar(rig2.trans_plano == "ocasion", "un tiro en el aire es «ocasión» (%s)" % rig2.trans_plano)
	## El foco no tiembla con el balón que se mueve dentro de la zona muerta.
	var r_antes := CameraRig.new()
	add_child(r_antes)
	r_antes.set_process(false)
	r_antes.build_for(49.0, 68.0, 13.0)
	var c3: Camera3D = r_antes.cameras[0]
	r_antes.pista_estado = "juego"
	r_antes.pista_ataca = 1.0
	for i in 200:
		r_antes._transmision(c3, Vector3(0, 0.1, 0), dt)
	var f0 := r_antes._trans_foco
	var mov := 0.0
	for i in 240:
		r_antes._transmision(c3, Vector3(sin(i * 0.3) * 0.8, 0.1, cos(i * 0.21) * 1.2), dt)
		mov = maxf(mov, r_antes._trans_foco.distance_to(f0))
	_comprobar(mov < 0.6, "zona muerta: el balón que se mueve 1 m no mueve el plano (%.2f m)" % mov)
	## Contraataque: el balón cruza el campo rápido hacia la portería rival.
	var r4 := CameraRig.new()
	add_child(r4)
	r4.set_process(false)
	r4.build_for(49.0, 68.0, 13.0)
	var c4: Camera3D = r4.cameras[0]
	r4.pista_estado = "juego"
	r4.pista_ataca = 1.0
	for i in 30:
		r4._transmision(c4, Vector3(0, 0.1, -40.0), dt)
	var abierto := false
	var fov_max := 0.0
	var adelanta := false
	for i in 150:
		var bz := -40.0 + 12.0 * float(i) * dt
		r4._transmision(c4, Vector3(0, 0.1, bz), dt)
		abierto = abierto or r4.trans_plano == "abierto"
		fov_max = maxf(fov_max, c4.fov)
		if i == 120:
			adelanta = r4._trans_foco.z > bz
	_comprobar(abierto and fov_max > CameraRig.FOV_TRANSMISION + 2.5, "en el contraataque el plano se abre (%.1f°)" % fov_max)
	_comprobar(adelanta, "el plano se adelanta hacia donde va el balón")
	_comprobar(CameraRig.lectura_jugada(Vector3(0, 0, 40), Vector3.ZERO, 1.0, false, "puerta", "saque").x == 0.0, "en un saque de puerta no se cierra el plano")
	_comprobar(CameraRig.lectura_jugada(Vector3(30, 0, 52), Vector3.ZERO, 1.0, false, "corner", "saque").x == 1.0, "en un córner se cierra el plano")
	var z0 := CameraRig.amortiguar(0.0, 10.0, 0.0, 0.5, 100.0, 1.0)
	_comprobar(z0.x <= 10.0 and z0.x > 5.0, "el amortiguador no se pasa del objetivo con un fotograma largo (%.2f)" % z0.x)
	rig2.free()
	r_antes.free()
	r4.free()
	## 3) Las estadísticas.
	var penal := EstadisticasVivo.xg_de(Vector2(0, 41.5), true)
	var cerca := EstadisticasVivo.xg_de(Vector2(0, 46.5), true)
	var lejos := EstadisticasVivo.xg_de(Vector2(0, 27.5), true)
	var esquina := EstadisticasVivo.xg_de(Vector2(25, 50.0), true)
	_comprobar(cerca > penal and penal > lejos and lejos < 0.06 and cerca > 0.4, "xG por distancia: 6 m %.2f > 11 m %.2f > 25 m %.2f" % [cerca, penal, lejos])
	_comprobar(esquina < 0.05, "sin ángulo casi no hay xG (%.3f)" % esquina)
	_comprobar(absf(EstadisticasVivo.xg_de(Vector2(0, -41.5), false) - penal) < 0.001, "la visita ataca hacia -Z con la misma vara")
	var ev := EstadisticasVivo.new()
	ev.anotar_tiro(true, Vector2(2, 38), 12)
	ev.anotar_tiro(false, Vector2(-3, -30), 20)
	ev.cerrar_tiro(true, "atajada")
	ev.cerrar_tiro(false, "gol")
	ev.cerrar_tiro(true, "gol", Vector3(0, 0, 50))
	ev.tarjeta(true, false)
	ev.tarjeta(false, true)
	ev.anotar_calor(0, Vector2(0, 40))
	ev.anotar_calor(0, Vector2(0, 41))
	_comprobar(ev.n_tiros(true) == 2 and String(ev.tiros[0]["res"]) == "atajada" and String(ev.tiros[2]["res"]) == "gol",
		"cada remate guarda cómo acabó (y un gol de rebote se apunta aparte)")
	_comprobar(ev.amarillas == [1, 0] and ev.rojas == [0, 1], "tarjetas por equipo")
	## M-137: xA = el xG de los remates que salieron de un pase.
	(ev.tiros[0] as Dictionary)["asist"] = "pasador"
	_comprobar(is_equal_approx(ev.xa(true), float(ev.tiros[0]["xg"])) and ev.xa(false) == 0.0
		and is_equal_approx(float(ev.xa_por_jugador().get("pasador", 0.0)), float(ev.tiros[0]["xg"])), "xA: el pase previo se lleva el xG del remate")
	## M-162: la tabla y los remates, a CSV.
	var ruta_csv := ev.a_csv(null, null)
	var txt_csv := FileAccess.get_file_as_string(ruta_csv) if ruta_csv != "" else ""
	_comprobar(txt_csv.contains("remate;equipo;minuto") and txt_csv.contains(";pasador") and txt_csv.contains("Tarjetas rojas"),
		"CSV: el partido se exporta con la tabla y cada remate")
	if ruta_csv != "":
		DirAccess.remove_absolute(ruta_csv)
	var celda := int((40.0 + 52.5) / 105.0 * EstadisticasVivo.COLS) + int(34.0 / 68.0 * EstadisticasVivo.FILAS) * EstadisticasVivo.COLS
	_comprobar((ev.calor[0] as PackedInt32Array)[celda] == 2, "el mapa de calor cuenta por zonas")
	var ca := Club.new()
	ca.nombre = "Local de prueba"
	var cb := Club.new()
	cb.nombre = "Visita de prueba"
	var pa := Partido.new(ca, cb)
	pa.posesion_local = 58.0
	pa.remates_local = 7
	pa.tiros_puerta_local = 3
	var filas := ev.resumen(pa, null)
	var nombres: Array = filas.map(func(f: Array) -> String: return String(f[0]))
	var faltan: Array = []
	for k: String in ["Posesión", "Tiros", "Tiros a puerta", "Goles esperados (xG)", "Córners", "Faltas", "Tarjetas amarillas", "Tarjetas rojas"]:
		if not k in nombres:
			faltan.append(k)
	_comprobar(faltan.is_empty() and String(filas[0][1]) == "58%", "el resumen tiene todas las filas %s" % str(faltan))
	var hechos := {}
	_comprobar(RotuloEstadisticas.cuando(10, "saque", 1, hechos) == "", "antes del 17' no hay rótulo")
	_comprobar(RotuloEstadisticas.cuando(18, "juego", 1, hechos) == "", "con el balón en juego no hay rótulo")
	_comprobar(RotuloEstadisticas.cuando(18, "saque", 1, hechos) == "primero", "en la primera pelota parada pasado el 17' sale el rótulo")
	hechos["primero"] = true
	_comprobar(RotuloEstadisticas.cuando(25, "saque", 1, hechos) == "" and RotuloEstadisticas.cuando(45, "descanso", 1, hechos) == "descanso"
		and RotuloEstadisticas.cuando(66, "saque", 2, hechos) == "segundo", "uno por momento: 17', descanso y 65'")
	## El panel se arma (tabla + dos campos) sin motor.
	var raiz := Control.new()
	add_child(raiz)
	var panel := PanelEstadisticas.abrir(raiz, pa, null, ev)
	_comprobar(panel != null and panel.get_child_count() > 0, "el panel de estadísticas se arma")
	var rot := RotuloEstadisticas.mostrar(raiz, "descanso", pa, null, ev)
	_comprobar(rot != null and rot.get_child_count() > 0, "el rótulo de la tele se arma")
	raiz.free()
	## El botón: configurable y sin pisar a nadie.
	Mando.registrar()
	_comprobar(InputMap.has_action("jugar_estadisticas"), "«Estadísticas del partido» tiene su acción en el InputMap")
	var pisa: Array = []
	for a: String in Mando.MAPA:
		if a == "jugar_estadisticas":
			continue
		for k: int in Mando.teclas_de("jugar_estadisticas"):
			if k in Mando.teclas_de(a):
				pisa.append(a)
		for b: int in Mando.botones_de("jugar_estadisticas"):
			if b in Mando.botones_de(a):
				pisa.append(a)
	_comprobar(pisa.is_empty(), "su tecla y su botón no son de otra acción %s" % str(pisa))
	var en_grupo := false
	for gr: Array in PanelControles.GRUPOS:
		en_grupo = en_grupo or "jugar_estadisticas" in (gr[1] as Array)
	_comprobar(en_grupo, "se puede reasignar en la pantalla de controles")
